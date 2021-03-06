(require :unittest "lib/llib/unittest.l")
(init-unit-test)

(defun test-collision-sphere-analytical
    ()
  (let* ((radius1 100)
         (radius2 200)
         (obj1 (make-sphere radius1))
         (obj2 (make-sphere radius2))
         (cnt 0)
         (dist)
         (analy-dist)
         (ret)
         )
    (send obj1 :set-color (float-vector 1 0 0) 0.5)
    (send obj2 :set-color (float-vector 0 1 0) 0.4)
    (objects (list obj1 obj2))
    (do-until-key
     ;; move object
     (incf cnt)
     (send obj1 :newcoords (make-coords :pos (float-vector (* 500.0 (sin (/ cnt 20.0))) 50 0)))
     (send *irtviewer* :draw-objects)
     ;; get bullet distance
     (setq ret (collision-distance obj1 obj2))
     (setq dist (elt ret 0))
     ;; get analytical distance and compare
     (setq analy-dist (- (norm (send obj1 :worldpos)) (+ radius1 radius2)))
     (cond ((eq *collision-algorithm* *collision-algorithm-pqp*)
            ;; very large tolerance for pqp algorithm because
            ;; 1) pqp does not return correct collision distance when collision occurs.
            ;; 2) pqp does not return correct collision detection (i.e., 0 or 1 detection) when if one object is completely contained in the other object.
            ;; 3) euspqp.c and CPQP.c do not treat euslisp sphere model as sphere but treat as polyhedron mesh.
            (assert (eps= dist analy-dist 1e3))
            )
           ((eq *collision-algorithm* *collision-algorithm-bullet*)
            (assert (eps= dist analy-dist 1e-3))
            )
           (t
            (error "invalid collision algorithm: ~a~%" *collision-algorithm*)
            ))
     ;; draw
     (send (elt ret 1) :draw-on :flush nil :width 16 :size 50 :color (float-vector 1 0.4 0.4))
     (send (elt ret 2) :draw-on :flush nil :width 16 :size 50 :color (float-vector 0.4 1 0.4))
     (send (make-line (elt ret 1) (elt ret 2)) :draw-on :flush nil
           :width 8 :color (if (> (elt ret 0) 0) (float-vector 0 1 1) (float-vector 1 1 0)))
     (send *irtviewer* :viewer :flush)
     (unix::usleep (* 20 1000))
     (when (> cnt 100)
       (return-from nil nil))
     )
    ))

(defun test-collision-object-approx
    (obj1 obj2)
  (let* ((bbox-radius1
          (norm (v- (send (send obj1 :box) :center) (send (send obj1 :box) :maxpoint))))
         (bbox-radius2
          (norm (v- (send (send obj2 :box) :center) (send (send obj2 :box) :maxpoint))))
         (cnt 0)
         (dist)
         (approx-dist-min)
         (approx-dist-max)
         (ret)
         )
    (send obj1 :set-color (float-vector 1 0 0) 0.5)
    (send obj2 :set-color (float-vector 0 1 0) 0.4)
    (objects (list obj1 obj2))
    (do-until-key
     ;; move object
     (incf cnt)
     (send obj1 :newcoords
           (make-coords :pos (float-vector (* 750.0 (sin (/ cnt 20.0))) 50 0)
                        :rpy (list (* pi (sin (/ cnt 200.0))) (+ (* pi (sin (/ cnt 400.0))) pi/2) 0)))
     (send *irtviewer* :draw-objects)
     ;; get bullet distance
     (setq ret (collision-distance obj1 obj2))
     (setq dist (elt ret 0))
     ;; get approximate distance and compare
     (setq approx-dist-max
           (norm (v- (send (send obj1 :box) :center) (send (send obj2 :box) :center))))
     (setq approx-dist-min
           (- approx-dist-max (+ bbox-radius1 bbox-radius2)))
     ;; (format t "[result: ~a] ~a < ~a < ~a~%"
     ;;         (< approx-dist-min dist approx-dist-max)
     ;;         approx-dist-min dist approx-dist-max)
     (assert (< approx-dist-min dist approx-dist-max))
     ;; draw
     (send (elt ret 1) :draw-on :flush nil :width 16 :size 50 :color (float-vector 1 0.4 0.4))
     (send (elt ret 2) :draw-on :flush nil :width 16 :size 50 :color (float-vector 0.4 1 0.4))
     (send (make-line (elt ret 1) (elt ret 2)) :draw-on :flush nil
           :width 8 :color (if (> (elt ret 0) 0) (float-vector 0 1 1) (float-vector 1 1 0)))
     (send *irtviewer* :viewer :flush)
     (unix::usleep (* 20 1000))
     (when (> cnt 100)
       (return-from nil nil))
     )
    ))

