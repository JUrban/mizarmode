;; pretty simple-minded hack for getting and sending exercises

;; should be rewritten using w3, but that means installing w3
;; second possibility is e.g. using perl, but that means
;; installing perl on Window$


(defvar edu-test-session-number 0 
"The session number, valid only if nonzero")

(defvar edu-test-problem-number 0 
"The problem number, valid only if nonzero")

(defvar edu-test-file-name "exercise.miz"
"Name of the file which stores the current exercise.
If the file exists, we will save it to `edu-test-old-name' first")

(defvar edu-test-old-name "exercise.old"
"Name of the backup file which stores the old exercise.")

(defun edu-test-user-logged ()
"Telling if user is logged"
(not (eq edu-test-session-number 0)))

(defvar edu-test-server "merak.pb.bialystok.pl")

(defvar edu-test-log-cgi "/cgi-bin/edu/log.cgi"
"Used for login and logout, with variables 'user' and 'password',
returns a session_number for login")

(defvar edu-test-result-cgi "/cgi-bin/edu/result.cgi"
"Used for sending results for a logged user, witha variables 'session_number'
'text', 'problem_number'")

(defvar edu-test-problem-cgi "/cgi-bin/edu/problem.cgi"
"Used for obtaining problems for a logged user, with variables 'session_number'
and 'problem_number'")

;;; does not work
;(defvar edu-test-login-prompt "Login as user: " )
; "Zaloguj sie jako: "
(defvar edu-test-password-prompt "Password for user " )
; "Haslo uzytkownika "
;(defvar edu-test-problem-prompt "Problem number " )
; "Numer problemu "


(defvar edu-test-bad-login-msg "Bad login or password, try again")
(defvar edu-test-bad-problem-msg "Bad problem number, try again")
(defvar edu-test-no-session-msg "No session currently open, log in first!")
(defvar edu-test-no-problem-msg "No problem currently open, get problem first!")
(defvar edu-test-renaming-msg 
(concat "Renaming existing file " edu-test-file-name 
	" to " edu-test-old-name))


(defun edu-test-get-problem (nr)
"Get problem number NR, put it into buffer `edu-test-file-name'
and display it.
If file named `edu-test-file-name' exists, rename it to `edu-test-old-name',
and possibly kill the buffer containing it"
(interactive "nProblem_number: ")
;(concat "n" edu-test-problem-prompt))
(if (eq edu-test-session-number 0)
    (error edu-test-no-session-msg))
(let* ((cgi (concat edu-test-problem-cgi "?session_number=" 
		    (int-to-string edu-test-session-number)
		    "&problem_number=" (int-to-string nr)))
       (reply (edu-test-get-response cgi))
       nbuffer)
  (if (string-equal reply "")
      (error edu-test-bad-problem-msg))
  (when (file-exists-p edu-test-file-name)
    (message edu-test-renaming-msg)
    (rename-file edu-test-file-name edu-test-old-name t)
    (if (get-buffer edu-test-file-name)
	(kill-buffer edu-test-file-name)))
  (setq edu-test-problem-number nr)
  (setq nbuffer (find-file edu-test-file-name))
  (switch-to-buffer nbuffer)
  (insert reply)
  (save-buffer)
  (edu-test-setup)))
  
(defun edu-test-send-result ()
(interactive)
(if (eq edu-test-session-number 0)
    (error edu-test-no-session-msg))
(if (eq edu-test-problem-number 0)
    (error edu-test-no-problem-msg))
(let ((cname (buffer-name))
      (nbuffer (get-buffer edu-test-file-name)))
  (when (not (eq (current-buffer) nbuffer))
    (cond 
     (nbuffer
      (switch-to-buffer nbuffer)
      (error "Displaying buffer %s, try again!" edu-test-file-name))
     ((file-exists-p edu-test-file-name)
      (find-file edu-test-file-name)
      (error "Displaying buffer %s, try again!" edu-test-file-name))
     (t
      (error "No file %s exists, get it from the server first" 
	     edu-test-file-name))))
  ;; now we know that we are in the right buffer
  (let* ((text (query-handle-chars-cgi
	       (buffer-substring-no-properties
		(point-min) (point-max))))
	(data (concat  "session_number=" 
			 (int-to-string edu-test-session-number)
			 "&problem_number=" 
			 (int-to-string edu-test-problem-number)
			 "&text=" text))
	(reply (string-to-number 
		(edu-test-get-response edu-test-result-cgi data))))
	(if (eq reply 0)
	    (error "Server did not accept your result!"))
	(write-file (concat edu-test-file-name "." 
			    (int-to-string edu-test-problem-number)))
	(setq edu-test-problem-number 0)
	(message "Server stored your result, get the next problem!"))))
	

