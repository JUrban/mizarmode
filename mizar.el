;;; mizar.el --- mizar.el -- Mizar Mode for Emacs
;;
;; $Revision: 1.46 $
;;
;;; License:     GPL (GNU GENERAL PUBLIC LICENSE)
;;
;;; Commentary:
;;
;; Emacs mode for authoring Mizar (www.mizar.org) articles.
;; Run C-h f mizar-mode for overview of commands.
;; Complete info, html, pdf and ps documentation is
;; downloadable from http://kti.ms.mff.cuni.cz/~urban/MizarModeDoc.tar.gz .
;; Browse it at http://ktilinux.ms.mff.cuni.cz/~urban/MizarModeDoc/html .


;;; History:
;; 
;; Started by Bob Beck, beck@cs.UAlberta.CA (beck@alberta) as 
;; a mode for Unix version of Mizar-MSE.
;;
;; Since April 3 2000, rewritten and maintained by 
;; Josef Urban (urban@kti.ms.mff.cuni.cz) for use with Mizar Version >= 6.
;;
;; Go to http://kti.ms.mff.cuni.cz/cgi-bin/viewcvs.cgi/mizarmode/mizar.el,
;; to see complete revision history.
;;


;;; Usage
;;
;; If you obtained this with your Mizar distribution, just append
;; the .emacs file enclosed there to your .emacs.
;; Otherwise, the latest version of .emacs is downloadable from
;; http://kti.ms.mff.cuni.cz/cgi-bin/viewcvs.cgi/mizarmode/.emacs .
;;;;;;;;;;;;;; start of .emacs ;;;;;;;;;;;;;;;;;;;;;

; (global-font-lock-mode t)
; (autoload 'mizar-mode "mizar" "Major mode for editing Mizar programs." t)
; (setq auto-mode-alist (append '(  ("\\.miz" . mizar-mode)
;                                   ("\\.abs" . mizar-mode))
; 			      auto-mode-alist))

;;;;;;;;;;;;;; end of .emacs    ;;;;;;;;;;;;;;;;;;;;;;;;



;;; TODO: 
;;
;; better indentation,


          

;;; Start of original info:
;;
;; emacs lisp hack for mizar
;; Copyright (C) Bob Beck, Department of Computing Science
;; University of Alberta,  July 23 1990

;; This file is part of GNU Emacs.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY.  No author or distributor
;; accepts responsibility to anyone for the consequences of using it
;; or for whether it serves any particular purpose or works at all,
;; unless he says so in writing.  Refer to the GNU Emacs General Public
;; License for full details.

;; Everyone is granted permission to copy, modify and redistribute
;; GNU Emacs, but only under the conditions described in the
;; GNU Emacs General Public License.   A copy of this license is
;; supposed to have been given to you along with GNU Emacs so you
;; can know your rights and responsibilities.  It should be in a
;; file named COPYING.  Among other things, the copyright notice
;; and this notice must be preserved on all copies.


;; This code is distributed on an as-is basis in the hope that it will
;; be useful. It is provided with ABSOLUTELY NO WARRANTY, with no
;; responsibility being taken by either the author, Bob Beck, or the
;; University of Alberta Department of Computing Science for the use,
;; usefulness, or consequences of its use. All terms of the GNU Emacs
;; General Public License apply.


;; Please report any bugs or useful improvements/modifications to
;; Bob Beck, beck@cs.UAlberta.CA (beck@alberta)



