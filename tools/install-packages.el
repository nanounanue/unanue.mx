;;; install-packages.el --- Install export deps project-locally -*- lexical-binding: t; -*-
;; Run: emacs --batch -l tools/install-packages.el
;; Installs ox-hugo and citeproc into tools/elpa (gitignored) so the
;; export never depends on the personal Emacs configuration, locally or
;; in CI.
(require 'package)
(setq package-user-dir (expand-file-name "elpa" (file-name-directory load-file-name)))
(setq package-archives '(("gnu" . "https://elpa.gnu.org/packages/")
                         ("melpa" . "https://melpa.org/packages/")))
(package-initialize)
(package-refresh-contents)
(dolist (pkg '(ox-hugo citeproc))
  (unless (package-installed-p pkg)
    (package-install pkg)))
(message "ox-hugo installed: %s / citeproc installed: %s"
         (package-installed-p 'ox-hugo)
         (package-installed-p 'citeproc))
