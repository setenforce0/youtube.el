(defvar youtube-oauth-refresh-token nil)
(defvar youtube-oauth-access-code nil)

(setq youtube-api-key "AIzaSyCW0c4fXbykXueatnBnUGE2g9t1zThS_-Q"
      youtube-base-url "https://www.googleapis.com/youtube/v3/"
      youtube-show-thumbnails t
      youtube-thumbnail-size 'default
      youtube-show-videos 'true
      youtube-mpv-fullscreen t
      youtube-last-error nil
      youtube-debug nil
      youtube-video-ids '()
      youtube-request-type nil
      youtube-last-response nil)

(defun youtube-sign-out ()
  (interactive)
  (setq
   youtube-oauth-access-code nil
   youtube-oauth-refresh-token nil))

(make-variable-buffer-local
 (defvar youtube-returned-data nil))

(make-variable-buffer-local
 (defvar youtube-pretty-json nil))

(defun youtube-request (url)
  (when youtube-debug
    (message "%s" url-request-data))
  (let ((response (url-retrieve-synchronously url t))
        (json-object-type 'alist)
        (json-array-type 'list)
        json json-null json-false)
    (with-current-buffer response
      (goto-char (point-min))
      (re-search-forward "{")
      (delete-region (point-min) (1- (match-beginning 0)))
      (setq json (json-read-from-string (buffer-string))))
    (if (alist-get 'error json)
        (error (prog1 "API Error" (setq youtube-last-error json)))
      ;; setq returns whatever you give it
      (setq youtube-last-response json))))

(defun youtube-oauth-authorize ()
  (let* ((client_id "457835332683-7k3hgag48hd5rpseahsik6s76cdd71kf.apps.googleusercontent.com")
         (redirect_uri "urn:ietf:wg:oauth:2.0:oob")
         (response_type "code")
         (scope "https://www.googleapis.com/auth/youtube")
         (arg-stuff (concat "?scope=" scope
                            "&response_type=" response_type
                            "&redirect_uri=" redirect_uri
                            "&client_id=" (url-hexify-string client_id))))
    (browse-url (concat "https://accounts.google.com/o/oauth2/v2/auth" arg-stuff))))

(defun youtube-sign-in ()
  (interactive)
  (youtube-oauth-authorize)
  (let* ((authorization_code (read-string "Authorization Code: "))
         (client_id "457835332683-7k3hgag48hd5rpseahsik6s76cdd71kf.apps.googleusercontent.com")
         (client_secret "dgRS0Qm9Z0Mi24QM1bk6rii4")
         (json-object-type 'alist)
         (url-request-method "POST")
         (url-request-extra-headers
          '(("Content-Type" . "application/x-www-form-urlencoded")))
         (url-request-data
          (concat "code=" (url-hexify-string authorization_code)
                  "&client_id=" client_id
                  "&client_secret=" client_secret
                  "&redirect_uri=" "urn:ietf:wg:oauth:2.0:oob"
                  "&grant_type=" "authorization_code"))
         (response (youtube-request "https://www.googleapis.com/oauth2/v4/token")))
    (setq youtube-oauth-access-code (alist-get 'access_token response)
          youtube-oauth-refresh-token (alist-get 'refresh_token response))
    (if (bound-and-true-p youtube-oauth-refresh-token)
        (message "You have been signed in successfully!")
      (message "Something went wrong :("))))

(defun youtube-oauth-access-code-refresh ()
  (if (bound-and-true-p youtube-oauth-refresh-token)
      (let* ((json-object-type 'alist)
             (url-request-method "POST")
             (url-request-extra-headers
              '(("Content-Type" . "application/x-www-form-urlencoded")))
             (url-request-data
              (concat "refresh_token=" youtube-oauth-refresh-token
                      "&client_id=" "457835332683-7k3hgag48hd5rpseahsik6s76cdd71kf.apps.googleusercontent.com"
                      "&client_secret=" "dgRS0Qm9Z0Mi24QM1bk6rii4"
                      "&grant_type=" "refresh_token"))
             (response (youtube-request "https://www.googleapis.com/oauth2/v4/token")))
        (setq youtube-oauth-access-code (alist-get 'access_token response)))
    (message "You are not authorized yet! Please run youtube-sign-in")))

(defun youtube-list-subscriptions (part channelId maxResults &optional mine pageToken)
  (interactive (list "snippet" nil "50" "true" nil))
  (if mine
      (if (bound-and-true-p youtube-oauth-refresh-token)
          (let* ((url-request-method "GET")
                 (arg-stuff (concat "?part=" part
                                    (if mine "" (concat "&channelId=" channelId))
                                    (if mine (concat "&mine=" mine) "")
                                    "&maxResults=" maxResults
                                    "&pageToken=" pageToken
                                    "&access_token=" youtube-oauth-access-code
                                    "&key=" youtube-api-key)))
            (youtube-display-search-results
             (youtube-request (concat youtube-base-url "subscriptions" arg-stuff))))
        (message "Sorry, you're not signed in yet!"))))


(defun youtube-comments-query (part videoId maxResults &optional pageToken searchTerms)
  (let* ((json-object-type 'alist)
         (url-request-method "GET")
         (arg-stuff (concat "?part=" part
                            "&videoId=" videoId
                            "&maxResults=" maxResults
                            "&key=" youtube-api-key
                            "&textFormat=" "plainText"
                            "&pageToken=" pageToken
                            "&searchTerms=" searchTerms)))
    (youtube-request (concat youtube-base-url "commentThreads" arg-stuff))))


(defun youtube-activities-query (part channelId mine maxResults &optional pageToken accessToken)
  (let* ((url-request-method "GET")
         (arg-stuff (concat "?part=" part
                            (if mine (concat "&mine=" mine) "")
                            (if channelId (concat "&channelId=" channelId) "")
                            "&maxResults=" maxResults
                            "&pageToken=" pageToken
                            "&access_token=" accessToken
                            "&key=" youtube-api-key)))
    (youtube-request (concat youtube-base-url "activities" arg-stuff))))

(defun youtube-ratings-query (id)
  (let* ((url-request-method "GET")
         (arg-stuff (concat "?id=" id
                            "&part=statistics"
                            "&key=" youtube-api-key)))
    (youtube-request (concat youtube-base-url "videos" arg-stuff))))

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
                            "&pageToken=" pageToken)))
    (youtube-request (concat youtube-base-url "playlistItems" arg-stuff))))

(defun youtube-search-query (part type maxResults q &optional channelId order ids pageToken)
  (let* ((url-request-method "GET")
         (arg-stuff (concat "?part=" (url-hexify-string part)
                            (if q (concat "&q=" q) "")
                            (if channelId (concat "&channelId=" channelId) "")
                            "&type=" type
                            "&maxResults=" maxResults
                            "&key=" youtube-api-key
                            "&order=" order
                            "&id=" ids
                            "&pageToken=" pageToken)))
    (youtube-request (concat youtube-base-url "search" arg-stuff))))


(defun youtube-search-user-query (search)
  (interactive (list (read-string "User: ")))
  (youtube-display-search-results
   (youtube-search-query "snippet" "channel" "50" search nil "relevance")))

;; (youtube-search-user-query "direwolf20")


(defun youtube-user-playlist-query (part channelId maxResults &optional pageToken)
  (let* ((url-request-method "GET")
         (arg-stuff (concat "?part=" (url-hexify-string part)
                            "&channelId=" (url-hexify-string channelId)
                            "&maxResults=" (url-hexify-string maxResults)
                            "&key=" youtube-api-key)))
    (youtube-request (concat youtube-base-url "playlists" arg-stuff))))

;; (defun youtube-dislay-playlists (id maxResults part key))


;; (youtube-display-comments (youtube-comments-query "snippet,replies" videoId "100" nextPageToken))

(defun youtube-cleanse (string)
  (remove-if-not
   (lambda (char)
     (encode-coding-char char buffer-file-coding-system))
   string))

(defun youtube-display-comments (json)
  (let ((buffer (get-buffer-create "*youtube-comment-results*"))
        (nextPageToken (alist-get 'nextPageToken youtube-last-response))
        (videoId (alist-get 'videoId (alist-get 'snippet (first (alist-get 'items youtube-last-response))))))
    (switch-to-buffer buffer)
    (erase-buffer)
    (local-set-key
     (kbd "C-x y n")
     `(lambda ()
        (interactive)
        (youtube-display-comments
         (youtube-comments-query
          "snippet,replies" ,videoId "100" ,nextPageToken))))
    (loop for item in (alist-get 'items json)
          for snippet = (alist-get 'snippet item) do
          (insert
           (concat
            (propertize
             (youtube-cleanse
              (alist-get 'authorDisplayName
                         (alist-get 'snippet
                                    (alist-get 'topLevelComment snippet))))
             'face 'font-lock-builtin-face)
            "\n"
            (youtube-cleanse
             (alist-get 'textDisplay
                        (alist-get 'snippet
                                   (alist-get 'topLevelComment snippet))))))
          (when (/= 0 (alist-get 'totalReplyCount snippet))
            (loop for comment in (alist-get 'comments (alist-get 'replies item))
                  for snippet = (alist-get 'snippet comment) do
                  (insert
                   (concat "\n    ---------------\n    "
                           (propertize (youtube-cleanse (alist-get 'authorDisplayName snippet))
                                       'face 'font-lock-builtin-face)
                           "\n    "
                           (replace-regexp-in-string
                            "[\n]" "\n    "
                            (youtube-cleanse (alist-get 'textDisplay snippet)))))))
          (insert "\n\n------------------------------------------\n\n"))
    (beginning-of-buffer)))

;; (youtube-video-search "Lamborghini Sesto Elemento at Imola - Top Gear - Series 20 - BBC")

(defun youtube-video-search (query)
  (interactive (list (read-string "Search Query: ")))
  (youtube-display-search-results
   (youtube-search-query "snippet" "video" "50" query nil "relevance")))

;; (defun youtube-display-activities (&optional channelId)
;;   (let ((query (youtube-activities-query
;;                 "snippet,contentDetails" channelId
;;                 "true" "5" nil youtube-oauth-access-code))
;;     (loop for item in (alist-get 'items query)
;;           for details = (alist-get 'contentDetails item)
;;           for snippet = (alist-get 'snippet item)
;;           for type = (intern (alist-get 'type snippet)) do
;;           (case type
;;             (subscription
;;              (insert
;;               (concat "Subscribed to "
;;                       (propertize (alist-get 'channelTitle snippet)
;;                                   'face 'font-lock-builtin-face))))
;;             )
;;           (insert "\n\n-------------------------------\n\n")

;;       )))

;; (switch-to-buffer "*youtube*")
(defun youtube-display-search-results (json &optional buffer)
  (switch-to-buffer
   (if buffer
       (get-buffer-create buffer)
     (get-buffer-create "*youtube*")))
  (read-only-mode -1)
  (erase-buffer)
  (setq youtube-next-page-token (cdr (assoc 'nextPageToken json)))
  (setq youtube-video-ids '())
  (let ((map (make-sparse-keymap)))
    (setq youtube-video-ids
          (loop
           for item in (alist-get 'items json)
           collecting (alist-get 'videoId
                                 (if (string= "youtube#searchResult" (alist-get 'kind item))
                                     (alist-get 'id item)
                                   (alist-get 'resourceId (alist-get 'snippet item))))
           do
           (insert
            (propertize
             (concat "  " (cdr
                           (assoc 'title
                                  (assoc 'snippet item))))
             'mouse-face 'highlight
             'keymap youtube-search-results-map
             'thumbnail (cdr (assoc 'url
                                    (assoc youtube-thumbnail-size
                                           (assoc 'thumbnails
                                                  (assoc 'snippet item)))))
             'kind (cdr
                    (assoc 'kind
                           (assoc 'resourceId item)))

             'channelId
             (if (equal (alist-get 'kind youtube-last-response)
                        "youtube#subscriptionListResponse")
                 (alist-get 'channelId (assoc 'resourceId (assoc 'snippet item)))
               (alist-get 'channelId (assoc 'snippet item)))

             'videoId
             (alist-get 'videoId
                        (if (string= "youtube#searchResult" (alist-get 'kind item))
                            (alist-get 'id item)
                          (alist-get 'resourceId (alist-get 'snippet item))))

             'help-echo (cdr
                         (assoc 'description
                                (assoc 'snippet item)))))
           (beginning-of-line)
           (if (string= youtube-show-thumbnails "t")
               (insert-image (youtube-get-thumbdata
                              (get-text-property (point) 'thumbnail))))
           (end-of-line)
           (insert "\n")))
    (goto-char (+ 1 (point-min)))
    (read-only-mode)))

(defun youtube-display-user-playlist-results (json)
  (get-buffer-create "*youtube-playlist-results*")
  (switch-to-buffer "*youtube-playlist-results*")
  (erase-buffer)
  (let ((map (make-sparse-keymap)))
    (loop
     for item in (alist-get 'items json) do
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

;;  TODO: Make a dashboard
;;  TODO: Use batch requests for videos, use loop to gather them
;;  TODO: Make as little api requests as possible

(setq youtube-search-results-map
      (loop with map = (make-sparse-keymap)
            for (key action) in
            '(("C-x y p"
               (lambda ()
                 (interactive)
                 (youtube-display-user-playlist-results
                  (youtube-user-playlist-query "snippet" (get-text-property (point) 'channelId) "50"))))
              ("C-x y c"
               (lambda ()
                 (interactive)
                 (message "Comments are loading...")
                 (youtube-display-comments (youtube-comments-query "snippet,replies" (get-text-property (point) 'videoId) "100"))))
              ("RET"
               (lambda ()
                  (interactive)
                  (let ((videoId (get-text-property (point) 'videoId)))
                    (if (not videoId)
                        (youtube-display-search-results
                         (youtube-search-query "snippet" "video" "50" nil
                                               (get-text-property (point) 'channelId) "date") (format "*youtube-channel-%s" (get-text-property (point) 'channelId)))
                      (message "Video is loading...")
                      (start-process-shell-command "mpv" "mpv"
                                                   (format "mpv %s" (concat (if youtube-mpv-fullscreen "--fs ") "'https://www.youtube.com/watch?v=" videoId "'")))))))
              ("C-x y n"
               (lambda ()
                 (interactive)
                 (let ((playlistId (cdr
                                    (assoc 'playlistId
                                           (assoc 'snippet ',item)))))
                   (if (not playlistId)
                       (youtube-display-search-results
                        (youtube-search-query "snippet" "video" "50" nil
                                              (get-text-property (point) 'channelId) "date" nil youtube-next-page-token))
                   (youtube-display-search-results
                    (youtube-playlist-query playlistId "50" "snippet" youtube-api-key youtube-next-page-token))
                   (beginning-of-buffer))))))
      do (define-key map (kbd key) action)
      finally (return map)))

(defun swap (LIST el1 el2)
  "in LIST swap indices EL1 and EL2 in place"
  (let ((tmp (elt LIST el1)))
    (setf (elt LIST el1) (elt LIST el2))
    (setf (elt LIST el2) tmp)))


(defun shuffle (LIST)
  "Shuffle the elements in LIST.
shuffling is done in place."
  (loop for i in (reverse (number-sequence 1 (1- (length LIST))))
        do (let ((j (random (+ i 1))))
             (swap LIST i j)))
  LIST)

(defun youtube-play-random-videos ()
  (interactive)
  (shuffle youtube-video-ids)
  (let* ((youtube-videos
        (loop for id in youtube-video-ids
              collecting (concat "https://youtube.com/watch\\?v\\=" id)))
         (youtube-videos-string (mapconcat 'identity youtube-videos " ")))
    (start-process-shell-command "youtube-random-videos" "mpv" (concat "mpv " youtube-videos-string))
    (message "Loading...")))

(defun youtube-dashboard (part channelId maxResults &optional mine pageToken)
  (interactive (list "snippet" nil "50" "true" ""))
  (if (not (bound-and-true-p youtube-oauth-refresh-token))
      (youtube-sign-in))
  (youtube-oauth-access-code-refresh)
  (youtube-display-user-results (youtube-query-subscriptions "snippet" nil "50" "true" "" "relevance") nil "true"))

(defun youtube-query-subscriptions (part channelId maxResults &optional mine pageToken order)
  (if (bound-and-true-p youtube-oauth-refresh-token)
      (let* ((url-request-method "GET")
             (arg-stuff (concat "?part=" part
                                (if mine "" (concat "&channelId=" channelId))
                                (if mine (concat "&mine=" mine) "")
                                "&maxResults=" maxResults
                                "&pageToken=" pageToken
                                "&access_token=" youtube-oauth-access-code
                                (if order (concat "&order=" order) "")
                                "&key=" youtube-api-key)))
        (youtube-request (concat youtube-base-url "subscriptions" arg-stuff)))
    (message "Sorry, you're not signed in yet!")))

(defun youtube-display-user-results (json &optional buffer number-of-videos)
  (switch-to-buffer
   (if buffer
       (get-buffer-create buffer)
     (get-buffer-create "*youtube*")))
  (read-only-mode -1)
  (erase-buffer)
  (font-lock-mode)
  (toggle-truncate-lines)
  (message "Loading...")
  (setq youtube-next-page-token (cdr (assoc 'nextPageToken json)))
  (let ((map (make-sparse-keymap)))
    (loop
     for item in (alist-get 'items json) do
     (insert
      (propertize
       (concat "  " (cdr
                     (assoc 'title
                            (assoc 'snippet item))))
       'font-lock-face '(:foreground "orange")
       'mouse-face 'highlight
       'keymap youtube-search-results-map
       'thumbnail (cdr (assoc 'url
                              (assoc youtube-thumbnail-size
                                     (assoc 'thumbnails
                                            (assoc 'snippet item)))))
       'kind (cdr
              (assoc 'kind
                     (assoc 'resourceId item)))

       'channelId
       (alist-get 'channelId (assoc 'resourceId (assoc 'snippet item)))

       'videoId
       (alist-get 'videoId
                  (if (string= "youtube#searchResult" (alist-get 'kind item))
                      (alist-get 'id item)
                    (alist-get 'resourceId (alist-get 'snippet item))))

       'help-echo (cdr
                   (assoc 'description
                          (assoc 'snippet item)))))
     (beginning-of-line)
     (if (string= youtube-show-thumbnails "t")
         (insert-image (youtube-get-thumbdata
                        (get-text-property (point) 'thumbnail))))
     (end-of-line)
     (insert "\n")
     (cond ((string= youtube-show-videos "true")
            (backward-char 2)
            ;; TODO: Use video endpoint and include statistics, to insert video views
            (let ((json (youtube-search-query "snippet" "video" "5" nil (get-text-property (point) 'channelId) "date" (mapconcat 'identity
                         (loop for item in
                               (cdr (assoc 'items (youtube-search-query "snippet" "video" "5" nil
                                                                        (get-text-property
                                                                         (point)
                                                                         'channelId)
                                                                        "date")))
                               collecting (cdr (assoc 'videoId (assoc 'id item)))) ","))))
              (forward-line)
              (insert "\n")
              (let ((map (make-sparse-keymap)))
                (loop
                 for item in (alist-get 'items json) do
                 (insert
                  (propertize
                   (concat "  " (cdr
                                 (assoc 'title
                                        (assoc 'snippet item))))
                   'mouse-face 'highlight
                   'keymap youtube-search-results-map
                   'thumbnail (cdr (assoc 'url
                                          (assoc youtube-thumbnail-size
                                                 (assoc 'thumbnails
                                                        (assoc 'snippet item)))))
                   'kind (cdr
                          (assoc 'kind
                                 (assoc 'resourceId item)))

                   'channelId
                   (if (equal (alist-get 'kind youtube-last-response)
                              "youtube#subscriptionListResponse")
                       (alist-get 'channelId (assoc 'resourceId (assoc 'snippet item)))
                     (alist-get 'channelId (assoc 'snippet item)))

                   'videoId
                   (alist-get 'videoId
                              (if (string= "youtube#searchResult" (alist-get 'kind item))
                                  (alist-get 'id item)
                                (alist-get 'resourceId (alist-get 'snippet item))))

                   'help-echo (cdr
                               (assoc 'description
                                      (assoc 'snippet item)))))
                 (backward-char 1)
                 (let ((videoId (get-text-property (point) 'videoId)))
                   (beginning-of-line))
                   ;; (insert "  "))
                 ;;   (insert (propertize (format "%7s" (cdr (assoc 'viewCount (assoc 'statistics  (car (cdr (assoc 'items (cdr (youtube-ratings-query videoId)))))))))
                 ;;                       'font-lock-face '(:foreground "sea green"))))
                 (end-of-line)
                 (insert "\n")))
              (insert "\n")))))
    (goto-char (+ 1 (point-min)))
    (end-of-line 0)
    (open-line 1)
    (insert (propertize "Subscriptions\n"
                        'font-lock-face '(:foreground "sea green" :underline t)))
    (read-only-mode)
    (message "Done")))
