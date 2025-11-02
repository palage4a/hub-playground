(ns clojure-noob.core
  (:gen-class))

(defn -main
  "I don't do a whole lot ... yet."
  [& args]
  (println "I'm a little teapot!"))

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
