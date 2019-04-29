;;; cort-test.el --- Simplify extended unit test framework -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Naoya Yamashita

;; Author: Naoya Yamashita <conao3@gmail.com>
;; Maintainer: Naoya Yamashita <conao3@gmail.com>
;; Keywords: test lisp
;; Version: 6.0.0
;; URL: https://github.com/conao3/cort.el
;; Package-Requires: ((emacs "24.0"))

;;   Abobe declared this package requires Emacs-24, but it's for warning
;;   suppression, and will actually work from Emacs-22.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Simplify extended unit test framework

;;; Code:

(if (<= 24 emacs-major-version)
    (require 'cl-lib)
  (eval-when-compile
    (require 'cl)))

(defgroup cort nil
  "Simplify elisp test framework."
  :group 'lisp)

(defconst cort-test-env-symbols '(:cort-emacs<
                                  :cort-emacs<=
                                  :cort-emacs=
                                  :cort-emacs>
                                  :cort-emacs>=
                                  :cort-if)
  "Test case environment symbols.")

(defvar cort-test-test-cases nil
  "Test list such as ((TEST-NAME VALUE) (TEST-NAME VALUE) ...).")

(defcustom cort-test-debug nil
  "If non nil, turn on debug mode.

- don't throw annoying error when test fail, just output message."
  :type 'boolean
  :group 'cort)

(defcustom cort-test-show-backtrace nil
  "If non nil, show backtrace when fail test case."
  :type 'boolean
  :group 'cort)

(defcustom cort-test-enable-color noninteractive
  "If non nil, enable color message to output with meta character.
Default, enable color if run test on CUI.
`noninteractive' returns t on --batch mode"
  :type 'boolean
  :group 'cort)

(defcustom cort-test-header-message
  (if cort-test-enable-color
      "\n\e[33mRunning %d tests...\e[m\n"
    "\nRunning %d tests...\n")
  "Header message."
  :type 'string
  :group 'cort)

(defcustom cort-test-passed-label
  (if cort-test-enable-color
      "\e[36m[PASSED] \e[m"
    "[PASSED] ")
  "Passed label."
  :type 'string
  :group 'cort)

(defcustom cort-test-fail-label
  (if cort-test-enable-color
      "\e[31m[FAILED] \e[m"
    "[FAILED] ")
  "Fail label."
  :type 'string
  :group 'cort)

(defcustom cort-test-error-label
  (if cort-test-enable-color
      "\e[31m<ERROR>  \e[m"
    "<<ERROR>>")
  "Fail label."
  :type 'string
  :group 'cort)

(defcustom cort-test-error-message
  (if cort-test-enable-color
      "\e[31m===== Run %2d Tests, %2d Expected, %2d Failed, %2d Errored on Emacs-%s =====\e[m\n\n"
    "===== Run %2d Tests, %2d Expected, %2d Failed, %2d Errored on Emacs-%s =====\n\n")
  "Error message."
  :type 'string
  :group 'cort)

(defcustom cort-test-passed-message
  (if cort-test-enable-color
      "\e[34m===== Run %2d Tests, %2d Expected, %2d Failed, %2d Errored on Emacs-%s =====\e[m\n\n"
    "===== Run %2d Tests, %2d Expected, %2d Failed, %2d Errored on Emacs-%s =====\n\n")
  "Error message."
  :type 'string
  :group 'cort)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  for old Emacs
;;

(defmacro cort-test-inc (var &optional step)
  "Increment VAR.  If given STEP, increment VAR by STEP.
Emacs-22 doesn't support `incf'."
  (declare (indent 1) (debug t))
  `(setq ,var (+ ,var ,(if step step 1))))

;; defalias cl-symbols for old Emacs.
(when (version< emacs-version "24.0")
  (mapc (lambda (x)
          (defalias (intern (format "cl-%s" x)) x))
        '(multiple-value-bind)))

(defmacro cort-test-case (fn var &rest conds)
  "Switch case CONDS macro with FN for VAR.
Emacs-22 doesn't support `pcase'."
  (declare (indent 2))
  (let ((lcond var))
    `(cond
      ,@(mapcar (lambda (x)
                  (let ((rcond (car x))
                        (form (cadr x)))
                    (if (eq rcond '_)
                        `(t ,form)
                      `((funcall ,fn ,lcond ,rcond) ,form))))
                conds)
      (t nil))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  small functions
;;

(defmacro cort-test-aif (test-form* then-form &rest else-form)
  "Anaphoric if macro.
This macro expansion is implemented carefully so that sexp is not
evaluated multiple times.

\(fn (ASYM TEST-FORM) THEN-FORM [ELSE-FORM...])"
  (declare (indent 2) (debug t))
  `(let ((,(car test-form*) ,(cadr test-form*)))
     (if ,(car test-form*) ,then-form ,@else-form)))

(defmacro cort-test-asetq (sym* &optional body)
  "Anaphoric setq macro.

\(fn (ASYM SYM) &optional BODY)"
  (declare (indent 1))
  `(let ((,(car sym*) ,(cadr sym*)))
     (setq ,(cadr sym*) ,body)))

(defmacro cort-test-alet (varlist* &rest body)
  "Anaphoric let macro.  Return first arg value.
CAUTION:
`it' has first var value, it is NOT updated if var value changed.

  (macroexpand
   '(cort-test-alet (it ((result t)))
    (princ it)))
  => (let* ((result t)
            (it result))
       (progn (princ it))
       result)

\(fn (ASYM (VARLIST...)) &rest BODY)"
  (declare (debug t) (indent 1))
  `(let* (,@(cadr varlist*)
          (,(car varlist*) ,(caar (cadr varlist*))))
     (progn ,@body)
     ,(caar (cadr varlist*))))

(defmacro cort-test-with-gensyms (syms &rest body)
  "Create `let' block with `gensym'ed variables.
SYMS is symbol list.

\(fn (SYM...) &rest BODY)"
  (declare (indent 1))
  `(let ,(mapcar (lambda (s)
                   `(,s (gensym)))
                 syms)
     ,@body))

(defsubst cort-test-truep (var)
  "Return t if VAR is non-nil."
  (not (not var)))

(defsubst cort-test-pp (sexp)
  "Return pretty printed SEXP string."
  (replace-regexp-in-string "\n+$" "" (pp-to-string sexp)))

(defsubst cort-test-list-digest (fn list)
  "Make digest from LIST using FN (using 2 args).
Example:
  (list-digest (lambda (a b) (or a b))
    '(nil nil t))
  => nil

  (list-digest (lambda (a b) (or a b))
    '(nil nil t))
  => nil"
  (declare (indent 1))
  (let ((result))
    (mapc (lambda (x) (setq result (funcall fn x result))) list)
    result))

(defsubst cort-test-list-memq (symlist list)
  "Return t if LIST contained element of SYMLIST."
  (cort-test-truep
   (cort-test-list-digest (lambda (a b) (or a b))
                          (mapcar (lambda (x) (memq x list)) symlist))))

(defsubst cort-test-get-funcsym (symbol)
  "Return function symbol from SYMBOL like :eq."
  (intern
   (replace-regexp-in-string "^:+" "" (symbol-name symbol))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  support functions
;;

(defun cort-test-get-value-fn (env)
  "Recursive search function for `cort-test-get-value' from ENV."
  (cort-test-aif (it (plist-get env :cort-if))
                 (if (eval (car it))
                     (cadr it)
                   (funcall #'cort-test-get-value-fn (member :cort-if (cddr env))))))

(defun cort-test-get-value (plist symbol)
  "Get reasonable value from PLIST.
Take SYMBOL value from PLIST and return the value
by interpretingcort-test-if etc.

Example:
  (cort-test-get-value
   '(x (:default 'a :cort-if (t 'b)))
  'x)
  ;; => 'b
  
  (cort-test-get-value
   '(x (:default 'a :cort-if (nil 'b)))
   'x)
  ;; => 'a"

  ;;   (let ((element (plist-get plist symbol))
  ;;    (fn (lambda (env)
  ;;               (cort-test-aif (it (plist-get env :cort-if))
  ;;                      (if (eval (car it))
  ;;                          (cadr it)
  ;;                        (funcall fn (member :cort-if (cddr env))))))))
  ;;     (cort-test-aif (it (funcall fn element))
  ;;    it
  ;;       (plist-get element :default)))
  (let ((element (plist-get plist symbol)))
    (cort-test-aif (it (funcall #'cort-test-get-value-fn element))
                   it
                   (plist-get element :default))))

(defun cort-test-test (plist)
  "Actually execute GIVEN to check it match EXPECT geted from PLIST.
If match, return t, otherwise return nil."

  (let ((method   (cort-test-get-value plist :method))
        (given    (cort-test-get-value plist :given))
        (expect   (cort-test-get-value plist :expect))
        (err-type (cort-test-get-value plist :err-type)))
    (cort-test-case #'eq method
                    (:cort-error
                     (eval
                      `(condition-case err
                           (eval ,given)
                         (,err-type t))))
                    (_
                     (let* ((funcsym (cort-test-get-funcsym method)))
                       (funcall funcsym (eval given) (eval expect)))))))

(defun cort-test-testpass (name _plist)
  "Output messages for test passed for NAME and _PLIST."

  (let ((mesheader (format "%s %s\n" cort-test-passed-label name)))
    (princ (concat mesheader))))

(defun cort-test-testfail (name plist &optional err)
  "Output messages for test failed for NAME and PLIST.
ERR is error message."

  (let ((method   (cort-test-get-value plist :method))
        (given    (cort-test-get-value plist :given))
        (expect   (cort-test-get-value plist :expect))
        (err-type (cort-test-get-value plist :err-type)))
    (let* ((failp           (not err))
           (errorp          (not failp))
           (method-errorp   (eq method :cort-error))
           (method-defaultp (not (or method-errorp))))
      (let ((mesheader) (mesmethod) (mesgiven) (mesreturned) (mesexpect)
            (meserror) (mesbacktrace))
        (setq mesgiven  (format "Given:\n%s\n" (cort-test-pp given)))
        (setq mesbacktrace (format "Backtrace:\n%s\n"
                                   (with-output-to-string
                                     (backtrace))))
        (progn
          (when errorp
            (setq mesheader (format "%s %s\n" cort-test-error-label name))
            (setq meserror  (format "Unexpected-error: %s\n" (cort-test-pp err))))
          (when failp
            (setq mesheader (format "%s %s\n" cort-test-fail-label name))))

        (progn
          (when method-defaultp
            (setq mesmethod (format "< Tested with %s >\n" method))
            (setq mesexpect (format "Expected:\n%s\n" (cort-test-pp expect)))
            (when failp
              (setq mesreturned (format "Returned:\n%s\n" (cort-test-pp (eval given))))))
          (when method-errorp
            (setq meserror  (format "Unexpected-error: %s\n" (cort-test-pp err)))
            (setq mesexpect (format "Expected-error:   %s\n" (cort-test-pp err-type)))))

        (princ (concat mesheader
                       (cort-test-aif (it mesmethod)   it)
                       (cort-test-aif (it mesgiven)    it)
                       (cort-test-aif (it mesreturned) it)
                       (cort-test-aif (it mesexpect)   it)
                       (cort-test-aif (it meserror)    it)
                       (if cort-test-show-backtrace
                           (cort-test-aif (it mesbacktrace) it))
                       "\n"
                       ))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Define test phase
;;

(defun cort-test-interpret-env-keyword (env)
  "Interpret a single keyword and return sexp.
ENV is list such as (KEYWORD VALUE)"
  (let ((symbol (car env))
        (value  (cadr env)))
    (let ((keyname (prin1-to-string symbol)))
      (if (string-match (rx (group ":cort-")
                            (group (or "emacs" "if"))
                            (? (group (or "<" "<=" "=" ">=" ">"))))
                        keyname)
          (cort-test-case #'string= (match-string 2 keyname)
                          ("emacs"
                           (let ((condver  (car value))
                                 (expected (cadr value))
                                 (sign     (match-string 3 keyname)))
                             (if (string-match "^>=?$" sign)
                                 (progn
                                   (setq sign (replace-regexp-in-string "^>" "<" sign))
                                   (list 2 `(:cort-if
                                             ((not
                                               (funcall
                                                (intern ,(concat "version" sign))
                                                emacs-version ,(prin1-to-string condver)))
                                              ,expected))))
                               (list 2 `(:cort-if
                                         ((funcall
                                           (intern ,(concat "version" sign))
                                           emacs-version ,(prin1-to-string condver))
                                          ,expected))))))
                          
                          ("if"
                           (list 2 `(:cort-if ,value))))

        (list 1 `(:default ,symbol))))))

(defun cort-test-normalize-env (env)
  "Return normalize test environment list for ENV.

Example:
  (cort-test-normalize-env :eq)
  => (:default :eq)

  (cort-test-normalize-env '('b
                       :cort-if (t 'a)))
  => (:default 'b
      :cort-if (t 'a))"
  (cort-test-alet (_it ((result)))
                  (if (and (listp env) (cort-test-list-memq cort-test-env-symbols env))
                      (let ((i 0) (envc (length env)))
                        (while (< i envc)
                          (cl-multiple-value-bind (step value)
                              (cort-test-interpret-env-keyword (nthcdr i env))
                            (cort-test-asetq (it result)
                                             (append it value))
                            (cort-test-inc i step))))
                    (cort-test-asetq (it result)
                                     (append it `(:default ,env))))))

(defmacro cort-deftest (name testlst)
  "Define a test case with the NAME.
TESTLST is list of forms as below.

basic: (:COMPFUN EXPECT GIVEN)
error: (:cort-test-error EXPECTED-ERROR-TYPE FORM)"
  (declare (indent 1))

  (let ((fn #'cort-test-normalize-env)
        (testlst* (eval testlst)))
    `(progn
       ,@(mapcar (lambda (test)
                   (cort-test-case #'eq (nth 0 test)
                                   (:cort-error
                                    (let ((method   (funcall fn (nth 0 test)))
                                          (err-type (funcall fn (nth 1 test)))
                                          (given    (funcall fn (nth 2 test))))
                                      `(add-to-list 'cort-test-test-cases
                                                    '(,name (:cort-testcase
                                                             :method   ,method
                                                             :err-type ,err-type
                                                             :given    ,given))
                                                    t)))
                                   (_
                                    (let ((method (funcall fn (nth 0 test)))
                                          (expect (funcall fn (nth 1 test)))
                                          (given  (funcall fn (nth 2 test))))
                                      (if t ;; (fboundp (cort-test-get-funcsym (car method)))
                                          `(add-to-list 'cort-test-test-cases
                                                        '(,name (:cort-testcase
                                                                 :method ,method
                                                                 :expect ,expect
                                                                 :given  ,given))
                                                        t)
                                        `(progn
                                           (cort-test-testfail ',name (cdr
                                                                       '(:cort-testcase
                                                                         :method ,method
                                                                         :expect ,expect
                                                                         :given  ,given)))
                                           (error "Invalid test case")))))))
                 testlst*))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Run test phase
;;

(defun cort-test-prune ()
  "Prune all test."
  (interactive)
  (setq cort-test-test-cases nil)
  (message "prune tests completed."))

(defun cort-test-run ()
  "Run all test."
  (let ((testc  (length cort-test-test-cases))
        (failc  0)
        (errorc 0))
    (princ (format cort-test-header-message (length cort-test-test-cases)))
    (princ (format "%s\n" (emacs-version)))

    (dolist (test cort-test-test-cases)
      (let* ((name  (car  test))
             (keys  (cadr test))
             (plist (cdr  keys)))       ; remove :cort-testcase symbol
        (condition-case err
            (if (cort-test-test plist)
                (cort-test-testpass name plist)
              (cort-test-testfail name plist)
              (cort-test-inc failc))
          (error
           (cort-test-testfail name plist err)
           (cort-test-inc errorc)))))

    (princ "\n\n")
    (if (or (< 0 failc) (< 0 errorc))
        (if cort-test-debug
            (princ "Test failed!!\n")
          (error (format cort-test-error-message
                         testc (- testc failc errorc) failc errorc emacs-version)))
      (princ (format cort-test-passed-message
                     testc (- testc failc errorc) failc errorc emacs-version)))))

(provide 'cort-test)
;;; cort-test.el ends here
