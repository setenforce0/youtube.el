(require 'url)

(setq
 +cache+
 (let ((dir (concat user-emacs-directory "youtube/")))
   (prog1 dir
     (unless (file-exists-p dir)
       (make-directory dir))))

 +base-url+
 "https://www.googleapis.com/youtube/v3/"

 +scope+
 "https://www.googleapis.com/auth/youtube"

 +client-id+
 "457835332683-7k3hgag48hd5rpseahsik6s76cdd71kf.apps.googleusercontent.com"

 +client-secret+
 "dgRS0Qm9Z0Mi24QM1bk6rii4"

 +api-key+
 "AIzaSyCW0c4fXbykXueatnBnUGE2g9t1zThS_-Q"

 +auth-token+
 "Bearer ya29.Glt-BIU4iis31P4M1IHL4fjIVdLLtw_s8giU7Y_9Gz4a2s7cUoUHt8SU6vsl4uV_tYvwF_pylsA6vPKCPuHRbbOMJHOhJkV80Fh6j6IfH3gUHXViwI53dfcDfjz5"

 )

;; (epoch-last-time expiry-int refresh-token-string-from-google)

(cl-defun url-request (endpoint &optional (token *auth-token*))
  )

(defun refresh-key ()
  (destructuring-bind (last-time expiry refresh-token)
      *auth-info*
    (when (> (- (- (time-to-seconds) expiry) last-time) 0)
      )))

'(this that those)


(defun yt-search-videos (query authtoken)
  (request
   "https://www.googleapis.com/youtube/v3/search"
   :params `(("part" . "id,snippet") ("q" . ,query))
   :headers `(("Authorization" . ,(concat "Bearer " authtoken)))
   :parser 'json-read
   :success #'print-search))

()


(yt-search-videos "haskell" authtoken)
(switch-to-buffer "*youtube-search*")
ya29.Glt-BFV91uNGRu56V7uumrrdVsBZiGS0lqcAA_kMCzifpLoAmgkL4WAh50cp8zzMMZFsHb3vgOk1mNCws3Ua9VRi4hdvCtv7_a7jiD4_huMSlNSrqvzhlnv4ssMW
1/yg34AOcuY3IwXMX-3xiLcR4hWDQ3vNkxKeYdrMJQ1pc

(cl-defun print-search (&key data &allow-other-keys)
  (let ((buffer (get-buffer-create "*youtube-search*"))
        (results (elt (assoc-default 'items data) 0)))
    (erase-buffer buffer)
    (setq whatever (apply #'list (time-to-seconds) results))
    (with-current-buffer buffer
      (insert "CAN YOU HEAR ME")
      (loop for result across results do
            (insert (format "%s" (assoc-default 'snippet result)))))))

{"installed":{"client_id":"457835332683-7k3hgag48hd5rpseahsik6s76cdd71kf.apps.googleusercontent.com","project_id":"youtube-el","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://accounts.google.com/o/oauth2/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_secret":"dgRS0Qm9Z0Mi24QM1bk6rii4","redirect_uris":["urn:ietf:wg:oauth:2.0:oob","http://localhost"]}}
AIzaSyCW0c4fXbykXueatnBnUGE2g9t1zThS_-Q

(defun construct-params (url &rest params)
  (declare (indent 1))
  (let ((char "?"))
    (loop while params do
          (setq url (format "%s%s%s=%s" url char (pop params) (pop params))
                char "&")
          finally return url)))

(construct-params "http://google.com/"
  'test "this"
  'hello "world")

"http://google.com/?test=this&hello=world"

(cl-defun request-with-params (base callback &key headers params cbargs)
  (declare (indent 1))
  (message "%s" (apply #'construct-params base params))
  (let ((url-request-extra-headers headers))
    (url-retrieve (apply #'construct-params base params) callback cbargs t t)))

(request-with-params "http://google.com/"
  (lambda (status) (switch-to-buffer (current-buffer)))
  :params (list "q" "test" "test" "q")
  :headers '("Authorization" . "Test"))




(let ((url-request-extra-headers
       '("Authorization" . "whatever"))
      )
  (url-retrieve (cons)))
