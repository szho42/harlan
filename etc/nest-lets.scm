(library
  (harlan front nest-lets)
  (export nest-lets)
  (import (rnrs) (elegant-weapons helpers)
    (harlan helpers))

(define-match nest-lets
  ((module ,[Decl -> decl*] ...)
   `(module . ,decl*)))

(define-match Decl
  ((fn ,name ,args . ,[(Value* '()) -> value*])
   `(fn ,name ,args . ,value*))
  ((define (,name . ,args) . ,[(Value* '()) -> value*])
   `(define (,name . ,args) . ,value*))
  (,else else))

(define (unroll-lets def* value*)
  (cond
    ((null? def*) value*)
    (else
      `((let (,(car def*)) .
          ,(unroll-lets (cdr def*) value*))))))

(define-match (Value* def*)
  (((let ,x ,[Value -> e]))
   (guard (symbol? x))
   (unroll-lets def* `(,e)))
  (((let ,x ,[Value -> e]) . ,value*)
   (guard (symbol? x))
   ((Value* (append def* `((,x ,e)))) value*))
  ((,value) (unroll-lets def* `(,(Value value))))
  ((,[Value -> value] . ,value*)
   (unroll-lets def*
     (cons value ((Value* '()) value*)))))

(define-match Value
  (,c (guard (char? c)) c)
  (,i (guard (integer? i)) i)
  (,b (guard (boolean? b)) b)
  (,f (guard (float? f)) f)
  (,str (guard (string? str)) str)
  (,id (guard (ident? id)) id)
  ((let ((,x ,[Value -> e]) ...) . ,[(Value* '()) -> value*])
   `(let ((,x ,e) ...) . ,value*))
  ((begin . ,value*)
   (make-begin ((Value* '()) value*)))
  ((print ,[Value -> e] ...) `(print . ,e))
  ((println ,[Value -> e] ...) `(println . ,e))
  ((assert ,[Value -> e]) `(assert ,e))
  ((set! ,[Value -> x] ,[Value -> v]) `(set! ,x ,v))
  ((for (,i ,[Value -> start]
          ,[Value -> end])
     . ,[(Value* '()) -> value*])
   `(for (,i ,start ,end) . ,value*))
  ((for (,i ,[Value -> start]
          ,[Value -> end]
          ,[Value -> step])
     . ,[(Value* '()) -> value*])
   `(for (,i ,start ,end ,step) . ,value*))
  ((while ,[Value -> test] . ,[(Value* '()) -> value*])
   `(while ,test . ,value*))
  ((if ,[Value -> t] ,[Value -> c])
   `(if ,t ,c))
  ((if ,[Value -> t] ,[Value -> c] ,[Value -> a])
   `(if ,t ,c ,a))
  ((return) `(return))
  ((return ,[Value -> e]) `(return ,e))
  ((var ,id) `(var ,id))
  ((vector ,[Value -> e*] ...) `(vector . ,e*))
  ((vector-ref ,[Value -> v] ,[Value -> i])
   `(vector-ref ,v ,i))
  ((kernel ((,x ,[Value -> e]) ...) . ,[(Value* '()) -> value*])
   `(kernel ((,x ,e) ...) . ,value*))
  ((reduce ,op ,[Value -> e]) `(reduce ,op ,e))
  ((iota ,[Value -> e]) `(iota ,e))
  ((length ,[Value -> e]) `(length ,e))
  ((make-vector ,[Value -> i] ,[Value -> e])
   `(make-vector ,i ,e))
  ((,op ,[Value -> e1] ,[Value -> e2])
   (guard (or (binop? op) (relop? op)))
   `(,op ,e1 ,e2))
  ((,v ,[Value -> e*] ...) (guard (ident? v))
   `(,v . ,e*)))

;; end library
)
