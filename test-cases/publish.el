;;; publish.el --- Publish reveal.js presentations from Org sources
;; -*- Mode: Emacs-Lisp -*-
;; -*- coding: utf-8 -*-

;; SPDX-FileCopyrightText: 2017-2020 Jens Lechtenbörger
;; SPDX-License-Identifier: GPL-3.0-or-later

;;; License: GPL-3.0-or-later

;;; Commentary:
;; Publication of Org source files to reveal.js uses Org export
;; functionality offered by org-re-reveal and oer-reveal.
;; Initialization code for both is provided by emacs-reveal, e.g.,
;; in the Docker image emacs-reveal: https://gitlab.com/oer/docker
;; Org-re-reveal and oer-reveal are also available on MELPA.
;;
;; Use this file from its parent directory with the following shell
;; command:
;; emacs --batch -L /root/.emacs.d/elpa/emacs-reveal/org-mode/lisp --load org-re-reveal.el --load test-cases/publish.el

;;; Code:
(package-initialize)

(defun publish-readme-to-reveal (plist filename pub-dir)
  "Publish readme with correct path to reveal.js.
Pass PLIST, FILENAME, and PUB-DIR to `org-re-reveal-publish-to-reveal'."
  (let ((org-re-reveal-root "test-cases/reveal.js"))
    (oer-reveal-publish-to-reveal plist filename pub-dir)))

;; Add Docker path for oer-reveal, load it
(add-to-list 'load-path "/root/.emacs.d/elpa/emacs-reveal/oer-reveal")
(require 'oer-reveal-publish)

(let ((oer-reveal-plugins '("reveal.js-jump-plugin"))
      (org-re-reveal-history t)
      (org-re-reveal-script-files oer-reveal-script-files)
      (org-re-reveal--href-fragment-prefix org-re-reveal--slide-id-prefix)
      (org-re-reveal-multiplex-url "https://reveal-js-multiplex-ccjbegmaii.now.sh")
      (org-re-reveal-multiplex-socketio-url "https://cdn.socket.io/socket.io-1.3.5.js")
      (org-re-reveal-preamble "<div class=\"legalese\"><p><a href=\"/imprint.html\">Imprint</a> | <a href=\"/privacy.html\">Privacy Policy</a></p></div>")
      (org-html-postamble "<p class=\"date\">Created: <span property=\"dc:created\">%C</span></p>
<div class=\"legalese\"><p><a href=\"/imprint.html\">Imprint</a> | <a href=\"/privacy.html\">Privacy Policy</a></p></div>")
      (org-publish-project-alist
       (list
	(list "org-presentations"
	      :base-directory "test-cases"
	      :base-extension "org"
              :exclude "config-.*"
	      :publishing-function 'org-re-reveal-publish-to-reveal
	      :publishing-directory "./public/test-cases")
        (list "multiplex-client"
	      :base-directory "test-cases"
	      :include '("test-multiplex.org")
	      :exclude ".*"
	      :publishing-function 'org-re-reveal-publish-to-reveal-client
	      :publishing-directory "./public/test-cases")
        (list "readme"
	      :base-directory "."
	      :include '("Readme.org")
	      :exclude ".*"
	      :publishing-function 'publish-readme-to-reveal
	      :publishing-directory "./public")
        (list "css"
	      :base-directory "."
	      :include '("local.css")
	      :exclude ".*"
	      :publishing-function 'org-publish-attachment
	      :publishing-directory "./public")
        (list "images"
	      :base-directory "images"
	      :base-extension (regexp-opt '("png" "jpg" "ico" "svg" "gif"))
	      :publishing-directory "./public/images"
	      :publishing-function 'org-publish-attachment
	      :recursive t)
        (list "index"
	      :base-directory "."
	      :include '("index.org")
	      :exclude ".*"
	      :publishing-function '(org-html-publish-to-html)
	      :publishing-directory "./public")
	(list "reveal-static"
	      :base-directory (expand-file-name
			       "reveal.js" oer-reveal-submodules-dir)
	      :exclude "\\.git"
	      :base-extension 'any
	      :publishing-directory "./public/test-cases/reveal.js"
	      :publishing-function 'org-publish-attachment
	      :recursive t)
	(list "reveal.js-jump-plugin"
	      :base-directory (expand-file-name
			       "reveal.js-jump-plugin/jump"
			       oer-reveal-submodules-dir)
	      :base-extension 'any
	      :publishing-directory "./public/test-cases/reveal.js/plugin/jump"
	      :publishing-function 'org-publish-attachment
	      :recursive t))))
  (oer-reveal-publish-all))
