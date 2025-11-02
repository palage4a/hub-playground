(local fiber (require "fiber"))

(fn cluster [replicasets]
  {: replicasets})

(fn cluster-each [cluster fun]
  (each [_ rs (ipairs cluster.replicasets)]
    (fun rs.name rs)))








(fn req [call args]
  {: call
   : args})

(fn req-args [req]
  (. req "call"))

(fn req-args [req]
  (. req "args"))

(fn req-tostring [req]
  (.. "req " 
     req.call
     "["
     (table.concat (req-args req) ",")
    ;;  (accumulate [acc "[ "
    ;;               _ v (ipairs (req-args req))]
    ;;    (table.concat acc v ", "))
     "]"
     ))







(fn resp [req out]
  {: req
   : out})

(fn resp-out [resp]
  (. resp "out"))











(fn instance [name]
  {: name})

(fn instance-do [instance req]
  (print (.. "Executed request on " instance.name ": " (req-tostring req)))
  (resp req (tostring (math.random 19000))))








(fn replicaset [name]
  {: name
   "instances" (fcollect [i 1 4 1]
                 (instance (.. name "-" (tostring i))))
   "curid" 0 })

(fn replicaset-next-instance [replicaset]
  (tset replicaset "curid" (+ replicaset.curid 1))
  (. replicaset.instances (+ (% (+ (length replicaset.instances) 1) replicaset.curid) 1)))

(fn replicaset-do-instance [replicaset name req]
  (let [found-instance (. (icollect [_ inst (ipairs replicaset.instances)]
       (if (= inst.name name) inst)) 1)]
    (instance-do found-instance req)))

(fn replicaset-do [replicaset req]
  (instance-do (replicaset-next-instance replicaset) req))

(fn replicaset-each [replicaset fun]
  (each [_ ins (ipairs replicaset.instances)]
    (fun ins.name ins)))







(fn poller [replicaset instance cursor params]
  {: replicaset
   : params
   : cursor
   "curinst" instance
   "id" ""})


(fn poller-poll [poller]
  (replicaset-do-instance poller.replicaset poller.curinst
                          (req "storae.poll_from" [poller.id])))

(fn poller-create [poller params]
  (let [poller-id (replicaset-do-instance poller.replicaset poller.curinst 
                          (req "storage.create_poller" params))]
   (set poller.id poller-id)))













(fn chan []
  [])

(fn chan-put [ch message]
  (table.insert ch message))

(fn chan-get [ch]
  (table.remove ch (length ch)))
















(fn consumer [cluster]
  {: cluster
   "pollers" []})

(fn consumer-consume [consumer params]
  (let [ch (chan)]
  (each [_ p (ipairs consumer.pollers)]
    (fiber.create (fn []
                    (while true
                      (poller-poll p)))))
  ch))

(fn commit [consumer cursor]
  :true)


(fn main []
  (let [params [ "queue" "sharding_key" ]
        cluster (cluster [(replicaset "s-1") (replicaset "s-2")])]
    (cluster-each cluster
                  (fn [rsname rs]
                    (fiber.create (fn []
                       (replicaset-each rs
                                         (fn [iname _]
                                           (let [p (poller rs iname) ]
                                             (for [_ 1 (math.random 5)] 
                                               (print)
                                               (print (.. "create poller for " rsname))
                                               (let [resp (replicaset-do-instance rs iname
                                                                                (req "storage.create_poller" params))]
                                                 (for [_ 1 (math.random 5)] 
                                                   (print)
                                                   (replicaset-do-instance rs iname (req "storage.poll_from" [resp.out]))
                                                   (fiber.sleep 1)))))))))))
    (print "Done")))

(main)
