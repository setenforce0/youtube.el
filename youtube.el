;; (with-current-buffer (url-retrieve-synchronously "https://accounts.google.com/o/oauth2/v2/auth?scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fyoutube&response_type=code&state=security_token%3D138r5719ru3e1%26url%3Dhttps://oauth2.example.com/token&redirect_uri=urn:ietf:wg:oauth:2.0:oob&client_id=457835332683-7k3hgag48hd5rpseahsik6s76cdd71kf.apps.googleusercontent.com"))

;; ~ $ curl --data "code=4/Cf-PX285KJ5aHlmpIQaWbGHPJS6cMO4qWhVpsCAqUoQ&client_id=457835332683-7k3hgag48hd5rpseahsik6s76cdd71kf.apps.googleusercontent.com&client_secret=dgRS0Qm9Z0Mi24QM1bk6rii4&redirect_uri=urn:ietf:wg:oauth:2.0:oob&grant_type=authorization_code" https://www.googleapis.com/oauth2/v4/token
;; {
;; "access_token": "ya29.GluVBHKr9Sycw16XFVrxPfVrte1Jb3p5vXpqRj1flod4bpZC2pqxwWFsJ0B7MOJMuK4r5f5h3a53Oj32FsqNBJ_S8OqX9zldd6VJ1wIBZ4MNETKhI4aKBL9Vp9Cf",
;; "token_type": "Bearer",
;; "expires_in": 3600,
;; "refresh_token": "1/R6mS8UIWuh2-rKXKc1HAhdMnvQ8tCQzI4MJyCozuv0M"
;; }

;; ~ $ curl -i -G -d "channelId=UCgCflAd-1Yf7ffXjEYXbPUQ&part=snippet,contentDetails&key=AIzaSyCW0c4fXbykXueatnBnUGE2g9t1zThS_-Q" https://www.googleapis.com/youtube/v3/subscriptions

;; ~ $ curl -i -d "client_id=457835332683-7k3hgag48hd5rpseahsik6s76cdd71kf.apps.googleusercontent.com&client_secret=dgRS0Qm9Z0Mi24QM1bk6rii4&refresh_token=1/R6mS8UIWuh2-rKXKc1HAhdMnvQ8tCQzI4MJyCozuv0M&grant_type=refresh_token" https://www.googleapis.com/oauth2/v4/token

;; ya29.GlyXBDErqt4KPSA6GYwRJTV98hiUytf_0GyvbB4gf02m9w35aIG2tT8CXLQOACyv6C9aNMThenokMo9VRajnT0wPbR-ETnd4MJ-wLRxo5FoX5ty3ItDe_b995cVv5w

;; ~ $ curl -i -G -d "maxResults=25&channelId=direwolf20&part=snippet,contentDetails&key=AIzaSyCW0c4fXbykXueatnBnUGE2g9t1zThS_-Q" https://www.googleapis.com/youtube/v3/playlists

;; UC_ViSsVg_3JUDyLS3E2Un5g

;; ~/Repos/kadinparker/elisp $ curl -i -G -d "playlistId=PLaiPn4ewcbkHxqv1ao5R-piPIqRDe3kkI&maxResults=25&part=snippet,contentDetails&key=AIzaSyCW0c4fXbykXueatnBnUGE2g9t1zThS_-Q" https://www.googleapis.com/youtube/v3/playlistItems

(setq youtube-api-key "AIzaSyCW0c4fXbykXueatnBnUGE2g9t1zThS_-Q"
      youtube-base-url "https://www.googleapis.com/youtube/v3/")

(make-variable-buffer-local
 (defvar youtube-returned-data nil))

(make-variable-buffer-local
 (defvar youtube-pretty-json nil))

