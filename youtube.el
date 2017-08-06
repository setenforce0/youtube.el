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
      youtube-base-url "https://www.googleapis.com/youtube/v3/"
      youtube-show-thumbnails nil
      youtube-thumbnail-size 'medium)

(make-variable-buffer-local
 (defvar youtube-returned-data nil))

(make-variable-buffer-local
 (defvar youtube-pretty-json nil))

(defun youtube-get-thumbdata (url)
  (create-image
   (let ((response (url-retrieve-synchronously url t)))
     (with-current-buffer response
       (goto-char (point-min))
       (re-search-forward "^$")
       (string-trim-left (buffer-substring (point) (point-max)))))
   nil t))

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
      (delete-region (point-min) (1- (match-beginning 0)))
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
    (with-current-buffer response-buffer
      (goto-char (point-min))
      (re-search-forward "{")
      (delete-region (point-min) (1- (match-beginning 0)))
      (json-read-from-string (buffer-string)))))

(defun youtube-search-user-query (search)
  (interactive (list (read-string "User: ")))
  (youtube-display-search-results
   (youtube-search-query "snippet" "channel" "50" search)))

;; (youtube-search-user-query "direwolf20")


(defun youtube-user-playlist-query (part channelId maxResults &optional pageToken)
  (let* ((url-request-method "GET")
         (arg-stuff (concat "?part=" (url-hexify-string part)
                            "&channelId=" (url-hexify-string channelId)
                            "&maxResults=" (url-hexify-string maxResults)
                            "&key=" youtube-api-key))
         (response-buffer
          (url-retrieve-synchronously (concat youtube-base-url "playlists" arg-stuff) )))
    (with-current-buffer response-buffer
      (goto-char (point-min))
      (re-search-forward "{")
      (delete-region (point-min) (match-beginning 0))
      (json-read-from-string (buffer-string)))))

(defun youtube-display-playlists (id maxResults part key))

(defun youtube-video-search (query)
  (interactive (list (read-string "Search Query: ")))
  (youtube-display-search-results
   (youtube-search-query "snippet" "video" "50" query)))

;; (switch-to-buffer "*youtube*")
(defun youtube-display-search-results (json)
  (switch-to-buffer (get-buffer-create "*youtube*"))
  (read-only-mode -1)
  (erase-buffer)
  (setq youtube-next-page-token (cdr (assoc 'nextPageToken json)))
  (let ((map (make-sparse-keymap)))
    (loop
     for item across (alist-get 'items json) do
     (define-key map [f5]
       (lambda ()
         (interactive)
         (youtube-display-user-playlist-results
          (youtube-user-playlist-query "snippet" (get-text-property (point) 'channelId) "50"))))
     (define-key map [?\r]
       `(lambda ()
          (interactive)
          (message "Video is loading...")
          (start-process-shell-command "mpv" "mpv"
                                       (format "mpv %s"
                                               (concat "https://www.youtube.com/watch?v="
                                                       (get-text-property (point) 'videoId))))))
     (define-key map [f4]
       `(lambda ()
          (interactive)
          (let ((playlistId (cdr
                             (assoc 'playlistId
                                    (assoc 'snippet ',item)))))
            (youtube-display-search-results
             (youtube-playlist-query playlistId "50" "snippet" youtube-api-key youtube-next-page-token))
            (beginning-of-buffer))))
     (insert
      (propertize
       (concat "  " (cdr
        (assoc 'title
               (assoc 'snippet item))))
       'mouse-face 'highlight
       'keymap map
       'thumbnail (cdr (assoc 'url
                              (assoc youtube-thumbnail-size
                                     (assoc 'thumbnails
                                            (assoc 'snippet item)))))
       'kind (cdr
              (assoc 'kind
                     (assoc 'resourceId item)))
       'channelId (cdr
                   (assoc 'channelId
                          (assoc 'snippet item)))
       'videoId
       (alist-get 'videoId
                  (if (string= "youtube#searchResult" (alist-get 'kind item))
                      (alist-get 'id item)
                    (alist-get 'resourceId (alist-get 'snippet item))))

       'help-echo (cdr
                   (assoc 'description
                          (assoc 'snippet item)))))
     (beginning-of-line)
     (insert-image (youtube-get-thumbdata
                    (get-text-property (point) 'thumbnail)))
     (end-of-line)
     (insert "\n")))
  (goto-char (+ 1 (point-min)))
  (read-only-mode))

(defun youtube-display-user-playlist-results (json)
  (get-buffer-create "*youtube-playlist-results*")
  (switch-to-buffer "*youtube-playlist-results*")
  (erase-buffer)
  (let ((map (make-sparse-keymap)))
    (loop
     for item across (alist-get 'items json) do
     (define-key map [?\r]
       `(lambda ()
          (interactive)
          (let ((title
                 (format "%s"
                         (get-text-property
                          (point)
                          'title))))
            (message "Loading")
            (youtube-display-search-results
             (youtube-playlist-query (get-text-property (point) 'playlistId) "50" "snippet" youtube-api-key)))))
     (insert
      (propertize
       (cdr
        (assoc 'title
               (assoc 'snippet item)))
       'title (cdr
               (assoc 'title
                      (assoc 'snippet item)))
       'mouse-face 'highlight
       'keymap map
       'playlistId (cdr
                    (assoc 'id item))
       'help-echo (cdr
                   (assoc 'description
                          (assoc 'snippet item)))))
     (insert "\n")))
  (switch-to-buffer "*youtube-playlist-results*")
  (goto-char (point-min)))
