;; April 6 2000 ... some more features added
;; April 3 2000, modified by Josef Urban (urban@kti.ms.mff.cuni.cz)
;; for use with Mizar  Version 6.0.01 (Linux/FPC)
;; some parts might also work with dos-emacs and dos mizar
;;
;; to use it, put it where your .el files are, and add following to to your
;; .emacs file ; see further instructions for the "miz1","miz3" and "MIZTAGS" files

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
;                           and goes to first error found, needs file miz1 (see further) in path
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
;      C-c C-t ............ interface to thconstr
;      C-c C-s ............ interface to scconstr
;      C-c C-h ............ runs irrths on current buffer, refreshes it 
;                           and goes to firts error found, needs file miz3 in path (see further)
;      C-c C-i or C-c TAB.. runs relinfer on current buffer, refreshes it 
;                           and goes to firts error found, needs file miz3 in path (see further)
;      C-c C-y ............ runs relprem on current buffer, refreshes it 
;                           and goes to firts error found, needs file miz3 in path (see further)
;      C-c C-v ............ runs irrvoc on current buffer, refreshes it 
;                           and goes to firts error found, needs file miz3 in path (see further)
;      C-c C-a ............ runs inacc on current buffer, refreshes it 
;                           and goes to firts error found, needs file miz3 in path (see further)
       



; this is file MIZTAGS, in fact, it is a single line, so you can simply run it in shell. 
; It needs to be executed in the disrectory $MIZFILES/abstr

;;;;;;;;; start of MIZTAGS file ;;;;;;;;;;;;;;;;;;;;;;;;;; 
; etags --language=none --regex='/scheme[ \n]*\([^ {]*\)[ \n]*{/\1/' --regex='/.*:: \([^ \n:]+\):\([0-9]+\)/\1:\2/' --regex='/.*:: \([^ \n:]+\):def *\([0-9]+\)/\1:def \2/' *.abs
;;;;;;;;; end of MIZTAGS file   ;;;;;;;;;;;;;;;;;;;;;;;;;; 


; this is file miz3 needed for various Irrelevant ( :-) ) Utilities. Needs to be executable 
; and in the bin directory of the distribution.

;;;;;;;;; start of miz3 file ;;;;;;;;;;;;;;;;;;;;;;;;;; 
; #!/bin/sh
; $1 $2
; errflag $2
; addfmsg $2 $MIZFILES/mizar
;;;;;;;;; end of miz3 file   ;;;;;;;;;;;;;;;;;;;;;;;;;;


; this is file miz1 needed for C-c C-m, you get it by replacing all references to
; "text/$1" by just "$1" in the shell script mizf, in the bin dir of the 
; 6.0.01 (Linux/FPC) distributuiion. It needs to be executable.  

;;;;;;;;; start of miz1 file ;;;;;;;;;;;;;;;;;;;;;;;;;;
; #!/bin/sh
; #
; #          Mizar Verifier, example shell command
; #

; mizf_exit()
; {
;  if test -e "$1.err"
;   then rm "$1.err"
;  fi
;  if test -e $1.'$$$'
;   then rm $1.'$$$'
;  fi
; }

; accomodate()
; {
; makeenv "$1"
; if test ! -s "$1.err" && test -e "$1.err"
;  then
;   verify "$1"
;  else
;   errflag "$1"
;   addfmsg "$1" $MIZFILES/mizar
; fi
; }

; verify()
; {
; verifier "$1"
; errflag "$1"
; addfmsg "$1" $MIZFILES/mizar
; }

; if test -z "$1"
;  then
;   echo '> Error : Missing parameter'
;  else
;   accomodate "$1"
;   mizf_exit "$1"
; fi
;;;;;;;;;;;;;;;;;;; end of miz1 file ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; to do: better indentation,
;           show references using tags and M-. (in another buffer?) ... done in version 1.1.
;           find out why it hangs during C-c C-m when switching to another buffer,
;           interface to other Mizar commands (findvoc, etc?) ......... done in version 1.1.
;           menu ...................................................... done in version 1.1.
;           ..... (whatever you like) 
          





    
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

