(require 'request)

(request
 "https://accounts.google.com/o/oauth2/v2/auth?scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fyoutube&response_type=code&state=security_token%3D138r5719ru3e1%26url%3Dhttps://oauth2.example.com/token&redirect_uri=urn:ietf:wg:oauth:2.0:oob&client_id=457835332683-7k3hgag48hd5rpseahsik6s76cdd71kf.apps.googleusercontent.com"
 :params '(("scope" . "https://www.googleapis.com/auth/youtube")
           ("response_type" . "code")
           ("state" . "security_token%3D138r5719ru3e1%26url%3Dhttps://oauth2.example.com/token")
           ("redirect_uri" . "urn:ietf:wg:oauth:2.0:oob")
           ("client_id" . "457835332683-7k3hgag48hd5rpseahsik6s76cdd71kf.apps.googleusercontent.com"))
 :parser 'json-read
 :success (function*
           (lambda (&key data &allow-other-keys)
             (message data)))
 )

(with-current-buffer (url-retrieve-synchronously "https://accounts.google.com/o/oauth2/v2/auth?scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fyoutube&response_type=code&state=security_token%3D138r5719ru3e1%26url%3Dhttps://oauth2.example.com/token&redirect_uri=urn:ietf:wg:oauth:2.0:oob&client_id=457835332683-7k3hgag48hd5rpseahsik6s76cdd71kf.apps.googleusercontent.com"))


4/qQh10lpU0TGCRwXrQelgfNkFkntKtZNYasFPr8F74-Y

(request
 "https://www.googleapis.com/oauth2/v4/token"
 :type "POST"
 :data '(("code" . "4/qQh10lpU0TGCRwXrQelgfNkFkntKtZNYasFPr8F74-Y")
         ("client_id" . "457835332683-7k3hgag48hd5rpseahsik6s76cdd71kf.apps.googleusercontent.com")
         ("client_secret" . "dgRS0Qm9Z0Mi24QM1bk6rii4")
         ("redirect_uri" . "http://127.0.0.1")
         ("grant_type" . "authorization_code"))
 :parser 'json-read
 :success (function*
          (lambda (&key data &allow-other-keys)
            (message data))))


~ $ curl --data "code=4/Cf-PX285KJ5aHlmpIQaWbGHPJS6cMO4qWhVpsCAqUoQ&client_id=457835332683-7k3hgag48hd5rpseahsik6s76cdd71kf.apps.googleusercontent.com&client_secret=dgRS0Qm9Z0Mi24QM1bk6rii4&redirect_uri=urn:ietf:wg:oauth:2.0:oob&grant_type=authorization_code" https://www.googleapis.com/oauth2/v4/token
{d
"access_token": "ya29.GluVBHKr9Sycw16XFVrxPfVrte1Jb3p5vXpqRj1flod4bpZC2pqxwWFsJ0B7MOJMuK4r5f5h3a53Oj32FsqNBJ_S8OqX9zldd6VJ1wIBZ4MNETKhI4aKBL9Vp9Cf",
"token_type": "Bearer",
"expires_in": 3600,
"refresh_token": "1/R6mS8UIWuh2-rKXKc1HAhdMnvQ8tCQzI4MJyCozuv0M"
}
~ $


~ $ curl -i -G -d "channelId=UCgCflAd-1Yf7ffXjEYXbPUQ&part=snippet,contentDetails&key=AIzaSyCW0c4fXbykXueatnBnUGE2g9t1zThS_-Q" https://www.googleapis.com/youtube/v3/subscriptions

~ $ curl -i -d "client_id=457835332683-7k3hgag48hd5rpseahsik6s76cdd71kf.apps.googleusercontent.com&client_secret=dgRS0Qm9Z0Mi24QM1bk6rii4&refresh_token=1/R6mS8UIWuh2-rKXKc1HAhdMnvQ8tCQzI4MJyCozuv0M&grant_type=refresh_token" https://www.googleapis.com/oauth2/v4/token

