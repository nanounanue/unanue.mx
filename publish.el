;;; publish.el --- Build script for unanue.mx  -*- lexical-binding: t; -*-
;;
;; Run with:
;;   emacs -Q --batch --load publish.el --funcall org-publish-all
;;
;; Produces a static site under ./public/ styled with Tufte CSS.  Features:
;;   - Footnotes rewritten into Tufte sidenotes (custom `tufte-html' backend)
;;   - Auto-generated index of posts at /posts/, sorted by #+DATE
;;   - RSS 2.0 feed at /feed.xml
;;   - Tag pages at /tags/<tag>.html (from #+FILETAGS:)

;;; Code:

(require 'package)
(setq package-user-dir (expand-file-name ".packages" (file-name-directory load-file-name)))
(setq package-archives '(("gnu"    . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")))
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))
(dolist (pkg '(org htmlize))
  (unless (package-installed-p pkg)
    (package-install pkg)))

(require 'ox-publish)
(require 'ox-html)
(require 'htmlize)
(require 'xml)
(require 'seq)

;; ---------------------------------------------------------------------------
;; Paths and site metadata
;; ---------------------------------------------------------------------------

(defvar unanue/root (file-name-directory (or load-file-name buffer-file-name))
  "Absolute path to the repository root.")

(defvar unanue/org-dir    (expand-file-name "org"    unanue/root))
(defvar unanue/out-dir    (expand-file-name "public" unanue/root))
(defvar unanue/static-dir (expand-file-name "static" unanue/root))
(defvar unanue/posts-src  (expand-file-name "posts"  unanue/org-dir))
(defvar unanue/posts-out  (expand-file-name "posts"  unanue/out-dir))

(defvar unanue/site-url    "https://unanue.mx")
(defvar unanue/site-title  "Adolfo De Unánue")
(defvar unanue/site-descr  "Machine Learning · Operations Research · Political Economy")

;; ---------------------------------------------------------------------------
;; Tufte HTML backend: Org footnotes -> Tufte sidenotes
;; ---------------------------------------------------------------------------

(defun unanue/strip-outer-p (html)
  "Remove a single outer <p>…</p> wrapper from HTML, if present."
  (let ((s (org-trim (or html ""))))
    (if (string-match "\\`<p[^>]*>\\(\\(?:.\\|\n\\)*\\)</p>\\'" s)
        (org-trim (match-string 1 s))
      s)))

(defun unanue/footnote-reference (footnote-reference _contents info)
  "Transcode FOOTNOTE-REFERENCE into Tufte sidenote HTML."
  (let* ((n    (org-export-get-footnote-number footnote-reference info))
         (def  (org-export-get-footnote-definition footnote-reference info))
         (raw  (if def (org-export-data def info) ""))
         (body (unanue/strip-outer-p raw))
         (id   (format "sn-%d" n)))
    (format (concat
             "<label for=\"%s\" class=\"margin-toggle sidenote-number\"></label>"
             "<input type=\"checkbox\" id=\"%s\" class=\"margin-toggle\"/>"
             "<span class=\"sidenote\">%s</span>")
            id id body)))