(defun test-collision-distance
    (obj1 obj2)
  (let* ((bbox-radius
          (elt (v- (send (send obj1 :box) :center) (send (send obj1 :box) :minpoint)) 1))
         (cnt 0)
         (dist)
         (approx-dist-min)
         (approx-dist-max)
         (ret1) (ret2) (ret3)
         )
    (send obj1 :set-color (float-vector 1 0 0) 0.5)
    (send obj2 :set-color (float-vector 0 1 0) 0.4)
    (objects (list obj1 obj2))
    (do-until-key
     ;; move object
     (incf cnt)
     (send obj1 :newcoords
           (make-coords :pos (float-vector (* 300.0 (sin (/ cnt 20.0))) 50 0)))
     (send obj1 :worldcoords)
     (send *irtviewer* :draw-objects)
     ;; get pqp/bullet distance
     ;; PQP requries geo::PQP_FIRST_CONTACT, where as bullet does not need this
     (setf (get obj1 :pqpmodel) nil) (setf (get obj1 :btmodel) nil) ;; clear cache
     (setf (get obj2 :pqpmodel) nil) (setf (get obj2 :btmodel) nil)
     (setq ret1 (collision-check obj1 obj2 geo::PQP_FIRST_CONTACT))
     (setf (get obj1 :pqpmodel) nil) (setf (get obj1 :btmodel) nil) ;; clear cache
     (setf (get obj2 :pqpmodel) nil) (setf (get obj2 :btmodel) nil)
     (setq ret2 (collision-check obj1 obj2))
     (setf (get obj1 :pqpmodel) nil) (setf (get obj1 :btmodel) nil) ;; clear cache
     (setf (get obj2 :pqpmodel) nil) (setf (get obj2 :btmodel) nil)
     (send obj1 :make-collisionmodel :faces (send obj1 :faces))
     (send obj2 :make-collisionmodel :faces (send obj2 :faces))
     (setq ret3 (collision-check obj1 obj2))
     (assert (and (eq ret1 ret2) (eq ret1 ret3)))
     ;; get approximate distance and compare
     (setq approx-dist-max
           (norm (v- (send (send obj1 :box) :center) (send (send obj2 :box) :center))))
     (setq approx-dist-min
           (- approx-dist-max (+ bbox-radius bbox-radius)))
     ;(format t "ret: ~A/~A/~A dist-min: ~A, (~A ~A)~%" ret1 ret2 ret3 approx-dist-min (> ret1 0) (< approx-dist-min 0))
     (assert (or (and (> ret1 0) (< approx-dist-min 5))
                 (and (= ret1 0) (> approx-dist-min -5))))
     ;; draw
     (when (> ret1 0)
       (send obj1 :draw-on :flush nil :width 16 :color (float-vector 1 0.4 0.4))
       (send obj2 :draw-on :flush nil :width 16 :color (float-vector 0.4 1 0.4)))
     (send *irtviewer* :viewer :flush)
     (unix::usleep (* 20 1000))
     (when (> cnt 100)
       (return-from nil nil))
     )
    ))

