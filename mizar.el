;; Fri Jan 11 2002 ... mizar-launch-dir added, controlling from where
;; mizf is run; use it e.g. if 'dict/' and 'text/' are in the same directory  
;; Dec 20 2001 ... some changes by Freek Wiedijk and Dan Synek:
;; undo and output fixed, standard compilation (C-c c) is now possible
;; using the scripts mizfe and erpp.pl (put them where mizf is and make
;; them executable)
;; Dec 15 2001  
;; some small additions and fixes: fixed and added some
;; irrelevant utils, can be run with revf now; some other utils added;
;; fixed "hereby" and font-lock; added abbrev-table support ... define your
;; own abbreviations using the abbrev-mode; started attempts at xemacs
;; compatibility, not done yet
;; March 21 2001 ...hide/show minor mode added ... hiding proofs
;;               quick-run added ...speeds up verifier execution by about 50%,
;;                                  (caused by slow displays), toggle it in menu 
;; March 9 2001  ... symbol browsing functions added, see 
;; http://kti.ms.mff.cuni.cz/~urban/README_BROWSING.txt for detailed info on it, 
;; the MIZTAGS are now obsolete
;; August 31 2000 ... theorem and reservation summary added, MIZTAGS for schemes changed a litle
;; April 18 2000 ... small adjustment to Mizar Version 6.0.07, miz1 and miz3 files no longer needed
;; April 6 2000 ... some more features added
;; April 3 2000, modified by Josef Urban (urban@kti.ms.mff.cuni.cz)
;; for use with Mizar  Version 6.0.01 (Linux/FPC)
;; some parts might also work with dos-emacs and dos mizar
;;
;; to use it, put it where your .el files are, and add following to to your
;; .emacs file ; see further instructions for the  "MIZTAGS" files

;;;;;;;;;;;;;; start of .emacs ;;;;;;;;;;;;;;;;;;;;;

; (global-font-lock-mode t)
; (autoload 'mizar-mode "mizar" "Major mode for editing Mizar programs." t)
; (setq auto-mode-alist (append '(  ("\\.miz" . mizar-mode)
;                                   ("\\.abs" . mizar-mode))
; 			      auto-mode-alist))

;;;;;;;;;;;;;; end of .emacs    ;;;;;;;;;;;;;;;;;;;;;;;;

;; functions: 
;      syntax highlighting .. put "(global-font-lock-mode t)" into your
;                             .emacs file to enable it
;      basic indentation 
;      C-c C-m or C-c RET.. runs Mizar on current .miz buffer, refreshes it
;                           and goes to first error found
;      C-c C-n ............ goes to next error and displays its explanation
;                           in minibuffer
;      C-c C-p ............ goes to previous error and displays its explanation
;                           in minibuffer
;      C-c C-e ............ deletes all error lines added by Mizar 
;                           (lines starting with ::>)
;      C-c C-c ............ comments selected region
;      C-u C-c C-c ........ uncomments selected region
;      M-C-\ .............. indents selected region
;      TAB ................ indents line 

;;; added in versions 1.1:
;      Mizar menu
;      M-. ................ shows theorem, definition or scheme with label LABEL, 
;                           needs to run MIZTAGS (see further) in the directory $MIZFILES/abstr 
;                           before start of the work
;      C-c C-f ............ interface to findvoc
;      C-c C-l ............ interface to listvoc
;      C-c C-t ............ interface to thconstr ... 9.3. 2001: changed to run constr
;      C-c C-s ............ interface to scconstr ... 9.3. 2001: defunct, replaced now by constr
;      C-c C-h ............ runs irrths on current buffer, refreshes it 
;                           and goes to first error found
;      C-c C-i or C-c TAB.. runs relinfer on current buffer, refreshes it 
;                           and goes to first error found 
;      C-c C-y ............ runs relprem on current buffer, refreshes it 
;                           and goes to first error found 
;      C-c C-v ............ runs irrvoc on current buffer, refreshes it 
;                           and goes to first error found 
;      C-c C-a ............ runs inacc on current buffer, refreshes it 
;                           and goes to first error found

;;; added 31.8. 2000:
;      C-c C-r ............ shows all reservations before current point
;      C-c C-z ............ makes summary of theorems in current article