ya29.GlyXBDErqt4KPSA6GYwRJTV98hiUytf_0GyvbB4gf02m9w35aIG2tT8CXLQOACyv6C9aNMThenokMo9VRajnT0wPbR-ETnd4MJ-wLRxo5FoX5ty3ItDe_b995cVv5w

~ $ curl -i -G -d "maxResults=25&channelId=direwolf20&part=snippet,contentDetails&key=AIzaSyCW0c4fXbykXueatnBnUGE2g9t1zThS_-Q" https://www.googleapis.com/youtube/v3/playlists

UC_ViSsVg_3JUDyLS3E2Un5g

~/Repos/kadinparker/elisp $ curl -i -G -d "playlistId=PLaiPn4ewcbkHxqv1ao5R-piPIqRDe3kkI&maxResults=25&part=snippet,contentDetails&key=AIzaSyCW0c4fXbykXueatnBnUGE2g9t1zThS_-Q" https://www.googleapis.com/youtube/v3/playlistItems

(defvar playlistId "PLaiPn4ewcbkHxqv1ao5R-piPIqRDe3kkI")

(defvar key "AIzaSyCW0c4fXbykXueatnBnUGE2g9t1zThS_-Q")

(defvar playlistItemsUrl "https://www.googleapis.com/youtube/v3/playlistItems")

(defun youtube-playlist-query (id maxResults part key)
  (let ((url-request-method "GET")
        (arg-stuff (concat "?playlistId=" (url-hexify-string id)
                           "&maxResults=" (url-hexify-string maxResults)
                           "&part=" (url-hexify-string part)
                           "&key=" (url-hexify-string key))))
    (url-retrieve (concat playlistItemsUrl arg-stuff)
                  (lambda (status)
                    (goto-char (point-min))
                    (re-search-forward "{")
                    (previous-line)
                    (delete-region (point) (point-min))
                    (setq youtube-returned-data (buffer-string))))))

(setq youtube-pretty-json (json-read-from-string youtube-returned-data))

(require 'request)

(request
 "https://accounts.google.com/o/oauth2/v2/auth?scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fyoutube&response_type=code&state=security_token%3D138r5719ru3e1%26url%3Dhttps://oauth2.example.com/token&redirect_uri=urn:ietf:wg:oauth:2.0:oob&client_id=457835332683-7k3hgag48hd5rpseahsik6s76cdd71kf.apps.googleusercontent.com"
 :params '(("scope" . "https://www.googleapis.com/auth/youtube")
           ("response_type" . "code")
           ("state" . "security_token%3D138r5719ru3e1%26url%3Dhttps://oauth2.example.com/token")
           ("redirect_uri" . "urn:ietf:wg:oauth:2.0:oob")
           ("client_id" . "457835332683-7k3hgag48hd5rpseahsik6s76cdd71kf.apps.googleusercontent.com"))
 :parser 'json-read
 :success (function*
           (lambda (&key data &allow-other-keys)
             (message data)))
 )

(with-current-buffer (url-retrieve-synchronously "https://accounts.google.com/o/oauth2/v2/auth?scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fyoutube&response_type=code&state=security_token%3D138r5719ru3e1%26url%3Dhttps://oauth2.example.com/token&redirect_uri=urn:ietf:wg:oauth:2.0:oob&client_id=457835332683-7k3hgag48hd5rpseahsik6s76cdd71kf.apps.googleusercontent.com"))


4/qQh10lpU0TGCRwXrQelgfNkFkntKtZNYasFPr8F74-Y

(request
 "https://www.googleapis.com/oauth2/v4/token"
 :type "POST"
 :data '(("code" . "4/qQh10lpU0TGCRwXrQelgfNkFkntKtZNYasFPr8F74-Y")
         ("client_id" . "457835332683-7k3hgag48hd5rpseahsik6s76cdd71kf.apps.googleusercontent.com")
         ("client_secret" . "dgRS0Qm9Z0Mi24QM1bk6rii4")
         ("redirect_uri" . "http://127.0.0.1")
         ("grant_type" . "authorization_code"))
 :parser 'json-read
 :success (function*
          (lambda (&key data &allow-other-keys)
            (message data))))