(eval-when-compile
  (require 'compile)
  (require 'font-lock)
  (require 'imenu)
  (require 'info)
  (require 'shell)
  )

(require 'comint)
(require 'easymenu)



(defvar mizar-mode-syntax-table nil)
(defvar mizar-mode-abbrev-table nil)
(defvar mizar-mode-map nil)

(font-lock-mode)
(defvar mizar-indent-width 3)

(if mizar-mode-syntax-table
    ()
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?\" "_" table)
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
  (setq comment-indent-function 'mizar-comment-indent))


(defun mizar-mode-commands (map)
  (define-key map "\t" 'mizar-indent-line)
  (define-key map "\r" 'newline-and-indent))


(if mizar-mode-map
    nil
  (setq mizar-mode-map (make-sparse-keymap))
  (define-key mizar-mode-map  "\C-c\C-m" 'mizar-it)
  (define-key mizar-mode-map  "\C-c\C-n" 'mizar-next-error)
  (define-key mizar-mode-map  "\C-c\C-p" 'mizar-previous-error)
  (define-key mizar-mode-map "\C-c\C-e" 'mizar-strip-errors)
  (define-key mizar-mode-map "\C-c\C-c" 'comment-region)
  (define-key mizar-mode-map "\C-c\C-f" 'mizar-findvoc)
  (define-key mizar-mode-map "\C-c\C-l" 'mizar-listvoc)
  (define-key mizar-mode-map "\C-c\C-t" 'mizar-thconstr)
  (define-key mizar-mode-map "\C-c\C-s" 'mizar-scconstr)

  (define-key mizar-mode-map "\C-c\C-h" 'mizar-irrths)
  (define-key mizar-mode-map "\C-c\C-v" 'mizar-irrvoc)
  (define-key mizar-mode-map "\C-c\C-i" 'mizar-relinfer)
  (define-key mizar-mode-map "\C-c\C-y" 'mizar-relprem)
  (define-key mizar-mode-map "\C-c\C-a" 'mizar-inacc)

  (define-key mizar-mode-map "\M-." 'mizar-show-ref)
  (mizar-mode-commands mizar-mode-map))

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
	      ((looking-at "\\(proof\\|now\\)") (setq more t)))
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
	  (cond ((looking-at "\\(proof\\|now\\)")
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









(defun mizar-ref-at-point ()
  "Return the reference at the point."
  (save-excursion
    (skip-chars-backward "^ \n,;()")
    (if (or (looking-at "\\([^ \n:,;]+:def [0-9]+\\)")
	    (looking-at "\\([^ \n:,;]+:[0-9]+\\)")
	    (looking-at "\\([^ \n:,;()]+\\)[ \n,;:.()]"))
	(buffer-substring-no-properties (match-beginning 1) (match-end 1))
      (current-word))
    ))





(defun mizar-show-ref (&optional whole-exp)
  "show theorem, definition or scheme with label LABEL"
  (interactive "p")
  (find-tag-other-window (read-string  (concat "Show reference (Default: " (mizar-ref-at-point) "): " )
				       nil nil      (mizar-ref-at-point))))






(defconst mizar-error-regexp "\\*\\([0-9]+\\)" "regexp used to locate error messages in a mizar text")

(defvar mizar-region-count 0  "number of regions on mizar-region-stack")

(defvar mizar-mode-map nil "keymap used by mizar mode..")


(defun mizar-it (&optional whole-exp)
  "run mizar on the text in the current .miz buffer"
  (interactive "p")
  (cond ((not (string-match "miz$" (buffer-file-name)))
 	 (message "Not in .miz file!!"))
	(t 
	 (save-buffer)
	 (setq mizarg (substring (buffer-name) 0 (string-match ".miz" (buffer-name))  ))
	 (cond ((get-buffer "*mizar-output*") 
		(display-buffer "*mizar-output*"))
	       (t
		(save-window-excursion 
		  (ansi-term "bash")
		  (rename-buffer "*mizar-output*"))
		(display-buffer "*mizar-output*")))
	 (progn
	   (term-exec "*mizar-output*" "run-mizar" "miz1" nil (list mizarg))
	   (end-of-buffer-other-window 0)
	   (while  (term-check-proc "*mizar-output*") 
	     (sit-for 5))
	   (revert-buffer t t t)
	   (setq pos (point)) 
	   (goto-char (point-min))
	   (mizar-next-error)
	   (if (= (point) (point-min)) (goto-char pos) t)) 
	 )))





(defun mizar-error-util (util &optional whole-exp)
  "run mizar uitility util  on the text in the current .miz buffer"
  (interactive "p")
  (cond ((not (string-match "miz$" (buffer-file-name)))
 	 (message "Not in .miz file!!"))
	(t 
	 (save-buffer)
	 (setq mizarg (substring (buffer-name) 0 (string-match ".miz" (buffer-name))  ))
	 (cond ((get-buffer "*mizar-output*") 
		(display-buffer "*mizar-output*"))
	       (t
		(save-window-excursion 
		  (ansi-term "bash")
		  (rename-buffer "*mizar-output*"))
		(display-buffer "*mizar-output*")))
	 (progn
	   (term-exec "*mizar-output*" util "miz3" nil (list util mizarg))
	   (end-of-buffer-other-window 0)
	   (while  (term-check-proc "*mizar-output*") 
	     (sit-for 5))
	   (revert-buffer t t t)
	   (setq pos (point)) 
	   (goto-char (point-min))
	   (mizar-next-error)
	   (if (= (point) (point-min)) (goto-char pos) t)) 
	 )))





(defun mizar-irrths (&optional whole-exp)
  (interactive "p")
  (mizar-error-util "irrths"))

(defun mizar-irrvoc (&optional whole-exp)
  (interactive "p")
  (mizar-error-util "irrvoc"))

(defun mizar-inacc (&optional whole-exp)
  (interactive "p")
  (mizar-error-util "inacc"))

(defun mizar-relinfer (&optional whole-exp)
  (interactive "p")
  (mizar-error-util "relinfer"))

(defun mizar-relprem (&optional whole-exp)
  (interactive "p")
  (mizar-error-util "relprem"))




(defun mizar-findvoc (&optional whole-exp)
  "find vocabulary for a symbol"
  (interactive "p")
  (shell-command (concat "findvoc "  
			 (read-string  (concat "findvoc [-iswGKLMORUV] SearchString (Default: " (current-word) "): " )
				       nil nil      (current-word))
			 )))

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




(defun mizar-next-error ()
  "Go to the next error in a mizar text"
  (interactive)
  (progn (goto-char (+ (point) 1))	; incase we just did previous-error
	 (cond ((re-search-forward mizar-error-regexp (point-max) t)
		(match-string 1)
		(setq pos (point)) 
		(goto-char (point-max))
		(setq find (concat "^::> *\\(" (match-string 1) ":.*\\) *$"))
		(re-search-backward find (point-min) t)
		(message (match-string 1))
		(goto-char pos))
	       (t
		(progn
		  (goto-char (- (point) 1)) ; undo the change
		  (ding)
		  (message "No more errors!!"))))))


(defun mizar-previous-error ()
  "Go to the previous error in a mizar text"
  (interactive)
  (progn
    (goto-char (- (point) 1))
    (while (looking-at "[0-9]") (backward-char 1)) ;incase we just did next-error
    (cond ((re-search-backward mizar-error-regexp (point-min) t)
	   (match-string 1)
	   (setq pos (point)) 
	   (goto-char (point-max))
	   (setq find (concat "^::> *\\(" (match-string 1) ":.*\\) *$"))
	   (re-search-backward find (point-min) t)
	   (message (match-string 1))
	   (goto-char pos))
	  (t
	   (progn
	     (goto-char (+ (point) 1))	; undo the change
	     (ding)
	     (message "No more errors!!"))))))



(defun mizar-strip-errors ()
  "Delete all lines beginning with ::> (i.e. error lines)"
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "^::>.*\n" nil t)
      (replace-match "" nil nil))
    ))




(setq font-lock-defaults
      '(mizar-font-lock-keywords nil nil ((?_ . "w"))))

(make-local-variable 'comment-start)
(setq comment-start "::")


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
		  '((mizar-warning-face nil nil t t nil)
		    (mizar-builtin-face nil nil nil nil t)
		    (mizar-redo-face nil nil nil t nil)
		    (mizar-exit-face nil nil nil nil t)
		    (mizar-exception-face nil nil t t t)))
		 ((memq font-lock-display-type '(grayscale greyscale
							   grayshade greyshade))
		  '((mizar-warning-face nil nil t t nil)
		    (mizar-builtin-face nil nil nil nil t)
		    (mizar-redo-face nil nil nil t nil)
		    (mizar-exit-face nil nil nil nil t)
		    (mizar-exception-face nil nil t t t)))
		 (dark-bg 		; dark colour background
		  '((mizar-warning-face "red" nil t nil nil)
		    (mizar-builtin-face "LightSkyBlue" nil nil nil nil)
		    (mizar-redo-face "darkorchid" nil nil nil nil)
		    (mizar-exit-face "green" nil nil nil nil)
		    (mizar-exception-face "black" "Khaki" t nil nil)))
		 (t			; light colour background
		  '((mizar-warning-face "red" nil t nil nil)
		    (mizar-builtin-face "Orchid" nil nil nil nil)
		    (mizar-redo-face "darkorchid" nil nil nil nil)
		    (mizar-exit-face "ForestGreen" nil nil nil nil)
		    (mizar-exception-face "black" "Khaki" t nil nil))))))

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
	       '("\\<\\(proof\\|now\\|end\\)"
		 0 'font-lock-keyword-face ))
	      (comments '("::[^\n]*"  0 'font-lock-comment-face ))
	      (refs '("\\( by\\|from\\)[^;.]*" 0 'font-lock-type-face))
	      (extra '("&"  0  'mizar-builtin-face))
	      (keywords			; directives (queries)
	       (list
		"\\<\\(and\\|antonym\\|attr\\|as\\|assume\\|be\\|begin\\|being\\|canceled\\|case\\|cases\\|cluster\\|coherence\\|compatibility\\|consider\\|consistency\\|constructors\\|contradiction\\|correctness\\|clusters\\|def\\|deffunc\\|definition\\|definitions\\|defpred\\|environ\\|equals\\|ex\\|existence\\|for\\|func\\|given\\|hence\\|hereby\\|\\|requirements\\|holds\\|if\\|iff\\|implies\\|irreflexivity\\|it\\|let\\|means\\|mode\\|not\\|notation\\|of\\|or\\|otherwise\\|\\|over\\|per\\|pred\\|provided\\|qua\\|reconsider\\|redefine\\|reflexivity\\|reserve\\|scheme\\|schemes\\|signature\\|struct\\|such\\|suppose\\|synonym\\|take\\|that\\|thus\\|then\\|theorems\\|vocabulary\\|where\\|associativity\\|commutativity\\|connectedness\\|irreflexivity\\|reflexivity\\|symmetry\\|uniqueness\\|transitivity\\)\\>" 
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
      M-. ................ shows theorem, definition or scheme with label LABEL, 
                            needs to run MIZTAGS  in the directory $MIZFILES/abstr 
                            before start of the work
      C-c C-f ............ interface to findvoc
      C-c C-l ............ interface to listvoc
      C-c C-t ............ interface to thconstr
      C-c C-s ............ interface to scconstr
      C-c C-h ............ runs irrths on current buffer, refreshes it 
                            and goes to firts error found, needs file miz3 in path 
      C-c C-i or C-c TAB.. runs relinfer on current buffer, refreshes it 
                            and goes to firts error found, needs file miz3 in path 
      C-c C-y ............ runs relprem on current buffer, refreshes it 
                            and goes to firts error found, needs file miz3 in path 
      C-c C-v ............ runs irrvoc on current buffer, refreshes it 
                            and goes to firts error found, needs file miz3 in path 
      C-c C-a ............ runs inacc on current buffer, refreshes it 
                            and goes to firts error found, needs file miz3 in path "

  (interactive)
  (kill-all-local-variables)
					;  (set-syntax-table text-mode-syntax-table)
  (use-local-map mizar-mode-map)
					;  (setq local-abbrev-table text-mode-abbrev-table)
  (setq major-mode 'mizar-mode)
  (setq mode-name "mizar")
  (mizar-mode-variables)
  (setq buffer-offer-save t)
  (run-hooks  'mizar-mode-hook))


;; Menu for the mizar editing buffers
(defvar mizar-menu
  '(list  "Mizar" 	      
	  '("Goto errors"
	    ["Next error"  mizar-next-error t]
	    ["Previous error" mizar-previous-error t]
	    ["Remove error lines" mizar-strip-errors t])
	  ["Show reference" mizar-show-ref t]
	  ["Run Mizar" mizar-it t]
	  "-"
	  (list "Voc. & Constr. Utilities"
		["Findvoc" mizar-findvoc t]
		["Listvoc" mizar-listvoc t]		   
		["Thconstr" mizar-thconstr t]
		["Scconstr" mizar-scconstr t])	  
	  '("Irrelevant Utilities"
	    ["Irrelevant Theorems" mizar-irrths t]
	    ["Irrelevant Inferences" mizar-relinfer t]
	    ["Irrelevant Premises" mizar-relprem t]
	    ["Irrelevant Vocabularies" mizar-irrvoc t]
	    ["Inaccessible Items" mizar-inacc t])
	  "-"
	  ["Comment region" comment-region t]
	  ["Uncomment region" (comment-region (region-beginning) (region-end) -1) t]
	  "-"
	  '("Indent"
	    ["Line" mizar-indent-line t]
	    ["Region" indent-region t]
	    ["Buffer" mizar-indent-buffer t])
	  '("Fontify"
	    ["Buffer" font-lock-fontify-buffer t])
	  )
  "The definition for the menu in the editing buffers."
  )



(defvar mizar-emacs 
  (if (string-match "XEmacs\\|Lucid" emacs-version)
      'xemacs
    'gnuemacs)
  "The variant of Emacs we're running.
Valid values are 'gnuemacs and 'xemacs.")


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



(add-hook 'mizar-mode-hook 'mizar-menu)

(visit-tags-table (substitute-in-file-name "$MIZFILES/abstr"))

(provide 'mizar)