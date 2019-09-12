(defpackage "MOBILE"
  (:use 
   #:COMMON-LISP 
   #:ACL-COMPAT.EXCL
   #:NET.HTML.GENERATOR
   #:NET.ASERVE)
  (:export
   #:jtest
   #:hexstr-to-char
   #:kb-decode
   #:kb-encode
   #:kbsb
   #:kbrd
   #:kb
   #:kbha
   #:kbprn
   #:start-server
   #:stop-server
   #:start-simple-server))

(in-package :mobile)

(defmacro make-jlist (body)
  "make list like ((x 1)(y 2)(z 3))"
  `(list ,@(mapcar #'(lambda (x)
                       `(list ,@x)) body)))


(defmacro make-json-list (&body body)
  "make list like ((a 1)(b 2)(c 3))"
  ;(cons (second body) nil))
  `(let ((lst ',body))
     (loop for item in lst  
       collect (list 
                (first item) 
                (eval (second item))))))
       
       
(defun string-print (stream str &key start (end (length str)))
  (let ((pos 0)
        (r (make-array 4 :fill-pointer 0 :adjustable t :element-type 'character)))
    (map nil #'(lambda(ch)
                 (if
                   (and (>= pos start) (<= pos end))
                   (format r "~c" ch)
                   ())
                 (incf pos))
         str)
    (format stream "~a" r)))
               

(defun string-replace (str &key oldstr newstr)
"analog of the replace function"
  (let* (
        (r (make-array 4 :fill-pointer 0 :adjustable t :element-type 'character))
        (len-oldstr (length oldstr))
        (pos-start 0)
        (pos-end (search oldstr str)))
    (progn
      (if (not pos-end)
          (return-from string-replace str)
          (loop do
               (string-print r str :start pos-start  :end (1- pos-end))
               (format r "~a" newstr)
               (setf pos-start (+ pos-end len-oldstr))
               (setf pos-end (search oldstr str :start2 pos-start))
             while pos-end))
      (string-print r str :start pos-start)
      r )))


(defun string-split (delimiter str)
  "split string by delimiter which is part of pattern"
    (loop for i = 0 then (1+ j) 
       as j = (position delimiter str :start i)
       collect (subseq str i j)
       while j))
  

(defun string-split-pattern (delimiter pattern str)
  "split string by delimiter which is part of pattern"
  (loop with offset = (position delimiter pattern) 
     for i = 0 then (1+ e) 
     as k = (search pattern str :start2 i)
     as e = (if k 
                (+ k offset) 
                k)
     collect (subseq str i e)
     while k))


(defun parse-number-if-possible(data)
  "if data is integer returns integer otherwise returns same data without changes"
  (if (eq 'SYMBOL (type-of (read-from-string data)))
      data
      (read-from-string data)))


(defun json-split-to-plist-entry(data)
  "split string in json format into symbol:value entry"
  (let ((lst (string-split #\: data)))
    (list (remove #\" (first lst)) 
          (parse-number-if-possible (remove #\" (second lst))))))


(defun json-object-to-plist(data)
  "convert json data into lisp plist"
  (let ((dt (remove #\{ (remove #\} data))))
    (loop for i in (string-split-pattern #\, "\",\"" dt)
       collect (json-split-to-plist-entry i))))


(defun list-to-json (lst)
  "convert plist like list into json formatted string"
  (let ((stream (mu-string)))
  (format stream "{")
  (loop with i = 0 for item in lst do
       (format stream "~s:~s~@[,~]" 
               (first item) 
               (second item) 
               (/= (incf i) (length lst))))
  (format stream "}")
  stream))


(defun fn-login (&key uid pwd)
  "get first and last name in json format by uid and pwd"
  (let* ((lst (get-account-id :uid uid :pwd pwd))
         (id-local (first lst))
         (login-local "")
         (sid-local "")
         (fname-local "")
         (lname-local ""))
    (if id-local
        (with-slots ((login login) 
                     (fname fname) 
                     (lname lname)) (elt *accounts* id-local)
          (setf sid-local (session-login-to-id login))
          (setf login-local "1")
          (setf fname-local fname)
          (setf lname-local lname))

        (setf login-local (if (second lst) 
                              "1"
                              "")))
    (list-to-json 
     (make-jlist (("sid"   sid-local)
                  ("login" login-local)
                  ("fname" fname-local)
                  ("lname" lname-local))))))


(defun fn-signup (&key uid pwd fname lname)
  "sign up new user"
  (let* ((lst (get-account-id :uid uid :pwd pwd))
         (id-local (first lst))
         (login-local "")
         (sid-local "")
         (fname-local fname)
         (lname-local lname))
    (if id-local
        (setf login-local "")
        (progn
          (accounts-ins uid pwd fname lname "email@localhost.com")
          (setf sid-local (session-login-to-id uid)) 
          (setf login-local "1")))

    (list-to-json 
     (make-jlist (("sid"   sid-local)
                  ("login" login-local)
                  ("fname" fname-local)
                  ("lname" lname-local))))))


(defparameter *fn-hash* (make-hash-table  :test 'equal))


(defun json-fn (data)
  "call function given as first entry in json data"
  (let* ((lst (json-object-to-plist data))
         (fnstr (concatenate 'string (first (first lst)) "-" (second (first lst))))
         (fn (gethash fnstr *fn-hash*))
         (arg-list
          (loop for item in (cdr lst)
             collect (find-symbol (string-upcase (first item)) 'keyword)
             collect (second item))))
    (if fn 
        (apply fn arg-list)
        data)))

 
(setf (gethash "fn-login" *fn-hash*) (symbol-function (find-symbol (string-upcase "fn-login"))))
(setf (gethash "fn-signup" *fn-hash*) (symbol-function (find-symbol (string-upcase "fn-signup"))))


(defun kb (s x)
  (format s "~a" 
          (kb-encode
           (json-fn
            (kb-decode x)))))


(defmacro kbha (qq)
   (let ((q qq))
     `(kb net.html.generator:*html-stream* ,q)))


(defun json-test2 (req ent)
  (let ((req-query-res (get-request-body req)))
    (with-http-response (req ent)
      (with-http-body (req ent)
        (html (kbha req-query-res)   )))))
