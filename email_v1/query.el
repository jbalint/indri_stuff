(setq query-index-file "/home/jbalint/sw/indri_stuff/email_v1_index")
(setq query-db-file "/home/jbalint/sw/indri_stuff/email_v1.kch")

(defun kch-db-get (key)
  "Get a value from a KCH db"
  (let ((output (shell-command-to-string
				 (concat "kchashmgr get " query-db-file " " key))))
	(if (string-match "DB::get failed" output)
		(progn
		  (message (concat "kch-db-get failed for key: " key))
		  "")
	  (replace-regexp-in-string
	   " *\n" "" output))))

(defun msg-get-field (msg-id field)
  (kch-db-get (concat msg-id "." field)))

(defun email-result-build-line (line)
  ;; Would be nice to have TEXT too for preview
  (let* ((msg-id (nth 1 (split-string line "\t")))
		 (msg-subject (msg-get-field msg-id "TITLE"))
		 (msg-from (msg-get-field msg-id "FROM"))
		 (msg-to (msg-get-field msg-id "TO"))
		 (msg-cc (msg-get-field msg-id "CC"))
		 (msg-date (msg-get-field msg-id "DATE")))
  (with-current-buffer email-query-buf
	(end-of-buffer)
	(insert (format "%s   %.20s   %s\n" msg-date msg-from msg-subject)))))

(defun email-result-build-filter (proc line)
  (dolist (x (split-string line "\n"))
	(if (string-match "^-[0-9]+" x)
		(email-result-build-line x))))

(defun email-query (query-string)
  (let* ((tmpbuf (generate-new-buffer "*email-query-result*"))
		 (proc (start-process
				"indri" " *IndriRunQuery*" "IndriRunQuery"
				(concat "-index=" query-index-file)
				(concat "-query=" query-string))))
	(setq email-query-buf tmpbuf)
	(with-current-buffer email-query-buf
	  (insert (format "%s  %.20s  %s\n" "Date" "From" "Subject")))
	(set-process-filter proc 'email-result-build-filter)
	(while (accept-process-output proc 1000))
	(display-buffer tmpbuf)
))
	;;(kill-buffer (process-buffer proc))))
