;;; example setting for Mizar mode

 (global-font-lock-mode t)
 (setq load-path (cons (substitute-in-file-name "$MIZFILES") load-path))
 (autoload 'mizar-mode "mizar" "Major mode for editing Mizar articles." t)
 (setq auto-mode-alist (append '(  ("\\.miz" . mizar-mode)
                                   ("\\.abs" . mizar-mode))
 			      auto-mode-alist))
