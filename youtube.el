(require 'request)
;; (setq cid "457835332683-7k3hgag48hd5rpseahsik6s76cdd71kf.apps.googleusercontent.com"
;;       csec "dgRS0Qm9Z0Mi24QM1bk6rii4")
;; (setq user-input (read-string "String: "))
(setq authtoken "ya29.Glt-BMPipsaTquQ96yM4_JqVd-CLfmY-a5bOq6IyDH2gpksCTGVfyf3NOb92eHRB2xOTQliaC-SpYXXHY1FrSK262DekTUo3DuuHaNP9n47V-N8wju5jl4jqBkUb")

(defun yt-search-videos (query authtoken)
  (request
   "https://www.googleapis.com/youtube/v3/search"
   :params `(("part" . "id,snippet") ("q" . ,query))
   :headers `(("Authorization" . ,(concat "Bearer " authtoken)))
   :parser 'json-read
   :success (function*
             (lambda (&key data &allow-other-keys)
               (let* ((item (elt (assoc-default 'items data) 0 ))
                      (snippet (assoc-default 'snippet item))
                      (title (assoc-default 'title snippet)))
               (let ((buffer (get-buffer-create "*youtube*")))
                 (with-current-buffer buffer
                   (insert title))
                 (switch-to-buffer buffer)))))))

(yt-search-videos "haskell" authtoken)