;;; Code:
(defvar mizar-emacs
  (if (featurep 'xemacs)
      'xemacs
    (if (featurep 'dos-w32)
	'winemacs
      'gnuemacs))
  "The variant of Emacs we're running.
Valid values are 'gnuemacs,'Xemacs and 'winemacs.")

(eval-when-compile
  (require 'compile)
  (require 'font-lock)
  (require 'imenu)
  (require 'info)
  (require 'shell)
  )

(require 'comint)
(require 'cl)
(require 'easymenu)
(require 'etags)
(require 'hideshow)
(require 'dabbrev)
(require 'executable)
(require 'term)
(require 'imenu)
(if (eq mizar-emacs 'xemacs)
    (require 'speedbar) ;; no NOERROR in xemacs
  (require 'speedbar nil t)) ;;noerror if not present


(defvar mizar-mode-syntax-table nil)
(defvar mizar-mode-abbrev-table nil)
(defvar mizar-mode-map nil "Keymap used by mizar mode..")


;; current xemacs has no custom-set-default
(if (fboundp 'custom-set-default)
    (progn
; ;; this gets rid of the "Keep current list of tag tables" message
; ;; when working with two tag tables
      (custom-set-default 'tags-add-tables nil)

; ;; this shows all comment lines when hiding proofs
      (custom-set-default 'hs-hide-comments-when-hiding-all nil)
; ;; this prevents the default value, which is hs-hide-initial-comment-block
      (custom-set-default 'hs-minor-mode-hook nil))
  (custom-set-variables
   '(tags-add-tables nil)
   '(hs-hide-comments-when-hiding-all nil)
   '(hs-minor-mode-hook nil)))

(defvar mizar-indent-width 2 
"*Indentation width for Mizar articles.
Customizable from Mizar Mode menu.")

(defun mizar-set-indent-width (to)
"Set indent width to TO."
(interactive)
(setq mizar-indent-width to))

(if mizar-mode-syntax-table
    ()
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?\" "_" table)
    (modify-syntax-entry ?: ". 12" table)
    (modify-syntax-entry ?\n ">   " table)
    (modify-syntax-entry ?\^m ">   " table)
    (setq mizar-mode-syntax-table table)))

(define-abbrev-table 'mizar-mode-abbrev-table ())

(defun mizar-mode-variables ()
  (set-syntax-table mizar-mode-syntax-table)
  (setq local-abbrev-table mizar-mode-abbrev-table)
  (make-local-variable 'paragraph-start)
  (setq paragraph-start (concat "^::::\\|^$\\|" page-delimiter)) ;'::..'
  (make-local-variable 'paragraph-separate)
  (setq paragraph-separate paragraph-start)
  (make-local-variable 'paragraph-ignore-fill-prefix)
  (setq paragraph-ignore-fill-prefix t)
  (make-local-variable 'indent-line-function)
  (setq indent-line-function 'mizar-indent-line)
  (make-local-variable 'comment-start)
  (setq comment-start "::")
  (make-local-variable 'comment-start-skip)
  (setq comment-start-skip "::+ *")
  (make-local-variable 'comment-column)
  (setq comment-column 48)
  (make-local-variable 'comment-indent-function)
  (setq comment-indent-function 'mizar-comment-indent)
;  (set (make-local-variable 'tool-bar-map) mizar-tool-bar-map)
  (make-local-variable 'font-lock-defaults)
  (setq font-lock-defaults
      '(mizar-font-lock-keywords nil nil ((?_ . "w"))))  
  )


(defun mizar-mode-commands (map)
  (define-key map "\t" 'mizar-indent-line)
  (define-key map "\r" 'newline-and-indent))


(if mizar-mode-map
    nil
  (setq mizar-mode-map (make-sparse-keymap))
  (define-key mizar-mode-map  "\C-c\C-m" 'mizar-it)
  (define-key mizar-mode-map  "\C-cc" 'mizar-compile)
  (define-key mizar-mode-map  "\C-c\C-n" 'mizar-next-error)
  (define-key mizar-mode-map  "\C-c\C-p" 'mizar-previous-error)
  (define-key mizar-mode-map "\C-c\C-e" 'mizar-strip-errors)
  (define-key mizar-mode-map "\C-c\C-d" 'mizar-hide-proofs)
  (define-key mizar-mode-map "\C-cg" 'mizar-grep-abs)
  (define-key mizar-mode-map "\C-c\C-g" 'mizar-grep-full)
  (define-key mizar-mode-map "\C-c\C-c" 'comment-region)
  (define-key mizar-mode-map "\C-c\C-f" 'mizar-findvoc)
  (define-key mizar-mode-map "\C-c\C-l" 'mizar-listvoc)
  (define-key mizar-mode-map "\C-c\C-t" 'mizar-constr)

  (define-key mizar-mode-map "\C-c\C-h" 'mizar-irrths)
  (define-key mizar-mode-map "\C-c\C-v" 'mizar-irrvoc)
  (define-key mizar-mode-map "\C-c\C-i" 'mizar-relinfer)
  (define-key mizar-mode-map "\C-c\C-o" 'mizar-trivdemo)
  (define-key mizar-mode-map "\C-c\C-s" 'mizar-reliters)
  (define-key mizar-mode-map "\C-c\C-b" 'mizar-chklab)
  (define-key mizar-mode-map "\C-c\C-y" 'mizar-relprem)
  (define-key mizar-mode-map "\C-c\C-a" 'mizar-inacc)
  (define-key mizar-mode-map "\C-c\C-z" 'make-theorem-summary)
  (define-key mizar-mode-map "\C-c\C-r" 'make-reserve-summary)
  (define-key mizar-mode-map "\C-cr" 'mizar-occur-refs)
  (define-key mizar-mode-map "\M-;"     'mizar-symbol-def)
  (define-key mizar-mode-map "\M-\C-i"     'mizar-ref-complete)
  (define-key mizar-mode-map "\C-c\C-q" 'query-start-entry)
  (if (eq mizar-emacs 'xemacs)
      (progn
	(define-key mizar-mode-map [button3]     'mizar-mouse-symbol-def)
	(define-key mizar-mode-map [(shift button3)]     'mizar-mouse-direct-symbol-def)
	(define-key mizar-mode-map [(shift button1)]     'mizar-mouse-direct-show-ref)
;	(define-key mizar-mode-map [(shift button2)]     'mouse-find-tag-history)
	)
    (define-key mizar-mode-map [mouse-3]     'mizar-mouse-symbol-def)
    (define-key mizar-mode-map [(shift down-mouse-3)]     'mizar-mouse-direct-symbol-def)
    (define-key mizar-mode-map [(shift down-mouse-1)]     'mizar-mouse-direct-show-ref)
;    (define-key mizar-mode-map [(shift down-mouse-2)]     'mouse-find-tag-history)
;    (define-key mizar-mode-map [double-mouse-1]     'mizar-mouse-ref-constrs)
)
  (define-key mizar-mode-map "\M-."     'mizar-show-ref)
  (define-key mizar-mode-map "\C-c."     'mizar-show-ref-constrs)
  (mizar-mode-commands mizar-mode-map))

(defvar mizar-tag-ending ";"
"End of the proper tag name in mizsymbtags and mizreftags.
Used for exact completion.")

(defun miz-complete ()
"Used for exact tag completion."
(interactive )
(if (active-minibuffer-window)
    (progn
      (set-buffer (window-buffer (active-minibuffer-window)))
      (insert mizar-tag-ending)
      (minibuffer-completion-help))))


(define-key minibuffer-local-completion-map ";" 'miz-complete)


;;;;;;;;;;;;;;;;;;;;; utilities ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; destructive!
(defun unique (l1)
  (let ((l1 l1))
  (while l1
      (setq l1 (setcdr l1 (delete (car l1) (cdr l1))))))
  l1)

(defun file-size (fname)
"Size of a file FNAME."
(elt (file-attributes fname) 7))

;; returns sublist satisfying test
;; loop without recursion probably better than previous
(defun test-list1 (test l1)
  (let ((l2 ()))
    (while l1
      (if (funcall  test  (car l1))
	  (setq l2 (cons (car l1) l2)))
      (setq l1 (cdr l1)))
    (reverse l2)))

(defun remove-from (pos l1)
"Destructively deletes members from POS on in L1."
(let* ((l2  l1)
       (end (nthcdr (- pos 1) l2)))
  (if (consp end)
      (setcdr  end nil))
  l2))

;;;;;;;;;;;;  indentation (pretty poor) ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun mizar-indent-line ()
  "Indent current line as Mizar code."
  (interactive)
  (let ((indent (mizar-indent-level))
	(pos (- (point-max) (point))) beg)
    (beginning-of-line)
    (setq beg (point))
    (skip-chars-forward " \t")
    (if (zerop (- indent (current-column)))
	nil
      (delete-region beg (point))
      (mizar-indent-to indent))
					;      (indent-to (+ 3 indent)))
    (if (> (- (point-max) pos) (point))
	(goto-char (- (point-max) pos)))
    ))


(defun mizar-indent-to (indent)
  (insert-char 32 indent) )             ; 32 is space...cannot use tabs




(defun mizar-indent-level ()
  "Compute mizar indentation level."
  (save-excursion
    (beginning-of-line)
    (skip-chars-forward " \t")
    (cond
     ((looking-at "::::::") 0)		;Large comment starts
     ((looking-at "::") (current-column)) ;Small comment starts
     ((looking-at "\\(theorem\\|scheme\\|definition\\|environ\\|vocabulary\\|constructors\\|requirements\\|notation\\|clusters\\)") 0)
     ((bobp) 0)				;Beginning of buffer
     (t
      (let ((empty t) ind more less res)
	;; See previous indentation
	(cond ((looking-at "end;") (setq less t))
	      ((looking-at "\\(proof\\|now\\|hereby\\)") (setq more t)))
	(while empty
	  (forward-line -1)
	  (beginning-of-line)
 	  (if (bobp)
 	      (setq empty nil)
 	    (skip-chars-forward " \t")
	    (if (not (looking-at "\\(::\\|\n\\)"))
 		(setq empty nil))))
 	(if (bobp)
 	    (setq ind 0)		;Beginning of buffer
	  (setq ind (current-column)))	;Beginning of clause
	;; See its beginning
	(if (and more (= ind 2))
	    0                           ;proof begins inside theorem
	  ;; Real mizar code
	  (cond ((looking-at "\\(proof\\|now\\|hereby\\)")
		 (setq res (+ ind mizar-indent-width)))
		((looking-at "\\(definition\\|scheme\\|theorem\\|vocabulary\\|constructors\\|requirements\\|notation\\|clusters\\)")
		 (setq res (+ ind 2)))
 		(t (setq res ind)))
	  (if less (max (- ind mizar-indent-width) 0)
	    res)
	  )))
     )))



(defun mizar-comment-indent ()
  "Compute mizar comment indentation."
  (cond ((looking-at "::::::") 0)
	((looking-at "::::") (mizar-indent-level))
	(t
	 (save-excursion
	   (skip-chars-backward " \t")
	   ;; Insert one space at least, except at left margin.
	   (max (+ (current-column) (if (bolp) 0 1))
		comment-column)))
	))


(defun mizar-indent-buffer ()
  "Indent the entire mizar buffer."
  (interactive )
  ( indent-region (point-min) (point-max) nil))

;;;;;;;;;;;;;;;;  end of indentation ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun mizar-ref-at-point ()
  "Return the reference at the point."
  (save-excursion
    (skip-chars-backward "^ \t\n,;()")
    (if (or (looking-at "\\([^ \t\n:,;]+:def [0-9]+\\)")
	    (looking-at "\\([^ \t\n:,;]+:[0-9]+\\)")
	    (looking-at "\\([^ \t\n:,;()]+\\)[ \t\n,;:.()]"))
	(buffer-substring-no-properties (match-beginning 1) (match-end 1))
      (current-word))
    ))


;; ref-completion,should be improved for definitions
(defvar mizar-ref-char-regexp "[A-Za-z0-9:'_]")
(defun mizar-ref-complete ()
"Complete the current reference using dabbrevs from current buffer."
(interactive)
(let ((old-check dabbrev-check-other-buffers)
      (old-regexp dabbrev-abbrev-char-regexp)
      (old-case dabbrev-case-fold-search))


  (unwind-protect
      (progn
	(setq dabbrev-check-other-buffers nil
	      dabbrev-abbrev-char-regexp mizar-ref-char-regexp
	      dabbrev-case-fold-search nil)
;	      dabbrev-abbrev-skip-leading-regexp ".* *")
;;	(fset 'dabbrev--abbrev-at-point
;;	      (symbol-function 'mizar-abbrev-at-point))
	(dabbrev-completion))
    (setq dabbrev-check-other-buffers old-check
	  dabbrev-abbrev-char-regexp old-regexp
	  dabbrev-case-fold-search old-case)
  )))


;;;;;;;;;;; grepping ;;;;;;;;;;;;;;;;;;;;;
;;; we should do some additional checks for winemacs

(defvar mizar-abstr (substitute-in-file-name "$MIZFILES/abstr"))
(defvar mizar-mml (substitute-in-file-name "$MIZFILES/mml"))
(defvar mizar-grep-case-sensitive t
"*Tells if MML grepping is case sensitive or not.")

(defun mizar-toggle-grep-case-sens ()
"Toggle the case sensitivity of MML grepping."
(interactive)
(setq mizar-grep-case-sensitive (not mizar-grep-case-sensitive)))

(defun mizar-grep-abs (exp)
"Grep MML abstracts for regexp EXP.
Variable `mizar-grep-case-sensitive' controls case sensitivity.
The results are shown and clickable in the Compilation buffer. "
  (interactive "sregexp: ")
  (let ((old default-directory))
    (unwind-protect
	(progn
	  (cd mizar-abstr)
	  (if mizar-grep-case-sensitive
	      (grep (concat "grep -n -e \"" exp "\" *.abs"))
	    (grep (concat "grep -i -n -e \"" exp "\" *.abs"))))
      (cd old)
    )))

(defun mizar-grep-full (exp)
"Greps full MML articles for regexp EXP.
Variable `mizar-grep-case-sensitive' controls case sensitivity.
The results are shown and clickable in the Compilation buffer. "
  (interactive "sregexp: ")
  (let ((old default-directory))
    (unwind-protect
	(progn
	  (cd mizar-mml)
	  (if mizar-grep-case-sensitive
	      (grep (concat "grep -n -e \"" exp "\" *.miz"))
	    (grep (concat "grep -i -n -e \"" exp "\" *.miz"))))
      (cd old)
      )))


;;;;;;;;;;;;;;; imenu and speedbar handling ;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar mizar-sb-trim-hack
(cond ((fboundp 'trim-words) (list 'trim-words))
      ((fboundp  'speedbar-trim-words-tag-hierarchy)
       (list 'speedbar-trim-words-tag-hierarchy)))
"Hack ensuring proper trimming across various speedbar versions."
)

(defvar mizar-sb-in-abstracts t
  "Tells if we use speedbar for abstracts too.")

(defvar mizar-sb-in-mmlquery t
  "Tells if we use speedbar for mmlquery abstracts too.")

(defun mizar-setup-imenu-sb ()
"Speedbar and imenu setup for mizar mode."
(progn
  (setq imenu-case-fold-search nil)
  (setq imenu-generic-expression mizar-imenu-expr)
  (if (featurep 'speedbar)
      (progn
	(speedbar-add-supported-extension ".miz")
	(if mizar-sb-in-abstracts
	    (speedbar-add-supported-extension ".abs"))
	(if mizar-sb-in-abstracts
	    (speedbar-add-supported-extension ".gab"))
	(setq speedbar-use-imenu-flag t
	      speedbar-show-unknown-files nil
	      speedbar-special-mode-expansion-list t
	      speedbar-tag-hierarchy-method mizar-sb-trim-hack
	      ;;'(simple-group trim-words)
	      ;;'('speedbar-trim-words-tag-hierarchy 'trim-words)
	      )))))


;; I want the tags in other window, probably some local machinery
;; should be applied instead of a redefinition here
(defun speedbar-tag-find (text token indent)
  "For the tag TEXT in a file TOKEN, goto that position.
INDENT is the current indentation level."
  (let ((file (speedbar-line-path indent)))
    (speedbar-find-file-in-frame file)
    (save-excursion (speedbar-stealthy-updates))
    ;; Reset the timer with a new timeout when clicking a file
    ;; in case the user was navigating directories, we can cancel
    ;; that other timer.
    (speedbar-set-timer speedbar-update-speed)
    (switch-to-buffer-other-window (current-buffer))
    (goto-char token)
    (run-hooks 'speedbar-visiting-tag-hook)
    ;;(recenter)
    (speedbar-maybee-jump-to-attached-frame)
    ))

;;;;;;;;;;;;  the tags handling starts here ;;;;;;;;;;;;;;;;;;;;;;;;;
;;; xemacs seems unhappy yet

(put 'mizar-mode 'find-tag-default-function 'mizar-ref-at-point)

(defvar mizsymbtags
  (substitute-in-file-name "$MIZFILES/abstr/symbtags")
  "Symbol tags file created with stag.pl (now in Mizar distro).")
(defvar mizreftags
  (substitute-in-file-name "$MIZFILES/abstr/reftags")
  "References tags file created with stag.pl (now in Mizar distro).")

;; nasty to redefine these two, but working; I could not get the local vars machinery right
(defun etags-goto-tag-location (tag-info)
  (let ((startpos (cdr (cdr tag-info)))
	(line (car (cdr tag-info)))
	offset found pat)
	;; Direct file tag.
	(cond (line (goto-line line))
	      (startpos (goto-char startpos))
	      (t (error "BUG in etags.el: bogus direct file tag")))
      (and (eq selective-display t)
	 (looking-at "\^m")
	 (forward-char 1))
    (beginning-of-line)))

(defun etags-tags-completion-table ()
  (let ((table (make-vector 511 0)))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward	"^\\([^\177\n]+\\)\177.*\n" nil t)
	(intern	  (buffer-substring (match-beginning 1) (match-end 1))
		table)))
      table))

;; redefined to put the default in minibuffer for quick browsing
(defun find-tag-tag (string)
  (let* ((default (funcall (or find-tag-default-function
			       (get major-mode 'find-tag-default-function)
			       'find-tag-default)))
	 (spec (completing-read (if default
				    (format "%s(default %s) " string default)
				  string)
				'tags-complete-tag
				nil nil default nil default)))
    (if (equal spec "")
	(or default (error "There is no default tag"))
      spec)))

(defvar in-mizar-mouse-symbol-def nil
  "Used for `mizar-mouse-symbol-def'.")

(defun mizar-mouse-symbol-def ()
  "\\<mizar-mode-map>\\[mizar-mouse-symbol-def] is bound to this function.
Runs mizar-symbol-def and the second mouse-3
shows the symbol's completions."
  (interactive)
  (if in-mizar-mouse-symbol-def
      (progn (setq in-mizar-mouse-symbol-def nil)
	     (if (active-minibuffer-window)
		 (miz-complete)))
    (mouse-set-point last-input-event)
    (setq in-mizar-mouse-symbol-def t)
    (mizar-symbol-def))
  )

(defun mizar-mouse-direct-symbol-def ()
  "\\<mizar-mode-map>\\[mizar-mouse-direct-symbol-def] is bound to this function.
Goes directly to the first match of the symbol under the mouse click."
  (interactive)
  (mouse-set-point last-input-event)
  (mizar-symbol-def  t))

(defun mizar-mouse-direct-show-ref ()
  "\\<mizar-mode-map>\\[mizar-mouse-direct-show-ref] is bound to this function.
Goes directly to the reference under the mouse click."
  (interactive)
  (mouse-set-point last-input-event)
  (mizar-show-ref  t))

(defun visit-tags-or-die (name)
  (if (file-readable-p name)
      (visit-tags-table name)
    (error "No tags file %s, run the script stag.pl" name)
    nil))

(defun mizar-symbol-def  (&optional nocompletion tag nootherw)
"Find the definition of a symbol at point with completion using file symbtags.
If in *.abs buffer, show its definition in current window, otherwise,
i.e. in *.miz buffer, show it in other window.
In the *Completions* buffer, aside from its normal key bindings,
';' is bound to show all exact matches.
If invoked by right-click (`mizar-mouse-symbol-def'),
second right-click does this too.
NOCOMPLETION goes to the first hit instead.
If TAG is given, search for it instead.
NOOTHERW finds in current window.
File symbtags is included in the Mizar distribution."
  (interactive)
  (if (visit-tags-or-die mizsymbtags)
      (let ((abs (or nootherw (buffer-abstract-p (current-buffer)))))
	(if nocompletion
	    (let ((tag (or tag (mizar-ref-at-point))))
	      (if abs (find-tag  tag)
		(find-tag-other-window tag)))
	  (if abs (call-interactively 'find-tag)
	    (call-interactively 'find-tag-other-window))))))
  

(defun mizar-show-ref (&optional nocompletion)
  "Find the library reference with completion using file reftags.
Show it in its abstract in other window.
Non-nil NOCOMPLETION goes to the first hit without completing.
Library references are theorems, definitions and schemes imported
from other Mizar articles.
File reftags is included in the Mizar distribution."
  (interactive)
  (if (visit-tags-or-die mizreftags)
      (if nocompletion
	  (find-tag-other-window  (mizar-ref-at-point))
	(call-interactively 'find-tag-other-window))))


(defun symbol-apropos ()
  "Displays list of all MML symbols that match a regexp."
  (interactive)
  (if (visit-tags-or-die mizsymbtags)
      (call-interactively 'tags-apropos)))



(defun mouse-find-tag-history ()
"Popup menu with last 20 visited tags and go to selection.
Works properly only for symbols (not references)."
  (interactive)
  (if (visit-tags-or-die mizsymbtags)
      (let* ((allowed (unique (delete nil (copy-alist find-tag-history)) ))
	     (double (mapcar '(lambda (x) (cons x x)) (remove-from 20 allowed)))
	     (backadded (cons (cons "Go to previous" t) double))
	     (menu (list "Visited symbols" (cons "Tags" backadded)))
	     (tag (x-popup-menu t menu)))
	(if (eq tag t) (pop-tag-mark)
	  (if (stringp tag) (find-tag tag))))))





(defun buffer-abstract-p (x)
"Non nil if buffer X is mizar abstract."
(let ((name  (buffer-file-name x)))
  (and (stringp name)
       (string-match "\.abs$" name))))

(defun mizar-current-abstracts ()
"Return list of buffers of mizar abstracts."
(let ((l (buffer-list)) (l1 ()))
  (while l (if (buffer-abstract-p (car l))
	       (setq l1 (cons (car l) l1)))
	 (setq l (cdr l)))
  l1))

(defun mizar-close-all-abstracts ()
"Close all Mizar abstracts.
Useful when you did too much browsing and want to get back to your
editing buffers."
(interactive)
(let* ((l (mizar-current-abstracts)) (i (length l)))
  (mapcar '(lambda (x) (kill-buffer x)) l)
  (message "%d abstracts closed" i)))

(defun mizar-close-some-abstracts ()
"Choose the abstracts you want to close."
(interactive)
(kill-some-buffers  (mizar-current-abstracts)))

(defun mizar-bury-all-abstracts ()
"Bury (put at the end of buffer list) all Mizar abstracts.
Useful when you did too much browsing and want to get back to your
editing buffers."
(interactive)
(let* ((l (mizar-current-abstracts)) (i (length l)))
  (mapcar '(lambda (x) (bury-buffer x)) l)
  (message "%d abstracts buried" i)))


;;;;;;;;;;;;;;;;;; end of tags handling ;;;;;;;;;;;;;;;;;;;;;;;;

(defun mizar-move-to-column (col &optional force)
"Mizar replacement for `move-to-column'.
Avoids tabs in mizar buffers.
Goto column COL, if FORCE, then insert spaces if short."
(if force
    (let ((new (move-to-column col)))
      (if (< new col)
	  (insert-char 32 (- col new)))) ; 32 is space...cannot use tabs
  (move-to-column col)))
		    
;;;;;;;;;;;;;;;;;; errflag              ;;;;;;;;;;;;;;;;;;
;; error format in *.err: Line Column ErrNbr


(defvar mizfiles
(substitute-in-file-name "$MIZFILES/"))

;; fixed for xemacs leaving "" in the end
(defun buff-to-numtable ()
(let ((l (delete "" (split-string (buffer-string) "\n"))))
  (mapcar '(lambda (x)
	     (mapcar 'string-to-number (split-string x)))
	  l)
  ))

(defun mizar-get-errors (aname)
"Return an unsorted table of errors on ANAME or nil."
(save-excursion
  (let ((errors (concat aname ".err")))
    (if (file-readable-p errors)
	(with-temp-buffer           ; sort columns, then lines
	  (insert-file-contents errors)
	  (buff-to-numtable)
	  )
      ))))

(defun sort-for-errflag (l)
"Sort with L, greater lines first, then by column."
(let ((l (copy-alist l)))
  (sort l '(lambda (x y) (or (> (car x) (car y))
			     (and (= (car x) (car y))
				  (< (cadr x) (cadr y)))))
	)))



(defun mizar-error-flag (aname &optional table)
"Insert error flags into main mizar buffer for ANAME (like errflag).
If `mizar-use-momm' is non-nil, puts the 'pos property into *4 errors too.
If TABLE is not given, get it with `mizar-get-errors'."
(interactive "s")
(let (lline
      (atab (sort-for-errflag (or table (mizar-get-errors aname))))
      (props (list 'mouse-face 'highlight
		   local-map-kword mizar-momm-err-map)))
  (if atab
      (save-excursion
	(setq lline (goto-line (caar atab)))
	(if (or (and (eq mizar-emacs 'xemacs) (not lline))
		(and (not (eq mizar-emacs 'xemacs)) (< 0 lline)))
	    (error "Main buffer and the error file do not agree, run verifier!"))
	(if (< 0 (forward-line))
	    (insert "\n"))
	(let ((cline (caar atab)) srec sline scol snr
	      (currerrln "::>") (cpos 3))
	  (while atab
	    (setq srec (car atab) sline (car srec)
		  scol (- (cadr srec) 1)         ; 0 based in emacs
		  snr (caddr srec) atab (cdr atab))
	    (if (> cline sline)		; start new line ... go back
		(progn
		  (insert currerrln "\n")    ; insert previous result
		  (forward-line (- (- sline cline) 1))
		  (setq currerrln "::>" cpos 3)
		  (setq cline sline)
		  ))
	    (let* ((snrstr (number-to-string snr))
		   (snrl (length snrstr)))
	      (if (and mizar-use-momm (eq snr 4))  ; add momm stuff
		  (progn
		    (add-text-properties 0 1 props snrstr)
		    (put-text-property 0 1 'pos (list sline (cadr srec))
				       snrstr)))
	      (if (> scol cpos)              ; enough space
		  (progn
		    (setq cpos scol)
		    (if (<  (length currerrln) cpos)
			(let ((str (make-string         ; spaces
				    (- cpos (length currerrln)) 32)))
			  (setq currerrln (concat currerrln str))))
		    (setq currerrln (concat currerrln "*" snrstr)))
		(setq currerrln (concat currerrln "," snrstr)))
	      (setq cpos (+ cpos snrl))))
	  (insert currerrln "\n")  ; the first line
	      )))))


(defvar mizar-err-msgs (substitute-in-file-name "$MIZFILES/mizar.msg")
  "File with explanations of Mizar error messages.")
(defun mizar-getmsgs (errors &optional cformat)
"Return string of error messages for ERRORS.
If CFORMAT, return list of numbered messages for `mizar-compile'."
(save-excursion
  (let ((buf (find-file-noselect  mizar-err-msgs))
	(msgs (if cformat nil ""))
	(prefix (if cformat " *" "::> "))
)
    (set-buffer buf)
    (goto-char (point-min))
    (while errors
      (let* ((s (number-to-string (car errors)))
	     (res  (concat prefix s ": "))
	     msg)
	(if (re-search-forward (concat "^# +" s "\\b") (point-max) t)
	    (let (p)
	      (forward-line 1)
	      (setq p (point))
	      (end-of-line)
	      (setq msg (buffer-substring p (point)))
	      (setq res (concat res  msg "\n")))
	  (setq res (concat res  "  ?" "\n"))
	  (goto-char (point-min)))
	(if cformat
	    (setq msgs (nconc msgs (list (list (car errors) res))))
	    (setq msgs (concat msgs res)))
	(setq errors (cdr errors))))
    msgs)))


(defun mizar-err-codes (aname &optional table)
  (sort (unique (mapcar 'third (or table (mizar-get-errors aname)))) '<))
  
(defun mizar-addfmsg (aname &optional table)
"Insert error explanations into mizar buffer for ANAME (like addfmsg).
See `mizar-err-codes' for the maning of TABLE."
(interactive "s")
(save-excursion
  (goto-char (point-max))
  (if (not (bolp)) (insert "\n"))
  (insert (mizar-getmsgs (mizar-err-codes aname table)))))


(defun mizar-do-errors (aname)
"Add err-flags and errmsgs using ANAME.err in current buffer."
(save-excursion
  (let ((errors (concat aname ".err")))
    (if (and (file-readable-p errors)
	     (< 0 (file-size errors)))
	(let ((table (mizar-get-errors aname)))
	  (mizar-error-flag aname table)
	  (mizar-addfmsg aname table))))))
  
(defun mizar-comp-addmsgs (atab expl)
"Replace errcodes in ATAB by  explanations from EXPL.
ATAB is reversed."
(let ((msgs "")
      (atab atab))
  (while atab
    (let* ((l1 expl)
	   (currecord (car atab))
	   (ercode (third currecord)))
      (while (not (= ercode (caar l1)))
	(setq l1 (cdr l1)))
      (setq msgs (concat aname ".miz:" (number-to-string (car currecord)) ":"
			 (number-to-string (cadr currecord)) ":"
			 (cadar l1) msgs)))
    (setq atab (cdr atab)))
  msgs))


(defun mizar-compile-errors (aname)
"Return string of errors and explanations for ANAME in compile-like format.
Nil if no errors."
  (let ((errors (concat aname ".err")))
    (if (and (file-readable-p errors)
	     (< 0 (file-size errors)))
	(let* ((table (mizar-get-errors aname))
	       (atab (sort-for-errflag table))
	       (expl (mizar-getmsgs (mizar-err-codes aname table) t)))
	  (mizar-comp-addmsgs atab expl)))))


;;;;;;;;;;;;;;; end of errflag ;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;; scanning ;;;;;;;;;;;;;;;;;;;;;

(defvar mizar-symbols-regexp "" "String for fontification of symbols.")
(defvar dct-table-date -1 "Date of the dct file.")

(make-variable-buffer-local 'mizar-symbols-regexp)
(make-variable-buffer-local 'dct-table-date)

;; fixed for xemacs leaving "" in the end
(defun buff-to-symblist ()
(let ((l (delete "" (split-string (buffer-string) "\n")))
      res)
  (while l
;    (if (string-match "^.[0-9]+ \\(.*\\)" (car l))
    (if (string-match "^[GKLMORUV][0-9]+ \\(.*\\)" (car l))
	(setq res (cons (match-string 1 (car l)) res)))
    (setq l (cdr l)))
  (nreverse res)))


(defun mizar-get-dct (aname)
"Return the symbols regexp for an article ANAME."
(save-excursion
  (let ((dct (concat aname ".dct")))
    (if (file-readable-p dct)
	(let ((dctdate (cadr (nth 5 (file-attributes dct)))))
	  (if (/= dct-table-date dctdate)
	      (let (tab)
		(with-temp-buffer           ; sort columns, then lines
		  (insert-file-contents dct)
		  (setq tab (buff-to-symblist)))
		(setq dct-table-date dctdate
		      mizar-symbols-regexp (regexp-opt tab))))))
    mizar-symbols-regexp)))

;;;;;;; some cluster hacking (also for MMLQuery) ;;;;;;;;;;;;;;;;;;
;;; this should be improved by outputting the cluster tables after
; analyzer (or having interactive verifier), we now have only clusters
; after accommodation

; cluster-table stuff commented now, ver. 6.2. resigned on
; collecting; leaving it here since two years from now we will
; be collecting again :-)

; (defvar cluster-table nil "table of clusters for the article")
(defvar eclusters nil "Table of existential clusters for the article.")
(defvar fclusters nil "Table of functor clusters for the article.")
(defvar cclusters nil "Table of conditional clusters for the article.")

; (defvar cluster-table-date -1
; "now as constr-table-date, but should be updated more often")
(defvar ecl-table-date -1
"Now as constr-table-date, but should be updated more often.")

; (make-variable-buffer-local 'cluster-table)
(make-variable-buffer-local 'eclusters)
(make-variable-buffer-local 'fclusters)
(make-variable-buffer-local 'cclusters)
; (make-variable-buffer-local 'cluster-table-date)
(make-variable-buffer-local 'ecl-table-date)

; (defun parse-cluster-table (aname &optional reload)
;   (let ((cluname (concat aname ".clu")))
;     (or (file-readable-p cluname)
; 	(error "File unreadable: %s" cluname))
;     (let ((cludate (cadr (nth 5 (file-attributes cluname)))))
;       (if (or reload (/= cluster-table-date cludate))
; 	  (let (tab)
; 	    (with-temp-buffer
; 	      (insert-file-contents cluname)
; 	      (setq tab
; 		    (vconcat '("")
; 			     (split-string (buffer-string) " ;[\n]"))))
; 	    (setq cluster-table tab
; 		  cluster-table-date cludate))))))


(defun fix-pre-type (str)
"Change G for type to L in STR.
This is now based on a shaky assumption
that any _real_ G (functor) has at least one field."
  (let ((start 0) (res (copy-sequence str)))
    (while  (setq start (string-match "G\\([0-9]+ [;WV]\\)" res start))
      (aset res start 76)
      (setq start (match-end 0)))
    res))


; (defun fix-pre-type (str &optional table)
;   "expand clusters for types using cluster-table, change G for type to L "
;   (let ((table (or table cluster-table))
; 	(lend 0)  start  mtch cl clnr typ (res ""))
;     (while  (string-match "V[0-9]+ V\\([0-9]+\\) \\([MGL]\\)" str lend)
;       (setq start (match-beginning 0)
; 	    mtch (match-string 1 str)
; 	    clnr (string-to-number mtch)
; 	    cl (if (< clnr (length table))
; 		   (aref table (string-to-number mtch))
; 		 (concat "c" mtch))
; 	    typ (match-string 2 str)
; 	    res (concat res (substring str lend start) cl " "
; 			(if (equal typ "G") "L" typ))
; 	    lend (match-end 0)))
;     (concat res (substring str lend))))


; (defun expand-incluster (str &optional table)
;   "expand cluster entry in .ecl using cluster-table"
;   (let ((table (or table cluster-table)))
;     (string-match "^.[AW][0-9]+" str)
;     (let* ((clnr (string-to-number (substring str 2 (match-end 0))))
; 	   (cl (concat (aref table clnr) ":"))
; 	   (result (replace-match cl t t str)))
;       (if (string-match "C\\([0-9]+\\)[ \t]*$" result)
; 	  (let* ((clnr2 (string-to-number
; 			 (substring result (match-beginning 1)
; 				    (match-end 1))))
; 		 (cl2 (concat ":" (aref table clnr2) )))
; 	    (replace-match cl2 t t result))
; 	result))))


(defun parse-clusters (aname &optional reload)
"Parse the eclusters, fcluster and cclusters tables  for ANAME.
Usually from .ecl file.  Cluster-table must be loaded.
RELOAD does this unconditionally."
(let ((ecldate (cadr (nth 5 (file-attributes (concat aname ".ecl"))))))
  (if (or reload (/= ecl-table-date ecldate))
      (let (ex func cond)  ; (table cluster-table))
	(with-temp-buffer
	  (insert-file-contents (concat aname ".ecl"))
	  (let ((all (split-string (buffer-string) "[\n]")))
	    (while (eq (aref (car all) 0) 143) ; char 143 is exist code
	      (setq ex (cons (car all) ex))
	      (setq all (cdr all)))
	    (while (eq (aref (car all) 0) 102) ; char 102 is 'f'
	      (setq func (cons (car all) func))
	      (setq all (cdr all)))
	    (while (eq (aref (car all) 0) 45) ; char 45 is '-'
	      (setq cond (cons (car all) cond))
	      (setq all (cdr all)))))
	(setq eclusters (vconcat (nreverse ex))
	      fclusters (vconcat (nreverse func))
	      cclusters (vconcat (nreverse cond))
	      ecl-table-date ecldate)
	))))

(defun print-vec1 (vec &optional translate)
"Print vector of strings VEC into string.
Used only for clusters.  Calls `frmrepr' if TRANSLATE."
(let ((res "")
      (l (length vec))
      (i 0))
  (while (< i l)
    (setq res (concat res "\n"
		      (if translate (frmrepr (aref vec i)) (aref vec i))))
    (setq i (+ 1 i)))
  res))
  
  
(defun show-clusters (&optional translate)
"Show the cluster tables in buffer *Clusters*.
Previous contents of that buffer are killed first.
TRANSLATE causes `frmrepr' to be called."
  (interactive)
  ;; This puts a description of bindings in a buffer called *Help*.
  (let ((result (concat (print-vec1 eclusters translate) "\n"
			(print-vec1 fclusters translate) "\n"
			(print-vec1 cclusters translate) "\n")))
		       
    (with-output-to-temp-buffer "*Clusters*"
      (save-excursion
	(set-buffer standard-output)
	(erase-buffer)
	(insert result))
      (goto-char (point-min)))))

; should be tested for 6.2.!
(defun parse-show-cluster (&optional translate fname reload)
(interactive)
(save-excursion
(let ((name (or fname
		(substring (buffer-file-name) 0
			   (string-match "\\.miz$"
					 (buffer-file-name))))))
;  (parse-cluster-table name reload)
  (parse-clusters name reload)
  (if translate (get-sgl-table name))
  (show-clusters translate))))


;;;;;;;;;;;;;;; translation for MML Query ;;;;;;;;;;;;;;;;;;;;;;
;; should be improved but mostly works
(defvar mizar-do-expl nil
"*Put constructor format of 'by' items as properties after verifier run.")
(defvar constrstring "KRVMLGU")
(defvar cstrlen (length constrstring))
; (defvar constructors '("K" "R" "V" "M" "L" "G" "U"))
(defvar ckinds ["func" "pred" "attr" "mode" "struct" "aggr" "sel"])
(defvar cstrnames [])
(defvar cstrnrs [])
(defvar impnr 0)
(defvar constr-table-date -1
"Set to last accommodation date, after creating the table.
Used to keep tables up-to-date.")

(make-variable-buffer-local 'cstrnames)
(make-variable-buffer-local 'cstrnrs)
(make-variable-buffer-local 'impnr)
(make-variable-buffer-local 'constr-table-date)

(defun cstr-idx (kind)  ; just a position
"Return nil if KIND not in `constrstring', otherwise its position."
(let ((res 0))
  (while (and (< res cstrlen) (/= kind (aref constrstring res)))
    (setq res (+ res 1)))
  (if (< res cstrlen)
      res)))
	      
; (position kind constructors :test 'equal))

(defun make-one-tvect (numvect)
  (vconcat (mapcar 'string-to-int (split-string numvect))))

(defun get-sgl-table (aname)
  "Two vectors created from the .sgl file for ANAME."
  (let ((sglname (concat aname ".sgl")))
    (or (file-readable-p sglname)
	(error "File unreadable: %s" sglname))
    (let ((sgldate (cadr (nth 5 (file-attributes sglname)))))
      (if (/= constr-table-date sgldate)
	  (let* ((decl (with-temp-buffer
			 (insert-file-contents sglname)
			 (split-string (buffer-string) "[\n]")))
		 (count (string-to-int (car decl)))
		 (result (cdr decl))
		 (tail (nthcdr count decl))
		 (nums (cdr tail))
		 names)
	    (setcdr tail nil)
	    (setq names (vconcat result (list (upcase aname))))
	    (setq nums (vconcat (mapcar 'make-one-tvect nums)))
	    (list names nums)
	    (setq impnr (- (length names) 1)
		  cstrnames names
		  cstrnrs nums
		  constr-table-date sgldate)
	    )))))

(defun idxrepr (idx nr)
"Does the work for tokenrepr, IDX is index of constrkind."
  (let ((artnr 0))
    (while (and (< artnr impnr)
		(< (aref (aref cstrnrs artnr) idx) nr))
      (setq artnr (+ artnr 1)))
    (if (or (< artnr impnr)
	    (<= nr (aref (aref cstrnrs artnr) idx)))
	(setq artnr (- artnr 1)))
    (concat (aref cstrnames artnr) ":"
	    (aref ckinds idx) "."
	    (int-to-string (- nr (aref (aref cstrnrs artnr) idx))))
    ))

(defun tokenrepr (kind nr)
"Return absolute name of a lexem KIND, NR, if possible.
Uses the global tables `cstrnames' and `cstrnrs'."
  (let ((idx (cstr-idx kind))
	(artnr 0))
    (if idx (idxrepr idx nr)
      (concat kind (int-to-string nr))
      )))

(defvar mizartoken2human
  (let ((table (make-vector 256 0))
	(i 0))
    (while (< i 256) (aset table i (char-to-string i)) (incf i))
    (aset table 38 "and ")
    (aset table 170 "not ")
    (aset table 157 "for ")
    (aset table 144 "is ")
    (aset table 37 "verum ")
    (aset table 63 "unknown ")
    table)
"Table translating internal tokens for formula kinds")


(defun frmrepr (frm &optional cstronly)
"Absolute repr of a formula FRM.
If CSTRONLY, only list of constructors,
The clusters inside FRM must already be expanded here."
  (let* ((frm1 frm) (res (if cstronly nil ""))
	(cur 0) (end (or (position 39 frm1) (length frm1)))) ;
    (while (< cur end)
      (let* ((tok (aref frm1 cur))
	     (nonv (= tok 87))   ; W
	     (idx (if nonv (cstr-idx 86) ; V - we put the "non" back below
		    (cstr-idx tok))))
	(if idx
	    (let* ((cur1 (+ cur 1))
		   (nr1 "") (cont t) n1)
	      (while (and cont (< cur1 end)) ;number
		(setq n1 (aref frm1 cur1))
		(if (and (< 47 n1) (< n1 58))
		    (setq nr1 (concat nr1 (char-to-string n1))
			  cur1 (+ cur1 1))
		  (setq cont nil)))
	      (setq tok (idxrepr idx (string-to-int nr1))
		    cur cur1)
	      (setq res
		    (if cstronly (nconc res (list tok))
		      (concat res (if nonv "non " "") tok))))
	  (setq cur (+ 1 cur))
	  (if (not cstronly)
	      (setq res (concat res (aref mizartoken2human tok)))))))
    res))

(defun expfrmrepr (frm &optional cstronly)
(frmrepr (fix-pre-type frm) cstronly))

(defun mizar-getbys (aname)
  "Get constructor repr of bys from the .pre file for ANAME."
  (let ((prename (concat aname ".pre")))
    (or (file-readable-p prename)
	(error "File unreadable: %s" prename))
    (let (res)
      (with-temp-buffer
	(insert-file-contents prename)
	(goto-char (point-min))
	(while (re-search-forward
		"e[0-9]+ [0-9]+ [0-9]+ \\(.*\\)['][^;]*; *\\([0-9]+\\) \\([0-9]+\\)"
		(point-max) t)
	  (let ((line (match-string 2))
		(col (match-string 3))
		(frm (match-string 1)))
	    (setq res (cons (list (string-to-int line)
				  (string-to-int col) frm) res)))))
      (nreverse res))))
      

(defvar byextent 1 "Size of the underlined region.")
(defvar mizar-underline-expls nil
"*If t, the clickable explanation spots in mizar buffer are underlined.")

(defvar mizar-expl-map
  (let ((map (make-sparse-keymap))
	(button_kword (if (eq mizar-emacs 'xemacs) [(shift button3)]
			[(shift mouse-3)])))
    (set-keymap-parent map mizar-mode-map)
    (define-key map button_kword 'mizar-show-constrs-other-window)
    (define-key map "\M-;"     'mizar-show-constrs-kbd)
    map)
"Keymap used at explanation points.")

(defconst local-map-kword
  (if (eq mizar-emacs 'xemacs) 'keymap 'local-map)
  "Xemacs vs.  Emacs local-map.")

(defun mizar-put-bys (aname)
"Put the constructor representation of bys as text properties
into the mizar buffer ANAME.
Underlines and mouse-highlites the places."
(save-excursion
; check at least for the .pre file, not to exit with error below
(if (not (file-readable-p (concat aname ".pre")))
    (message "Cannot explain constructors, verifying was incomplete")
  (get-sgl-table aname)
;  (parse-cluster-table aname)
  (let ((bys (mizar-getbys aname))
	(oldhook after-change-functions)
	(map mizar-expl-map)
	props)
    (setq after-change-functions nil)
    (setq props (list 'mouse-face 'highlight local-map-kword map))
    (if mizar-underline-expls
	(setq props (append props '(face underline))))
    (while bys
      (let* ((rec (car bys))
	     (line (car rec))
	     (col (cadr rec))
	     (frm (third rec))
	     beg eol end)
	(goto-line line)
	(end-of-line)
	(setq eol (point))
	(move-to-column col)
	(setq beg (point)
	      end (min eol (+ byextent beg)))
	(add-text-properties beg end props)
	(put-text-property beg end 'expl frm)
	(setq bys (cdr bys))))
    (setq after-change-functions oldhook)
    nil))))
	
(defvar mizar-expl-kind 'sorted
"*Variable controlling the display of constructor representation of formulas.
Possible values are now 
'raw for the internal Mizar representation,
'expanded for expansion of clusters,
'translate for expanded formula in absolute notation,
'constructors for list of constructors in absolute notation,
'sorted for sorted list of constructors in absolute notation.
The values 'raw and 'expanded are for debugging only, do
not use them to get constructor explanatios.")

(defvar cstrregexp "\\([A-Z0-9_]+\\):\\([a-z]+\\)[.]\\([0-9]+\\)"
"Description of the constr format we use, see idxrepr.")

(defvar mizar-cstr-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-m" 'mizar-kbd-cstr-mmlquery)
    (define-key map "\C-\M-m" 'mizar-kbd-ask-query)
    (define-key map "\M-." 'mizar-kbd-cstr-tag)
    (define-key map "\C-c\C-c" 'mizar-ask-advisor)
    (if (eq mizar-emacs 'xemacs)
	(progn
	  (define-key map [button2] ' mizar-mouse-cstr-mmlquery)
	  (define-key map [(shift button2)] 'mizar-mouse-ask-query)
	  (define-key map [button3] 'mizar-mouse-cstr-tag))
      (define-key map [mouse-2] 'mizar-mouse-cstr-mmlquery)
      (define-key map [(shift mouse-2)] 'mizar-mouse-ask-query)
      (define-key map [mouse-3] 'mizar-mouse-cstr-tag))
    map)
"Keymap in the buffer *Constructors list*.
Used for viewing constructor meanings via symbtags or sending
constructor queries to MML Query.
Commands:
\\{mizar-cstr-map}
")

(defvar alioth-url "http://alioth.uwb.edu.pl/cgi-bin/query/")
(defvar megrez-url "http://megrez.mizar.org/cgi-bin/")
(defvar query-url megrez-url)
(defvar query-text-output nil
"If non-nil, text output is required from MML Query.")
(defvar mizar-query-browser nil
"*Browser for MML Query, we allow 'w3 or default.")

; Xemacs vs. Emacs
(if (not (fboundp 'event-window))
    (fset 'event-window (lambda (e) (posn-window (event-end e)))))
(if (not (fboundp 'event-point))
    (fset 'event-point (lambda (e) (posn-point (event-end e)))))

(defun mizar-ask-query (query)
  (if (eq mizar-query-browser 'w3)
      (browse-url-w3 query)
    (browse-url query)))

(defun mizar-ask-meaning-query (cstr)
"Send a constructor query CSTR to MML Query."
(interactive "s")
(mizar-ask-query (concat query-url "emacs_search?entry=" cstr)))

(defun mizar-cstr-at-point (pos &optional agg2str)
"Get the constructor around POS, if AGG2STR, replace aggr by struct."
(save-excursion
  (goto-char pos)
  (skip-chars-backward ":.a-zA-Z_0-9")
  (if (looking-at cstrregexp)
      (let ((res (match-string 0)))
	(if (and agg2str (equal "aggr" (match-string 2)))
	    (concat (match-string 1) ":struct." (match-string 3))
	  res)))))

(defun mizar-mouse-ask-query (event)
"Ask MML Query about the constructor we clicked on."
  (interactive "e")
  (select-window (event-window event))
  (let ((cstr (mizar-cstr-at-point (event-point event))))
    (if cstr (mizar-ask-meaning-query cstr)
      (message "No constructor at point"))))

(defun mizar-kbd-ask-query (pos)
"Ask MML Query about the constructor at position POS."
  (interactive "d")
  (let ((cstr (mizar-cstr-at-point pos)))
    (if cstr (mizar-ask-meaning-query cstr)
      (message "No constructor at point"))))


(defun mizar-mouse-cstr-mmlquery (event)
"Find the definition of the constructor we clicked on in its
MMLQuery abstract."
  (interactive "e")
  (select-window (event-window event))
  (let ((cstr (mizar-cstr-at-point (event-point event))))
    (if cstr (mmlquery-goto-symdef (intern cstr) t)
      (message "No constructor at point"))))

(defun mizar-kbd-cstr-mmlquery (pos)
"Find the definition of the constructor at position POS in its
MMLQuery abstract."
  (interactive "d")
  (let ((cstr (mizar-cstr-at-point pos)))
    (if cstr (mmlquery-goto-symdef (intern cstr) t)
      (message "No constructor at point"))))



(defun mizar-kbd-cstr-tag (pos)
"Find the definition of the constructor at position POS."
  (interactive "d")
  (let ((cstr (mizar-cstr-at-point pos t)))
    (if cstr (mizar-symbol-def t cstr t)
      (message "No constructor at point"))))

(defun mizar-mouse-cstr-tag (event)
"Find the definition of the constructor we clicked on."
  (interactive "e")
  (select-window (event-window event))
  (let ((cstr (mizar-cstr-at-point (event-point event) t)))
    (if cstr (mizar-symbol-def t cstr t)
      (message "No constructor at point"))))


(defun mizar-highlight-constrs ()
(save-excursion
  (goto-char (point-min))
  (let ((props (list 'mouse-face 'highlight 'face 'underline)))
  (while (re-search-forward cstrregexp (point-max) t)
    (add-text-properties (match-beginning 0) (match-end 0) props)))))

(defun mizar-intern-constrs-other-window (res)
"Display the constructors RES in buffer *Constructors list* in other window and highlight."
(let ((cbuf (get-buffer-create "*Constructors list*")))
  (set-buffer cbuf)
  (erase-buffer)
  (insert res)
  (mizar-highlight-constrs)
  (use-local-map mizar-cstr-map)
  (goto-char (point-min))
  (switch-to-buffer-other-window cbuf)))


(defun mizar-show-constrs-kbd (&optional pos)
  "Show constructors of the inference at point.
The constructors are translated according to the variable 
`mizar-expl-kind', and shown in the buffer *Constructors list*.
The variable `mizar-do-expl' should be non-nil."
  (interactive)
  (let ((pos (or pos (point))))
    (interactive)
    (save-excursion
    (let ((frm (get-text-property pos 'expl)))
      (if frm
	  (let ((res
		 (cond ((eq mizar-expl-kind 'raw) frm)
		       ((eq mizar-expl-kind 'expanded) (fix-pre-type frm))
		       ((eq mizar-expl-kind 'translate) (expfrmrepr frm))
		       ((eq mizar-expl-kind 'constructors)
			(prin1-to-string (expfrmrepr frm t)))
		       ((eq mizar-expl-kind 'sorted)
			(prin1-to-string (sort (unique (expfrmrepr frm t)) 'string<)))
		       (t ""))))
	    (goto-char pos)
	    (mizar-intern-constrs-other-window res)))))))



(defun mizar-show-constrs-other-window (event)
  "Show constructors of the inference you click on.
The constructors are translated according to the variable 
`mizar-expl-kind', and shown in the buffer *Constructors list*.
The variable `mizar-do-expl' should be non-nil."
  (interactive "e")
  (select-window (event-window event))
  (save-excursion
    (let ((frm (get-text-property (event-point event) 'expl)))
      (if frm
	  (let ((res
		 (cond ((eq mizar-expl-kind 'raw) frm)
		       ((eq mizar-expl-kind 'expanded) (fix-pre-type frm))
		       ((eq mizar-expl-kind 'translate) (expfrmrepr frm))
		       ((eq mizar-expl-kind 'constructors)
			(prin1-to-string (expfrmrepr frm t)))
		       ((eq mizar-expl-kind 'sorted)
			(prin1-to-string (sort (unique (expfrmrepr frm t)) 'string<)))
		       (t ""))))
	    (goto-char (event-point event))
	    (mizar-intern-constrs-other-window res))))))

(defvar advisor-url "http://lipa.ms.mff.cuni.cz/cgi-bin/mycgi1.cgi")
(defvar advisor-limit 30
"*The number of hits you want Mizar proof Advisor to send you.")
(defvar advisor-output "*Proof Advice*")

(defun mizar-ask-advisor ()
  "Send the contents of the *Constr Explanations* buffer to Mizar Proof Advisor.
Resulting advice is shown in the buffer *Proof Advice*, where normal tag-browsing
keyboard bindings can be used to view the suggested references.
"
  (interactive)
  (let* ((query (concat advisor-url "?Text=1\\&Limit=" 
			(number-to-string advisor-limit)
			"\\&Formula="
			(query-handle-chars-cgi
			 (buffer-substring-no-properties
			  (point-min) (point-max)))))
	 (command (concat "wget -q -O - " (shell-quote-argument query))))
    (shell-command command advisor-output)
    (let ((abuffer (get-buffer advisor-output)))
      (if abuffer
	  (progn (switch-to-buffer-other-window abuffer)
		 (mizar-mode))
	(message "No references advised")))
    ))

(defun mizar-toggle-cstr-expl (to)
  (cond ((eq to 'none) (setq  mizar-do-expl nil))
	(t (setq  mizar-expl-kind to
		  mizar-do-expl t))))




;; Code for access to the squery ring
;; mostly stolen from vc
;; (these history funcs should be done generically in some emacs library)
(defconst query-maximum-squery-ring-size 128
  "Maximum number of saved comments in the comment ring.")
(defvar query-squery-ring (make-ring query-maximum-squery-ring-size))
(defvar query-squery-ring-index nil)
(defvar query-last-squery-match nil)
(defvar query-entry-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\M-n" 'query-next-squery)
    (define-key map "\M-p" 'query-previous-squery)
    (define-key map "\M-r" 'query-squery-search-reverse)
    (define-key map "\M-s" 'query-squery-search-forward)
    (define-key map "\C-c\C-c" 'query-send-entry)
    map)
"Keymap in the *MML Query Input* buffer.
Used for sending queries to MML Query server and browsing and searching
previous queries.
Commands:
\\{query-entry-map}
"
)

(defun query-entry-mode ()
  "Minor mode for sending MML Queries.
These bindings are added to the global keymap when you enter this mode:
\\[query-send-entry]	send the query to MML Query

Whenever you send a query, it is added to a ring of
saved queries.  These can be recalled as follows:

\\[query-next-squery]	replace region with next message in squery ring
\\[query-previous-squery]	replace region with previous message in squery ring
\\[query-squery-search-reverse]	search backward for regexp in the squery ring
\\[query-squery-search-forward]	search backward for regexp in the squery ring

Entry to the query-entry submode calls the value of `text-mode-hook', then
the value of query-entry-mode-hook."
  (interactive)
  (set-syntax-table text-mode-syntax-table)
  (use-local-map query-entry-map)
  (setq local-abbrev-table text-mode-abbrev-table)
  (setq major-mode 'query-entry-mode)
  (setq mode-name "Query-entry")
  (make-local-variable 'query-squery-ring-index)
  (set-buffer-modified-p nil)
  (setq buffer-file-name nil)
  (run-hooks 'text-mode-hook 'query-entry-mode-hook)
)

(defun query-start-entry ()
"Start a new query in buffer *MML Query input*."
  (interactive)
  (let ((buf  (or (get-buffer "*MML Query input*")
		  (get-buffer-create "*MML Query input*"))))
    (pop-to-buffer buf)
    (erase-buffer)
    (if (not (eq major-mode 'query-entry-mode))
	(query-entry-mode)))
  (message "Enter a query. Type C-c C-c when done.")
)

(defun alfanump (nr)
  (or (and (< nr 123) (< 96 nr))
      (and (< nr 91) (< 64 nr))
      (and (< nr 58) (< 47 nr))))

(defun query-handle-chars-cgi (str)
"Replace nonalfanumeric chars in STR by %code."
(let ((slist (string-to-list str))
      (space (nreverse (string-to-list (format "%%%x" 32))))
      res codel)
  (if (eq mizar-emacs 'xemacs)
      (setq slist (mapcar 'char-to-int slist)))
  (while slist
    (let ((i (car slist)))
      (cond ((alfanump i)
	     (setq res (cons i res)))
	    ((member i '(32 10 9 13))        ; "[ \n\t\r]"
	     (setq res (append space res)))
	    (t
	     (setq codel (nreverse (string-to-list (format "%x" i))))
	     (setq res (nconc codel (cons 37 res))))))
    (setq slist (cdr slist)))
  (concat (nreverse res))))



(defun query-send-entry ()
  "Send the contents of the current buffer to MML Query."
  (interactive)
  (ring-insert query-squery-ring (buffer-string))
  (let ((query (concat query-url "emacs_search?input="
		     (query-handle-chars-cgi (buffer-string)))))
  (if query-text-output
      (setq query (concat query "&text=1")))
  (mizar-ask-query query)))

(defun query-previous-squery (arg)
  "Cycle backwards through query-squery history.
With a numeric prefix ARG, go back ARG queries."
  (interactive "*p")
  (let ((len (ring-length query-squery-ring)))
    (cond ((<= len 0)
	   (message "Empty query-squery ring")
	   (ding))
	  (t
	   (erase-buffer)
	   ;; Initialize the index on the first use of this command
	   ;; so that the first M-p gets index 0, and the first M-n gets
	   ;; index -1.
	   (if (null query-squery-ring-index)
	       (setq query-squery-ring-index
		     (if (> arg 0) -1
			 (if (< arg 0) 1 0))))
	   (setq query-squery-ring-index
		 (mod (+ query-squery-ring-index arg) len))
	   (message "%d" (1+ query-squery-ring-index))
	   (insert (ring-ref query-squery-ring query-squery-ring-index))))))

(defun query-next-squery (arg)
  "Cycle forward through comment history.
With a numeric prefix ARG, go forward ARG queries."
  (interactive "*p")
  (query-previous-squery (- arg)))

(defun query-squery-search-reverse (str)
  "Search backward through squery history for substring match of STR."
  (interactive "sPrevious query matching (regexp): ")
  (if (string= str "")
      (setq str query-last-squery-match)
    (setq query-last-squery-match str))
  (if (null query-squery-ring-index)
      (setq query-squery-ring-index -1))
  (let ((len (ring-length query-squery-ring))
	(n (1+ query-squery-ring-index)))
    (while (and (< n len) (not (string-match str (ring-ref query-squery-ring n))))
      (setq n (+ n 1)))
    (cond ((< n len)
	   (query-previous-squery (- n query-squery-ring-index)))
	  (t (error "Not found")))))

(defun query-squery-search-forward (str)
  "Search forwards through squery history for substring match of STR."
  (interactive "sNext query matching (regexp): ")
  (if (string= str "")
      (setq str query-last-squery-match)
    (setq query-last-squery-match str))
  (if (null query-squery-ring-index)
      (setq query-squery-ring-index 0))
  (let ((len (ring-length query-squery-ring))
	(n query-squery-ring-index))
    (while (and (>= n 0) (not (string-match str (ring-ref query-squery-ring n))))
      (setq n (- n 1)))
    (cond ((>= n 0)
	   (query-next-squery (- n query-squery-ring-index)))
	  (t (error "Not found")))))


;;;;;;;;;;; MMLQuery browsing

(defvar mmlquery-mode nil
  "True if Mmlquery mode is in use.")

(make-variable-buffer-local 'mmlquery-mode)
(put 'mmlquery-mode 'permanent-local t)

(defcustom mmlquery-mode-hook nil
  "Functions to run when entering Mmlquery mode."
  :type 'hook
  :group 'mmlquery)

(defvar mmlquery-mode-map nil
  "Keymap for mmlquery minor mode.")

(defvar mmlquery-mode-menu nil
  "Menu for mmlquery minor mode.")


(if mmlquery-mode-map
    nil
  (setq mmlquery-mode-map (make-sparse-keymap))
  (define-key mmlquery-mode-map "\C-cn" 'mmlquery-next)
  (define-key mmlquery-mode-map "\C-cp" 'mmlquery-previous)
  (easy-menu-define mmlquery-mode-menu
    mmlquery-mode-map
    "Menu used when mmlquery minor mode is active."
    '("MML Query"	    
	    ["Next" mmlquery-next :active (< 0 mmlquery-history-position)
	    :help "Go to the next mmlquery definition"]	    
	    ["Previous" mmlquery-previous :active 
              (< (+ 1 mmlquery-history-position) (ring-length mmlquery-history))
	    :help "Go to the previous definition"]
	    ("Hiding items in browser"	    
	     ["Definitional theorems" mmlquery-toggle-def :style radio 
	      :selected (not (memq 'mmlquery-def buffer-invisibility-spec)) :active t
	      :help "Toggle hiding of definitional theorems" ]
	      ["Definienda" mmlquery-toggle-dfs :style radio :selected 
	      (not (memq 'mmlquery-dfs buffer-invisibility-spec)) :active t
	      :help "Toggle hiding of constructor definienda" ]
	     ["Property formulas" mmlquery-toggle-property-hiding 
	      :style radio :selected (not mmlquery-properties-hidden) :active t
	      :help "Hide/Show all property formulas" ]
	     ["Existential clusters" (mmlquery-toggle-hiding 'mmlquery-exreg) :style radio 
	      :selected (not (memq 'mmlquery-exreg buffer-invisibility-spec)) :active t
	      :help "Toggle hiding of existential clusters" ]
	     ["Functor clusters" (mmlquery-toggle-hiding 'mmlquery-funcreg) :style radio 
	      :selected (not (memq 'mmlquery-funcreg buffer-invisibility-spec)) :active t
	      :help "Toggle hiding of functor clusters" ]
	     ["Conditional clusters" (mmlquery-toggle-hiding 'mmlquery-condreg) :style radio 
	      :selected (not (memq 'mmlquery-condreg buffer-invisibility-spec)) :active t
	      :help "Toggle hiding of conditional clusters" ]	
	      ["Theorems" (mmlquery-toggle-hiding 'mmlquery-th) :style radio 
	      :selected (not (memq 'mmlquery-th buffer-invisibility-spec)) :active t
	      :help "Toggle hiding of theorems" ]
	     ))))

(or (assq 'mmlquery-mode minor-mode-map-alist)
    (setq minor-mode-map-alist
          (cons (cons 'mmlquery-mode mmlquery-mode-map)
                minor-mode-map-alist)))
(or (assq 'mmlquery-mode minor-mode-alist)
    (setq minor-mode-alist
	  (cons '(mmlquery-mode " MMLQuery")
		minor-mode-alist)))


(defvar mmlquery-tool-bar-map
  (if (display-graphic-p)
      (let ((tool-bar-map (make-sparse-keymap)))
;	(tool-bar-add-item-from-menu 'Info-exit "close" Info-mode-map)
	(tool-bar-add-item-from-menu 'mmlquery-previous "left_arrow" mmlquery-mode-map)
	(tool-bar-add-item-from-menu 'mmlquery-next "right_arrow" mmlquery-mode-map)
 	(tool-bar-add-item-from-menu 'mmlquery-toggle-def "cut" mmlquery-mode-map)
 	(tool-bar-add-item-from-menu 'mmlquery-toggle-dfs "preferences" mmlquery-mode-map)
	(tool-bar-add-item-from-menu 'mmlquery-toggle-property-hiding "paste" 
				     mmlquery-mode-map)
;; 	(tool-bar-add-item-from-menu 'Info-top-node "home" Info-mode-map)
;; 	(tool-bar-add-item-from-menu 'Info-index "index" Info-mode-map)
;; 	(tool-bar-add-item-from-menu 'Info-goto-node "jump_to" Info-mode-map)
;; 	(tool-bar-add-item-from-menu 'Info-search "search" Info-mode-map)
	tool-bar-map)))




(defun mmlquery-mode (&optional arg)
  "Minor mode for browsing text/mmlquery files.
These are files with embedded formatting information in the MIME standard
text/mmlquery format.
Turning the mode on runs `mmlquery-mode-hook'.

Commands:

\\<mmlquery-mode-map>\\{mmlquery-mode-map}"
  (interactive "P")
  (let ((mod (buffer-modified-p)))
    (cond ((or (<= (prefix-numeric-value arg) 0)
	       (and mmlquery-mode (null arg)))
	   ;; Turn mode off
	   (easy-menu-remove mmlquery-mode-menu) ; xemacs only
	   (setq mmlquery-mode nil)
	   (setq buffer-file-format (delq 'text/mmlquery buffer-file-format)))
	  
	  (mmlquery-mode nil)		; Mode already on; do nothing.

	  (t (setq mmlquery-mode t)	; Turn mode on
	     (mizar-mode)               ; Turn on mizar-mode
	     (hs-minor-mode -1)         ; Turn off hs-minor-mode
	     (add-to-list 'buffer-file-format 'text/mmlquery)
	     (add-to-list 'fontification-functions 'mmlquery-underline-highlited)
	
	     (make-local-variable 'font-lock-fontify-region-function)
	     (make-local-variable 'mmlquery-properties-hidden)
	     (set (make-local-variable 'tool-bar-map) mmlquery-tool-bar-map)
	     (let ((oldfun font-lock-fontify-region-function))
	       (setq font-lock-fontify-region-function
		     `(lambda (beg end loudly) 
			(,oldfun beg end loudly)
		       (mmlquery-underline-in-region beg end))))	

	     (mmlquery-underline-highlited 0)
	     (mmlquery-default-invisibility)
	     (easy-menu-add mmlquery-mode-menu) ; for xemacs only

	     (run-hooks 'mmlquery-mode-hook)))
    (set-buffer-modified-p mod)
    (force-mode-line-update)))



;; Reading .gab files

;; The .gab files contain anchors and definitions. 
;; During parsing, the text properties are set for anchors,
;; while definitions are used to save their position as symbol
;; property 'definition.

;; If the 'definition property is missing from a symbol, we 
;; open the .gab file containing the symbol first.


;; Parsing  completely stolen from enriched.el

;; We use a lot of invisibility
(put 'invisible 'format-list-valued t)

(defconst mmlquery-annotation-regexp "<\\(/\\)?\\([-A-Za-z0-9]+\\)>"
  "Regular expression matching mmlquery-text annotations.")

(defconst mmlquery-translations
  '(
;;    (mouse-face    (highlight   "a"))		   
    (PARAMETER     (t           "p")) ; Argument of preceding annotation
    ;; The following are not part of the standard:
    (FUNCTION      (mmlquery-decode-anchor "a")
		   (mmlquery-decode-definition "l")
		   (mmlquery-decode-constructor "c")
		   (mmlquery-decode-property     "r")
		   (mmlquery-decode-hidden "h")) ; generic hidden
    (read-only     (t           "x-read-only"))
    (unknown       (nil         format-annotate-value))
)
  "List of definitions of text/mmlquery annotations.
See `format-annotate-region' and `format-deannotate-region' for the definition
of this structure.")


(defvar mmlquery-anchor-map
  (let ((map (make-sparse-keymap))
	(button_kword (if (eq mizar-emacs 'xemacs) [button2]
			[mouse-2])))
    (set-keymap-parent map mizar-mode-map)
    (define-key map button_kword 'mmlquery-goto-def-mouse)
    (define-key map "\C-m"  'mmlquery-goto-def)
    map)
"Keymap used at mmlquery anchors.")


(defun mmlquery-decode-anchor (start end &optional param)
  "Decode an anchor property for text between START and END.
PARAM is a `<p>' found for the property.
Value is a list `(START END SYMBOL VALUE)' with START and END denoting
the range of text to assign text property SYMBOL with value VALUE "
  (let ((map mmlquery-anchor-map))
    (add-text-properties start end 
			 (list 'mouse-face 'highlight 'face 'underline 
			       'fontified t local-map-kword map))
    (list start end 'anchor (intern param))))

(defun mmlquery-decode-definition (start end &optional param)
  "Decode a definition property for text between START and END.
PARAM is a `<p>' found for the property.
Value is a list `(START END SYMBOL VALUE)' with START and END denoting
the range of text to assign text property SYMBOL with value VALUE "
(let (kind (sym (intern param)))
  (unless (string-match ".*\\:\\([a-z]+\\) .*" param)
    (error "Error: all dli items are supposed to match \":[a-z]+[ ]\": %s" param))
  (setq kind (intern (concat "mmlquery-" (match-string 1 param))))
  (put sym 'mmlquery-definition start)
  (put sym 'mmlquery-kind kind)
  (put-text-property start end 'mmlquery-kind kind)
  (list start end 'invisible kind)))

(defvar mmlquery-property-map
  (let ((map (make-sparse-keymap))
	(button_kword (if (eq mizar-emacs 'xemacs) [button2]
			[mouse-2])))
    (set-keymap-parent map mizar-mode-map)
    (define-key map button_kword 'mmlquery-toggle-property-invis-mouse)
    (define-key map "\C-m"  'mmlquery-toggle-property-invis)
    map)
"Keymap used at mmlquery properties.")

(defun mmlquery-decode-property (start end &optional param)
  "Decode a 'property property for text between START and END.
PARAM is a `<p>' found for the property and must be nil.
Value is a list `(START END SYMBOL VALUE)' with START and END denoting
the range of text to assign text property SYMBOL with value VALUE "
  (let ((map mmlquery-property-map)
	(text (buffer-substring-no-properties start end)))
    (or (string-match "^\\([a-z]+\\);" text)
	(error "Error: all properties are supposed to match \"^[a-z]+$\": %s" param))
    (let ((prop (match-string 1 text)))
      (add-text-properties start (+ start (length prop))
			   (list 'mouse-face 'highlight 'face 'underline 
				 'fontified t local-map-kword map))
      (list start end 'mmlquery-property (intern (concat "mmlquery-" prop))))))


(defun mmlquery-decode-hidden (start end &optional param)
  "Decode a hidden property for text between START and END.
PARAM is a `<p>' found for the property.
Value is a list `(START END SYMBOL VALUE)' with START and END denoting
the range of text to assign text property SYMBOL with value VALUE "
  (unless (string-match "^[a-z]+$" param)
    (error "Error: all properties are supposed to match \"^[a-z]+$\": %s" param))
  (let ((invis (get-text-property start 'invisible))
	(kind (intern  (concat "mmlquery-" param))))
    (put-text-property start end 'mmlquery-property-fla t)
    (list start end 'invisible 'mmlquery-property)
))


(defun get-mmlquery-symbol-article (sym)
"Extract the article name from a symbol, append '.gab'."
  (let ((sname (symbol-name sym)))
    (unless (string-match "\\([A-Z_0-9]+\\):.*" sname)
      (error "Bad article name %s in symbol %S" sname sym))
    (concat (downcase (match-string 1 sname)) ".gab")))


(defun mmlquery-decode-constructor (start end &optional param)
  "Decode a constructor property for text between START and END.
PARAM is a `<p>' found for the property.
Value is a list `(START END SYMBOL VALUE)' with START and END denoting
the range of text to assign text property SYMBOL with value VALUE "
(let ((sym (intern param)))
;; The first def in its article is the 'true' original for us 
  (if (and (not (get sym 'constructor))
	   (equal (get-mmlquery-symbol-article sym)
		  (file-name-nondirectory (buffer-file-name (current-buffer)))))      	   
      (put sym 'constructor start)
;; otherwise it is stored among redefinitions
    (put sym 'constructor-redef (cons start (get sym 'constructor-redef))))
  (list start end 'definition sym)))



(defun mmlquery-next-annotation ()
  "Find and return next text/mmlquery annotation.
Any \"<<\" strings encountered are converted to \"<\".
Return value is \(begin end name positive-p), or nil if none was found."
  (while (and (search-forward "<" nil 1)
	      (progn (goto-char (match-beginning 0))
		     (not (looking-at mmlquery-annotation-regexp))))
    (forward-char 1)
    (if (= ?< (char-after (point)))
	(delete-char 1)
      ;; A single < that does not start an annotation is an error,
      ;; which we note and then ignore.
      (message "Warning: malformed annotation in file at %s" 
	       (1- (point)))))
  (if (not (eobp))
      (let* ((beg (match-beginning 0))
	     (end (match-end 0))
	     (name (downcase (buffer-substring 
			      (match-beginning 2) (match-end 2))))
	     (pos (not (match-beginning 1))))
	(list beg end name pos))))


(defun mmlquery-remove-header ()
  "Remove file-format header at point."
  (while (looking-at "^::[ \t]*Content-[Tt]ype: .*\n")
    (delete-region (point) (match-end 0)))
  (if (looking-at "^\n")
      (delete-char 1)))

(defun mmlquery-decode (from to)
  (save-excursion
    (save-restriction
      (narrow-to-region from to)
      (goto-char from)
      (mmlquery-remove-header)
      ;; Translate annotations
      (format-deannotate-region from (point-max) mmlquery-translations
				'mmlquery-next-annotation)
      (point-max))))

;;;; The browsing functions

(defvar mmlquery-history-size 512
"*Size of the mmlquery history ring.
When this is reached, the oldest element is forgotten.")

(defvar mmlquery-history-position -1
"Our position in mmlquery-history.
Has to be updated with any operation on `mmlquery-history'.")

(defvar mmlquery-history (make-ring mmlquery-history-size)
  "History of definitions user has visited.
It has a browser-like behavior: going from the middle of it
to something different from its successor causes the whole
successor list to be forgotten.
Each element of the history is a list
(buffer file-name position), if buffer was killed and file-name exists, we re-open the file.")

(defvar mmlquery-abstracts 
"/home/urban/mizarmode/gab/"
;(substitute-in-file-name "$MIZFILES/gab")
  "*Directory containing the mmlquery abstracts for browsing.")

      
(defun ring-delete-from (ring index)
"Delete all RING elements starting from INDEX (including it).
INDEX = 0 is the most recently inserted; higher indices
correspond to older elements.
If INDEX > RING legth, do nothing and return nil, otherwise 
return the new RING length."
(if (< index (ring-length ring))
;; This could be done more efficiently
(let ((count (+ 1 index)))
  (while (< 0 count)
    (ring-remove ring 0)
    (decf count))
  (ring-length ring))))


(defun mmlquery-goto-def (&optional pos)
"Goto the definition of the constructor at point or POS if given."
  (interactive "d")
  (let* ((anch (get-text-property (or pos (point)) 'anchor)))
    (unless anch (error "No mmlquery reference at point!"))
    (mmlquery-goto-symdef anch t)))

(defun mmlquery-goto-def-mouse (event)
"Goto to the definition of the constructor we clicked on."
  (interactive "e")
  (select-window (event-window event))
  (let* ((anch (get-text-property (event-point event) 'anchor)))
    (unless anch (error "No mmlquery reference at point!"))
    (mmlquery-goto-symdef anch t)))


(defun mmlquery-goto-symdef (anch &optional push)
"Go to the definition of ANCH. 
If PUSH, push positions onto the mmlquery-history."
  (let ((afile (concat mmlquery-abstracts 
		       (get-mmlquery-symbol-article anch)))
	(defpos (get anch 'constructor))
	(oldbuf (current-buffer))
	(oldfile (buffer-file-name (current-buffer)))
	(oldpos (point)))
;; Load the article if not yet
    (unless defpos
      (find-file-noselect afile)
      (setq defpos (get anch 'constructor)))
    (unless defpos (error "No mmlquery definition for symbol %S" anch))
    (find-file afile)
    (goto-char defpos)
    (if push
	(progn
;; Forget the forward part of history
;; This delees the mmlquery-history-position too
	  (if (<= 0 mmlquery-history-position)
	      (ring-delete-from mmlquery-history 
				mmlquery-history-position))
;; Fix the previous position too - we deleted it above
	  (ring-insert mmlquery-history (list oldbuf oldfile oldpos))
	  (ring-insert mmlquery-history 
		       (list (current-buffer) afile defpos))
	  (setq mmlquery-history-position 0)))
    anch))


(defun mmlquery-goto-history-pos (history-pos)
"Go to the history position HISTORY-POS, trying to re-open the file
if killed in the meantime. Error if it is in temporary buffer,
which was killed."
(if (buffer-live-p (car history-pos))
    (switch-to-buffer (car history-pos))
  (if (cadr history-pos)
      (find-file (cadr history-pos))
    (error "Cannot go back, the temporary buffer was deleted.")))
(goto-char (third history-pos)))


(defun mmlquery-previous ()
  "Go back to the previous mmlquery definiition visited
before `mmlquery-history-position', and change this variable.
If `mmlquery-history-position' is 0, i.e. we just start using
the history, add the current position into `mmlquery-history', 
to be able to return here with `mmlquery-next'."
  (interactive)
;; Initialy the ring-length is 0 and mmlquery-history-position is -1
  (if (<= (ring-length mmlquery-history) (+ 1 mmlquery-history-position))
      (message "No previous definitions visited.")

    (incf mmlquery-history-position)
    (mmlquery-goto-history-pos (ring-ref mmlquery-history 
					 mmlquery-history-position))))

(defun mmlquery-next ()
  "Go forward to the next mmlquery definiition visited
before `mmlquery-history-position', and change this variable."
  (interactive)
;; Initialy the ring-length is 0 and mmlquery-history-position is -1
  (if (<= mmlquery-history-position 0)
      (message "No next definitions visited.")
    (decf mmlquery-history-position)
    (mmlquery-goto-history-pos (ring-ref mmlquery-history 
					 mmlquery-history-position))))

(defvar mmlquery-default-hidden-kinds
  (list 'mmlquery-def 'mmlquery-dfs 'mmlquery-property)
  "List of item kinds that get hidden upon loading of 
mmlquery abstracts.")

(defun mmlquery-default-invisibility ()
(dolist (sym mmlquery-default-hidden-kinds)
  (add-to-invisibility-spec sym)))



;; Borrowed from lazy-lock.el.
;; We use this to preserve or protect things when modifying text properties.
(defmacro save-buffer-state (varlist &rest body)
  "Bind variables according to VARLIST and eval BODY restoring buffer state."
  `(let* ,(append varlist
		  '((modified (buffer-modified-p)) (buffer-undo-list t)
		    (inhibit-read-only t) (inhibit-point-motion-hooks t)
		    (inhibit-modification-hooks t)
		    deactivate-mark buffer-file-name buffer-file-truename))
     ,@body
     (when (and (not modified) (buffer-modified-p))
       (set-buffer-modified-p nil))))


(defun mmlquery-underline-highlited (start)
"Add 'underline to 'highlite."
(save-buffer-state nil
(save-excursion
  (goto-char start)
  (while (not (eobp))
    (let ((mfprop (get-text-property (point) 'mouse-face))
	  (next-change
	   (or (next-single-property-change (point) 'mouse-face 
					    (current-buffer))
	       (point-max))))
      (if (eq mfprop 'highlight)
	  (put-text-property (point) next-change 'face 'underline))
      (goto-char next-change))))))

(defun mmlquery-underline-in-region (beg end)
  (mmlquery-underline-highlited beg))


(defun mmlquery-toggle-hiding (sym)
(if (memq sym buffer-invisibility-spec)
    (remove-from-invisibility-spec sym)
  (add-to-invisibility-spec sym))
(redraw-frame (selected-frame))   ; Seems needed
)

(defun mmlquery-toggle-dfs () (interactive) (mmlquery-toggle-hiding 'mmlquery-dfs))
(defun mmlquery-toggle-def () (interactive) (mmlquery-toggle-hiding 'mmlquery-def))

(defun mmlquery-toggle-property-invis (&optional pos force)
"Toggle hiding of the property formula at POS.
Non-nil FORCE can be either 'hide or 'unhide, and then this
function is used to force the hiding state."
  (interactive)
  (save-buffer-state nil
  (let* ((pos (or pos (point)))
	 (propval (get-text-property pos 'mmlquery-property))
	 next-change start invis)
    (or propval (error "No MMLQuery expression at point!"))
    (setq next-change
	  (or (next-single-property-change pos 'mmlquery-property (current-buffer))
	      (point-max)))
    (or (get-text-property (- next-change 1)  'mmlquery-property-fla)
	(error "No property formula available for this property!"))
    (setq start (next-single-property-change pos 'mmlquery-property-fla 
					     (current-buffer) next-change))
    (setq invis (get-text-property start 'invisible))
    (if  (memq 'mmlquery-property invis)
	(setq invis (delq 'mmlquery-property invis))
      (setq invis (cons 'mmlquery-property invis)))
    (put-text-property start  next-change 'invisible invis))))

(defun mmlquery-toggle-property-invis-mouse (event)
"Toggle hiding of the property formula we clicked on."
  (interactive "e")
  (select-window (event-window event))
  (mmlquery-toggle-property-invis (event-point event)))


(defvar mmlquery-properties-hidden t
"Tells the property hiding for mmlquery abstracts. Is buffer-local there.")

(defun mmlquery-toggle-property-hiding ()
"Force all property formulas to be either hidden or not,
according to current value of the flag `mmlquery-properties-hidden'.
Toggle the flag afterwards."
(interactive)
(save-buffer-state nil
(save-excursion
  (setq mmlquery-properties-hidden (not mmlquery-properties-hidden))
  (goto-char (point-min))
  (while (not (eobp))
    (let ((mfprop (get-text-property (point) 'mmlquery-property-fla))
	  (next-change
	   (or (next-single-property-change (point) 'mmlquery-property-fla 
					    (current-buffer))
	       (point-max))))
      (if mfprop
	  (let (doit (invis (get-text-property (point) 'invisible)))
	    (if mmlquery-properties-hidden
		(if (not (memq 'mmlquery-property invis))
		    (setq invis (cons 'mmlquery-property invis) doit t))
	      (if (memq 'mmlquery-property invis)	      
		  (setq invis (delq 'mmlquery-property invis) doit t)))
	    (if doit (put-text-property (point) next-change 'invisible invis))))
      (goto-char next-change))))))


(defun mmlquery-find-abstract ()
"Start the Emacs MMLQuery browser for given article."
(interactive)
(or (file-directory-p mmlquery-abstracts)
    (error "MMLQuery abstracts not available, put them into %s, or change the variable 'mmlquery-abstracts!" mmlquery-abstracts))
(let ((olddir default-directory)
      (oldbuf (current-buffer)))
  (unwind-protect
      (progn 
	(cd mmlquery-abstracts)
	(call-interactively 'find-file))
    (set-buffer oldbuf)
    (cd olddir))))

;;;;;;;;;;;;;;;;;;;;; MoMM ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Caution, this version of mizar.el is transitory. I have
;; ported the Constr. Explanations to Mizar 6.2. here, but MoMM 0.2
;; is still based on Mizar 6.1, so in case you have Mizar 6.2, MoMM
;; will not work. I hope to port MoMM to Mizar 6.2. shortly. If you
;; want to use it in the meantime, use Mizar 6.1. and previous
;; version of mizar.el .

(defvar mizar-use-momm nil
"*If t, errors *4 are clickable, trying to get MoMM's hints.
MoMM should be installed for this.")


(defvar mizar-momm-compressed t
"*If t, the distribution files (except from the typ directory)
are gzipped to save space")

(defvar mizar-momm-max-start-time 20
"How long we wait for the MoMM process to start to exist;
loading can take longer, we just need the process")

(defvar mizar-momm-load-tptp t
"*If t, the simple justification clause bases are loaded into MoMM too.")

(defconst mizar-fname-regexp  "[A-Za-z0-9_]+"
"Allowed characters for mizar filenames.")

(defvar mizar-momm-dir (substitute-in-file-name
		       "$MIZFILES/MoMM/")
"*Directory containing the MoMM distribution.")
(defvar mizar-mommths (concat mizar-momm-dir "ths/")
  "Directory with articles' .ths files.")
(defvar mizar-mommtyp (concat mizar-momm-dir "typ/")
  "Directory with articles' .typ files.")
(defvar mizar-mommtptp (concat mizar-momm-dir "tptp/")
  "Directory with articles' .tptp files.")
(defvar mizar-mommall-tt (concat mizar-momm-dir "all.typ")
  "Complete type table to be loaded into MoMM.")
(defvar mizar-mommall-db (concat mizar-momm-dir "all.ths")
  "The MoMM database to load.
The .tb and .cb extensions will be appended to get
the termbank and clausebank.")
(defvar mizar-momm-binary (concat mizar-momm-dir "MoMM")
  "Path to the MoMM binary.")
(defvar mizar-momm-verifier (concat mizar-momm-dir "tptpver")
  "The verifier used for creating tptp problems.
They can be later sent to MoMM from unsuccessful simple justifications")
(defvar mizar-momm-exporter (concat mizar-momm-dir "tptpexp")
  "The exporter used for creating tptp problems form articles.
To be loaded into MoMM on  startup.")
(defvar mizar-relcprem (concat mizar-momm-dir "relcprem")
  "*The detector of irrelevant local constants, necessary for MoMM exporter.")

(defvar mizar-momm-rant "Please process clauses now, I beg you, great shining CSSCPA, wonder of the world, most beautiful program ever written.
"
  "The rant sequence to overcome CLIB input buffering.")

(defvar mizar-momm-finished (concat mizar-momm-rant " state: "
				    mizar-momm-rant)
  "The sequence to send at the end of innitial data.
Used to get the 'loaded' response from MoMM.")

(defvar mizar-momm-accept-output t
"Used to suppress output during MoMM loading.")

(defvar mizar-momm-verbosity 'translate
"Possible values are now 'raw, 'translate.")


(defun mizar-toggle-momm ()
"Check that MoMM is installed first."
(interactive)
(if (and (not mizar-use-momm)
	 (not (file-executable-p mizar-momm-verifier)))
    (error "MoMM is not installed!"))
(setq mizar-use-momm (not mizar-use-momm)))

(defvar mizar-momm-err-map
  (let ((map (make-sparse-keymap))
	(button_kword (if (eq mizar-emacs 'xemacs) [(shift button3)]
			[(shift down-mouse-3)])))
    (set-keymap-parent map mizar-mode-map)
    (define-key map button_kword 'mizar-ask-momm)
    map)
"Keymap used at MoMM-sendable errors.")


(defconst directivenbr 8
"Tells how many kinds of directive there are (in .evl), see env_han.pas."
)
; Following is order of directives in .evl, see env_han.pas
(defconst voc-dir-order 0)
(defconst not-dir-order 1)
(defconst def-dir-order 2)
(defconst the-dir-order 3)
(defconst sch-dir-order 4)
(defconst clu-dir-order 5)
(defconst con-dir-order 6)
(defconst req-dir-order 7)

(defvar evl-table nil "The table of environment directives.")
(defvar evl-table-date -1
"Set to last accommodation date, after creating the table.
Used to keep tables up-to-date.")

(make-variable-buffer-local 'evl-table)
(make-variable-buffer-local 'evl-table-date)


(defun get-directive (directives start count )
"DIRECTIVES is a  list created from .evl.
Get COUNT of them beginning at the START position."
  (let ((counter 0) (result ()))
    (while (< counter count)
      (setq result (append result (list (elt directives (+ start (* 2 counter))))))
      (setq counter (+ counter 1)))
    result))


(defun get-evl (aname)
"Return a `directivenbr'-long list of directives for the article ANAME.
Created from its .evl file."
(let ((evlname (concat aname ".evl")))
  (or (file-readable-p evlname)
	(error "File unreadable: %s, run accommodator first" evlname))
  (let ((evldate (cadr (nth 5 (file-attributes evlname)))))
    (if (/= evl-table-date evldate)
	(let ((decl (with-temp-buffer
		      (insert-file-contents evlname)
		      (split-string (buffer-string) "[\n]")))
	      (d ()) (i 0) (start 0) (count 0))
	  (while  (< i directivenbr)
	    (setq count (string-to-number (elt decl start)))
	    (setq d (append d (list (get-directive
				     decl (+ start 1) count))))
	    (setq start (+ start 1 (* 2 count)))
	    (setq i (+ 1 i)))
	  (setq  evl-table-date evldate
		 evl-table d)))
    evl-table)))

(defun get-theorem-dir (aname)
"Return list of theorem directives for ANAME."
  (elt (get-evl aname) the-dir-order))

(defun get-all-dirs (aname)
"Return list of all names occurring in some directive for ANAME."
(let ((d (get-evl aname))
      res (i 0))
  (while  (< i directivenbr)
    (setq res (append (elt d i) res)
	  i   (+ 1 i)))
  (unique res)))

(defun get-all-dirs-rec (aname)
"Return list of all names occurring in some directive for ANAME,
plus transitive hull of constructors."
(get-sgl-table aname)
(unique (append cstrnames (get-all-dirs aname))))

(defun mizar-get-momm-input (aname pos)
"Search file ANAME.tptp for problems generated for given POS.
Return list of them."
(let* ((problems (concat aname ".tptp"))
       (linestr (number-to-string (car pos)))
       (colstr (number-to-string (cadr pos)))
       (searchstr (concat "^ninscheck: pos(" mizar-fname-regexp
			  ", 0, 0, " linestr ", " colstr ", .*"))
       res b e)
  (or (file-readable-p problems)
      (error "File %s not readable, run tptpver first!"))
  (with-temp-buffer
    (insert-file-contents problems)
    (goto-char (point-min))
    (while (re-search-forward searchstr (point-max) t)
      (setq b (match-beginning 0))
      (setq e (search-forward "." (point-max))) ; error if not found
      (setq res (cons (buffer-substring-no-properties b e) res))))
  (nreverse res)))

(defun mizar-ask-momm (event)
  "Ask MoMM for hints on an error at click EVENT.
The results are put into the buffer *MoMM's Hints*."
  (interactive "e")
  (select-window (event-window event))
  (save-excursion
    (let ((mommpr (get-process "MoMM"))
	  (pos (get-text-property (event-point event) 'pos)))
      (if (not mommpr) (error "Start MoMM first!"))
      (if (not pos) (error "No semantic error here, perhaps you did not run tptpver?"))
      (let ((in (mizar-get-momm-input
		 (file-name-sans-extension
		  (file-name-nondirectory (buffer-file-name)))
		 pos))
	    (cbuf (get-buffer-create "*MoMM's Hints*")))
	(if (not in)
	    (error "No data for MoMM found, use the right verifier!"))
	(set-buffer cbuf)
	(erase-buffer)
	(setq mizar-momm-accept-output t)
	(while in
	  (process-send-string mommpr (car in))
	  (process-send-string mommpr " ")
	  (process-send-string mommpr mizar-momm-rant)
	  (accept-process-output mommpr 2)
	  (setq in (cdr in)))
	(process-send-string mommpr mizar-momm-rant)
	(switch-to-buffer-other-window cbuf)
	(goto-char (event-point event))))))


(defun mizar-momm-hints-filter (res)
"Put the hints RES in buffer *MoMM's Hints* if `mizar-momm-accept-output'nonil.
Used to get rid of the output while MoMM loading."
(if (not mizar-momm-accept-output)
    (let ((l (length res)) (i 0))
      (while (< i l)
	(if (eq (aref res i) 35)      ; 35 = # - now serves as loaded-info
	    (setq mizar-momm-accept-output t
		  i l)
	  (setq i (+ 1 i))))))
(if mizar-momm-accept-output
    (let ((cbuf (get-buffer-create "*MoMM's Hints*")))
      (set-buffer cbuf)
      (cond
       ((string-match "^# CSSCPAState" res)  ; now serves as loaded-info
	(insert "MoMM loaded
")
	(message " ... MoMM loaded"))
       ((eq 'raw mizar-momm-verbosity)
	(insert res))
       ((string-match "^1" res)
	(insert "Tautology
"))
       ((string-match "^2" res)
	(insert "No match
"))
       ((string-match "^0" res)
	(insert "Unhandled by MoMM yet
"))
       ((string-match "^pos[(] *\\([^,]+\\), *\\([^,]+\\), *\\([^,]+\\), *\\([^,]+\\), *\\([^,]+\\)" res)
	(let ((type (match-string 2 res)))
	  (cond
	   ((string-equal "1" type)
	    (insert (concat (upcase (match-string 1 res))
			    ":" (match-string 3 res) "
")))
	   ((or (string-equal "2" type)    ; normal def theorem
		(string-equal "3" type)    ; func property
		(string-equal "4" type))   ; pred property
	    (insert (concat (upcase (match-string 1 res))
			    ":def " (match-string 3 res) "
")))
	   (t (insert (concat (match-string 0 res) ")
")))))))
       
      
;  (mizar-highlight-constrs)
;  (use-local-map mizar-cstr-map)
;  (goto-char (point-min))
;  (switch-to-buffer-other-window cbuf)))
)))

(defun mizar-momm-process-filter (proc str)
(mizar-momm-hints-filter str))

(defun mizar-run-momm1 (typetables tlist &optional tb raw filter)
"Start momm  interactively in background.
If multiple TYPETABLES, they have to be appended into temporary file here.
TLIST is the list of files to load, TB is optional termbank.
If RAW is non-nil, process filter FILTER is used if given, otherwise none."
(interactive)
(if (get-process "MoMM") (kill-process "MoMM"))
(if (get-buffer "*MoMM*") (kill-buffer "*MoMM*"))
(sit-for 1)
(let* ((tt (cond
	    ((cdr typetables)     ; have to create tmp
	     (let ((t (make-temp-name
		       (concat default-directory "tmptt")))
		 (t1 typetables))
	       (with-temp-file t
		 (while t1
		   (insert-file-contents (car t))
		  (setq t1 (cdr t1))))
	       t))
	    (typetables (car typetables))
	    (t nil)))
       (args tlist) compr (i 0))
  (if mizar-momm-compressed
      (while args
	(if (equal (file-name-extension (car args)) "gz")
	    (setq compr (cons (car args) compr)
		  tlist (delete (car args) tlist)))
	(setq args (cdr args))))
  (setq mizar-momm-accept-output nil)
  (cond
   (compr
    (setq compr (concat "(gzip -dc "
			(mapconcat 'identity compr " ")
			"; cat)| ")
	  args (concat compr mizar-momm-binary " -s "
		       (if tt (concat " -y " tt " ") "")
		       (if tb (concat " -b " tb " ") "")
		       (if tlist (mapconcat 'identity tlist " ")
			 "")))
    (start-process-shell-command "MoMM" "*MoMM*" args))
   (t
    (setq args (append (list "MoMM" "*MoMM*" mizar-momm-binary "-s")
		       (if tt (list "-y" tt))
		       (if tb (list "-b" tb))
		       tlist (list "-")))
;  (apply 'make-comint args)
    (apply 'start-process args)))

  (while (and (not (get-process "MoMM"))
	      (< i mizar-momm-max-start-time))
    (sit-for 1)
    (setq i (+ 1 i)))
  (or (get-process "MoMM")
      (error "MoMM not started, try increasing mizar-momm-max-start-time"))
  (if raw
      (set-process-filter (get-process "MoMM") filter)
    (set-process-filter (get-process "MoMM")
			'mizar-momm-process-filter))
  (process-send-string (get-process "MoMM")
		       mizar-momm-finished)
  (if (cdr typetables)
      (message "Temporary typetable %s created" tt))
  (message "Loading MoMM data...")
))

(defun verify-file-readable (f)
  (or (file-readable-p f)
      (error "File %s not readable" f)))

(defun mizar-momm-get-default-files (aname &optional thsdirs tptp)
"Get default files for running MoMM for article ANAME.
Pair (not found, absolute names) is returned.
If THSDIRS is given, use instead of default.
TPTP tells to use tptp files too."
(let* ((args (if thsdirs (copy-alist (get-theorem-dir aname))
	       (get-all-dirs-rec aname)))
       res no f f1)
  (while args
    (setq f (concat mizar-mommths
		    (downcase (car args))
		    (if mizar-momm-compressed ".ths.cb.gz" ".ths.cb"))
	  f1 (concat mizar-mommtptp
		     (downcase (car args))
		     (if mizar-momm-compressed ".tptp.cb.gz"
		       ".tptp.cb")))
    (if (file-readable-p f) (setq res (cons f res))
      (setq no (cons f no)))
    (if tptp
	(if (file-readable-p f1)
	    (setq res (cons f1 res))
	  (setq no (cons f1 no))))
    (setq args (cdr args)))
  (list no (nreverse res))
))

(defun mizar-run-momm ()
"Get type, clause and termbank files for running MoMM and run it.
Default process filter is used.  Verify that the default argument
files exist first."
(interactive)
(let* ((aname (file-name-sans-extension
	       (file-name-nondirectory (buffer-file-name))))
       (args (cadr (mizar-momm-get-default-files aname nil
						 mizar-momm-load-tptp)))
       tt tb)
  (setq args (mapconcat 'identity args " "))
  (setq tts (split-string
	    (read-string  "Typetable(s): " mizar-mommall-tt)
	    "[, \f\t\n\r\v]+")
	args (split-string
	      (read-string  "Clause file(s): " args)
	      "[, \f\t\n\r\v]+")
	tb  (let ((s (read-string
		      "Termbank (Default: none): ")))
		(if (string-equal "" s) nil s)))
;  (mapcar 'verify-file-readable tts)
;  (mapcar 'verify-file-readable args)
;  (if tb (verify-file-readable tb))
  (mizar-run-momm1 tts args tb)))



(defun mizar-run-momm-default (&optional aname thsdirs tptp)
"Run MoMM for article ANAME.
Load theorems from all its directive filenames.
If THSDIRS is non-nil, use the theorem directive only.
Complete typetable is loaded, which makes later on demand
loading with `mizar-momm-add-files' possible.
Use TPTP to load the tptp files (non-theorem information) too."
(interactive)
(let* ((aname (or aname
		  (file-name-sans-extension
		   (file-name-nondirectory (buffer-file-name)))))
       (res (mizar-momm-get-default-files aname thsdirs tptp)))
  (mizar-run-momm1 (list mizar-mommall-tt) (cadr res))))


(defun mizar-run-momm-full ()
"Fast load MoMM with the full theorems db.
This takes about 120M in MoMM 0.2."
(interactive)
(mizar-run-momm1 (list mizar-mommall-tt)
		 (list (concat mizar-mommall-db ".cb"))
		 (concat mizar-mommall-db ".tb")))

(defun mizar-momm-get-file (f dir ext)
"Find the momm file F, possibly in DIR and with extension EXT."
(cond
 ((file-readable-p f) f)
 ((file-readable-p (concat f ext)) (concat f ext))
 ((file-readable-p (concat f ext ".cb")) (concat f ext ".cb"))
 ((and mizar-momm-compressed
       (file-readable-p (concat f ext ".cb.gz")))
  (concat f ext ".cb.gz"))
 ((file-readable-p (concat dir f)) (concat dir f))
 ((file-readable-p (concat dir f ext)) (concat dir f ext))
 ((file-readable-p (concat dir f ext ".cb")) (concat dir f ext ".cb"))
 ((and mizar-momm-compressed
       (file-readable-p (concat dir f ext ".cb.gz")))
  (concat dir f ext ".cb.gz"))
 (t nil)))

(defun mizar-momm-add-files (tlist &optional tptp)
"Add ths files from TLIST into running MoMM.
The type-table must be loaded on start,
e.g. by running MoMM with all.typ.
If TPTP, load tptp files too.  Current directory is searched first,
then the MoMM db."
(interactive "sarticles: ")
(let ((mommpr (get-process "MoMM"))
      (tptp (or tptp mizar-momm-load-tptp))
      (i 0))
  (if (not mommpr) (error "Start MoMM first!"))
  (if (stringp tlist)
      (setq tlist (split-string tlist "[(), \f\t\n\r\v]+")))
  (setq mizar-momm-accept-output nil)
  (while tlist
    (let ((f (mizar-momm-get-file (car tlist) mizar-mommths ".ths"))
	  (f1 (if tptp
		  (mizar-momm-get-file  (car tlist)
					mizar-mommtptp ".tptp"))))
      (if f
	  (with-temp-buffer
	    (if (and mizar-momm-compressed
		     (equal (file-name-extension f) "gz"))
		(let ((excode (call-process "gzip" f t nil "-dc"))
		   (if (or (stringpp excode) (/= 0 excode))
		       (error "Error in decompressing %s" f))))
	      (insert-file-contents f))
	    (process-send-string mommpr (buffer-string))
	    (setq i (+ 1 i))))
      (if (and f1 (not (equal f f1)))
	  (with-temp-buffer
	    (if (and mizar-momm-compressed
		     (equal (file-name-extension f1) "gz"))
		(let ((excode (call-process "gzip" f1 t nil "-dc"))
		   (if (or (stringpp excode) (/= 0 excode))
		       (error "Error in decompressing %s" f1))))
	      (insert-file-contents f1))
	    (process-send-string mommpr (buffer-string))
	    (setq i (+ 1 i))))
      (setq tlist (cdr tlist))))
  (message "Loading %d files ..." i)
  (process-send-string mommpr mizar-momm-finished)
))

(defun mizar-pos-at-point ()
  "Return the momm position at the point."
  (save-excursion
    (skip-chars-backward "^ \t\n,;")
    (if (looking-at "pos[(] *\\([^,]+\\), *\\([^,]+\\), *\\([^,]+\\), *\\([^,]+\\), *\\([^,]+\\)")
	(let ((article (match-string 1))
	      (line    (string-to-number (match-string 4)))
	      (col     (string-to-number (match-string 5))))
	  (list article line col)))))
      
(defun mizar-momm-find-pos ()
  "Find the position at point in other window."
(interactive)
(let ((pos (mizar-pos-at-point)))
  (if pos
      (let ((line (cadr pos))
	    (col  (car (last pos)))
	    (f (concat  mizar-mml "/" (car pos) ".miz")))
	(save-excursion
	  (find-file-other-window f)
	  (set-buffer (get-file-buffer f))
	  (goto-line line)
	  (move-to-column (- col 1))))
  (message "No position at point"))))

;;;;;;;;;;;;;;;;;;;;; Mizar TWiki  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar mizar-twiki-url "http://alioth.uwb.edu.pl/twiki/bin/view/Mizar/")
(defvar mizar-twiki-questions (concat mizar-twiki-url "MizarQuestion"))
(defvar mizar-twiki-features (concat mizar-twiki-url "FeatureBrainstorming"))
(defvar mizar-twiki-language (concat mizar-twiki-url "MizarLanguage"))
(defvar mizar-twiki-pitfalls (concat mizar-twiki-url "MizarPitfall"))
(defvar mizar-twiki-faq (concat mizar-twiki-url "MizarFAQ"))
(defvar mizar-twiki-bugs (concat mizar-twiki-url "BugReport"))
(defvar mizar-twiki-mml-sugg (concat mizar-twiki-url "MmlSuggestion"))

(defun mizar-error-at-point ()
  (let ((cw (current-word)))
    (if (string-match "[^0-9]*\\([0-9]+\\)\\b" cw)
	(match-string 1 cw)
      "")))

(defun mizar-twiki-comment-error (&optional errstr)
"Add a comment to the Mizar Twiki description of an error message."
(interactive)
(let ((errstr
       (or errstr
	   (read-string  (concat "ErrorCode to comment on: (Default: "
				 (mizar-error-at-point) "): " )
			 nil nil      (mizar-error-at-point)))))
  (browse-url (concat mizar-twiki-url "ErrorNo" errstr))))

;;;;;;;;;;;;;;;  abbrevs for article references ;;;;;;;;;;;;
(defun mizar-th-abbrevs (&optional aname)
(interactive)
(let ((aname (or aname
		(file-name-nondirectory
		 (file-name-sans-extension
		  (buffer-file-name))))))
  (setq aname (upcase aname))
(save-excursion
  (goto-char (point-min))
  (let (pos0 pos1 comm (thnr 0) pairs)
  (while (re-search-forward "[ \n\r\t]\\(theorem\\)[ \n\r\t]+" (point-max) t)
    (setq pos1 (point)
	  pos0 (match-end 1))
    (goto-char pos0)
    (beginning-of-line)
    (setq comm (search-forward comment-start pos0 t))
    (if comm  (beginning-of-line 2)  ;; inside comment, skip
      (setq thnr (+ thnr 1))
      (goto-char pos1)               ;; label  or not
      (if (looking-at "\\([a-zA-Z0-9_']+\\):")
	  (define-abbrev mizar-mode-abbrev-table
	    (downcase (match-string 1))
	    (concat aname ":" (number-to-string thnr))))
;	  (setq pairs (cons (cons (match-string 1) thnr) pairs)))))
  ))))))

(defun mizar-defs-abbrevs (&optional aname)
(interactive)
(let ((aname (or aname
		(file-name-nondirectory
		 (file-name-sans-extension
		  (buffer-file-name))))))
  (setq aname (upcase aname))
(save-excursion
  (goto-char (point-min))
  (let (pos0 pos1 comm (defnr 0) defname)
  (while (re-search-forward "[ \n\r\t]:\\([a-zA-Z0-9_']+\\):[ \n\r\t]" (point-max) t)
    (setq pos0 (match-end 1)
	  defname (match-string 1))
    (goto-char pos0)
    (beginning-of-line)
    (setq comm (search-forward comment-start pos0 t))
    (if comm  (beginning-of-line 2)  ;; inside comment, skip
      (setq defnr (+ defnr 1))
      (goto-char pos0)               ;; label  or not
      (define-abbrev mizar-mode-abbrev-table
	(downcase defname)
	(concat aname ":def " (number-to-string defnr))))
  )))))

;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; viewing constructor explanation of imported theorems and defs
(defvar theorem-table nil "Table of theorems for the article.")
(defvar theorem-directives nil "List of then directives parsed from thl.")
(defvar theorem-table-date -1
"As constr-table-date.")

(make-variable-buffer-local 'theorem-table)
(make-variable-buffer-local 'theorem-table-date)
(make-variable-buffer-local 'theorem-directives)


(defun parse-theorems (aname &optional reload)
"Load theorem-table and theorem-directives for ANAME.
Files .thl and .eth are used, RELOAD does it unconditionally."
(let ((thldate (cadr (nth 5 (file-attributes (concat aname ".thl"))))))
  (if (or reload (/= theorem-table-date thldate))
      (let (directives table)
      (with-temp-buffer
	(insert-file-contents (concat aname ".thl"))
	(let* ((all (split-string (buffer-string) "[\n]"))
	       (count (string-to-number (car all)))
	       (i 0))
	  (setq table (make-vector (* 2 count) 0)) ; just hash redundancy
	  (setq all (cdr all))
	  (while (< i count)
	    (let* ((symb (intern (car all) table))
		   (nrs (split-string (cadr all)))
		   (thvec (make-vector (string-to-number (car nrs))
				       nil))
		   (dfvec (make-vector (string-to-number (cadr nrs))
				       nil)))
	      (put symb 'ths thvec)
	      (put symb 'defs dfvec)
	      (setq directives (cons (car all) directives))
	      (setq i (+ 1 i))
	      (setq all (cddr all))))
	  (setq directives (nreverse directives)))
      (with-temp-buffer
	(insert-file-contents (concat aname ".eth"))
	(let* ((all (split-string (buffer-string) "[\n]"))
	       (count (string-to-number (car all)))
	       (dirs directives)
	       (i 0))
	  (setq all (cdr all))
	  (while (< i count)
	    (let* ((tcount (string-to-number (car all)))
		   (dcount 0)
		   (symb (intern-soft (car dirs) table))
		   (thvec (get symb 'ths ))
		   (dfvec (get symb 'defs))
		   (tnr 0) (dnr 0))
	      (setq all (cdr all))
	      (while (< tnr tcount)
		(aset thvec tnr (car all))
		(setq tnr (+ 1 tnr)
		      all (cddr all)))
	      (setq dcount (string-to-number (car all)))
	      (setq all (cdr all))
	      (while (< dnr dcount)
		(aset dfvec dnr (car all))
		(setq dnr (+ 1 dnr)
		      all (cddr all))))
	    (setq i (+ i 1)
		  all (cdr all)
		  dirs (cdr dirs))))))
      (setq theorem-table table
	    theorem-directives directives
	    theorem-table-date thldate)))
  theorem-table))

(defun mizar-ref-constrs (article nr &optional def table)
  "Constrs of the reference, if no table, use the buffer-local theorem-table."
  (let* ((aname (file-name-nondirectory
		(file-name-sans-extension
		 (buffer-file-name))))
	 (ltable (or table (parse-theorems aname)))
	 (symb (intern-soft article ltable))
	 (what (if def 'defs 'ths))
	 arr res)
    (if (not symb) (error "Article %s not in theorem directives" article))
    (setq arr (get symb what))
    (if (< (length arr) nr)
	(error "Maximum for article %s is %d" article (length arr)))
    (get-sgl-table aname)           ;; ensure up-to-date
;    (parse-cluster-table aname)     ;; ensure up-to-date
    (setq res (copy-sequence (aref arr (- nr 1))))
    (cond ((eq mizar-expl-kind 'raw) res)
	  ((eq mizar-expl-kind 'expanded) (fix-pre-type res))
	  ((eq mizar-expl-kind 'translate) (expfrmrepr res))
	  ((eq mizar-expl-kind 'constructors)
	   (prin1-to-string (expfrmrepr res t)))
	  ((eq mizar-expl-kind 'sorted)
	   (prin1-to-string (sort (unique (expfrmrepr res t)) 'string<)))
	  (t ""))))

(defun mizar-show-ref-constrs (&optional ref)
"Get the constructors for reference REF (possibly reading from minibuffer).
Show them in the buffer *Constructors List*."
(interactive)
(let ((ref1 (or ref (read-string
		     (concat "Constructor explanation for: ("
			     (mizar-ref-at-point) "): ")
		     nil nil      (mizar-ref-at-point)))))
  (if (string-match "\\([a-z_0-9]+\\):\\(def\\)? *\\([0-9]+\\)" ref1)
      (mizar-intern-constrs-other-window
       (mizar-ref-constrs (match-string 1 ref1)
			  (string-to-number (match-string 3 ref1))
			  (match-string 2 ref1)))
    (error "Bad reference %s" ref1))
  ref1))

(defun mizar-mouse-ref-constrs (event)
"Show the constructors for reference at mouse EVENT."
  (interactive "e")
  (select-window (event-window event))
  (goto-char (event-point event))
  (mizar-show-ref-constrs (mizar-ref-at-point)))





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defconst mizar-error-regexp "\\(\\*\\|::>,\\)\\([0-9]+\\)" "Regexp used to locate error messages in a mizar text.")

(defvar mizar-region-count 0  "Number of regions on mizar-region-stack.")

(defvar mizar-quick-run t 
"*Speeds up verifier by not displaying its intermediate output.
Can be toggled from the menu, however the nil value is no
longer supported and may be deprecated (e.g. on Windows).")

(defvar mizar-quick-run-temp-ext ".out" "Extension of the temp file for quick run.")

(defvar mizar-launch-dir nil
"*If non-nil, verifier and other programs are called from here.
Can be set from menu.
Set this to parent directory, if you use
private vocabulary file residing in ../dict/ , 
otherwise Mizar *will not* find it.")

(defvar mizar-show-output 10
"*Possible values: none, 4, 10, all.
Determines the size of the output window after processing. 
Can be set from menu")

(defvar mizar-goto-error "next"
"*What error to move to after processing.
Possible values are none, first, next, previous.
Can be set from menu")

(defvar mizar-imenu-expr
'(
  ("Structures" "[ \n\r]\\(struct\\b.*\\)" 1)
  ("Modes" "[ \n\r]\\(mode\\b.*\\)" 1)
  ("Attributes" "[ \n\r]\\(attr\\b.*\\)" 1)
  ("Predicates" "[ \n\r]\\(pred\\b.*\\)" 1)
  ("Functors" "[ \n\r]\\(func\\b.*\\)" 1)
  ("Clusters" "[ \n\r]\\(cluster\\b.*\\)" 1)
  ("Schemes" "^[ ]*scheme[ \n\r]+\\([a-zA-Z0-9_']+\\)" 1)
  ("Named Defs" "[ \n\r]\\(:[a-zA-Z0-9_']+:\\)[ \n\r]" 1)
  ("Named Theorems" "^[ ]*theorem[ \n\r]+\\([a-zA-Z0-9_']+:\\)[ \n\r]" 1)
)
"Mizar imenu expression.")


(defun toggle-quick-run ()
"Toggle the usage of quick-run for verifier, default is on."
(interactive)
(setq mizar-quick-run (not mizar-quick-run)))

(defun mizar-toggle-show-output (what)
"Set the size of the *mizar-output* window to WHAT.
See the documentation for the variable `mizar-show-output'."
(interactive)
(setq mizar-show-output what))

(defun mizar-toggle-goto-error (where)
"Set the error movement behavior after verifying to WHERE.
See the documentation for the variable `mizar-goto-error'."
(interactive)
(setq mizar-goto-error where))

(defun mizar-set-launch-dir ()
"Set the directory, where the verifier is launched.
This must be set to parent directory, if you use
private vocabulary file residing in ../dict/ ."
(interactive)
(let ((ld (or mizar-launch-dir "none"))
      pdefault default dir)
  (if mizar-launch-dir
      (setq pdefault "none" default "")
    (setq pdefault  (file-name-directory (directory-file-name
                       (file-name-directory (buffer-file-name))))
	  default pdefault))
  (setq dir (read-string  (concat "current launch dir: " ld
				  ", set to (Default: "
				  pdefault "): " )
			  nil nil  default))
  (mizar-set-ld dir)))
  
  
(defun mizar-set-ld (dir)
(if (or (equal "" dir) (not dir))
    (setq mizar-launch-dir nil)
  (if (file-accessible-directory-p dir)
      (setq mizar-launch-dir dir)
    (error (concat "Directory not accessible: " dir)))))



(defun make-theorem-summary ()
  "Make a summary of theorems in the buffer *Theorem-Summary*.
Previous contents of that buffer are killed first.
The command `hs-hide-all', accessible from the Hide/Show menu, 
can be used instead, to make a summary of an article."
  (interactive)
  (message "Making theorem summary...")
  ;; This puts a description of bindings in a buffer called *Help*.
  (setq result (make-theorems-string))
  (with-output-to-temp-buffer "*Theorem-Summary*"
    (save-excursion
      (let ((cur-mode "mizar"))
	(set-buffer standard-output)
	(mizar-mode)
	(erase-buffer)
	(insert result))
      (goto-char (point-min))))
  (message "Making theorem summary...done"))

(defun mizar-occur-refs ()
  (interactive)
  (occur "[ \\n\\r]by[ \\n\\r].*:"))



;;;;;;;;;;;;;;;; Running Mizar ;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun mizar-new-term-output (&optional force)
"Prepare output buffer if it was destroyed by quick-run; 
if force is non nil, do it regardless of the value of mizar-quick-run"
(if (or force (not mizar-quick-run))
    (let ((buff (get-buffer "*mizar-output*"))
	  (dir (or mizar-launch-dir default-directory)))
      (if (and  buff
		(not (member '(major-mode . term-mode)
			     (buffer-local-variables buff))))
	  (progn (kill-buffer buff) (setq buff nil)))
      (if (not buff)
	  (save-window-excursion
	    (ansi-term "bash")
	    (rename-buffer "*mizar-output*")))
      (display-buffer "*mizar-output*")
      (save-excursion
	(set-buffer "*mizar-output*")
	(cd  dir))
      (end-of-buffer-other-window 0))))


(defun mizar-compile (&optional util)
"Run verifier (`mizar-it') in a compilation-like way.
This means that the errors are shown and clickable in buffer 
*Compilation*, instead of being put into the editing buffer in
the traditional Mizar way.
If UTIL is given, call it instead of the Mizar verifier."
  (interactive)
  (mizar-it util nil t))

; (defun mizar-compile ()
;   "compile a mizar file in the traditional way"
;   (interactive)
;   (let ((old-dir (mizar-switch-to-ld)))
;     (compile (concat "mizfe " (substring (buffer-file-name) 0 (string-match "\\.miz$" (buffer-file-name)))))
;     (if old-dir (setq default-directory old-dir))))



(defun mizar-handle-output  ()
"Display processing output according to `mizar-show-output'."
(cond ((equal "none" mizar-show-output)
       (delete-other-windows))
      ((integerp mizar-show-output)
       (save-selected-window
; get-buffer-window seems buggy in winemacs
;		   (select-window (get-buffer-window
	 (pop-to-buffer
	  (get-buffer "*mizar-output*"))
	 (goto-char (point-max))
	 (delete-blank-lines)
	 (let ((new-height
		(min mizar-show-output
		     (count-lines (point-min) (point-max)))))
; no sense winemacs behaves strange anyway
;	   (if (fboundp 'set-window-text-height)
;	       (set-window-text-height (get-buffer-window (current-buffer))
;				       new-height)
	   (shrink-window (- (window-height) (+ 1 new-height)))
	   (goto-char (point-max))
	   (forward-line (- new-height))
	   (set-window-start (get-buffer-window (current-buffer)) (point))
	   )))
      (t
       (save-selected-window
	 (pop-to-buffer
	  (get-buffer "*mizar-output*"))))))

(defun mizar-show-errors ()
  "Post processing error explanation."
  (let ((pos (point)))
    (cond ((equal "first" mizar-goto-error)
	   (goto-char (point-min))
	   (if (not (mizar-next-error))
	       (goto-char pos)))
	  ((equal "next" mizar-goto-error)
	   (mizar-next-error))
	  ((equal "previous" mizar-goto-error)
	   (mizar-previous-error))
	  (t pos))))

(defvar makeenv "makeenv" "Program used for creating the article environment.")

(defun mizar-it (&optional util noqr compil)
"Run mizar verifier on the text in the current .miz buffer.
Show the result in buffer *mizar-output*.
If UTIL is given, run it instead of verifier.
If `mizar-use-momm', run tptpver instead.
If NOQR, does not use quick run.
If COMPIL, emulate compilation-like behavior for error messages."
  (interactive)
  (let ((util (or util (if mizar-use-momm mizar-momm-verifier
			 "verifier")))
	(makeenv makeenv))
    (if (eq mizar-emacs 'winemacs)
	(progn
	  (setq util (concat mizfiles util)
		makeenv (concat mizfiles makeenv))))
    (cond ((not (string-match "miz$" (buffer-file-name)))
	   (message "Not in .miz file!!"))
	  ((not (executable-find makeenv))
	   (message (concat makeenv " not found or not executable!!")))
	  ((not (executable-find util))
	   (message (concat util " not found or not executable!!")))
	  (t
	   (let* ((name (file-name-sans-extension (buffer-file-name)))
		  (fname (file-name-nondirectory name))
		  (old-dir (file-name-directory name)))
	     (if mizar-launch-dir (cd mizar-launch-dir))
	     (mizar-strip-errors)
	     (save-buffer)
	     (cond
	      ((and compil (not noqr))
	       (if (get-buffer "*compilation*") ; to have launch-dir
		    (kill-buffer "*compilation*"))
	       (let ((cbuf (get-buffer-create "*compilation*")))
		 (switch-to-buffer-other-window cbuf)
		 (erase-buffer)
		 (insert "Running " util " on " fname " ...\n")
		 (sit-for 0)     ; force redisplay
; call-process can return string (signal-description)
		 (let ((excode (call-process makeenv nil cbuf nil  name)))
		   (if (and (numberp excode) (= 0 excode))
		       (call-process util nil cbuf nil "-q" name)))
		 (other-window 1)))
	     ((and mizar-quick-run (not noqr))
	      (save-excursion
		(message (concat "Running " util " on " fname " ..."))
		(if (get-buffer "*mizar-output*")
		    (kill-buffer "*mizar-output*"))
		(let ((excode  (call-process makeenv nil (get-buffer-create "*mizar-output*") nil name)))
		  (if (and (numberp excode) (= 0 excode))
		      (shell-command (concat util " -q " name)
				     "*mizar-output*")
		    (display-buffer "*mizar-output*")))
		(message " ... done")))
	     (t
	      (let  ((excode (call-process makeenv nil nil nil name)))
		(if (and (numberp excode) (= 0 excode))
		   (progn
		     (mizar-new-term-output noqr)
		     (term-exec "*mizar-output*" util util nil (list name))
		     (while  (term-check-proc "*mizar-output*")
		       (sit-for 1)))))))
	     (if old-dir (setq default-directory old-dir))
	     (if mizar-do-expl
		 (save-excursion
		   (remove-text-properties (point-min) (point-max)
					   '(mouse-face nil expl nil local-map nil))
		   (mizar-put-bys fname)))
	     (if (and compil (not noqr))
		 (save-excursion
		   (set-buffer "*compilation*")
		   (insert (mizar-compile-errors name))
		   (compilation-mode)
		   (goto-char (point-min)))
	       (mizar-do-errors name)
	       (save-buffer)
	       (mizar-handle-output)
	       (mizar-show-errors))
	     )))))


(defun mizar-irrths ()
"Call Irrelevant Theorems & Schemes Detector on the article."
  (interactive)
(mizar-it "irrths"))

(defun mizar-irrvoc ()
"Call Irrelevant vocabulary Detector on the article."
  (interactive)
(mizar-it "irrvoc"))

(defun mizar-inacc ()
"Call Inaccessible Items Detector on the article."
  (interactive)
(mizar-it "inacc"))

(defun mizar-relinfer ()
"Call Irrelevant Inferences Detector on the article."
  (interactive)
(mizar-it "relinfer"))

(defun mizar-relprem ()
"Call Irrelevant Premises Detector on the article."
  (interactive)
(mizar-it "relprem"))

(defun mizar-reliters ()
"Call Irrelevant Iterative Steps Detector on the article."
  (interactive)
(mizar-it "reliters"))

(defun mizar-trivdemo ()
"Call Trivial Proofs Detector on the article."
  (interactive)
(mizar-it "trivdemo"))

(defun mizar-chklab ()
"Call Irrelevant Label Detector on the article."
  (interactive)
(mizar-it "chklab"))




(defun mizar-findvoc ()
  "Find vocabulary for a symbol."
  (interactive)
  (shell-command (concat "findvoc "
			 (read-string  (concat "findvoc [-iswGKLMORUV] SearchString (Default: " (current-word) "): " )
				       nil nil      (current-word))
			 )))

;;;;;;;;;;;; not done yet, seems quite complicated if we have e.g.
;;;;;;;;;;;; reserve A for set reserve F for Function of A,B
; (defun mizar-show-type (&optional whole-exp)
;   "show last type reserved for a variable"
;   (interactive "p")
;   (save-excursion
;     (setq var (read-string  (concat "reserved type of (Default: " (current-word) "): " )
; 				       nil nil      (current-word)))
;     (while
;  	(and
; 	 (re-search-backward "^ *reserve" (point-min) t)
; 	 (setq pos (match-beginning 0))
; 	 (re-search-forward (concat "[, \n]" var "[, \n]") " *\\([;]\\|by\\|proof\\)" (point-max) t))


(defun make-reserve-summary ()
  "Make a summary of all type reservations before current point in the article.
Display it in the buffer *Reservation-Summary* in other window.
Previous contents of that buffer are killed first.
Useful for finding out the exact meaning of variables used in
some Mizar theorem or definition."
  (interactive)
  (message "Making reservation summary...")
  ;; This puts a description of bindings in a buffer called *Help*.
  (setq result (make-reservations-string))
  (with-output-to-temp-buffer "*Reservations-Summary*"
    (save-excursion
      (let ((cur-mode "mizar"))
	(set-buffer standard-output)
	(mizar-mode)
	(erase-buffer)
	(insert result))
      (goto-char (point-min))))
  (message "Making reservations summary...done"))



			 

(defun mizar-listvoc ()
  "List vocabulary."
  (interactive)
  (shell-command (concat "listvoc "
			 (read-string  (concat "listvoc  VocNames (Default: " (current-word) "): " )
				       nil nil      (current-word))
			 )))

(defun mizar-constr ()
"Show required constructors files.
Constructor files needed for Mizar theorems, definitions, 
schemes or complete articles can be queried."
  (interactive)
  (shell-command (concat "constr "
			 (read-string  (concat "constr [-f FileName] Article:[def|sch|...] Number (Default: " (mizar-ref-at-point) "): " )
				       nil nil      (mizar-ref-at-point))
			 )))

(defvar mizar-error-start "^::>")
(defvar mizar-error-start-length 3)

(defun mizar-end-error (result pos oldpos &optional prev)
  "Common end for mizar-next-error and mizar-previous-error."
  (if result
      (let ((find (concat "^::>[ \t]*\\(" result ":.*\\)[ \t]*$")))
	(goto-char (point-max))
	(re-search-backward find (point-min) t)
	(message (match-string 1))
	(goto-char pos))
    (goto-char oldpos)
    (ding)
    (message (concat "No more errors "
		     (if prev "above!!"  "below!!")))
    nil ))

(defun mizar-next-error ()
"Go to the next error in a mizar text, return nil if not found.
Show the error explanation in the minibuffer."
  (interactive)
  (let ((oldpos (point))
	(inerrl nil) ;; tells if we start from an error line
	result pos)
    (beginning-of-line)
    (if (looking-at (concat mizar-error-start "[^:\n]+$"))
	(progn
	  (forward-char mizar-error-start-length)  ;; skip the error start
	  (if (< (point) oldpos)     ;; we were on an error or between
	      (progn
		(goto-char oldpos)
		(if (looking-at "[0-9]+") ;; on error
		    (forward-word 1))))
	  (skip-chars-forward "\t ,*")  ;; now next error or eoln
	  (if (looking-at "[0-9]+")
	    (setq pos (point) result (match-string 0)))))
    (if (and (not result)
	     (re-search-forward (concat mizar-error-start "[^:\n]+$") 
				(point-max) t)) ;; to avoid bottom explanations
	(progn
	  (beginning-of-line)
	  (forward-char mizar-error-start-length)
	  (skip-chars-forward "\t ,*")
	  (if (looking-at "[0-9]+")
	    (setq pos (point) result (match-string 0)))))
    (mizar-end-error result pos oldpos)))

(defun mizar-previous-error ()
"Go to the previous error in a mizar text, return nil if not found.
Show the error explanation in the minibuffer."
  (interactive)
  (let ((oldpos (point))
	(inerrl nil) ;; tells if we start from an error line
	result pos)
    (beginning-of-line)
    (if (looking-at (concat mizar-error-start "[^:\n]+$"))
	(progn
	  (end-of-line)
	  (if (> (point) oldpos)     ;; we were on an error or between
	      (progn
		(goto-char oldpos)
		(if (looking-at "[0-9]+") ;; on error
		    (skip-chars-backward "0-9"))))
	  (skip-chars-backward "\t ,*") ; whitechars
	  (skip-chars-backward "0-9") ; startof err if any
	  (if (looking-at "[0-9]+") ; another on ths line
	      (setq pos (point) result (match-string 0))
	    (beginning-of-line))))  ; nothing else here
    (if (and (not result)
	     (re-search-backward (concat mizar-error-start "[^:\n]+$")  
				 (point-min) t))
	(progn
	  (end-of-line)
	  (forward-word -1)
	  (if (looking-at "[0-9]+")
	    (setq pos (point) result (match-string 0)))))
    (mizar-end-error result pos oldpos t)))
    
(defun mizar-strip-errors ()
  "Delete all error lines added by Mizar.
These are lines beginning with ::>."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "^::>.*\n" nil t)
      (replace-match "" nil nil))
    ))

(defun mizar-hide-proofs (&optional beg end remove)
  "Put @@ before all proof keywords between BEG and END to disable checking.
With prefix (C-u, which sets REMOVE non-nil) remove them 
instead of adding, to enable proof checking again."
  (interactive "r\nP")
  (save-excursion
    (let ((beg (or beg (point-min)))
	  (end (or end (point-max))))
    (goto-char beg)
    (message "(un)hiding proofs ...")
    (if remove
	(while (re-search-forward "@proof\\b" end  t)
	  (replace-match "proof" nil nil))
      (while (re-search-forward "\\bproof\\b" end t)
	(replace-match "@proof" nil nil)))
    (message "... Done")
    )))

(defun mizar-move-then (&optional beg end reverse)
"Change the placement of the 'then' keyword between BEG and END.
With prefix (REVERSE non-nil) move from the end of lines to beginnings,
otherwise from beginnings of lines to ends.
This is a flamewar-resolving hack."
  (interactive "r\nP")
  (save-excursion
    (let ((beg (or beg (point-min)))
	  (end (or end (point-max))))
    (goto-char beg)
    (message "moving then ...")
    (if reverse
	(while (re-search-forward "; *\n\\( *\\)then " end t)
	  (replace-match "; then\n\\1 " nil nil))
      (while (re-search-forward "; *then *[\n]\\( *\\)" end  t)
	(replace-match ";\n\\1then " nil nil)))
    (message "... Done")
    )))



(defun make-theorems-string ()
  "Make string of all theorems."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (setq result "")
    (while
 	(and
	 (re-search-forward "^ *\\(theorem[^s]\\)" (point-max) t)
	 (setq pos (match-beginning 1))
	 (re-search-forward " *\\([;]\\|by\\|proof\\)" (point-max) t))
      (progn
	(setq result1 (buffer-substring-no-properties pos (match-beginning 0)))
	 (if  (string-match "\n$" result1)
	     (setq result (concat result result1 "\n" ))
	   (setq result (concat result result1 "\n\n" )))))
    result))

(defun make-reservations-string ()
  "Make string of all reservations before point."
  (interactive)
  (save-excursion
    (setq maxp (point))
    (goto-char (point-min))
    (setq result "")
    (while
 	(and
	 (re-search-forward "^[ \t]*\\(reserve\\)" maxp t)
	 (setq pos (match-beginning 1))
	 (re-search-forward ";" maxp t))
      (progn
	(setq result1 (buffer-substring-no-properties pos (match-end 0)))
	 (if  (string-match "\n$" result1)
	     (setq result result1 )
	   (setq result (concat result result1 "\n" )))))
    result))

;; Abbrevs
(setq dabbrev-abbrev-skip-leading-regexp "\\(\\sw+\\.\\)+" )

(defvar mizar-mode-abbrev-table nil
  "Abbrev table in use in Mizar-mode buffers.")
(define-abbrev-table 'mizar-mode-abbrev-table ())


;; Font lock
(defvar mizar-symbol-color nil "The color for the optional symbol fontification, white is suggested for the light-bg, nil (default) means no symbol fontification is done.")


(defun mizar-font-lock-keywords ()
  "Set up font lock keywords for the current Mizar system."
  (if window-system
      (progn
	(require 'font-lock)
	(if (boundp 'font-lock-background-mode)
	    ()
	  (make-local-variable 'font-lock-background-mode)
	  (setq font-lock-background-mode 'light)) ; Assume light bg
	(if (boundp 'font-lock-display-type)
	    ()
	  (make-local-variable 'font-lock-display-type)
	  (setq font-lock-display-type 'color)) ; Assume color

	;; Create faces
	;; Format: (FACE FOREGROUND BACKGROUND BOLD-P ITALIC-P UNDERLINE-P)
	(let* ((dark-bg (eq font-lock-background-mode 'dark))
	       (faces
		(cond
		 ((memq font-lock-display-type '(mono monochrome))
		  '(
		    (mizar-builtin-face nil nil nil nil t)
		    (mizar-exit-face nil nil nil nil t)
;		    (mizar-symbol-face nil nil nil nil t)
))
		 ((memq font-lock-display-type '(grayscale greyscale
							   grayshade greyshade))
		  '(
		    (mizar-builtin-face nil nil nil nil t)
		    (mizar-exit-face nil nil nil nil t)
;		    (mizar-symbol-face nil nil nil nil t)
))
		 (dark-bg 		; dark colour background
		  '(
		    (mizar-builtin-face "LightSkyBlue" nil nil nil nil)
		    (mizar-exit-face "green" nil nil nil nil)
;		    (mizar-symbol-face mizar-symbol-color nil nil nil nil)
))
		 (t			; light colour background
		  '(
		    (mizar-builtin-face "Orchid" nil nil nil nil)
		    (mizar-exit-face "ForestGreen" nil nil nil nil)
;		    (mizar-symbol-face mizar-symbol-color nil nil nil nil)
)))))
;; mizar-symbol-color fontification
	  (if mizar-symbol-color
	      (setq faces (cons (list 'mizar-symbol-face mizar-symbol-color nil nil nil nil) faces)))

	  (while faces
	    (if (fboundp 'font-lock-make-face)
		;; The preferred way
		(font-lock-make-face (car faces))
	      ;; The clumsy way
	      (let ((facename (nth 0 (car faces)))
		    (fg (nth 1 (car faces)))
		    (bg (nth 2 (car faces)))
		    (bold (nth 3 (car faces)))
		    (ital (nth 4 (car faces)))
		    (under (nth 5 (car faces))))
		(make-face facename)
		(if fg (set-face-foreground facename fg))
		(if bg (set-face-background facename bg))
		(if bold (make-face-bold facename))
		(if ital (make-face-italic facename))
		(if bold (make-face-bold facename))
		(set-face-underline-p facename under)
		;; This is needed under Emacs 20 for some reason.
		(set facename facename)
		))
	    (setq faces (cdr faces))))
      
	;; Font Lock Patterns
	(let (
	      ;; "Native" Mizar patterns
	      (head-predicates
	       '("\\<\\(theorem\\|scheme\\|definition\\)\\>"
		 0 font-lock-function-name-face))
	      (connectives
	       '("\\<\\(for\\|ex\\|not\\|&\\|or\\|implies\\|iff\\|st\\|holds\\|being\\)\\>"
		 ;;		 1 font-lock-variable-name-face
		 1 'mizar-builtin-face))
	      (proofs
	       '("\\<\\(proof\\|now\\|end\\|hereby\\)"
		 0 'font-lock-keyword-face ))
	      (comments '("::[^\n]*"  0 'font-lock-comment-face ))
	      (refs '("[ \n\t]\\(by\\|from\\)[^;.]*" 0 'font-lock-type-face))
	      (extra '("&"  0  'mizar-builtin-face))
	      (keywords			; directives (queries)
	       (list
		"\\<\\(and\\|antonym\\|attr\\|as\\|assume\\|be\\|begin\\|being\\|canceled\\|case\\|cases\\|cluster\\|coherence\\|compatibility\\|consider\\|consistency\\|constructors\\|contradiction\\|correctness\\|clusters\\|def\\|deffunc\\|definition\\|definitions\\|defpred\\|environ\\|equals\\|ex\\|existence\\|for\\|func\\|given\\|hence\\|\\|requirements\\|holds\\|if\\|iff\\|implies\\|irreflexivity\\|it\\|let\\|means\\|mode\\|not\\|notation\\|of\\|or\\|otherwise\\|\\|over\\|per\\|pred\\|provided\\|qua\\|reconsider\\|redefine\\|reflexivity\\|reserve\\|scheme\\|schemes\\|signature\\|struct\\|such\\|suppose\\|synonym\\|take\\|that\\|thus\\|then\\|theorems\\|vocabulary\\|where\\|associativity\\|commutativity\\|connectedness\\|irreflexivity\\|reflexivity\\|symmetry\\|uniqueness\\|transitivity\\|idempotence\\|asymmetry\\|projectivity\\|involutiveness\\)\\>"
		;;		1 'mizar-builtin-face
		1 font-lock-variable-name-face))
	      (syms
	       (if mizar-symbol-color
		   (list (mizar-get-dct (file-name-sans-extension (buffer-file-name)))
			 0 'mizar-symbol-face)))
	       )
	  ;; Make font lock list
	  (delq
	   nil
	   (cond
	    ((eq major-mode 'mizar-mode)
	     (list
	      comments
	      extra
	      refs
	      head-predicates
	      connectives
	      proofs
	      keywords
;; only if mizar-symbol-color defined and article has .dct
	      (if (and syms (not (equal "" (car syms)))) syms)
	      ))
	    ((eq major-mode 'mizar-inferior-mode)
	     (list
	     
	      keywords))
	    ((eq major-mode 'compilation-mode)
	     (list
	      
	      keywords))))
	  ))))


(defun mizar-mode (&optional arg)
  "Major mode for editing Mizar articles and viewing Mizar abstracts.

In addition to the following commands, there are special bindings
for special buffers *Constructors list* and *MML Query Input*.
See the documentation for variables `mizar-cstr-map' and `query-entry-map'
for more.

Commands:
\\{mizar-mode-map}
Entry to this mode calls the value of `mizar-mode-hook'
if that value is non-nil."
  (interactive "P")
  (kill-all-local-variables)
					;  (set-syntax-table text-mode-syntax-table)
  (use-local-map mizar-mode-map)
					;  (setq local-abbrev-table text-mode-abbrev-table)
  (setq major-mode 'mizar-mode)
  (setq mode-name "mizar")
  (setq local-abbrev-table mizar-mode-abbrev-table)
  (mizar-mode-variables)
  (setq buffer-offer-save t)
  (mizar-setup-imenu-sb)
  (run-hooks  'mizar-mode-hook)
  )

(defvar html-help-url "http://ktilinux.ms.mff.cuni.cz/~urban/MizarModeDoc/html"
"The html help for Mizar Mode resides here")

;; Menu for the mizar editing buffers
(defvar mizar-menu
  '(list  "Mizar"
	  ["Browse HTML Help" (browse-url html-help-url) t]
	  ["Visited symbols" mouse-find-tag-history t]
	  '("Goto errors"
	    ["Next error"  mizar-next-error t]
	    ["Previous error" mizar-previous-error t]
	    ["Remove error lines" mizar-strip-errors t])
	  "-"
	  ["View symbol def" mizar-symbol-def t]
	  ["Show reference" mizar-show-ref t]
	  '("MoMM"
	    ["Use MoMM (Not Mizar 6.2. yet!)" mizar-toggle-momm :style toggle
	     :selected mizar-use-momm  :active t]
	    ["Load theorems only"  (setq mizar-momm-load-tptp
					 (not mizar-momm-load-tptp))
	     :style toggle :selected (not mizar-momm-load-tptp)
	     :active mizar-use-momm]
	    ["Run MoMM for current article"
	     (mizar-run-momm-default nil nil mizar-momm-load-tptp)
	     mizar-use-momm]
	    ["Load additional files in MoMM" mizar-momm-add-files
	     mizar-use-momm]
	    ["Run MoMM with parameters" mizar-run-momm mizar-use-momm]
	    ["Run MoMM with all.ths (200M!)" mizar-run-momm-full
	     mizar-use-momm]
	    ["MoMM export current article"
	     (progn
	       (mizar-it mizar-relcprem)
	       (mizar-it mizar-momm-exporter))
	     mizar-use-momm]
	    )
	  '("Mizar TWiki"
	    ["Browse Mizar Twiki" (browse-url mizar-twiki-url) t]
	    ["Ask Mizar question" (browse-url mizar-twiki-questions) t]
	    ["Suggest feature" (browse-url mizar-twiki-features) t]
	    ["Comment Mizar error" mizar-twiki-comment-error t]
	    ["Describe pitfall" (browse-url mizar-twiki-pitfalls) t]
	    ["View FAQ" (browse-url mizar-twiki-faq) t]
	    ["Report bug" (browse-url mizar-twiki-bugs) t]
	    ["MML Suggestions" (browse-url mizar-twiki-mml-sugg) t]
	    )
	  '("MML Query"	    
	    ["View MMLQuery abstract" mmlquery-find-abstract t
	     :help "Start Emacs MMLQuery browser for given abstract"]
	    ["Query window" query-start-entry t]
	    ("MML Query server"
	     ["Megrez" (setq query-url megrez-url) :style radio :selected (equal query-url megrez-url) :active t]
	     ["Alioth" (setq query-url alioth-url) :style radio :selected (equal query-url alioth-url) :active t]
	     )
	    ("MML Query browser" 
	     :help "The preferred browser for WWW version of MMLQuery"
	     ["Emacs W3" (setq mizar-query-browser 'w3) :style radio :selected  (eq mizar-query-browser 'w3) :active t]
	     ["Default" (setq mizar-query-browser nil) :style radio :selected  (eq mizar-query-browser nil) :active t]
	     )
	    ["Show keybindings in *MML Query input*" (describe-variable 'query-entry-map) t]
	    )
	  '("Constr. Explanations"
	    :help "Explaining and browsing constructors in your formulas"
	    ("Verbosity" 
	     :help "Set to non-none to activate constructor explanations"
	    ["none" (mizar-toggle-cstr-expl 'none) :style radio :selected (not mizar-do-expl) :active t]
	    ["sorted constructors list" (mizar-toggle-cstr-expl 'sorted)
	     :style radio :selected
	     (and mizar-do-expl (eq mizar-expl-kind 'sorted)) :active t]
	    ["constructors list" (mizar-toggle-cstr-expl 'constructors)
	     :style radio :selected
	     (and mizar-do-expl (eq mizar-expl-kind 'constructors)) :active t]
	    ["translated formula" (mizar-toggle-cstr-expl 'translate)
	     :style radio :selected
	     (and mizar-do-expl (eq mizar-expl-kind 'translate)) :active t]
;; 	    ["expanded formula" (mizar-toggle-cstr-expl 'expanded)
;; 	     :style radio :selected
;; 	     (and mizar-do-expl (eq mizar-expl-kind 'expanded)) :active t]
;; 	    ["raw formula" (mizar-toggle-cstr-expl 'raw)
;; 	     :style radio :selected
;; 	     (and mizar-do-expl (eq mizar-expl-kind 'raw)) :active t]
	    )
	    ["Underline explanation points"
	     (setq mizar-underline-expls
		   (not mizar-underline-expls)) :style toggle :selected mizar-underline-expls  :active mizar-do-expl 
	      :help "Make the clickable explanation points underlined"]
	    ["Show keybindings in *Constructors list*" (describe-variable 'mizar-cstr-map) :active mizar-do-expl]
	    )
	  '("Grep"
	    ["Case sensitive" mizar-toggle-grep-case-sens :style
	     toggle :selected mizar-grep-case-sensitive :active t]
	    ["Abstracts" mizar-grep-abs t]
	    ["Full articles" mizar-grep-full t])
	  ["Symbol apropos" symbol-apropos t]
	  ["Bury all abstracts" mizar-bury-all-abstracts t]
	  ["Close all abstracts" mizar-close-all-abstracts t]
	  "-"
	  ["View theorems" make-theorem-summary t]
	  ["Reserv. before point" make-reserve-summary t]
	  "-"
	  ["Run Mizar" mizar-it t]
	  ["Mizar Compile" mizar-compile t]
	  ["Toggle quick-run" toggle-quick-run :style toggle :selected mizar-quick-run  :active (eq mizar-emacs 'gnuemacs)]
	  ["Toggle launch-dir" mizar-set-launch-dir :style toggle :selected mizar-launch-dir  :active t]
	  (list "Show output"
		["none" (mizar-toggle-show-output "none") :style radio :selected (equal mizar-show-output "none") :active t]
		["4 lines" (mizar-toggle-show-output 4) :style radio :selected (equal mizar-show-output 4) :active t]
		["10 lines" (mizar-toggle-show-output 10) :style radio :selected (equal mizar-show-output 10) :active t]
		["all" (mizar-toggle-show-output "all") :style radio :selected (equal mizar-show-output "all") :active t]
		)
	  (list "Show error"
		["none" (mizar-toggle-goto-error "none") :style radio :selected (equal mizar-goto-error "none") :active t]
		["first" (mizar-toggle-goto-error "first") :style radio :selected (equal mizar-goto-error "first") :active t]
		["next" (mizar-toggle-goto-error "next") :style radio :selected (equal mizar-goto-error "next") :active t]
		["previous" (mizar-toggle-goto-error "previous") :style radio :selected (equal mizar-goto-error "previous") :active t]
		)
	  "-"
	  (list "Voc. & Constr. Utilities"
		["Findvoc" mizar-findvoc t]
		["Listvoc" mizar-listvoc t]
		["Constr" mizar-constr t])
;		["Scconstr" mizar-scconstr t])
	  '("Irrelevant Utilities"
	    ["Irrelevant Theorems" mizar-irrths t]
	    ["Irrelevant Inferences" mizar-relinfer t]
	    ["Trivial Proofs" mizar-trivdemo t]
	    ["Irrelevant Iterative Steps" mizar-reliters t]
	    ["Irrelevant Premises" mizar-relprem t]
	    ["Irrelevant Labels" mizar-chklab t]
	    ["Irrelevant Vocabularies" mizar-irrvoc t]
	    ["Inaccessible Items" mizar-inacc t])
	  '("Other Utilities"
	    ["Miz2Prel" (mizar-it "miz2prel" t) (eq mizar-emacs 'gnuemacs)]
	    ["Miz2Abs" (mizar-it "miz2abs" t) (eq mizar-emacs 'gnuemacs)]
	    ["Ratproof" (mizar-it "ratproof") t])
	  "-"
	  ["Comment region" comment-region t]
	  ["Uncomment region" (comment-region (region-beginning)
					      (region-end) -1) t]
	  '("Proof checking"
	    ["proof -> @proof on region" mizar-hide-proofs t]
	    ["@proof -> proof on region" (mizar-hide-proofs (region-beginning)
							   (region-end) t) t]
	    ["proof -> @proof on buffer" (mizar-hide-proofs (point-min)
							   (point-max)) t]
	    ["@proof -> proof on buffer" (mizar-hide-proofs (point-min)
							   (point-max) t) t]
	    )
	  '("Then placement"
	    ["start of lines on region" mizar-move-then t]
	    ["end of lines on region" (mizar-move-then (region-beginning)
							  (region-end) t) t]
	    ["start of lines on buffer" (mizar-move-then (point-min)
							  (point-max)) t]
	    ["end of lines on buffer" (mizar-move-then (point-min)
							  (point-max) t) t]
	    )
	  "-"
	  '("Indent"
	    ["Line" mizar-indent-line t]
	    ["Region" indent-region t]
	    ["Buffer" mizar-indent-buffer t])
	  '("Indent width"
	    ["1" (mizar-set-indent-width 1) :style radio :selected (= mizar-indent-width 1) :active t]
	    ["2" (mizar-set-indent-width 2) :style radio :selected (= mizar-indent-width 2) :active t]
	    ["3" (mizar-set-indent-width 3) :style radio :selected (= mizar-indent-width 3) :active t])
	  '("Fontify"
	    ["Buffer" font-lock-fontify-buffer t])
	  )
  "The definition for the menu in the editing buffers."
  )


(defun mizar-menu ()
  "Add the menu in the editing buffer."
  (let ((menu (delete nil (eval mizar-menu))))
    (cond
     ((eq mizar-emacs 'gnuemacs)
      (easy-menu-define mizar-menu-map mizar-mode-map "" menu))
     ((eq mizar-emacs 'xemacs)
      (easy-menu-add menu))
     ;; The default
     (t
      (easy-menu-define mizar-menu-map mizar-mode-map "" menu))
     )))

(mizar-menu)


(defun mizar-hs-forward-sexp (arg)
  "Function used by function `hs-minor-mode' for `forward-sexp' in Mizar mode.
Move forward across one balanced expression (sexp).
With ARG, do it that many times.  Negative arg -N means
move backward across N balanced expressions."
(let ((both-regexps (concat "\\(" hs-block-start-regexp "\\)\\|\\("
			      hs-block-end-regexp "\\)")
      ))
  (if (< arg 0)
      (backward-sexp 1)
    (if (looking-at hs-block-start-regexp)
	(progn
	  (forward-sexp 1)
	  (setq count 1)
	  (while (> count 0)
	    (re-search-forward both-regexps (point-max) t nil)
	    (setq beg1  (match-beginning 0))
	    (setq end1 (match-end 0))
	    (setq result1 (buffer-substring-no-properties beg1 end1))
	    (if (string-match hs-block-start-regexp result1)
		(setq count (+  count 1))
	      (setq count (- count 1))))
	  (goto-char (match-end 0)))
	  ))))

(defun mizar-hs-adjust-block-beginning (pos)
(save-excursion
  (forward-word -1)
  (point)))


(let ((mizar-mode-hs-info '(mizar-mode ".*\\b\\(proof\\|now\\|hereby\\)[ \n\r]" "end;" "::+" mizar-hs-forward-sexp mizar-hs-adjust-block-beginning)))
    (if (not (member mizar-mode-hs-info hs-special-modes-alist))
            (setq hs-special-modes-alist
	                  (cons mizar-mode-hs-info hs-special-modes-alist))))
;(add-hook 'mizar-mode-hook 'mizar-menu)
(add-hook 'mizar-mode-hook 'hs-minor-mode)
(add-hook 'mizar-mode-hook 'imenu-add-menubar-index)
;; adding this as a hook causes an error when opening
;; other file via speedbar, so we do it the bad way
;;(if (featurep 'speedbar)
;;    (add-hook 'mizar-mode-hook '(lambda () (speedbar 1))))
(if (and window-system (featurep 'speedbar))
    (speedbar 1))

(provide 'mizar)

;;; mizar.el ends here