(defun edu-test-login (user)
"returns the sesion number, if not sucessful, 0"
(interactive "sUser: "); edu-test-login-prompt))
 (let* ((passwd (read-string (concat edu-test-password-prompt user ": ")))
	(cgi (concat edu-test-log-cgi
			 "?user=" user ;(make-string 1 92) 
 "&password=" passwd))
	(reply (edu-test-get-response cgi))
	(session-number (string-to-number reply)))
   (setq edu-test-session-number session-number)
   (if (eq edu-test-session-number 0)
       (message edu-test-bad-login-msg))
   edu-test-session-number))

(defun edu-test-logout ()
"Logs out the current session"
(interactive)
(if (eq edu-test-session-number 0)
    (error edu-test-no-session-msg)
  (let* ((cgi (concat edu-test-log-cgi "?session_number=" 
		      (int-to-string edu-test-session-number))))
    (setq edu-test-session-number 0)
    (edu-test-get-response cgi))))

(defun edu-test-setup ()
(interactive)
(let ((newmap (make-sparse-keymap)))
  (set-keymap-parent newmap (current-local-map))
;   (define-key edu-test-mode-map  "\C-c\C-j" 'insert-mmlq-version)
(easy-menu-define edu-test-menu newmap
  "Menu used for getting and sending examples."
  '("Test"
    ["Login" edu-test-login :active (not (edu-test-user-logged))]
    ["Logout" edu-test-logout :active (edu-test-user-logged)]
    ["Get problem" edu-test-get-problem :active (edu-test-user-logged)]
    ["Send result" edu-test-send-result 
     :active (and (edu-test-user-logged) 
		  (not (eq 0 edu-test-problem-number)))]
	 ))
(use-local-map newmap)))


(defun alfanump (nr)
  (or (and (< nr 123) (< 96 nr))
      (and (< nr 91) (< 64 nr))
      (and (< nr 58) (< 47 nr))))

(defun query-handle-chars-cgi (str)
"Replace nonalfanumeric chars in STR by %code."
(let ((slist (string-to-list str))
      (space (nreverse (string-to-list (format "%%%x" 32))))
      res codel)
;  (if (eq mizar-emacs 'xemacs)
;      (setq slist (mapcar 'char-to-int slist)))
  (while slist
    (let ((i (car slist)))
      (cond ((alfanump i)
	     (setq res (cons i res)))
;	    ((member i '(32 10 9 13))        ; "[ \n\t\r]"
;	     (setq res (append space res)))
	    (t
	     (setq codel (nreverse (string-to-list (format "%x" i))))
	     (if (eq (length codel) 1) (setq codel (nconc codel (list 48))))
	     (setq res (nconc codel (cons 37 res))))))
    (setq slist (cdr slist)))
  (concat (nreverse res))))

(defun edu-test-get-response (request &optional posted-data)
"Get the reply to request and clean-up"
(let* ((bufname (make-temp-name "tmp"))
       (abuffer (edu-test-get-http bufname edu-test-server 
				   request posted-data))
       reply)
  (with-current-buffer abuffer
    (setq reply (buffer-substring-no-properties (point-min) (point-max))))
  (kill-buffer abuffer)
  reply))

;; modified from Lisp:wikiarea.el by EdwardOConnor
;; we should use url.el or http-get.el, when they make it into distros
;; wget is good, but requires Window$ users to download it
(defun edu-test-get-http (bufname host request &optional posted-data)
  "Fetch http REQUEST from HOST, put result into buffer BUFNAME and return it.
Previous contents of BUFNAME is deleted.
If POSTED-DATA is non-nil, the request is POST instead of GET.
"
  (if (get-buffer bufname) (kill-buffer bufname))
  (let* ((proc (open-network-stream "GetHTTP" bufname host 80))
         (buf (process-buffer proc)))
    (if (not posted-data)
	(process-send-string proc 
			     (concat "GET " request " HTTP/1.0\r\n\r\n"))
      (process-send-string 
       proc 
       (concat "POST " request " HTTP/1.0\r\n"
	       "Content-type: application/x-www-form-urlencoded\r\n"
	       "Content-length: " 
	       (int-to-string (+ 2 (length posted-data)))
	       "\r\n\r\n" posted-data "\r\n" )))
    ;; Watch us spin and stop Emacs from doing anything else!
    (while (equal (process-status proc) 'open)
      (when (not (accept-process-output proc 180))
        (delete-process proc)
        (error "Network timeout!")))
    (delete-process proc)

    (with-current-buffer buf
      (goto-char (point-min))
      (if (looking-at "HTTP/[0-9.]+ \\([0-9]+\\) \\(.*\\)")
          (progn
            (forward-line 1)
            (while (looking-at "^.+[:].+")
              (forward-line 1))
            (forward-line 1)
            (delete-region (point-min) (point)))
        (error "Unable to fetch %s from %s." request host)))
    buf))

(provide 'edu-test)


