;;; export.el --- Batch-export the site sources to Hugo content -*- lexical-binding: t; -*-
;; Run: emacs --batch -l tools/export.el
;; Loads packages from tools/elpa (see install-packages.el), never from
;; the personal Emacs configuration.
;;
;; Exports site.org (one subtree per page), then every post file in
;; writing/ (one file per post). Drafts named *.draft.org are gitignored,
;; so CI never sees them; locally they export and `hugo server -D' shows
;; them.
(require 'package)
(setq package-user-dir (expand-file-name "elpa" (file-name-directory load-file-name)))
(package-initialize)
(require 'ox-hugo)
(let* ((root (expand-file-name ".." (file-name-directory load-file-name)))
       (site-org (expand-file-name "site.org" root))
       (writing (expand-file-name "writing" root)))
  (unless (file-exists-p site-org)
    (error "site.org not found at %s" site-org))
  (dolist (org-file (cons site-org
                          ;; writing/ can be absent in a checkout where every
                          ;; post is still a gitignored draft.
                          (and (file-directory-p writing)
                               (directory-files writing t "\\`[^.#].*\\.org\\'"))))
    (with-current-buffer (find-file-noselect org-file)
      (org-hugo-export-wim-to-md :all-subtrees))))
(message "ox-hugo export complete")