~ $ curl --data "code=4/Cf-PX285KJ5aHlmpIQaWbGHPJS6cMO4qWhVpsCAqUoQ&client_id=457835332683-7k3hgag48hd5rpseahsik6s76cdd71kf.apps.googleusercontent.com&client_secret=dgRS0Qm9Z0Mi24QM1bk6rii4&redirect_uri=urn:ietf:wg:oauth:2.0:oob&grant_type=authorization_code" https://www.googleapis.com/oauth2/v4/token
{d
"access_token": "ya29.GluVBHKr9Sycw16XFVrxPfVrte1Jb3p5vXpqRj1flod4bpZC2pqxwWFsJ0B7MOJMuK4r5f5h3a53Oj32FsqNBJ_S8OqX9zldd6VJ1wIBZ4MNETKhI4aKBL9Vp9Cf",
"token_type": "Bearer",
"expires_in": 3600,
"refresh_token": "1/R6mS8UIWuh2-rKXKc1HAhdMnvQ8tCQzI4MJyCozuv0M"
}
~ $


~ $ curl -i -G -d "channelId=UCgCflAd-1Yf7ffXjEYXbPUQ&part=snippet,contentDetails&key=AIzaSyCW0c4fXbykXueatnBnUGE2g9t1zThS_-Q" https://www.googleapis.com/youtube/v3/subscriptions

~ $ curl -i -d "client_id=457835332683-7k3hgag48hd5rpseahsik6s76cdd71kf.apps.googleusercontent.com&client_secret=dgRS0Qm9Z0Mi24QM1bk6rii4&refresh_token=1/R6mS8UIWuh2-rKXKc1HAhdMnvQ8tCQzI4MJyCozuv0M&grant_type=refresh_token" https://www.googleapis.com/oauth2/v4/token

ya29.GlyXBDErqt4KPSA6GYwRJTV98hiUytf_0GyvbB4gf02m9w35aIG2tT8CXLQOACyv6C9aNMThenokMo9VRajnT0wPbR-ETnd4MJ-wLRxo5FoX5ty3ItDe_b995cVv5w

~ $ curl -i -G -d "maxResults=25&channelId=direwolf20&part=snippet,contentDetails&key=AIzaSyCW0c4fXbykXueatnBnUGE2g9t1zThS_-Q" https://www.googleapis.com/youtube/v3/playlists

UC_ViSsVg_3JUDyLS3E2Un5g

~/Repos/kadinparker/elisp $ curl -i -G -d "playlistId=PLaiPn4ewcbkHxqv1ao5R-piPIqRDe3kkI&maxResults=25&part=snippet,contentDetails&key=AIzaSyCW0c4fXbykXueatnBnUGE2g9t1zThS_-Q" https://www.googleapis.com/youtube/v3/playlistItems

(setq playlistId "PLaiPn4ewcbkGyctKCSmPfYxr366z4BkOJ")
(setq youtube-api-key "AIzaSyCW0c4fXbykXueatnBnUGE2g9t1zThS_-Q")

(defvar youtube-base-url "https://www.googleapis.com/youtube/v3/")

(defun youtube-playlist-query (id maxResults part key)
  (let ((url-request-method "GET")
        (arg-stuff (concat "?playlistId=" (url-hexify-string id)
                           "&maxResults=" (url-hexify-string maxResults)
                           "&part=" (url-hexify-string part)
                           "&key=" (url-hexify-string youtube-api-key))))
    (url-retrieve (concat youtube-base-url "playlistItems" arg-stuff)
                  (lambda (status)
                    (goto-char (point-min))
                    (re-search-forward "{")
                    (backward-char)
                    (delete-region (point) (point-min))
                    (setq youtube-returned-data (buffer-string))
                    (setq youtube-pretty-json (let ((json-object-type 'alist))
                                                (json-read-from-string youtube-returned-data)))))))

(defun youtube-display-titles ()
  (let* ((testing (append (cdr (assoc 'items youtube-pretty-json)) nil)))
    (dolist (elt testing)
      (insert (cdr (assoc 'title (assoc 'snippet elt))))
      (insert "\n"))))

(defun youtube-display-playlists (id maxResults part key))


