(ns csvdb.core
  (:require [clojure-csv.core :as csv]))

(defn- parse-int [int-str]
  (Integer/parseInt int-str))


(def student-tbl (csv/parse-csv (slurp "student.csv")))
(def subject-tbl (csv/parse-csv (slurp "subject.csv")))
(def student-subject-tbl (csv/parse-csv (slurp "student_subject.csv")))

;; (table-keys student-tbl)
;; => [:id :surname :year :group_id]
;;
;; Hint: vec, map, keyword, first
(defn table-keys [tbl]
  (vec (map keyword (first tbl))))

;; (key-value-pairs [:id :surname :year :group_id] ["1" "Ivanov" "1996"])
;; => (:id "1" :surname "Ivanov" :year "1996")
;;
;; Hint: flatten, map, list
(defn key-value-pairs [tbl-keys tbl-record]
  (flatten (map #(list %1 %2) tbl-keys tbl-record)))


;; (data-record [:id :surname :year :group_id] ["1" "Ivanov" "1996"])
;; => {:surname "Ivanov", :year "1996", :id "1"}
;;
;; Hint: apply, hash-map, key-value-pairs
(defn data-record [tbl-keys tbl-record]
  (apply hash-map (key-value-pairs tbl-keys tbl-record)))

;; (data-table student-tbl)
;; => ({:surname "Ivanov", :year "1996", :id "1"}
;;     {:surname "Petrov", :year "1996", :id "2"}
;;     {:surname "Sidorov", :year "1997", :id "3"})
;;
;; Hint: let, map, next, table-keys, data-record
(defn data-table [tbl]
  (let [keys (table-keys tbl)]
    (map (partial data-record keys) (next tbl))))

(comment
  (data-table student-tbl))

;; (str-field-to-int :id {:surname "Ivanov", :year "1996", :id "1"})
;; => {:surname "Ivanov", :year "1996", :id 1}
;;
;; Hint: assoc, Integer/parseInt, get
(defn str-field-to-int [field rec]
  (assoc rec field (Integer/parseInt (field rec))))

(comment
  (Integer/parseInt "2")
  (first (data-table student-tbl))
  (str-field-to-int :id (first (data-table student-tbl))))

(def student (->> (data-table student-tbl)
                  (map #(str-field-to-int :id %))
                  (map #(str-field-to-int :year %))))

(comment
  student)

(def subject (->> (data-table subject-tbl)
                  (map #(str-field-to-int :id %))))

(comment
  subject)

(def student-subject (->> (data-table student-subject-tbl)
                          (map #(str-field-to-int :subject_id %))
                          (map #(str-field-to-int :student_id %))))

(comment
  student-subject)

;; (where* student (fn [rec] (> (:id rec) 1)))
;; => ({:surname "Petrov", :year 1997, :id 2} {:surname "Sidorov", :year 1996, :id 3})
;;
;; Hint: if-not, filter
(defn where* [data condition-func]
  (filter condition-func data))


(comment
  (->> student
       (filter #( > (:id %) 2)))

  (where* student (fn [rec] (> (:id rec) 1)))

  (where* () (fn [rec] (> (:id rec) 1)))

  student
  )


;; (limit* student 1)
;; => ({:surname "Ivanov", :year 1998, :id 1})
;;
;; Hint: if-not, take
(defn limit* [data lim]
  (take lim data))


(comment

  (take 2 student)

  (limit* student 1)
  )
;; (order-by* student :year)
;; => ({:surname "Sidorov", :year 1996, :id 3} {:surname "Petrov", :year 1997, :id 2} {:surname "Ivanov", :year 1998, :id 1})
;; Hint: if-not, sort-by
(defn order-by* [data column]
  (sort-by column data))


(comment

  (order-by* student :id)

  )

;; (join* (join* student-subject :student_id student :id) :subject_id subject :id)
;; => [{:subject "Math", :subject_id 1, :surname "Ivanov", :year 1998, :student_id 1, :id 1}
;;     {:subject "Math", :subject_id 1, :surname "Petrov", :year 1997, :student_id 2, :id 2}
;;     {:subject "CS", :subject_id 2, :surname "Petrov", :year 1997, :student_id 2, :id 2}
;;     {:subject "CS", :subject_id 2, :surname "Sidorov", :year 1996, :student_id 3, :id 3}]
;;
;; Hint: reduce, conj, merge, first, filter, get
;; Here column1 belongs to data1, column2 belongs to data2.
(defn join* [data1 column1 data2 column2]
  ;; 1. Start collecting results from empty collection.
  ;; 2. Go through each element of data1.
  ;; 3. For each element of data1 (lets call it element1) find all elements of data2 (lets call each as element2) where column1 = column2.
  ;; 4. Use function 'merge' and merge element1 with each element2.
  ;; 5. Collect merged elements.
  :ImplementMe!)


(comment

  (first student)
  (first subject)


  student

  (merge (first student) (first subject))

  student
  subject
  student-subject-tbl




  ;;  (filter (fn [elem1]
  ;;            (= (:subject_id elem1) (:id (first (filter (fn [elem2]
  ;;                                                     (= (:id elem2)) subject))))) student)



  (filter (fn [elem1]
            (first (filter (fn [elem2]
                             (= (:subject_id elem1) (:id elem2))) subject)))
          student)



  (filter (fn [elem1]
            (= (:id (filter (fn [elem2]
                              (= ())))))))

  )

;; (perform-joins student-subject [[:student_id student :id] [:subject_id subject :id]])
;; => [{:subject "Math", :subject_id 1, :surname "Ivanov", :year 1998, :student_id 1, :id 1} {:subject "Math", :subject_id 1, :surname "Petrov", :year 1997, :student_id 2, :id 2} {:subject "CS", :subject_id 2, :surname "Petrov", :year 1997, :student_id 2, :id 2} {:subject "CS", :subject_id 2, :surname "Sidorov", :year 1996, :student_id 3, :id 3}]
;;
;; Hint: loop-recur, let, first, next, join*
(defn perform-joins [data joins*]
  (loop [data1 data
         joins joins*]
    (if (empty? joins)
      data1
      (let [[col1 data2 col2] (first joins)]
        (recur (join* data1 col1 data2 col2)
               (next joins))))))

(defn select [data & {:keys [where limit order-by joins]}]
  (-> data
      (perform-joins joins)
      (where* where)
      (order-by* order-by)
      (limit* limit)))

(select student)
;; => [{:id 1, :year 1998, :surname "Ivanov"} {:id 2, :year 1997, :surname "Petrov"} {:id 3, :year 1996, :surname "Sidorov"}]

(select student :order-by :year)
;; => ({:id 3, :year 1996, :surname "Sidorov"} {:id 2, :year 1997, :surname "Petrov"} {:id 1, :year 1998, :surname "Ivanov"})

(select student :where #(> (:id %) 1))
;; => ({:id 2, :year 1997, :surname "Petrov"} {:id 3, :year 1996, :surname "Sidorov"})

(select student :limit 2)
;; => ({:id 1, :year 1998, :surname "Ivanov"} {:id 2, :year 1997, :surname "Petrov"})

(select student :where #(> (:id %) 1) :limit 1)
;; => ({:id 2, :year 1997, :surname "Petrov"})

(select student :where #(> (:id %) 1) :order-by :year :limit 2)
;; => ({:id 3, :year 1996, :surname "Sidorov"} {:id 2, :year 1997, :surname "Petrov"})

(select student-subject :joins [[:student_id student :id] [:subject_id subject :id]])
;; => [{:subject "Math", :subject_id 1, :surname "Ivanov", :year 1998, :student_id 1, :id 1} {:subject "Math", :subject_id 1, :surname "Petrov", :year 1997, :student_id 2, :id 2} {:subject "CS", :subject_id 2, :surname "Petrov", :year 1997, :student_id 2, :id 2} {:subject "CS", :subject_id 2, :surname "Sidorov", :year 1996, :student_id 3, :id 3}]

(select student-subject :limit 2 :joins [[:student_id student :id] [:subject_id subject :id]])
;; => ({:subject "Math", :subject_id 1, :surname "Ivanov", :year 1998, :student_id 1, :id 1} {:subject "Math", :subject_id 1, :surname "Petrov", :year 1997, :student_id 2, :id 2})
