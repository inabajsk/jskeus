;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; $Id$
;;;
;;; Copyright (c) 1987- JSK, The University of Tokyo.  All Rights Reserved.
;;;
;;; This software is a collection of EusLisp code for robot applications,
;;; which has been developed by the JSK Laboratory for the IRT project.
;;; For more information on EusLisp and its application to the robotics,
;;; please refer to the following papers.
;;;
;;; Toshihiro Matsui
;;; Multithread object-oriented language euslisp for parallel and
;;;  asynchronous programming in robotics
;;; Workshop on Concurrent Object-based Systems,
;;;  IEEE 6th Symposium on Parallel and Distributed Processing, 1994
;;;
;;; Permission to use this software for educational, research
;;; and non-profit purposes, without fee, and without a written
;;; agreement is hereby granted to all researchers working on
;;; the IRT project at the University of Tokyo, provided that the
;;; above copyright notice remains intact.  
;;;

(defun load-irteus ()
  (in-package "USER")
  (load-library
   (format nil "~A~A/lib/libirteus"
	   *eusdir* (unix:getenv "ARCHDIR"))
   '("irtmath" "irtutil" "irtc")))
(defun load-irteusg ()
  (in-package "GEOMETRY")
  (load-library
   (format nil "~A~A/lib/libirteusg"
	   *eusdir* (unix:getenv "ARCHDIR"))
   '("irtgeo" "euspqp" "pqp" "irtmodel" "irtrobot")))
(defun load-irteusx ()
  (in-package "X")
  (load-library
   (format nil "~A~A/lib/libirteusx"
	   *eusdir* (unix:getenv "ARCHDIR"))
   '("irtx" "eusjpeg"))
  (in-package "USER")
  )
(defun load-irteusgl ()
  (in-package "GL")
  (load-library
   (format nil "~A~A/lib/libirteusgl"
	   *eusdir* (unix:getenv "ARCHDIR"))
   '("irtglrgb" "irtgl" "irtviewer"))
  )

(unless (member (pathname-name *program-name*)
		(list "eus0" "eus1" "eus2" "eus" "eusx" "eusg" "eusgl")
		:test #'string=)
  (when (substringp "eus" (pathname-name *program-name*))
    (load-irteus))
  (when (or (substringp "eusg" (pathname-name *program-name*))
	    (substringp "eusx" (pathname-name *program-name*)))
    (load-irteusg))
  (when (or (substringp "eusx" (pathname-name *program-name*))
	    (substringp "eusgl" (pathname-name *program-name*)))
    (load-irteusx))
  (when (substringp "eusgl" (pathname-name *program-name*))
    (load-irteusgl)))