(defun test-collision-distance-fat
    (obj1 obj2 &optional (fat 25))
  (let* ((cnt 0) dist dist-fat ret ret-fat)
    (send obj1 :set-color (float-vector 1 0 0) 0.5)
    (send obj2 :set-color (float-vector 0 1 0) 0.4)
    (objects (list obj1 obj2))
    (do-until-key
     ;; move object
     (incf cnt)
     (send obj1 :newcoords
           (make-coords :pos (float-vector (* 750.0 (sin (/ cnt 20.0))) 50 0)))
     ;; do not rotate on cube, otherwise the distance with margin becomes very complex
     (unless (assoc :cube (send obj1 :csg))
       (send obj1 :rpy (* pi (sin (/ cnt 200.0))) (+ (* pi (sin (/ cnt 400.0))) pi/2) 0))
     (send obj1 :worldcoords)
     (send *irtviewer* :draw-objects)
     ;; get pqp/bullet distance
     ;; PQP requries geo::PQP_FIRST_CONTACT, where as bullet does not need this
     (setf (get obj1 :pqpmodel) nil) (setf (get obj1 :btmodel) nil) ;; clear cache
     (setf (get obj2 :pqpmodel) nil) (setf (get obj2 :btmodel) nil)
     (setq ret1 (collision-distance obj1 obj2))
     (setf (get obj1 :pqpmodel) nil) (setf (get obj1 :btmodel) nil) ;; clear cache
     (setf (get obj2 :pqpmodel) nil) (setf (get obj2 :btmodel) nil)
     (setq ret2 (collision-distance obj1 obj2 :fat fat))
     ;; check if fat works
     (setq dist (elt ret1 0) dist-fat (elt ret2 0))
     (when (and (eps> dist 0.0) (eps> dist-fat 0.0)) ;; when collide
       (warning-message
        (cond ((< (- dist dist-fat) (* fat 1.5)) 3)
              (t 2))
        "distance between objects ~7,3f ~7,3f ~7,3f~%" (- dist dist-fat ) dist dist-fat)
       (assert (< (* fat 1.05) (- dist dist-fat) (* fat 2.1))))
     ;;
     (send (elt ret2 1) :draw-on :flush nil :width 8 :size 50 :color (float-vector 1 0.4 0.4))
     (send (elt ret2 2) :draw-on :flush nil :width 8 :size 50 :color (float-vector 0.4 1 0.4))
     (send (make-line (elt ret2 1) (elt ret2 2)) :draw-on :flush nil
           :width 8 :color (if (> (elt ret2 0) 0) (float-vector 0 1 1) (float-vector 1 1 0)))
     (send *irtviewer* :viewer :flush)
     (x::window-main-one)
     (unix::usleep (* 20 1000))
     (when (> cnt 100)
       (return-from nil nil))
     )
    ))

(load "models/darwin.l")
;; use add no-face link for euscollada-robot, use darwin-robot to override
(defmethod darwin-robot
  ;; make collision model from faces or gl-vertices
  (:make-collision-model-for-links
   (&key (fat 0) ((:links ls) (send self :links)))
   ;;
   ;; for append camera links for test code
   (let (l)
     (setq l (instance bodyset-link :init (make-cascoords) :name "dummy-link"))
     (send (car links) :add-child-links l)
     (setq links (append links (list l)))
     (setq ls (send self :links)))
   )
  )

