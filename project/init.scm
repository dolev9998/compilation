;;; init.scm
;;; Initial definitions that should be available for the compiler
;;;
;;; Programmer: Mayer Goldberg, 2024

(define (caar x) (car (car x)))
(define (cadr x) (car (cdr x)))
(define (cdar x) (cdr (car x)))
(define (cddr x) (cdr (cdr x)))
(define (caaar x) (car (caar x)))
(define (caadr x) (car (cadr x)))
(define (cadar x) (car (cdar x)))
(define (caddr x) (car (cddr x)))
(define (cdaar x) (cdr (caar x)))
(define (cdadr x) (cdr (cadr x)))
(define (cddar x) (cdr (cdar x)))
(define (cdddr x) (cdr (cddr x)))
(define (caaaar x) (caar (caar x)))
(define (caaadr x) (caar (cadr x)))
(define (caadar x) (caar (cdar x)))
(define (caaddr x) (caar (cddr x)))
(define (cadaar x) (cadr (caar x)))
(define (cadadr x) (cadr (cadr x)))
(define (caddar x) (cadr (cdar x)))
(define (cadddr x) (cadr (cddr x)))
(define (cdaaar x) (cdar (caar x)))
(define (cdaadr x) (cdar (cadr x)))
(define (cdadar x) (cdar (cdar x)))
(define (cdaddr x) (cdar (cddr x)))
(define (cddaar x) (cddr (caar x)))
(define (cddadr x) (cddr (cadr x)))
(define (cdddar x) (cddr (cdar x)))
(define (cddddr x) (cddr (cddr x)))

(define (list? e)
  (or (null? e)
      (and (pair? e)
           (list? (cdr e)))))

(define list (lambda args args))

