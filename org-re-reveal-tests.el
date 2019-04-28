;;; org-re-reveal-tests.el --- org-re-reveal test  -*- lexical-binding: t; -*-

;; SPDX-License-Identifier: GPL-3.0-or-later
;; Copyright (C) 2013-2018 Yujie Wen and contributors to org-reveal, see:
;;                         https://github.com/yjwen/org-reveal/commits/master
;; Copyright (C) 2017-2019 Jens Lechtenbörger
;; Copyright (C) 2019      Naoya Yamashita <coano3@gmail.com>

;; URL: https://gitlab.com/oer/org-re-reveal
;; Version: 1.1.1
;; Package-Requires: ((emacs "24.4") (org "8.3") (htmlize "1.34"))
;; Keywords: tools, outlines, hypermedia, slideshow, presentation, OER

;; This file is not part of GNU Emacs.

;;; License:
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.
;; If not, see http://www.gnu.org/licenses/ or write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; org-re-reveal test

;;; Code:

(require 'cort-test)
(require 'org-re-reveal)

(defun org-re-reveal-f-parent (path)
  "Get parent dir.  Similar to `f-parent'."
  (file-name-directory
   (directory-file-name path)))

(defun org-re-reveal-f-this-file-path ()
  "Get this file path.  Similar to `f-this-file'"
  (cond
   (load-in-progress
    load-file-name)
   ((and (boundp 'byte-compile-current-file) byte-compile-current-file)
    byte-compile-current-file)
   (t
    (buffer-file-name))))

(defun org-re-reveal-f-this-file-dir ()
  "Get this file contains dir."
  (org-re-reveal-f-parent
   (org-re-reveal-get-this-file-path)))

(defun org-re-reveal-tests-get-file-contents (name &optional folder)
  "Get file named NAME contents in FOLDER."
  (with-temp-buffer
    (insert-file-contents (format "%s/%s"
                                  (or load-file-name default-directory) name)
                          (or folder "test-cases"))
    (buffer-substring (point-min) (point-max))))

(cort-deftest org-re-reveal/cort-test
  '((:string= "https://gitlab.com/oer/org-re-reveal"
              "https://gitlab.com/oer/org-re-reveal")))

(cort-deftest org-re-reveal/highlightjs
  '((org-re-reveal-tests-get-file-contents "test-highlightjs.html")
    (progn
      ;; TODO: create expect-highlightjs.html
      (org-re-reveal-tests-get-file-contents "expect-highlightjs.html"))))


(provide 'org-re-reveal-tests)
;;; org-re-reveal-tests.el ends here