(defun youtube-playlist-query (id maxResults part key &optional pageToken)
  (let* ((json-object-type 'alist)
         (url-request-method "GET")
         (arg-stuff (concat "?playlistId=" id
                            "&maxResults=" (url-hexify-string maxResults)
                            "&part=" (url-hexify-string part)
                            "&key=" (url-hexify-string youtube-api-key)
                            "&pageToken=" pageToken))
         (response-buffer
          (url-retrieve-synchronously (concat youtube-base-url "playlistItems" arg-stuff) t)))
    (with-current-buffer response-buffer
      (goto-char (point-min))
      (re-search-forward "{")
      (delete-region (point-min) (match-beginning 0))
      (json-read-from-string (buffer-string)))))

(defun youtube-search-query (part type maxResults q)
  (let* ((json-object-type 'alist)
         (url-request-method "GET")
         (arg-stuff (concat "?part=" (url-hexify-string part)
                            "&q=" q
                            "&type=" type
                            "&maxResults=" maxResults
                            "&key=" youtube-api-key))
         (response-buffer
          (url-retrieve-synchronously (concat youtube-base-url "search" arg-stuff) t)))
    (goto-char (point-min))
    (re-search-forward "{")
    (delete-region (point-min) (match-beginning 0))
    (json-read-from-string (buffer-string))))

(defun youtube-search-user-query (search)
  (interactive (list (read-string "User: ")))
  (youtube-display-search-results
   (youtube-search-query "snippet" "channel" "50" search)))

(defun youtube-user-playlist-query (part channelId maxResults &optional pageToken)
  (let ((url-request-method "GET")
        (arg-stuff (concat "?part=" (url-hexify-string part)
                           "&channelId=" (url-hexify-string channelId)
                           "&maxResults=" (url-hexify-string maxResults)
                           "&key=" youtube-api-key)))
    (url-retrieve (concat youtube-base-url "playlists" arg-stuff)
                  (lambda (status)
                    (goto-char
                     (point-min))
                    (re-search-forward "{")
                    (backward-char)
                    (delete-region
                     (point)
                     (point-min))
                    (setq youtube-returned-data
                          (buffer-string))
                    (setq youtube-pretty-json
                          (let ((json-object-type 'alist))
                            (json-read-from-string youtube-returned-data)))))))

(defun youtube-display-titles ()
  (let ((testing
         (append
          (cdr
           (assoc 'items youtube-pretty-json))
          nil))
        (map (make-sparse-keymap)))
    (dolist (test testing)
      (define-key map [?\r]
        `(lambda ()
          (interactive)
          (setq video-url
                (concat "https://www.youtube.com/watch?v="
                        (cdr
                         (assoc 'videoId
                                (assoc 'resourceId
                                       (assoc 'snippet ',test))))))
          (start-process-shell-command "mpv" "mpv"
                                       (format "mpv %s" video-url))))
      (insert
       (cdr
        (assoc 'title
               (assoc 'snippet test))))
      (add-text-properties
       (point)
       (save-excursion
         (beginning-of-line)
         (point))
       '(mouse-face highlight))
      (put-text-property
       (point)
       (save-excursion
         (beginning-of-line)
         (point))
       'keymap map)
      (insert "\n"))))

(defun youtube-display-playlists (id maxResults part key))

(defun youtube-video-search ()
  (interactive)
  (let ((query (read-string "Search Query: "))
        (maxResults (read-string "Max Results: ")))
    (youtube-search-query "snippet" "video" maxResults query)
    (sit-for 1)
    (youtube-display-search-results)))





;; (switch-to-buffer "*youtube*")
(defun youtube-display-search-results (data)
  (switch-to-buffer (get-buffer-create "*youtube*"))
  (erase-buffer)
  (setq youtube-next-page-token
        (cdr
         (assoc 'nextPageToken youtube-pretty-json)))
  (setq testing
        (append
         (cdr
          (assoc 'items youtube-pretty-json))
         nil))
  (let
      ((map (make-sparse-keymap)))
    (dolist (test testing)
      (define-key map [f5]
        (lambda ()
           (interactive)
           (youtube-user-playlist-query "snippet" (get-text-property (point) 'channelId) "50")
           (sit-for 1)
           (youtube-display-user-playlist-results)))
      (define-key map [?\r]
        `(lambda ()
           (interactive)
           (setq video-url
                 (concat "https://www.youtube.com/watch?v="
                         (get-text-property (point) 'videoId)))
           (message "Video is loading...")
           (start-process-shell-command "mpv" "mpv"
                                        (format "mpv %s" video-url))))
      (define-key map [f4]
        `(lambda ()
          (interactive)
          (let ((playlistId (cdr
                             (assoc 'playlistId
                                    (assoc 'snippet ',test)))))
            (youtube-playlist-query playlistId "50" "snippet" youtube-api-key youtube-next-page-token)
            (sit-for 0.5)
            (youtube-display-search-results)
            (beginning-of-buffer))))
      (insert
       (propertize
        (cdr
         (assoc 'title
                (assoc 'snippet test)))
        'mouse-face 'highlight
        'keymap map
        'kind (cdr
               (assoc 'kind
                      (assoc 'resourceId test)))
        'channelId (cdr
                    (assoc 'channelId
                           (assoc 'snippet test)))
        'videoId (cdr
                  (assoc 'videoId
                         (assoc 'resourceId
                                (assoc 'snippet test))))
        'help-echo (cdr
                      (assoc 'description
                             (assoc 'snippet test)))))
      (insert "\n"))))

(defun youtube-display-user-playlist-results ()
  (get-buffer-create "*youtube-playlist-results*")
  (switch-to-buffer "*youtube-playlist-results*")
  (erase-buffer)
  (setq testing
        (append
         (cdr
          (assoc 'items youtube-pretty-json))
         nil))
  (let
      ((map (make-sparse-keymap)))
    (dolist (test testing)
      (define-key map [?\r]
        `(lambda ()
           (interactive)
           (let ((title
                  (format "%s"
                          (get-text-property
                           (point)
                           'title))))
           (message (get-text-property (point) 'playlistId))
           (youtube-playlist-query (get-text-property (point) 'playlistId) "50" "snippet" youtube-api-key)
           (message "Loading")
           (sit-for 1)
           (youtube-display-search-results))))
      (insert
       (propertize
        (cdr
         (assoc 'title
                (assoc 'snippet test)))
        'title (cdr
                (assoc 'title
                       (assoc 'snippet test)))
        'mouse-face 'highlight
        'keymap map
        'playlistId (cdr
                     (assoc 'id test))
        'help-echo (cdr
                      (assoc 'description
                             (assoc 'snippet test)))))
      (insert "\n")))
  (switch-to-buffer "*youtube-playlist-results*"))
