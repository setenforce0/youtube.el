(require 'request)
(setq cid "457835332683-7k3hgag48hd5rpseahsik6s76cdd71kf.apps.googleusercontent.com"
      csec "dgRS0Qm9Z0Mi24QM1bk6rii4")

;; (setq user-input (read-string "String: "))

(request
 "https://www.googleapis.com/youtube/v3/search"
 :params '(("part" . "id,snippet") ("q" . "haskell"))
 :headers '(("Authorization" . "Bearer ya29.Glx9BPB2bovLoCqs0E3AHiHt5kscfu1vOTrW4zVLcUZ3p4ANFZV7_ZpzH5UrmpU0qMoeOcHXY4jknKvRdYiKqIhtmaE494uKzKxWPq81DbsFn4jgoT1eiBoiFNoDJw"))
 :parser 'json-read
 :success (function*
           (lambda (&key data &allow-other-keys)
             (let* ((item (elt (assoc-default 'items data) 0))
                    (snippet (assoc-default 'snippet item))
                    (title (assoc-default 'title snippet)))
               (message "%s" title)))))
