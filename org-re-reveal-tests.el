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

(defun org-re-reveal-tests-f-parent (path)
  "Get PATH's parent dir.  Similar to `f-parent'."
  (file-name-directory
   (directory-file-name path)))

(defun org-re-reveal-tests-f-this-file-path ()
  "Get this file path.  Similar to `f-this-file'."
  (cond
   (load-in-progress
    load-file-name)
   ((and (boundp 'byte-compile-current-file) byte-compile-current-file)
    byte-compile-current-file)
   (t
    (buffer-file-name))))

(defun org-re-reveal-tests-f-this-file-dir ()
  "Get this file contain dir."
  (org-re-reveal-tests-f-parent
   (org-re-reveal-tests-f-this-file-path)))

(defvar org-re-reveal-tests-top-dir (org-re-reveal-tests-f-this-file-dir))

(defun org-re-reveal-tests-get-file-contents (name &optional folder)
  "Get file named NAME contents in FOLDER."
  (with-temp-buffer
    (insert-file-contents
     (expand-file-name (format "%s/%s" (or folder "test-cases") name)
                       org-re-reveal-tests-top-dir))
    (buffer-substring-no-properties (point-min) (point-max))))

(defun org-re-reveal-tests-create-normal-test (name)
  "Create normal test for org-re-reveal with NAME."
  (eval
   `(cort-deftest ,(make-symbol (format "org-re-reveal/export-%s" name))
      `((:string=
         ,(org-re-reveal-tests-get-file-contents (format "expect-%s.html" ,name))
         ,(let ((sourcepath (expand-file-name (format "test-cases/test-%s.org" ,name)
                                        org-re-reveal-tests-top-dir))
                (exportpath (expand-file-name (format "test-cases/test-%s.html" ,name)
                                        org-re-reveal-tests-top-dir)))
            (save-window-excursion
              (if (not (file-readable-p sourcepath))
                  (error (format "Unable to read file: %s" path))
                (let ((buf (find-file sourcepath)))
                  (with-current-buffer buf
                    (unwind-protect
                        (org-re-reveal-export-to-html)
                      (when (buffer-name buf)
                        (kill-buffer buf)))))))
            (with-temp-buffer
              (insert-file-contents exportpath)
              (goto-char (point-min))
              (while (re-search-forward (rx "id=\"org" (= 7 not-newline)) nil t)
                (replace-match "id=\"org*******" nil nil))
              (write-region nil nil exportpath nil 0))
            (org-re-reveal-tests-get-file-contents (format "expect-%s.html" ,name))))))))

(cort-deftest org-re-reveal/cort-test
  '((:string= "https://gitlab.com/oer/org-re-reveal"
              "https://gitlab.com/oer/org-re-reveal")))

(mapc #'org-re-reveal-tests-create-normal-test
      '("highlightjs"
        "klipsify"
        "slide-numbers"
        "split"))

(provide 'org-re-reveal-tests)
;;; org-re-reveal-tests.el ends here
