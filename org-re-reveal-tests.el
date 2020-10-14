;;; org-re-reveal-tests.el --- org-re-reveal test  -*- lexical-binding: t; -*-

;; SPDX-License-Identifier: GPL-3.0-or-later
;; Copyright (C) 2019      Naoya Yamashita <conao3@gmail.com>
;; Copyright (C) 2020      Jens Lechtenbörger

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

(load "cort-test")
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

(defun org-re-reveal-tests-export-and-get-file-contents (name &optional folder)
  "Export file named NAME and get exported file contents."
  (let ((sourcepath (expand-file-name (format "%s/test-%s.org"
                                              (or folder "test-cases")
                                              name)
                                      org-re-reveal-tests-top-dir))
        (exportpath (expand-file-name (format "%s/test-%s.html"
                                              (or folder "test-cases")
                                              name)
                                      org-re-reveal-tests-top-dir))
        (replace-all-fn (lambda (before after)
                          (save-excursion
                            (goto-char (point-min))
                            (while (re-search-forward before nil t)
                              (replace-match after nil nil))))))
    (save-window-excursion
      (if (not (file-readable-p sourcepath))
          (error (format "Unable to read file: %s" sourcepath))
        (let ((buf (find-file sourcepath)))
          (with-current-buffer buf
            (unwind-protect
                (org-re-reveal-export-to-html)
              (when (buffer-name buf)
                (kill-buffer buf)))))))
    (with-temp-buffer
      (insert-file-contents exportpath)
      (mapc (lambda (x) (funcall replace-all-fn (car x) (cdr x)))
            `((,(rx "id=\"org"       (= 7 not-newline)) . "id=\"org*******")
              (,(rx "id=\"slide-org" (= 7 not-newline)) . "id=\"slide-org*******")
              (,(rx "id=\"outline-container-org" (= 7 not-newline)) . "id=\"outline-container-org*******")
              (,(rx "#/slide-org"    (= 7 not-newline)) . "#/slide-org*******")
              ("<p class=\"date\">Created:.*</p>"       . "<p class=\"date\">Created:{{date}}</p>")))
      (write-region nil nil exportpath nil 0))
    (org-re-reveal-tests-get-file-contents
     (format "test-%s.html" name) folder)))

(defun org-re-reveal-tests-string= (str1 str2)
  "Compare STR1 and STR2 for debug purposes."
  (or (string= str1 str2)
      (let ((comparison (compare-strings str1 nil nil str2 nil nil)))
        (if (booleanp comparison)
            comparison
          (unless (= (length str1) (length str2))
            (message "Strings have different lengths: %s vs %s"
                     (length str1) (length str2)))
          (message "Result of `compare-strings' is %s.  First difference: `%s' vs `%s'"
                   comparison
                   (substring str1 (- (abs comparison) 1) (abs comparison))
                   (substring str2 (- (abs comparison) 1) (abs comparison)))
          nil))))

(defun org-re-reveal-tests-create-normal-test (name)
  "Create normal test for org-re-reveal with NAME."
  (eval
   `(cort-deftest ,(make-symbol (format "org-re-reveal/export-%s" name))
      `((:org-re-reveal-tests-string=
         (org-re-reveal-tests-get-file-contents ,,(format "expect-%s.html" name))
         (org-re-reveal-tests-export-and-get-file-contents ,,name))))))

(cort-deftest org-re-reveal/cort-test
  '((:string= "https://gitlab.com/oer/org-re-reveal"
              "https://gitlab.com/oer/org-re-reveal")))

(mapc #'org-re-reveal-tests-create-normal-test
      '("blockquote"
        "extra-scripts"
        "highlightjs"
        "internal-links"
        "klipsify"
        "klipsify-python"
        "merge-classes"
        "multiplex"
        "noslide"
        "options"
        "pdf-notes"
        "plugins"
        "reveal-toc"
        "revealjs4"
        "src-blocks-hl"
        "src-blocks-no-hl"
        "slide-numbers"
        "slide-numbers-reveal-toc"
        "slide-numbers-toc"
        "split"
        "title-slide"
        "title-slide-notes"))

;; (provide 'org-re-reveal-tests)
;;; org-re-reveal-tests.el ends here