(when *collision-algorithm-pqp*

(deftest test-collision-sphere-analytical-pqp
  (select-collision-algorithm *collision-algorithm-pqp*)
  (test-collision-sphere-analytical)
  )

(deftest test-collision-cube-approx-pqp
  (select-collision-algorithm *collision-algorithm-pqp*)
  (test-collision-object-approx
   (make-cube 100 150 200) (make-cube 200 200 300))
  )

(deftest test-collision-cylinder-approx-pqp
  (select-collision-algorithm *collision-algorithm-pqp*)
  (test-collision-object-approx
   (make-cylinder 100 200) (make-cube 200 200 300))
  )

(deftest test-collision-mesh-approx-pqp
  (select-collision-algorithm *collision-algorithm-pqp*)
  (test-collision-object-approx
   (make-cone (float-vector 0 0 200) (list (float-vector -200 -200 0) (float-vector 200 -200 0) (float-vector 0 250 0))) ;; cone is treated as mesh
   (make-cube 200 200 300))
  )

(deftest test-collision-distance-pqp
  (select-collision-algorithm *collision-algorithm-pqp*)
  (test-collision-distance
   (make-cube 200 200 200)
   (make-cube 200 200 200)))

(deftest test-collision-distance-cube-pqp
  (select-collision-algorithm *collision-algorithm-pqp*)
  (test-collision-distance-fat
   (make-cube 200 300 200)
   (make-cube 200 200 200)))

(deftest test-collision-distance-cylinder-pqp
  (select-collision-algorithm *collision-algorithm-pqp*)
  (test-collision-distance-fat
   (make-cube 200 300 200)
   (make-cylinder 100 200)))

(deftest test-collision-distance-sphere-pqp
  (select-collision-algorithm *collision-algorithm-pqp*)
  (test-collision-distance-fat
   (make-sphere 200)
   (make-sphere 200)))

(deftest test-collision-distance-mesh-pqp
  (select-collision-algorithm *collision-algorithm-pqp*)
  (test-collision-distance-fat
   (body+ (make-cube 200 200 100) (make-cube 100 100 300))
   (body+ (make-cube 200 200 100) (make-cube 100 100 300))))

)

(when *collision-algorithm-bullet*

(deftest test-collision-sphere-analytical-bullet
  (select-collision-algorithm *collision-algorithm-bullet*)
  (test-collision-sphere-analytical)
  )

(deftest test-collision-cube-approx-bullet
  (select-collision-algorithm *collision-algorithm-bullet*)
  (test-collision-object-approx
   (make-cube 100 150 200) (make-cube 200 200 300))
  )

(deftest test-collision-cylinder-approx-bullet
  (select-collision-algorithm *collision-algorithm-bullet*)
  (test-collision-object-approx
   (make-cylinder 100 200) (make-cube 200 200 300))
  )

(deftest test-collision-mesh-approx-bullet
  (select-collision-algorithm *collision-algorithm-bullet*)
  (test-collision-object-approx
   (make-cone (float-vector 0 0 200) (list (float-vector -200 -200 0) (float-vector 200 -200 0) (float-vector 0 250 0))) ;; cone is treated as mesh
   (make-cube 200 200 300))
  )

(deftest test-collision-distance-bullet
  (select-collision-algorithm *collision-algorithm-bullet*)
  (test-collision-distance
   (make-cube 200 200 200)
   (make-cube 200 200 200)))

(deftest test-collision-distance-cube-bullet
  (select-collision-algorithm *collision-algorithm-bullet*)
  (test-collision-distance-fat
   (make-cube 200 300 200)
   (make-cube 200 200 300)))

(deftest test-collision-distance-cylinder-bullet
  (select-collision-algorithm *collision-algorithm-bullet*)
  (test-collision-distance-fat
   (make-cube 200 300 200)
   (make-cylinder 100 200)))

(deftest test-collision-distance-sphere-bullet
  (select-collision-algorithm *collision-algorithm-bullet*)
  (test-collision-distance-fat
   (make-sphere 200)
   (make-sphere 200)))

(deftest test-collision-distance-mesh-bullet
  (select-collision-algorithm *collision-algorithm-bullet*)
  (test-collision-distance-fat
   (body+ (make-cube 200 200 100) (make-cube 100 100 300))
   (body+ (make-cube 200 200 100) (make-cube 100 100 300))))

)

;; not sure why, but put this function within (when *collision-algorithm-pqp* causes errors...
(deftest test-self-collision-check-pqp
  (when *collision-algorithm-pqp*
    (setq *collision-algorithm* *collision-algorithm-pqp*)
    (let (robot)
      (setq robot (instance darwin-robot :init))
      (send robot :self-collision-check)
      )))


(deftest test-self-collision-check-bullet
  (when  *collision-algorithm-bullet*
    (setq *collision-algorithm* *collision-algorithm-bullet*)
    (let (robot)
      (setq robot (instance darwin-robot :init))
      (send robot :self-collision-check)
      )))

(eval-when (load eval)
  (run-all-tests)
  (exit 0))
