(ns clojure-noob.core
  (:gen-class))

(defn -main
  "I don't do a whole lot ... yet."
  [& args]
  (println "I'm a little teapot!"))

(comment
  (-main)

  (+ 2 4)

  (str "It was the panda " "in the library " "with a dust buster")

  (if true
    "By Zeus's hammer!"
    "By Aquaman's tridgen")

  (if false
    "By Odin's elbow!")


  (if true
    (do (println "Success")
        "By Zeus's hammer!")
    (do (println "Failure")
        "By Aquaman's trident!"))

  (when true
    (println "Success!")
    "abra cadabar")


  (nil? 1)

  (nil? nil)

  (nil? false)


  (if "some string is logical truthiness"
    "it's okey"
    "never ok")

  (if nil
    "too bad for you"
    "nil is logical falsiness")

  (= 1 1)

  (= 1 2)

  (def ager
    [{:type :person
      :age 15}
     {:type :car
      :releaseYear "1997"}
     {:type :dishwash
      :soldYear "2009"}])

  (defmulti age (fn [v] (:type v)))

  (defmethod age :person [v]
    (:age v))

  (defmethod age :car [v]
    (- (.getValue (java.time.Year/now)) (Integer/parseInt (:releaseYear v))))

  (defmethod age :dishwash [v]
    (- (.getValue (java.time.Year/now)) (Integer/parseInt (:soldYear v))))


  (map #(age %) ager)

  )