(define (not x) (if x #f #t))

(define (rational? q)
  (or (integer? q)
      (fraction? q)))

(define list*
  (letrec ((run
             (lambda (a s)
               (if (null? s)
                   a
                   (cons a
                     (run (car s) (cdr s)))))))
    (lambda (a . s)
      (run a s))))

(define apply
  (letrec ((run
             (lambda (a s)
               (if (pair? s)
                   (cons a
                     (run (car s)
                       (cdr s)))
                   a))))
    (lambda (f . s)
      (__bin-apply f
        (run (car s)
          (cdr s))))))

(define ormap
  (lambda (f . s)
    (letrec ((loop
               (lambda (s)
                 (and (pair? (car s))
                      (or (apply f (map car s))
                          (loop (map cdr s)))))))
      (and (pair? s)
           (loop s)))))

(define andmap
  (lambda (f . s)
    (letrec ((loop
               (lambda (s)
                 (or (null? (car s))
                     (and (apply f (map car s))
                          (loop (map cdr s)))))))
      (or (null? s)
          (and (pair? s)
               (loop s))))))

(define map
  (letrec ((map1
             (lambda (f s)
               (if (null? s)
                   '()
                   (cons (f (car s))
                     (map1 f (cdr s))))))
           (map-list
             (lambda (f s)
               (if (null? (car s))
                   '()
                   (cons (apply f (map1 car s))
                     (map-list f
                       (map1 cdr s)))))))
    (lambda (f . s)
      (if (null? s)
          '()
          (map-list f s)))))

(define reverse
  (lambda (s)
    (fold-left
      (lambda (r a) (cons a r))
      '()
      s)))

(define append
  (letrec ((run-1
             (lambda (s1 sr)
               (if (null? sr)
                   s1
                   (run-2 s1
                     (run-1 (car sr)
                       (cdr sr))))))
           (run-2
             (lambda (s1 s2)
               (if (null? s1)
                   s2
                   (cons (car s1)
                     (run-2 (cdr s1) s2))))))
    (lambda s
      (if (null? s)
          '()
          (run-1 (car s)
            (cdr s))))))

(define fold-left
  (letrec ((run
             (lambda (f unit ss)
               (if (ormap null? ss)
                   unit
                   (run f
                     (apply f unit (map car ss))
                     (map cdr ss))))))
    (lambda (f unit . ss)
      (run f unit ss))))

;;; Please remember that the order here is as per Scheme, and 
;;; not the correct order, which is in Ocaml!
(define fold-right
  (letrec ((run
             (lambda (f unit ss)
               (if (ormap null? ss)
                   unit
                   (apply f
                     `(,@(map car ss)
                       ,(run f unit (map cdr ss))))))))
    (lambda (f unit . ss)
      (run f unit ss))))

(define +
  (let* ((error (lambda () (error '+ "all arguments need to be numbers")))
         (bin+
           (lambda (a b)
             (cond ((integer? a)
                    (cond ((integer? b) (__bin-add-zz a b))
                          ((fraction? b)
                           (__bin-add-qq (__integer-to-fraction a) b))
                          ((real? b) (__bin-add-rr (integer->real a) b))
                          (else (error))))
                   ((fraction? a)
                    (cond ((integer? b)
                           (__bin-add-qq a (__bin_integer_to_fraction b)))
                          ((fraction? b) (__bin-add-qq a b))
                          ((real? b) (__bin-add-rr (fraction->real a) b))
                          (else (error))))
                   ((real? a)
                    (cond ((integer? b) (__bin-add-rr a (integer->real b)))
                          ((fraction? b) (__bin-add-rr a (fraction->real b)))
                          ((real? b) (__bin-add-rr a b))
                          (else (error))))
                   (else (error))))))
    (lambda s (fold-left bin+ 0 s))))

(define -
  (let* ((error (lambda () (error '- "all arguments need to be numbers")))
         (bin-
           (lambda (a b)
             (cond ((integer? a)
                    (cond ((integer? b) (__bin-sub-zz a b))
                          ((fraction? b)
                           (__bin-sub-qq (__integer-to-fraction a) b))
                          ((real b) (__bin-sub-rr (integer->real a) b))
                          (else (error))))
                   ((fraction? a)
                    (cond ((integer? b)
                           (__bin-sub-qq a (__integer-to-fraction b)))
                          ((fraction? b) (__bin-sub-qq a b))
                          ((real? b) (__bin-sub-rr (fraction->real a) b))
                          (else (error))))
                   ((real? a)
                    (cond ((integer? b) (__bin-sub-rr a (integer->real b)))
                          ((fraction? b) (__bin-sub-rr a (fraction->real b)))
                          ((real? b) (__bin-sub-rr a b))
                          (else (error))))
                   (else (error))))))
    (lambda (a . s)
      (if (null? s)
          (bin- 0 a)
          (let ((b (fold-left + 0 s)))
            (bin- a b))))))

(define *
  (let* ((error (lambda () (error '* "all arguments need to be numbers")))
         (bin*
           (lambda (a b)
             (cond ((integer? a)
                    (cond ((integer? b) (__bin-mul-zz a b))
                          ((fraction? b)
                           (__bin-mul-qq (__integer-to-fraction a) b))
                          ((real? b) (__bin-mul-rr (integer->real a) b))
                          (else (error))))
                   ((fraction? a)
                    (cond ((integer? b)
                           (__bin-mul-qq a (__integer-to-fraction b)))
                          ((fraction? b) (__bin-mul-qq a b))
                          ((real? b) (__bin-mul-rr (fraction->real a) b))
                          (else (error))))
                   ((real? a)
                    (cond ((integer? b)
                           (__bin-mul-rr a (integer->real b)))
                          ((fraction? b) (__bin-mul-rr a (fraction->real b)))
                          ((real? b) (__bin-mul-rr a b))
                          (else (error))))
                   (else (error))))))
    (lambda s
      (fold-left bin* 1 s))))

(define /
  (let* ((error (lambda () (error '/ "all arguments need to be numbers")))
         (bin/
           (lambda (a b)
             (cond ((integer? a)
                    (cond ((integer? b) (__bin-div-zz a b))
                          ((fraction? b)
                           (__bin-div-qq (__integer-to-fraction a) b))
                          ((real? b) (__bin-div-rr (integer->real a) b))
                          (else (error))))
                   ((fraction? a)
                    (cond ((integer? b)
                           (__bin-div-qq a (__integer-to-fraction b)))
                          ((fraction? b) (__bin-div-qq a b))
                          ((real? b) (__bin-div-rr (fraction->real a) b))
                          (else (error))))
                   ((real? a)
                    (cond ((integer? b)
                           (__bin-div-rr a (integer->real b)))
                          ((fraction? b) (__bin-div-rr a (fraction->real b)))
                          ((real? b) (__bin-div-rr a b))
                          (else (error))))
                   (else (error))))))
    (lambda (a . s)
      (if (null? s)
          (bin/ 1 a)
          (let ((b (fold-left * 1 s)))
            (bin/ a b))))))

(define fact
  (lambda (n)
    (if (zero? n)
        1
        (* n (fact (- n 1))))))

(define < #void)
(define <= #void)
(define > #void)
(define >= #void)
(define = #void)

(let* ((exit
         (lambda ()
           (error 'generic-comparator
             "all the arguments must be numbers")))
       (make-bin-comparator
         (lambda (comparator-zz comparator-qq comparator-rr)
           (lambda (a b)
             (cond ((integer? a)
                    (cond ((integer? b) (comparator-zz a b))
                          ((fraction? b)
                           (comparator-qq (__integer-to-fraction a) b))
                          ((real? b) (comparator-rr (integer->real a) b))
                          (else (exit))))
                   ((fraction? a)
                    (cond ((integer? b)
                           (comparator-qq a (__integer-to-fraction b)))
                          ((fraction? b) (comparator-qq a b))
                          ((real? b)
                           (comparator-rr (fraction->real a) b))
                          (else (exit))))
                   ((real? a)
                    (cond ((integer? b)
                           (comparator-rr a (integer->real b)))
                          ((fraction? b)
                           (comparator-rr a (fraction->real b)))
                          ((real? b) (comparator-rr a b))
                          (else (exit))))
                   (else (exit))))))
       (bin<? (make-bin-comparator
                __bin-less-than-zz
                __bin-less-than-qq
                __bin-less-than-rr))
       (bin=? (make-bin-comparator
                __bin-equal-zz
                __bin-equal-qq
                __bin-equal-rr))
       (bin>=? (lambda (a b) (not (bin<? a b))))
       (bin>? (lambda (a b) (bin<? b a)))
       (bin<=? (lambda (a b) (not (bin>? a b)))))
  (let ((make-run
          (lambda (bin-ordering)
            (letrec ((run
                       (lambda (a s)
                         (or (null? s)
                             (and (bin-ordering a (car s))
                                  (run (car s) (cdr s)))))))
              (lambda (a . s) (run a s))))))
    (set! < (make-run bin<?))
    (set! <= (make-run bin<=?))
    (set! > (make-run bin>?))
    (set! >= (make-run bin>=?))
    (set! = (make-run bin=?))))

;;; Replaced with the corresponding procedure in assembly,
;;; in the epilog.asm file
#;(define make-list
  (letrec ((run
             (lambda (n ch)
               (if (zero? n)
                   '()
                   (cons ch
                     (run (- n 1) ch))))))
    (lambda (n . chs)
      (cond ((null? chs) (run n #void))
            ((and (pair? chs)
                  (null? (cdr chs)))
             (run n (car chs)))
            (else (error 'make-list
                    "Usage: (make-list length ?optional-init-char)"))))))

(define char<? #void)
(define char<=? #void)
(define char=? #void)
(define char>? #void)
(define char>=? #void)

(let ((make-char-comparator
        (lambda (comparator)
          (lambda s
            (apply comparator
              (map char->integer s))))))
  (set! char<? (make-char-comparator <))
  (set! char<=? (make-char-comparator <=))
  (set! char=? (make-char-comparator =))
  (set! char>? (make-char-comparator >))
  (set! char>=? (make-char-comparator >=)))

(define char-downcase #void)
(define char-upcase #void)

(let ((delta
        (- (char->integer #\a)
          (char->integer #\A))))
  (set! char-downcase
    (lambda (ch)
      (if (char<=? #\A ch #\Z)
          (integer->char
            (+ (char->integer ch) delta))
          ch)))
  (set! char-upcase
    (lambda (ch)
      (if (char<=? #\a ch #\z)
          (integer->char
            (- (char->integer ch) delta))
          ch))))
