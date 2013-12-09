;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Org mode export to TREC format ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; boring, undecorated stuff
(defun org-trec-export-raw (element contents info)
  contents)
(defun org-trec-export-value (element contents info)
  (org-element-property :value element))

(defun org-trec-link (link desc info)
  desc)
(defun org-trec-plain-text (text info)
  text)
;; i don't often use it in this context...
(defun org-trec-subscript (element contents info)
  (concat "_" contents))

;; other stuff
(defun org-trec-headline (headline contents info)
 ;;(with-output-to-string (princ (org-element-property :title headline)))
  (concat (org-export-data (org-element-property :title headline) info) "\n" contents
		  ;;(with-output-to-string (princ (org-element-contents headline)))
		  )
)

(defun org-trec-planning (planning contents info)
  (message (with-output-to-string (princ (org-element-property :closed planning))))
  (let ((deadline (org-element-property :deadline planning))
		(scheduled (org-element-property :scheduled planning))
		(closed (org-element-property :closed planning)))
	;; TODO may be multiple, can't be contingent like this
	(if deadline
		(concat "Deadline: " (org-timestamp-to-date-string deadline))
	  (if scheduled
		  (concat "scheduled: " (org-timestamp-to-date-string scheduled))
		(if closed
			(concat "closed: " (org-timestamp-to-date-string closed)))))))

(defun org-trec-section (section contents info)
  ;; TODO put this with the output
  ;;(message (concat "Section category: " (org-export-get-category section info)))
  contents)

(defun org-timestamp-to-date-string (timestamp)
  "Convert an Org mode timestamp object to a string with time if given. e.g. 2013-01-01 10:13"
  (let ((date-part
		 (mapconcat 'number-to-string
					`(,(org-element-property :year-start timestamp)
					  ,(org-element-property :month-start timestamp)
					  ,(org-element-property :day-start timestamp))
					"-"))
		(hour-part (org-element-property :hour-start timestamp)))
	(if hour-part
		(concat date-part " " (number-to-string hour-part) ":"
				(number-to-string (org-element-property :minute-start timestamp)))
	  date-part)))

;; http://orgmode.org/worg/dev/org-export-reference.html
;; c.f. org-export-registered-backends
(when (require 'ox nil 'noerror)
  (org-export-define-backend
   'trec
   '((bold . org-trec-export-raw)
	 (center-block . org-trec-export-raw)
	 (clock . nil)
	 (code . org-trec-export-value)
	 (comment . nil)
	 (comment-block . nil)
	 (drawer . nil)
	 (dynamic-block . nil)
	 (entity . nil)
	 (example-block . nil)
	 (export-block . nil)
	 (export-snippet . nil)
	 (fixed-width . nil)
	 (footnote-reference . nil)
	 (headline . org-trec-headline)
	 (horizontal-rule . nil)
	 (inline-src-block . nil)
	 (inlinetask . nil)
	 (inner-template . nil)
	 (italic . org-trec-export-raw)
	 (item . org-trec-export-raw)
	 (keyword . nil)
	 ;; latex-environment, latex-fragment ..
	 (line-break . nil)
	 (link . org-trec-link)
	 (paragraph . org-trec-export-raw)
	 (plain-list . org-trec-export-raw)
	 ;;(plain-text . org-trec-export-value)
	 (plain-text . org-trec-plain-text)
	 (planning . org-trec-planning)
	 (quote-block . nil)
	 (quote-section . nil)
	 (radio-target . nil)
	 (section . org-trec-section)
	 (special-block . nil)
	 (src-block . org-trec-export-value)
	 (statistics-cookie . nil)
	 (strike-through . org-trec-export-raw)
	 (subscript . org-trec-subscript)
	 (superscript . org-trec-export-raw)
	 (table . nil)
	 (table-cell . nil)
	 (table-row . nil)
	 (target . nil)
	 (template . nil)
	 (timestamp . org-trec-export-raw)
	 (underline . org-trec-export-raw)
	 (verbatim . org-trec-export-value)
	 (verse-block . nil))
   :options-alist '((:with-planning nil "p" t))
))

(defun org-trec-export ()
  (interactive)
  (let ((outbuf
		 (org-export-to-buffer 'trec "*Org TREC Export*")))
	(when org-export-show-temporary-export-buffer
	  (switch-to-buffer-other-window outbuf))))
