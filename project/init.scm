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
