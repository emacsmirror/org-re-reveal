;;; publish.el --- Publish reveal.js presentations from Org sources
;; -*- Mode: Emacs-Lisp -*-
;; -*- coding: utf-8 -*-

;; Copyright (C) 2017-2019 Jens Lechtenbörger
;; SPDX-License-Identifier: GPL-3.0-or-later

;;; License: GPLv3

;;; Commentary:
;; Publication of Org source files to reveal.js uses Org export
;; functionality offered by org-re-reveal and oer-reveal.
;; Initialization code for both is provided by emacs-reveal, e.g.,
;; in the Docker image emacs-reveal: https://gitlab.com/oer/docker
;; Org-re-reveal and oer-reveal are also available on MELPA.
;;
;; Use this file from its parent directory with the following shell
;; command:
;; emacs --batch --load test-cases/publish.el

;;; Code:
(package-initialize)
(require 'oer-reveal)
(let ((oer-reveal-plugins '("reveal.js-jump-plugin"))
      (org-re-reveal-history t)
      (org-re-reveal-script-files oer-reveal-script-files)
      (org-re-reveal--href-fragment-prefix org-re-reveal--slide-id-prefix)
      (org-publish-project-alist
       (list
	(list "org-presentations"
	      :base-directory "test-cases"
	      :base-extension "org"
	      :publishing-function 'org-re-reveal-publish-to-reveal
	      :publishing-directory "./public")
	(list "reveal-static"
	      :base-directory (expand-file-name
			       "reveal.js" oer-reveal-submodules-dir)
	      :exclude "\\.git"
	      :base-extension 'any
	      :publishing-directory "./public/reveal.js"
	      :publishing-function 'org-publish-attachment
	      :recursive t)
	(list "reveal.js-jump-plugin"
	      :base-directory (expand-file-name
			       "reveal.js-jump-plugin/jump"
			       oer-reveal-submodules-dir)
	      :base-extension 'any
	      :publishing-directory "./public/reveal.js/plugin/jump"
	      :publishing-function 'org-publish-attachment
	      :recursive t))))
  (oer-reveal-setup-plugins)
  (org-publish-all))
