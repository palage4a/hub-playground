;; (local box (require "box"))

(fn newreq [call args]
  {"call" call
   "args" args})

(fn callReq [req]
  req.call)

(fn argsReq [req]
  req.args)

(fn doreq [r]
  (tset r "resp" (.. "response for "
                     (callReq r)
                     (accumulate [acc " [ "
                                      _ v (ipairs (argsReq r))]
                                      (.. acc v " "))
                     "]"))
  r)

(fn callResp [req]
  (. req "resp"))

(print (let [ didreq (doreq (newreq "storage.publish" ["queue" "sk" "rk" "payload"]))]
         (callResp didreq)))

;; (print (doreq (newreq "storage.publish" ["queue" "sk" "rk" "payload"])))
  