;;; added 9.3. 2001:
;      C-c C-t ............ bound to constr now
;      M-;     ............ runs mizar-symbol-def, see its doc.
;      mouse-3 ............ also mizar-symbol-def
;      M-.     ............ runs mizar-show-ref
;   S-down-mouse-3  ............ mizar-symbol-def with no completion
;   S-down-mouse-1  ............ mizar-show-ref with no completion
;   S-down-mouse-2  ............ pops up menu of visited symbols to go to      
; Added by Dan
;      C-c C   ............ runs mizar as if it was an ordinary compile command

;; to do: better indentation,
;           find out why it hangs during C-c C-m when switching to another buffer,

          


;;;;;;;;;;;;;;;;;;;; start of original info ;;;;;;;;;;;;;;;;;
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

(defvar mizar-emacs 
  (if (featurep 'xemacs)
      'xemacs
    (if (featurep 'dos-win32)
	'winemacs		      
      'gnuemacs))
  "The variant of Emacs we're running.
Valid values are 'gnuemacs,'xemacs and 'winemacs.")

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
(require 'executable)
(require 'term)
(require 'imenu)
(if (eq mizar-emacs 'xemacs)
    (require 'speedbar) ;; no NOERROR in xemacs 
  (require 'speedbar nil t)) ;;noerror if not present


(defvar mizar-mode-syntax-table nil)
(defvar mizar-mode-abbrev-table nil)
(defvar mizar-mode-map nil)

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

(defvar mizar-indent-width 2 "Indent for Mizar articles")

(defun mizar-set-indent-width (to)
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
  (make-local-variable 'font-lock-defaults)
  (setq font-lock-defaults
      '(mizar-font-lock-keywords nil nil ((?_ . "w")))))


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
  (define-key mizar-mode-map "\C-c\C-g" 'mizar-grep-abs)
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
  (define-key mizar-mode-map "\M-;"     'mizar-symbol-def)
  (define-key mizar-mode-map [mouse-3]     'mizar-mouse-symbol-def)
  (define-key mizar-mode-map [(shift down-mouse-3)]     'mizar-mouse-direct-symbol-def)
  (define-key mizar-mode-map [(shift down-mouse-1)]     'mizar-mouse-direct-show-ref)
  (define-key mizar-mode-map [(shift down-mouse-2)]     'mouse-find-tag-history)
  (define-key mizar-mode-map "\M-."     'mizar-show-ref)
  (mizar-mode-commands mizar-mode-map))

(defvar mizar-tag-ending ";"
"end of the proper tag name in mizsymbtags and mizreftags,
used for exact completion")

(defun miz-complete ()
"used for exact tag completion" 
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
"size of a file"
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
"destructively deletes members from pos on"
(let* ((l2  l1)
       (end (nthcdr (- pos 1) l2)))
  (if (consp end)
      (setcdr  end nil))
  l2))

;;;;;;;;;;;;  indentation (pretty poor) ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun mizar-indent-line (&optional whole-exp)
  "Indent current line as Mizar code.
With argument, indent any additional lines of the same clause
rigidly along with this one (not yet)."
  (interactive "p")
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
  "Indent the entire mizar buffer"
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


;;;;;;;;;;; grepping ;;;;;;;;;;;;;;;;;;;;;
;;; we should do some additional checks for winemacs

(defvar mizar-grep-case-sensitive t
"tells if grepping is case sensitive or not")

(defun mizar-toggle-grep-case-sens ()
(interactive)
(setq mizar-grep-case-sensitive (not mizar-grep-case-sensitive)))

(defun mizar-grep-abs (exp)
"Runs grep on abstracts"
  (interactive "sregexp: ")
  (let ((abs (substitute-in-file-name "$MIZFILES/abstr/*.abs")))
    (if mizar-grep-case-sensitive
	(grep (concat "grep -n -e \"" exp "\" " abs))
      (grep (concat "grep -i -n -e \"" exp "\" " abs)))
    ))

(defun mizar-grep-full (exp)
"Runs grep on full articles"
  (interactive "sregexp: ")
  (let ((miz (substitute-in-file-name "$MIZFILES/mml/*.miz")))
    (if mizar-grep-case-sensitive
	(grep (concat "grep -n -e \"" exp "\" " miz))
      (grep (concat "grep -i -n -e \"" exp "\" " miz)))
    ))

;;;;;;;;;;;;  tha tags handling starts here ;;;;;;;;;;;;;;;;;;;;;;;;;
;;; xemacs seems unhappy yet

(put 'mizar-mode 'find-tag-default-function 'mizar-ref-at-point)

(defvar mizsymbtags 
  (substitute-in-file-name "$MIZFILES/abstr/SYMBTAGS") 
  "Symbol tags file created with stag.pl")
(defvar mizreftags 
  (substitute-in-file-name "$MIZFILES/abstr/REFTAGS") 
  "References tags file created with stag.pl")

;; nasty to redefine these two, but working; I could not get the local vars machinery right  
(defun etags-goto-tag-location (tag-info)
  (let ((startpos (cdr (cdr tag-info)))
	(line (car (cdr tag-info)))
	offset found pat)
	;; Direct file tag.
	(cond (line (goto-line line))
	      (startpos (goto-char startpos))
	      (t (error "etags.el BUG: bogus direct file tag")))
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
  "used for mizar-mouse-symbol-def")

(defun mizar-mouse-symbol-def ()
  "mouse-3 is bound to this function, runs mizar-symbol-def
and the second mouse-3 shows the symbols completion"
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
  "S-mouse-3 is bound to this function, 
goes directly to the best match of symbol under point"
  (interactive)
  (mouse-set-point last-input-event)
  (mizar-symbol-def  t))

(defun mizar-mouse-direct-show-ref ()
  "S-mouse-1 is bound to this function, 
goes directly to the reference under point"
  (interactive)
  (mouse-set-point last-input-event)
  (mizar-show-ref  t))

(defun visit-tags-or-die (name)
  (if (file-readable-p name)
      (visit-tags-table name)
    (error "No tags file %s, run the script stag.pl" name)
    nil)) 

(defun mizar-symbol-def  (&optional nocompletion) 
  "Finds the definition of a symbol with completion,
if in *.abs buffer shows it it current window, otherwise,
i.e. in *.miz buffer, shows it in other window.
In Completion buffer, aside from its normal key bindings,
';' is bound to show all exact matches. If invoked by right-click,
second right-click does this too."
  (interactive)
  (if (visit-tags-or-die mizsymbtags)
      (let ((abs (buffer-abstract-p (current-buffer))))
	(if nocompletion
	    (if abs (find-tag  (mizar-ref-at-point))
	      (find-tag-other-window  (mizar-ref-at-point)))
	  (if abs (call-interactively 'find-tag)
	    (call-interactively 'find-tag-other-window))))))
  

(defun mizar-show-ref (&optional nocompletion) 
  "Finds the reference with completion in other window" 
  (interactive)
  (if (visit-tags-or-die mizreftags)
      (if nocompletion
	  (find-tag-other-window  (mizar-ref-at-point))
	(call-interactively 'find-tag-other-window))))


(defun symbol-apropos ()
  "Display list of all symbols REGEXP matches."
  (interactive)
  (if (visit-tags-or-die mizsymbtags)
      (call-interactively 'tags-apropos)))



(defun mouse-find-tag-history ()
"popup menu with last 20 visited tags and go to selection,
works properly only for symbols (not references)"
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
"Non nil if buffer is mizar abstract"
(let ((name  (buffer-file-name x)))
  (and (stringp name)
       (string-match "\.abs$" name))))

(defun mizar-current-abstracts ()
"Returns list of buffers of mizar abstracts"
(let ((l (buffer-list)) (l1 ()))
  (while l (if (buffer-abstract-p (car l)) 
	       (setq l1 (cons (car l) l1)))
	 (setq l (cdr l)))
  l1))

(defun mizar-close-all-abstracts ()
"Closes all abstracts, useful when too much browsing done
and you want to get to your editing buffers"
(interactive)
(let* ((l (mizar-current-abstracts)) (i (length l)))
  (mapcar '(lambda (x) (kill-buffer x)) l)
  (message "%d abstracts closed" i)))

(defun mizar-close-some-abstracts ()
"Choose the abstracts you want to close"
(interactive)
(kill-some-buffers  (mizar-current-abstracts)))

(defun mizar-bury-all-abstracts ()
"Bury all abstracts, useful when too much browsing done
and you want to get to your editing buffers"
(interactive)
(let* ((l (mizar-current-abstracts)) (i (length l)))
  (mapcar '(lambda (x) (bury-buffer x)) l)
  (message "%d abstracts buried" i)))


;;;;;;;;;;;;;;;;;; end of tags handling ;;;;;;;;;;;;;;;;;;;;;;;;

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
"Returns an unsorted table of errors on aname or nil."
(save-excursion
  (let ((errors (concat aname ".err"))) 
    (if (file-readable-p errors)
	(with-temp-buffer           ; sort columns, then lines
	  (insert-file-contents errors) 
	  (buff-to-numtable)
	  )
      )))) 

(defun sort-for-errflag (l)
"Greater lines first, then by column"
(let ((l (copy-alist l)))
  (sort l '(lambda (x y) (or (> (car x) (car y))
			     (and (= (car x) (car y))
				  (< (cadr x) (cadr y)))))
	)))

(defun mizar-error-flag (aname &optional table)
"Insert error flags into main mizar buffer (like errflag)."
(interactive "s")
(let ((atab (sort-for-errflag (or table (mizar-get-errors aname)))))
  (if atab
      (save-excursion	  
	(if (< 0 (goto-line (caar atab)))
	    (error "Main buffer and the error file do not agree, run verifier!"))
	(end-of-line)
	(insert "\n::>")
	(let ((cline (caar atab)) srec sline scol snr)
	  (while atab 
	    (setq srec (car atab) sline (car srec) 
		  scol (- (cadr srec) 1)         ; 0 based in emacs
		  snr (caddr srec) atab (cdr atab))
	    (if (> cline sline)		; start new line ... go back
		(progn
		  (forward-line (- sline cline))
		  (insert "::>\n")
		  (backward-char)
		  (setq cline sline)
		  ))
	    (if (> scol (current-column)) ; enough space
		(progn
		  (move-to-column scol t)
		  (insert (concat "*" (number-to-string snr))))
	      (insert (concat "," (number-to-string snr))) ; not enough space
	      )))))))

(defvar mizar-err-msgs (substitute-in-file-name "$MIZFILES/mizar.msg")
  "File with explanations of Mizar error messages")
(defun mizar-getmsgs (errors)
"Gets sorted errors, returns string of messages"
(save-excursion
  (let ((buf (find-file-noselect  mizar-err-msgs))
	(msgs ""))
    (set-buffer buf)
    (goto-char (point-min))
    (while errors
      (let* ((s (number-to-string (car errors)))
	     (res (concat mizar-error-start " " s ": "))
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
	(setq msgs (concat msgs res))
	(setq errors (cdr errors))))
    msgs)))


(defun mizar-err-codes (aname &optional table)
  (sort (unique (mapcar 'third (or table (mizar-get-errors aname)))) '<))
  
(defun mizar-addfmsg (aname &optional table)
"Insert error explanations into main mizar buffer (like addfmsg)."
(interactive "s")
(save-excursion
  (goto-char (point-max))
  (if (not (bolp)) (insert "\n"))
  (insert (mizar-getmsgs (mizar-err-codes aname table)))))


(defun mizar-do-errors (aname)
"add err-flags and errmsgs using aname.err in current buffer"
(save-excursion
  (let ((errors (concat aname ".err"))) 
    (if (and (file-readable-p errors)
	     (< 0 (file-size errors)))
	(let ((table (mizar-get-errors aname)))
	  (mizar-error-flag aname table)
	  (mizar-addfmsg aname table))))))
  





;;;;;;;;;;;;;;; end of errflag ;;;;;;;;;;;;;;;;;;


(defconst mizar-error-regexp "\\(\\*\\|::>,\\)\\([0-9]+\\)" "regexp used to locate error messages in a mizar text")

(defvar mizar-region-count 0  "number of regions on mizar-region-stack")

(defvar mizar-mode-map nil "keymap used by mizar mode..")

(defvar mizar-quick-run t "speeds up verifier by not displaying its intermediate output")

(defvar mizar-quick-run-temp-ext ".out" "extension of the temp file for quick run")

(defvar mizar-use-revf nil "tells if the script revf is used for running mizar irrelevant utilities")

(defvar mizar-launch-dir nil 
"If non-nil, mizf and other scripts are called from here")

(defvar mizar-show-output 10
"possible values: none,4,10,all; determines the size of the 
output window ")

(defvar mizar-goto-error "next"
"what error to move to after processing, possible values are
none,first,next,previous")

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
"Mizar imenu expression")


(defun toggle-quick-run ()
(interactive)
(setq mizar-quick-run (not mizar-quick-run)))

(defun mizar-toggle-show-output (what)
(interactive)
(setq mizar-show-output what))

(defun mizar-toggle-goto-error (where)
(interactive)
(setq mizar-goto-error where))

(defun toggle-use-revf ()
(interactive)
(if (or mizar-use-revf (executable-find "revf"))
    (setq mizar-use-revf (not mizar-use-revf))
  (error "The revf script not found or not executable!")))


(defun mizar-set-launch-dir ()
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
  Previous contents of that buffer are killed first."
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


(defun mizar-compile ()
  "compile a mizar file in the traditional way"
  (interactive)
  (let ((old-dir (mizar-switch-to-ld)))
    (compile (concat "mizfe " (substring (buffer-file-name) 0 (string-match "\\.miz$" (buffer-file-name)))))
    (if old-dir (setq default-directory old-dir))))


(defun mizar-handle-output  ()
"Display processing output according to mizar-show-output"
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
  "Post processing error explanation"
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

(defun mizar-switch-to-ld ()
"switch to mizar-launch-dir and return old default-directory if switched"
  (if mizar-launch-dir
      (let ((old-dir default-directory))
	(cd mizar-launch-dir)
	old-dir)))

(defun mizar-it (&optional util noqr)
  "Run mizar on the text in the current .miz buffer;
if util given, runs it instead of mizf, if noqr, does not 
use quick run"
  (interactive)
  (let ((util (or util "verifier"))
	(makeenv "makeenv"))
    (if (eq mizar-emacs 'winemacs)
	(progn
	  (setq util (concat mizfiles util)
		makeenv (concat mizfiles makeenv))))
    (cond ((not (string-match "miz$" (buffer-file-name)))
	   (message "Not in .miz file!!"))
	  ((not (executable-find util))
	   (message (concat util " not found or not executable!!")))
	  (t 
	   (let* ((name (file-name-sans-extension (buffer-file-name)))
		  (fname (file-name-nondirectory name))
		  (old-dir (mizar-switch-to-ld)))
	     (mizar-strip-errors)
	     (save-buffer)
	     (if (and mizar-quick-run (not noqr))
		 (save-excursion
		   (message (concat "Running " util " on " fname " ..."))
		   (if (get-buffer "*mizar-output*")
		       (kill-buffer "*mizar-output*"))
		   (if (= 0 (call-process makeenv nil (get-buffer-create "*mizar-output*") nil name))
		       (shell-command (concat util " -q " name) 
				      "*mizar-output*")
		     (switch-to-buffer-other-window "*mizar-output*"))
		   (message " ... done"))
	       (if (= 0 (call-process makeenv nil nil nil name))
		   (progn
		     (mizar-new-term-output noqr)
		     (term-exec "*mizar-output*" util util nil (list name))
		     (while  (term-check-proc "*mizar-output*") 
		       (sit-for 1)))))
	     (if old-dir (setq default-directory old-dir))	   
	     (mizar-do-errors name)
	     (save-buffer)
	     (mizar-handle-output)
	     (mizar-show-errors)
	     )))))

	     

(defun mizar-irrths ()  
  (interactive)
(mizar-it "irrths"))

(defun mizar-irrvoc ()  
  (interactive)
(mizar-it "irrvoc"))

(defun mizar-inacc ()  
  (interactive)
(mizar-it "inacc"))

(defun mizar-relinfer ()  
  (interactive)
(mizar-it "relinfer"))

(defun mizar-relprem ()  
  (interactive)
(mizar-it "relprem"))

(defun mizar-reliters ()  
  (interactive)
(mizar-it "reliters"))

(defun mizar-trivdemo ()  
  (interactive)
(mizar-it "trivdemo"))

(defun mizar-chklab ()  
  (interactive)
(mizar-it "chklab"))




(defun mizar-findvoc (&optional whole-exp)
  "find vocabulary for a symbol"
  (interactive "p")
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
  "Make a summary of type reservations before current point in the 
  buffer *Reservation-Summary*.
  Previous contents of that buffer are killed first."
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



			 





(defun mizar-listvoc (&optional whole-exp)
  "list vocabularies"
  (interactive "p")
  (shell-command (concat "listvoc "  
			 (read-string  (concat "listvoc  VocNames (Default: " (current-word) "): " )
				       nil nil      (current-word))
			 )))

(defun mizar-thconstr (&optional whole-exp)
  "Theorems Constructors"
  (interactive "p")
  (shell-command (concat "thconstr "  
			 (read-string  (concat "thconstr [-f FileName] Article:ThNumber (Default: " (mizar-ref-at-point) "): " )
				       nil nil      (mizar-ref-at-point))
			 )))


(defun mizar-scconstr (&optional whole-exp)
  "Schemes Constructors"
  (interactive "p")
  (shell-command (concat "scconstr "  
			 (read-string  (concat "scconstr [-f FileName] Article:ScNumber (Default: " (mizar-ref-at-point) "): " )
				       nil nil      (mizar-ref-at-point))
			 )))


(defun mizar-constr (&optional whole-exp)
  "Required Constructors Directives"
  (interactive "p")
  (shell-command (concat "constr "  
			 (read-string  (concat "constr [-f FileName] Article:[def|sch|...] Number (Default: " (mizar-ref-at-point) "): " )
				       nil nil      (mizar-ref-at-point))
			 )))

(defvar mizar-error-start "::>")

(defun mizar-end-error (result pos oldpos)
  "Common end for mizar-next-error and mizar-previous-error"
  (if result
      (let ((find (concat "^::>[ \t]*\\(" result ":.*\\)[ \t]*$")))
	(goto-char (point-max))
	(re-search-backward find (point-min) t)
	(message (match-string 1))
	(goto-char pos))
    (goto-char oldpos) 
    (ding)
    (message "No more errors!!")
    nil ))

(defun mizar-next-error ()
  "Go to the next error in a mizar text, return nil if not found
if found end on the first number of the error"
  (interactive)
  (let ((oldpos (point))
	(inerrl nil) ;; tells if we strat from an error line
	result pos)
    (beginning-of-line)
    (if (looking-at mizar-error-start)
	(progn
	  (goto-char (match-end 0))  ;; skip the error start
	  (if (< (point) oldpos)     ;; we were on an error or between
	      (progn
		(goto-char oldpos)
		(if (looking-at "[0-9]+") ;; on error
		    (forward-word 1))))
	  (skip-chars-forward "\t ,*")  ;; now next error or eoln
	  (if (looking-at "[0-9]+")
	    (setq pos (point) result (match-string 0)))))
    (if (and (not result)   
	     (re-search-forward mizar-error-start (point-max) t))
	(progn
	  (skip-chars-forward "\t ,*")
	  (if (looking-at "[0-9]+")
	    (setq pos (point) result (match-string 0)))))
    (mizar-end-error result pos oldpos)))

(defun mizar-previous-error ()
  "Go to the previous error in a mizar text, return nil if not found
if found end on the first number of the error"
  (interactive)
  (let ((oldpos (point))
	(inerrl nil) ;; tells if we strat from an error line
	result pos)
    (beginning-of-line)
    (if (looking-at mizar-error-start)
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
	     (re-search-backward mizar-error-start (point-min) t))
	(progn
	  (end-of-line)
	  (forward-word -1)
	  (if (looking-at "[0-9]+")
	    (setq pos (point) result (match-string 0)))))
    (mizar-end-error result pos oldpos)))
    
(defun mizar-strip-errors ()
  "Delete all lines beginning with ::> (i.e. error lines)"
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "^::>.*\n" nil t)
      (replace-match "" nil nil))
    ))

(defun mizar-hide-proofs (&optional beg end reverse)
  "Put @ before all proof keywords to disable checking, with prefix 
   unhide;"
  (interactive "r\nP")
  (save-excursion
    (let ((beg (or beg (point-min)))
	  (end (or end (point-max))))
    (goto-char beg)
    (message "(un)hiding proofs ...")
    (if reverse
	(while (re-search-forward "@proof\\b" end  t)
	  (replace-match "proof" nil nil))
      (while (re-search-forward "\\bproof\\b" end t)
	(replace-match "@proof" nil nil)))
    (message "... Done")
    )))

(defun make-theorems-string ()
  "Make string of all theorems"
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
  "Make string of all reservations before point"
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
))
		 ((memq font-lock-display-type '(grayscale greyscale
							   grayshade greyshade))
		  '(
		    (mizar-builtin-face nil nil nil nil t)
		    (mizar-exit-face nil nil nil nil t)
))
		 (dark-bg 		; dark colour background
		  '(
		    (mizar-builtin-face "LightSkyBlue" nil nil nil nil)
		    (mizar-exit-face "green" nil nil nil nil)
))
		 (t			; light colour background
		  '(
		    (mizar-builtin-face "Orchid" nil nil nil nil)
		    (mizar-exit-face "ForestGreen" nil nil nil nil)
)))))

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
		"\\<\\(and\\|antonym\\|attr\\|as\\|assume\\|be\\|begin\\|being\\|canceled\\|case\\|cases\\|cluster\\|coherence\\|compatibility\\|consider\\|consistency\\|constructors\\|contradiction\\|correctness\\|clusters\\|def\\|deffunc\\|definition\\|definitions\\|defpred\\|environ\\|equals\\|ex\\|existence\\|for\\|func\\|given\\|hence\\|\\|requirements\\|holds\\|if\\|iff\\|implies\\|irreflexivity\\|it\\|let\\|means\\|mode\\|not\\|notation\\|of\\|or\\|otherwise\\|\\|over\\|per\\|pred\\|provided\\|qua\\|reconsider\\|redefine\\|reflexivity\\|reserve\\|scheme\\|schemes\\|signature\\|struct\\|such\\|suppose\\|synonym\\|take\\|that\\|thus\\|then\\|theorems\\|vocabulary\\|where\\|associativity\\|commutativity\\|connectedness\\|irreflexivity\\|reflexivity\\|symmetry\\|uniqueness\\|transitivity\\|idempotence\\|antisymmetry\\|projectivity\\|involutiveness\\)\\>" 
		;;		1 'mizar-builtin-face
		1 font-lock-variable-name-face))

	      
	     
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
	      ))
	    ((eq major-mode 'mizar-inferior-mode)
	     (list
	     
	      keywords))
	    ((eq major-mode 'compilation-mode)
	     (list
	      
	      keywords))))
	  ))))




(defun mizar-mode ()
  " Major mode for editing mizar texts 
functions: 
      syntax highlighting .. put (global-font-lock-mode t) into your
                             .emacs file to enable it
      basic indentation 
      C-c C-m ............ runs Mizar on current .miz buffer, refreshes it
                           and goes to first error found, needs file miz1 in path
      C-c C-n ............ goes to next error and displays its explanation
                           in minibuffer
      C-c C-p ............ goes to previous error and displays its explanation
                           in minibuffer
      C-c C-e ............ deletes all error lines added by Mizar 
                           (lines starting with ::>)
      C-c C-c ............ comments selected region
      C-u C-c C-c ........ uncomments selected region
      M-C-\\ .............. indents selected region
      TAB ................ indents line   
      C-c C-f ............ interface to findvoc
      C-c C-l ............ interface to listvoc
      C-c C-t ............ interface to constr 
      C-c C-s ............ interface to scconstr ...obsolete now by constr
      C-c C-h ............ runs irrths on current buffer, refreshes it 
                            and goes to first error found, needs file miz3 in path 
      C-c C-i or C-c TAB.. runs relinfer on current buffer, refreshes it 
                            and goes to first error found, needs file miz3 in path 
      C-c C-y ............ runs relprem on current buffer, refreshes it 
                            and goes to first error found, needs file miz3 in path 
      C-c C-v ............ runs irrvoc on current buffer, refreshes it 
                            and goes to first error found, needs file miz3 in path 
      C-c C-a ............ runs inacc on current buffer, refreshes it 
                            and goes to first error found, needs file miz3 in path 
      C-c C-r ............ shows all reservations before current point
      C-c C-z ............ makes summary of theorems in current article 
      M-;     ............ runs mizar-symbol-def, see its doc.
      mouse-3 ............ also mizar-symbol-def
      M-. ................ shows theorem, definition or scheme with label LABEL, 
                           needs to run stags.pl  in the directory $MIZFILES/abstr 
                           before start of the work
      S-down-mouse-3  ............ mizar-symbol-def with no completion
      S-down-mouse-1  ............ mizar-show-ref with no completion
      S-down-mouse-2  ............ pops up menu of visited symbols to go to"      


  (interactive)
  (kill-all-local-variables)
					;  (set-syntax-table text-mode-syntax-table)
  (use-local-map mizar-mode-map)
					;  (setq local-abbrev-table text-mode-abbrev-table)
  (setq major-mode 'mizar-mode)
  (setq mode-name "mizar")
  (setq local-abbrev-table mizar-mode-abbrev-table)
  (mizar-mode-variables)
  (setq buffer-offer-save t)
  (setq imenu-case-fold-search nil)
  (setq imenu-generic-expression mizar-imenu-expr)
  (if (featurep 'speedbar)
      (progn
	(speedbar-add-supported-extension ".miz")
	(setq speedbar-use-imenu-flag t
	      speedbar-show-unknown-files nil
	      speedbar-special-mode-expansion-list t
	      speedbar-tag-hierarchy-method mizar-sb-trim-hack
;;'(simple-group trim-words)
;;'('speedbar-trim-words-tag-hierarchy 'trim-words)
)))
  (run-hooks  'mizar-mode-hook)
;  (define-key mizar-mode-map [(C-S-down-mouse-2)]   'hs-mouse-toggle-hiding)
)

(defvar mizar-sb-trim-hack
(cond ((intern-soft "trim-words") (list (intern "trim-words")))
      ((intern-soft  "speedbar-trim-words-tag-hierarchy")
       (list (intern "speedbar-trim-words-tag-hierarchy"))))
"Hack ensuring proper trimming across various speedbar versions"
)

;; Menu for the mizar editing buffers
(defvar mizar-menu
  '(list  "Mizar"
	  ["Visited symbols" mouse-find-tag-history t]
	  '("Goto errors"
	    ["Next error"  mizar-next-error t]
	    ["Previous error" mizar-previous-error t]
	    ["Remove error lines" mizar-strip-errors t])
	  "-"
	  ["View symbol def" mizar-symbol-def t]
	  ["Show reference" mizar-show-ref t]
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
	  ["Mizar Compile" mizar-compile (not (eq mizar-emacs 'winemacs))]
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
      (easy-menu-define mizar-menu-map (current-local-map) "" menu))
     ((eq mizar-emacs 'xemacs)
      (easy-menu-add menu))
     ;; The default
     (t
      (easy-menu-define mizar-menu-map (current-local-map) "" menu))
     )))


(defun mizar-hs-forward-sexp (arg)
  "Function used by `hs-minor-mode' for `forward-sexp' in Java mode."
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
(add-hook 'mizar-mode-hook 'mizar-menu)
(add-hook 'mizar-mode-hook 'hs-minor-mode)
(add-hook 'mizar-mode-hook 'imenu-add-menubar-index)
;; adding this as a hook causes an error when opening
;; other file via speedbar, so we do it the bad way
;;(if (featurep 'speedbar)
;;    (add-hook 'mizar-mode-hook '(lambda () (speedbar 1))))
(if (featurep 'speedbar)
    (speedbar 1))


;; I want the tags in other window, probably some local machinery 
;; should be applied instead of a redefinition here
(defun speedbar-tag-find (text token indent)
  "For the tag TEXT in a file TOKEN, goto that position.
INDENT is the current indentation level."
  (let ((file (speedbar-line-path indent)))
    (speedbar-find-file-in-frame file)
    (save-excursion (speedbar-stealthy-updates))
    ;; Reset the timer with a new timeout when cliking a file
    ;; in case the user was navigating directories, we can cancel
    ;; that other timer.
    (speedbar-set-timer speedbar-update-speed)
    (switch-to-buffer-other-window (current-buffer))
    (goto-char token)
    (run-hooks 'speedbar-visiting-tag-hook)
    ;;(recenter)
    (speedbar-maybee-jump-to-attached-frame)
    ))





(provide 'mizar)
