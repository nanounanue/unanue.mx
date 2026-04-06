;;; publish.el --- Build script for unanue.mx  -*- lexical-binding: t; -*-
;;
;; Run with:
;;   emacs -Q --batch --load publish.el --funcall org-publish-all
;;
;; Produces a static site under ./public/ styled with Tufte CSS, including
;; post-processing of Org footnotes into Tufte-style sidenotes.

;;; Code:

(require 'package)
(setq package-user-dir (expand-file-name ".packages" (file-name-directory load-file-name)))
(setq package-archives '(("gnu"   . "https://elpa.gnu.org/packages/")
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

;; ---------------------------------------------------------------------------
;; Paths
;; ---------------------------------------------------------------------------

(defvar unanue/root (file-name-directory (or load-file-name buffer-file-name))
  "Absolute path to the repository root.")

(defvar unanue/org-dir   (expand-file-name "org"    unanue/root))
(defvar unanue/out-dir   (expand-file-name "public" unanue/root))
(defvar unanue/static-dir (expand-file-name "static" unanue/root))

;; ---------------------------------------------------------------------------
;; Tufte HTML backend: sidenotes from Org footnotes
;; ---------------------------------------------------------------------------
;;
;; Org footnote reference  ->  Tufte sidenote markup:
;;
;;   <label for="sn-1" class="margin-toggle sidenote-number"></label>
;;   <input type="checkbox" id="sn-1" class="margin-toggle"/>
;;   <span class="sidenote">footnote body</span>
;;
;; The bottom "Footnotes" section is suppressed (replaced by an HTML comment)
;; since the content is now inlined at each reference.

(defun unanue/strip-outer-p (html)
  "Remove a single outer <p>…</p> wrapper, if present, from HTML."
  (let ((s (org-trim (or html ""))))
    (if (string-match "\\`<p[^>]*>\\(\\(?:.\\|\n\\)*\\)</p>\\'" s)
        (org-trim (match-string 1 s))
      s)))

(defun unanue/footnote-reference (footnote-reference _contents info)
  "Transcode a FOOTNOTE-REFERENCE element into Tufte sidenote HTML."
  (let* ((n   (org-export-get-footnote-number footnote-reference info))
         (def (org-export-get-footnote-definition footnote-reference info))
         (raw (if def (org-export-data def info) ""))
         (body (unanue/strip-outer-p raw))
         (id  (format "sn-%d" n)))
    (format (concat
             "<label for=\"%s\" class=\"margin-toggle sidenote-number\"></label>"
             "<input type=\"checkbox\" id=\"%s\" class=\"margin-toggle\"/>"
             "<span class=\"sidenote\">%s</span>")
            id id body)))

(org-export-define-derived-backend 'tufte-html 'html
  :translate-alist '((footnote-reference . unanue/footnote-reference)))

(defun org-tufte-publish-to-html (plist filename pub-dir)
  "Publish an Org file to Tufte-styled HTML.
PLIST is the property list of the publishing project; FILENAME the
source file; PUB-DIR the target directory."
  ;; Suppress the bottom footnotes section: the template expects two %s
  ;; placeholders (label + body), so we use an HTML comment that consumes
  ;; both without rendering anything visible.
  (let ((org-html-footnotes-section "<!-- tufte:sidenotes %s %s -->")
        (org-html-divs
         '((preamble  "header" "preamble")
           (content   "article" "content")
           (postamble "footer" "postamble"))))
    (org-publish-org-to 'tufte-html filename ".html" plist pub-dir)))

;; ---------------------------------------------------------------------------
;; HTML head: link Tufte CSS and viewport
;; ---------------------------------------------------------------------------

(defvar unanue/html-head
  (concat
   "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"/>\n"
   "<link rel=\"stylesheet\" href=\"/tufte-css/tufte.css\"/>\n"
   "<link rel=\"stylesheet\" href=\"/static/site.css\"/>\n")
  "Extra <head> content injected into every page.")

;; ---------------------------------------------------------------------------
;; Publishing project
;; ---------------------------------------------------------------------------

(setq org-publish-project-alist
      `(("unanue-content"
         :base-directory       ,unanue/org-dir
         :base-extension       "org"
         :recursive            t
         :publishing-directory ,unanue/out-dir
         :publishing-function  org-tufte-publish-to-html
         :exclude              "setup\\.org\\|.*\\.draft\\.org"

         ;; Export options
         :with-toc             t
         :section-numbers      nil
         :with-author          t
         :with-creator         nil
         :with-date            t
         :with-footnotes       t
         :with-smart-quotes    t
         :with-sub-superscript t
         :html-doctype         "html5"
         :html-html5-fancy     t
         :html-head-include-default-style nil
         :html-head-include-scripts       nil
         :html-head            ,unanue/html-head
         :html-postamble       nil
         :html-validation-link nil
         :html-container       "section"

         ;; Sitemap (index of posts)
         :auto-sitemap         t
         :sitemap-filename     "sitemap.org"
         :sitemap-title        "Sitemap"
         :sitemap-sort-files   anti-chronologically
         :sitemap-style        list)

        ("unanue-static"
         :base-directory       ,unanue/static-dir
         :base-extension       "css\\|js\\|png\\|jpg\\|jpeg\\|gif\\|svg\\|webp\\|pdf\\|ico\\|txt\\|woff\\|woff2\\|ttf\\|eot\\|otf"
         :recursive            t
         :publishing-directory ,unanue/out-dir
         :publishing-function  org-publish-attachment)

        ("unanue" :components ("unanue-content" "unanue-static"))))

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