(org-export-define-derived-backend 'tufte-html 'html
  :translate-alist '((footnote-reference . unanue/footnote-reference)))

(defun org-tufte-publish-to-html (plist filename pub-dir)
  "Publish FILENAME as Tufte-styled HTML.
The bottom footnotes section is suppressed via an HTML comment that
absorbs the two %s placeholders Org inserts."
  (let ((org-html-footnotes-section "<!-- tufte:sidenotes %s %s -->")
        (org-html-divs
         '((preamble  "header" "preamble")
           (content   "article" "content")
           (postamble "footer" "postamble"))))
    (org-publish-org-to 'tufte-html filename ".html" plist pub-dir)))

;; ---------------------------------------------------------------------------
;; HTML head (injected into every page)
;; ---------------------------------------------------------------------------

(defvar unanue/html-head
  (concat
   "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"/>\n"
   "<link rel=\"stylesheet\" href=\"/tufte-css/tufte.css\"/>\n"
   "<link rel=\"stylesheet\" href=\"/site.css\"/>\n"
   "<link rel=\"alternate\" type=\"application/rss+xml\""
   " title=\"unanue.mx — posts\" href=\"/feed.xml\"/>\n")
  "Extra <head> content injected into every page.")

;; ---------------------------------------------------------------------------
;; File metadata helpers (read #+TITLE / #+DATE / #+FILETAGS from a file)
;; ---------------------------------------------------------------------------

(defun unanue/file-title (file)
  "Return the #+TITLE of FILE, or its basename."
  (with-temp-buffer
    (insert-file-contents file nil 0 4000)
    (goto-char (point-min))
    (if (re-search-forward "^#\\+TITLE:[ \t]+\\(.*?\\)[ \t]*$" nil t)
        (match-string 1)
      (file-name-base file))))

(defun unanue/file-date (file)
  "Return the #+DATE of FILE as an Emacs time value, or nil.
Accepts either an Org timestamp (<YYYY-MM-DD>) or a plain
YYYY-MM-DD string."
  (with-temp-buffer
    (insert-file-contents file nil 0 4000)
    (goto-char (point-min))
    (when (re-search-forward
           "^#\\+DATE:[ \t]+[<\\[]?\\([0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}\\)"
           nil t)
      (org-time-string-to-time (match-string 1)))))

(defun unanue/file-filetags (file)
  "Return the list of #+FILETAGS: declared in FILE, or nil.
Accepts either `:tag1:tag2:' or `tag1 tag2' syntax."
  (with-temp-buffer
    (insert-file-contents file nil 0 4000)
    (goto-char (point-min))
    (when (re-search-forward "^#\\+FILETAGS:[ \t]+\\(.*?\\)[ \t]*$" nil t)
      (split-string (match-string 1) "[ :]+" t))))

(defun unanue/list-posts ()
  "Return the list of post source files under org/posts/.
Excludes the auto-generated index.org / sitemap.org."
  (seq-remove
   (lambda (f)
     (member (file-name-nondirectory f) '("index.org" "sitemap.org")))
   (directory-files unanue/posts-src t "\\.org\\'")))

(defun unanue/date< (a b)
  "Return non-nil if time A is earlier than B. Nil dates sort last."
  (cond ((and a b) (time-less-p a b))
        (b t)
        (t nil)))

;; ---------------------------------------------------------------------------
;; Sitemap entry formatter (for the auto-generated org/posts/index.org)
;; ---------------------------------------------------------------------------
;;
;; Note: `org-publish-sitemap' sorts with `:sitemap-sort-files
;; anti-chronologically' using `org-publish-find-date', which returns
;; the file's #+DATE keyword when it is a proper Org timestamp
;; (<YYYY-MM-DD> or [YYYY-MM-DD]), and falls back to the file's mtime
;; otherwise.  Write post dates as <YYYY-MM-DD> to get deterministic,
;; DATE-based ordering.

(defun unanue/sitemap-format-entry (entry style _project)
  "Format ENTRY as `YYYY-MM-DD — [[file:entry][title]]'."
  (cond
   ((not (directory-name-p entry))
    (let* ((full  (expand-file-name entry unanue/posts-src))
           (title (unanue/file-title full))
           (date  (or (unanue/file-date full)
                      (file-attribute-modification-time
                       (file-attributes full)))))
      (format "%s — [[file:%s][%s]]"
              (format-time-string "%Y-%m-%d" date)
              entry
              title)))
   ((eq style 'tree)
    (file-name-nondirectory (directory-file-name entry)))
   (t entry)))

;; ---------------------------------------------------------------------------
;; RSS feed generation (public/feed.xml)
;; ---------------------------------------------------------------------------

(defun unanue/rss-date (time)
  "Format TIME as RFC-822 for RSS."
  (let ((system-time-locale "C"))
    (format-time-string "%a, %d %b %Y %H:%M:%S %z" time)))

(defun unanue/generate-rss ()
  "Write public/feed.xml from all posts under org/posts/."
  (let* ((posts (unanue/list-posts))
         (items (delq nil
                      (mapcar
                       (lambda (f)
                         (let ((date (unanue/file-date f)))
                           (when date
                             (list :title (unanue/file-title f)
                                   :date  date
                                   :link  (format "%s/posts/%s.html"
                                                  unanue/site-url
                                                  (file-name-base f))))))
                       posts)))
         (items (sort items
                      (lambda (a b)
                        (unanue/date< (plist-get b :date)
                                      (plist-get a :date)))))
         (feed-path (expand-file-name "feed.xml" unanue/out-dir)))
    (make-directory unanue/out-dir t)
    (with-temp-file feed-path
      (insert "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
      (insert "<rss version=\"2.0\" xmlns:atom=\"http://www.w3.org/2005/Atom\">\n")
      (insert "  <channel>\n")
      (insert (format "    <title>%s</title>\n"
                      (xml-escape-string unanue/site-title)))
      (insert (format "    <link>%s/</link>\n" unanue/site-url))
      (insert (format "    <atom:link href=\"%s/feed.xml\" rel=\"self\" type=\"application/rss+xml\"/>\n"
                      unanue/site-url))
      (insert (format "    <description>%s</description>\n"
                      (xml-escape-string unanue/site-descr)))
      (insert "    <language>en</language>\n")
      (insert (format "    <lastBuildDate>%s</lastBuildDate>\n"
                      (unanue/rss-date (current-time))))
      (dolist (it items)
        (insert "    <item>\n")
        (insert (format "      <title>%s</title>\n"
                        (xml-escape-string (plist-get it :title))))
        (insert (format "      <link>%s</link>\n" (plist-get it :link)))
        (insert (format "      <guid isPermaLink=\"true\">%s</guid>\n"
                        (plist-get it :link)))
        (insert (format "      <pubDate>%s</pubDate>\n"
                        (unanue/rss-date (plist-get it :date))))
        (insert "    </item>\n"))
      (insert "  </channel>\n</rss>\n"))
    (message "[unanue] wrote %s (%d items)" feed-path (length items))))

;; ---------------------------------------------------------------------------
;; Tag pages (public/tags/<tag>.html and public/tags/index.html)
;; ---------------------------------------------------------------------------

(defun unanue/collect-tags ()
  "Return a hash table TAG -> list-of-post-files."
  (let ((tags (make-hash-table :test 'equal)))
    (dolist (f (unanue/list-posts))
      (dolist (tag (unanue/file-filetags f))
        (puthash tag (cons f (gethash tag tags)) tags)))
    tags))

(defun unanue/html-page (title body out-file)
  "Write a minimal Tufte-styled HTML page.
TITLE becomes <title>; BODY is inserted inside <article>."
  (make-directory (file-name-directory out-file) t)
  (with-temp-file out-file
    (insert "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n")
    (insert "<meta charset=\"UTF-8\"/>\n")
    (insert "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"/>\n")
    (insert (format "<title>%s — %s</title>\n"
                    (xml-escape-string title)
                    (xml-escape-string unanue/site-title)))
    (insert "<link rel=\"stylesheet\" href=\"/tufte-css/tufte.css\"/>\n")
    (insert "<link rel=\"stylesheet\" href=\"/site.css\"/>\n")
    (insert "<link rel=\"alternate\" type=\"application/rss+xml\" href=\"/feed.xml\"/>\n")
    (insert "</head>\n<body>\n<article>\n")
    (insert body)
    (insert "\n</article>\n</body>\n</html>\n")))

(defun unanue/tag-page-body (tag files)
  "Return the HTML body listing FILES, a list of post files tagged TAG."
  (let ((sorted (sort (copy-sequence files)
                      (lambda (a b)
                        (unanue/date< (unanue/file-date b)
                                      (unanue/file-date a))))))
    (concat
     (format "<h1>Posts tagged <code>#%s</code></h1>\n"
             (xml-escape-string tag))
     "<p><a href=\"/tags/\">All tags</a> · <a href=\"/posts/\">All posts</a></p>\n"
     "<ul>\n"
     (mapconcat
      (lambda (f)
        (let ((title (unanue/file-title f))
              (date  (unanue/file-date f))
              (slug  (file-name-base f)))
          (format "  <li>%s — <a href=\"/posts/%s.html\">%s</a></li>"
                  (if date (format-time-string "%Y-%m-%d" date) "—")
                  slug
                  (xml-escape-string title))))
      sorted "\n")
     "\n</ul>\n")))

(defun unanue/tag-index-body (tag-counts)
  "Return the HTML body for /tags/index.html. TAG-COUNTS is an alist (tag . n)."
  (let ((sorted (sort (copy-sequence tag-counts)
                      (lambda (a b) (string< (car a) (car b))))))
    (concat
     "<h1>Tags</h1>\n"
     "<p><a href=\"/posts/\">All posts</a></p>\n"
     (if (null sorted)
         "<p><em>No tags yet.</em></p>"
       (concat
        "<ul>\n"
        (mapconcat
         (lambda (pair)
           (format "  <li><a href=\"/tags/%s.html\">#%s</a> — %d post%s</li>"
                   (car pair)
                   (xml-escape-string (car pair))
                   (cdr pair)
                   (if (= 1 (cdr pair)) "" "s")))
         sorted "\n")
        "\n</ul>\n")))))

(defun unanue/generate-tag-pages ()
  "Generate public/tags/index.html and one page per tag."
  (let* ((tags     (unanue/collect-tags))
         (tags-dir (expand-file-name "tags" unanue/out-dir))
         (counts   '()))
    (maphash
     (lambda (tag files)
       (push (cons tag (length files)) counts)
       (unanue/html-page
        (format "Tag: %s" tag)
        (unanue/tag-page-body tag files)
        (expand-file-name (format "%s.html" tag) tags-dir)))
     tags)
    (unanue/html-page
     "Tags"
     (unanue/tag-index-body counts)
     (expand-file-name "index.html" tags-dir))
    (message "[unanue] generated %d tag page(s)" (hash-table-count tags))))

;; ---------------------------------------------------------------------------
;; Posts completion hook: runs after org-publish finishes the posts project
;; ---------------------------------------------------------------------------

(defun unanue/posts-completion ()
  "Post-publish hook for the posts project: RSS + tag pages."
  (unanue/generate-rss)
  (unanue/generate-tag-pages))

;; ---------------------------------------------------------------------------
;; Publishing project
;; ---------------------------------------------------------------------------

(defvar unanue/common-html-opts
  `(:with-toc              t
    :section-numbers       nil
    :with-author           t
    :with-creator          nil
    :with-date             t
    :with-footnotes        t
    :with-smart-quotes     t
    :with-sub-superscript  t
    :html-doctype          "html5"
    :html-html5-fancy      t
    :html-head-include-default-style nil
    :html-head-include-scripts       nil
    :html-head             ,unanue/html-head
    :html-postamble        nil
    :html-validation-link  nil)
  "Shared HTML export options for every project component.")

(defun unanue/make-project (name &optional subdir &rest extra)
  "Build a project entry rooted at org/SUBDIR (or org/ if SUBDIR is nil).
EXTRA is appended to the plist and may override defaults."
  (let ((src (if subdir (expand-file-name subdir unanue/org-dir) unanue/org-dir))
        (dst (if subdir (expand-file-name subdir unanue/out-dir) unanue/out-dir)))
    (cons name
          (append
           (list :base-directory       src
                 :base-extension       "org"
                 :recursive            nil
                 :publishing-directory dst
                 :publishing-function  'org-tufte-publish-to-html)
           unanue/common-html-opts
           extra))))

(setq org-publish-project-alist
      (list
       ;; Top-level pages (org/index.org, org/about.org, …)
       (unanue/make-project "unanue-pages")

       ;; Posts: auto-sitemap -> posts/index.html, RSS + tags after publish
       (unanue/make-project
        "unanue-posts" "posts"
        :auto-sitemap         t
        :sitemap-filename     "index.org"
        :sitemap-title        "Posts"
        :sitemap-sort-files   'anti-chronologically
        :sitemap-format-entry 'unanue/sitemap-format-entry
        :completion-function  'unanue/posts-completion)

       ;; Papers and projects: plain per-section publishing (add auto-sitemap
       ;; later if desired)
       (unanue/make-project "unanue-papers"   "papers")
       (unanue/make-project "unanue-projects" "projects")

       ;; Static assets (tufte.css, fonts, site.css, favicons, etc.)
       `("unanue-static"
         :base-directory       ,unanue/static-dir
         :base-extension       "css\\|js\\|png\\|jpg\\|jpeg\\|gif\\|svg\\|webp\\|pdf\\|ico\\|txt\\|woff\\|woff2\\|ttf\\|eot\\|otf"
         :recursive            t
         :publishing-directory ,unanue/out-dir
         :publishing-function  org-publish-attachment)

       '("unanue"
         :components ("unanue-pages"
                      "unanue-posts"
                      "unanue-papers"
                      "unanue-projects"
                      "unanue-static"))))

;; ---------------------------------------------------------------------------
;; Misc export settings
;; ---------------------------------------------------------------------------

(setq org-export-with-broken-links 'mark
      org-export-with-toc          t
      org-export-headline-levels   4
      org-html-htmlize-output-type 'css
      org-confirm-babel-evaluate   nil
      make-backup-files            nil)

(provide 'publish)
;;; publish.el ends here
