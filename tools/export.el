;;; export.el --- Batch-export site.org to Hugo content -*- lexical-binding: t; -*-
;; Run: emacs --batch -l tools/export.el
;; Loads packages from tools/elpa (see install-packages.el), never from
;; the personal Emacs configuration.
(require 'package)
(setq package-user-dir (expand-file-name "elpa" (file-name-directory load-file-name)))
(package-initialize)
(require 'ox-hugo)
(let ((site-org (expand-file-name "../site.org" (file-name-directory load-file-name))))
  (unless (file-exists-p site-org)
    (error "site.org not found at %s" site-org))
  (with-current-buffer (find-file-noselect site-org)
    (org-hugo-export-wim-to-md :all-subtrees)))
(message "ox-hugo export complete")
