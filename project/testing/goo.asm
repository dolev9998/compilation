;;; prologue-1.asm
;;; The first part of the standard prologue for compiled programs
;;;
;;; Programmer: Mayer Goldberg, 2023

%define T_void 				0
%define T_nil 				1
%define T_char 				2
%define T_string 			3
%define T_closure 			4
%define T_undefined			5
%define T_boolean 			8
%define T_boolean_false 		(T_boolean | 1)
%define T_boolean_true 			(T_boolean | 2)
%define T_number 			16
%define T_integer			(T_number | 1)
%define T_fraction 			(T_number | 2)
%define T_real 				(T_number | 3)
%define T_collection 			32
%define T_pair 				(T_collection | 1)
%define T_vector 			(T_collection | 2)
%define T_symbol 			64
%define T_interned_symbol		(T_symbol | 1)
%define T_uninterned_symbol		(T_symbol | 2)

%define SOB_CHAR_VALUE(reg) 		byte [reg + 1]
%define SOB_PAIR_CAR(reg)		qword [reg + 1]
%define SOB_PAIR_CDR(reg)		qword [reg + 1 + 8]
%define SOB_STRING_LENGTH(reg)		qword [reg + 1]
%define SOB_VECTOR_LENGTH(reg)		qword [reg + 1]
%define SOB_CLOSURE_ENV(reg)		qword [reg + 1]
%define SOB_CLOSURE_CODE(reg)		qword [reg + 1 + 8]

%define OLD_RBP 			qword [rbp]
%define RET_ADDR 			qword [rbp + 8 * 1]
%define ENV 				qword [rbp + 8 * 2]
%define COUNT 				qword [rbp + 8 * 3]
%define PARAM(n) 			qword [rbp + 8 * (4 + n)]
%define AND_KILL_FRAME(n)		(8 * (2 + n))

%define MAGIC				496351

%macro ENTER 0
	enter 0, 0
	and rsp, ~15
%endmacro

%macro LEAVE 0
	leave
%endmacro

%macro assert_type 2
        cmp byte [%1], %2
        jne L_error_incorrect_type
%endmacro

%define assert_void(reg)		assert_type reg, T_void
%define assert_nil(reg)			assert_type reg, T_nil
%define assert_char(reg)		assert_type reg, T_char
%define assert_string(reg)		assert_type reg, T_string
%define assert_symbol(reg)		assert_type reg, T_symbol
%define assert_interned_symbol(reg)	assert_type reg, T_interned_symbol
%define assert_uninterned_symbol(reg)	assert_type reg, T_uninterned_symbol
%define assert_closure(reg)		assert_type reg, T_closure
%define assert_boolean(reg)		assert_type reg, T_boolean
%define assert_integer(reg)		assert_type reg, T_integer
%define assert_fraction(reg)		assert_type reg, T_fraction
%define assert_real(reg)		assert_type reg, T_real
%define assert_pair(reg)		assert_type reg, T_pair
%define assert_vector(reg)		assert_type reg, T_vector

%define sob_void			(L_constants + 0)
%define sob_nil				(L_constants + 1)
%define sob_boolean_false		(L_constants + 2)
%define sob_boolean_true		(L_constants + 3)
%define sob_char_nul			(L_constants + 4)

%define bytes(n)			(n)
%define kbytes(n) 			(bytes(n) << 10)
%define mbytes(n) 			(kbytes(n) << 10)
%define gbytes(n) 			(mbytes(n) << 10)

section .data
L_constants:
	; L_constants + 0:
	db T_void
	; L_constants + 1:
	db T_nil
	; L_constants + 2:
	db T_boolean_false
	; L_constants + 3:
	db T_boolean_true
	; L_constants + 4:
	db T_char, 0x00	; #\nul
	; L_constants + 6:
	db T_string	; "null?"
	dq 5
	db 0x6E, 0x75, 0x6C, 0x6C, 0x3F
	; L_constants + 20:
	db T_string	; "pair?"
	dq 5
	db 0x70, 0x61, 0x69, 0x72, 0x3F
	; L_constants + 34:
	db T_string	; "void?"
	dq 5
	db 0x76, 0x6F, 0x69, 0x64, 0x3F
	; L_constants + 48:
	db T_string	; "char?"
	dq 5
	db 0x63, 0x68, 0x61, 0x72, 0x3F
	; L_constants + 62:
	db T_string	; "string?"
	dq 7
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3F
	; L_constants + 78:
	db T_string	; "interned-symbol?"
	dq 16
	db 0x69, 0x6E, 0x74, 0x65, 0x72, 0x6E, 0x65, 0x64
	db 0x2D, 0x73, 0x79, 0x6D, 0x62, 0x6F, 0x6C, 0x3F
	; L_constants + 103:
	db T_string	; "vector?"
	dq 7
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x3F
	; L_constants + 119:
	db T_string	; "procedure?"
	dq 10
	db 0x70, 0x72, 0x6F, 0x63, 0x65, 0x64, 0x75, 0x72
	db 0x65, 0x3F
	; L_constants + 138:
	db T_string	; "real?"
	dq 5
	db 0x72, 0x65, 0x61, 0x6C, 0x3F
	; L_constants + 152:
	db T_string	; "fraction?"
	dq 9
	db 0x66, 0x72, 0x61, 0x63, 0x74, 0x69, 0x6F, 0x6E
	db 0x3F
	; L_constants + 170:
	db T_string	; "boolean?"
	dq 8
	db 0x62, 0x6F, 0x6F, 0x6C, 0x65, 0x61, 0x6E, 0x3F
	; L_constants + 187:
	db T_string	; "number?"
	dq 7
	db 0x6E, 0x75, 0x6D, 0x62, 0x65, 0x72, 0x3F
	; L_constants + 203:
	db T_string	; "collection?"
	dq 11
	db 0x63, 0x6F, 0x6C, 0x6C, 0x65, 0x63, 0x74, 0x69
	db 0x6F, 0x6E, 0x3F
	; L_constants + 223:
	db T_string	; "cons"
	dq 4
	db 0x63, 0x6F, 0x6E, 0x73
	; L_constants + 236:
	db T_string	; "display-sexpr"
	dq 13
	db 0x64, 0x69, 0x73, 0x70, 0x6C, 0x61, 0x79, 0x2D
	db 0x73, 0x65, 0x78, 0x70, 0x72
	; L_constants + 258:
	db T_string	; "write-char"
	dq 10
	db 0x77, 0x72, 0x69, 0x74, 0x65, 0x2D, 0x63, 0x68
	db 0x61, 0x72
	; L_constants + 277:
	db T_string	; "car"
	dq 3
	db 0x63, 0x61, 0x72
	; L_constants + 289:
	db T_string	; "cdr"
	dq 3
	db 0x63, 0x64, 0x72
	; L_constants + 301:
	db T_string	; "string-length"
	dq 13
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x6C
	db 0x65, 0x6E, 0x67, 0x74, 0x68
	; L_constants + 323:
	db T_string	; "vector-length"
	dq 13
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x6C
	db 0x65, 0x6E, 0x67, 0x74, 0x68
	; L_constants + 345:
	db T_string	; "real->integer"
	dq 13
	db 0x72, 0x65, 0x61, 0x6C, 0x2D, 0x3E, 0x69, 0x6E
	db 0x74, 0x65, 0x67, 0x65, 0x72
	; L_constants + 367:
	db T_string	; "exit"
	dq 4
	db 0x65, 0x78, 0x69, 0x74
	; L_constants + 380:
	db T_string	; "integer->real"
	dq 13
	db 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65, 0x72, 0x2D
	db 0x3E, 0x72, 0x65, 0x61, 0x6C
	; L_constants + 402:
	db T_string	; "fraction->real"
	dq 14
	db 0x66, 0x72, 0x61, 0x63, 0x74, 0x69, 0x6F, 0x6E
	db 0x2D, 0x3E, 0x72, 0x65, 0x61, 0x6C
	; L_constants + 425:
	db T_string	; "char->integer"
	dq 13
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x3E, 0x69, 0x6E
	db 0x74, 0x65, 0x67, 0x65, 0x72
	; L_constants + 447:
	db T_string	; "integer->char"
	dq 13
	db 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65, 0x72, 0x2D
	db 0x3E, 0x63, 0x68, 0x61, 0x72
	; L_constants + 469:
	db T_string	; "trng"
	dq 4
	db 0x74, 0x72, 0x6E, 0x67
	; L_constants + 482:
	db T_string	; "zero?"
	dq 5
	db 0x7A, 0x65, 0x72, 0x6F, 0x3F
	; L_constants + 496:
	db T_string	; "integer?"
	dq 8
	db 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65, 0x72, 0x3F
	; L_constants + 513:
	db T_string	; "__bin-apply"
	dq 11
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x70
	db 0x70, 0x6C, 0x79
	; L_constants + 533:
	db T_string	; "__bin-add-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x64
	db 0x64, 0x2D, 0x72, 0x72
	; L_constants + 554:
	db T_string	; "__bin-sub-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x73, 0x75
	db 0x62, 0x2D, 0x72, 0x72
	; L_constants + 575:
	db T_string	; "__bin-mul-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6D, 0x75
	db 0x6C, 0x2D, 0x72, 0x72
	; L_constants + 596:
	db T_string	; "__bin-div-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x64, 0x69
	db 0x76, 0x2D, 0x72, 0x72
	; L_constants + 617:
	db T_string	; "__bin-add-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x64
	db 0x64, 0x2D, 0x71, 0x71
	; L_constants + 638:
	db T_string	; "__bin-sub-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x73, 0x75
	db 0x62, 0x2D, 0x71, 0x71
	; L_constants + 659:
	db T_string	; "__bin-mul-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6D, 0x75
	db 0x6C, 0x2D, 0x71, 0x71
	; L_constants + 680:
	db T_string	; "__bin-div-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x64, 0x69
	db 0x76, 0x2D, 0x71, 0x71
	; L_constants + 701:
	db T_string	; "__bin-add-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x64
	db 0x64, 0x2D, 0x7A, 0x7A
	; L_constants + 722:
	db T_string	; "__bin-sub-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x73, 0x75
	db 0x62, 0x2D, 0x7A, 0x7A
	; L_constants + 743:
	db T_string	; "__bin-mul-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6D, 0x75
	db 0x6C, 0x2D, 0x7A, 0x7A
	; L_constants + 764:
	db T_string	; "__bin-div-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x64, 0x69
	db 0x76, 0x2D, 0x7A, 0x7A
	; L_constants + 785:
	db T_string	; "error"
	dq 5
	db 0x65, 0x72, 0x72, 0x6F, 0x72
	; L_constants + 799:
	db T_string	; "__bin-less-than-rr"
	dq 18
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6C, 0x65
	db 0x73, 0x73, 0x2D, 0x74, 0x68, 0x61, 0x6E, 0x2D
	db 0x72, 0x72
	; L_constants + 826:
	db T_string	; "__bin-less-than-qq"
	dq 18
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6C, 0x65
	db 0x73, 0x73, 0x2D, 0x74, 0x68, 0x61, 0x6E, 0x2D
	db 0x71, 0x71
	; L_constants + 853:
	db T_string	; "__bin-less-than-zz"
	dq 18
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6C, 0x65
	db 0x73, 0x73, 0x2D, 0x74, 0x68, 0x61, 0x6E, 0x2D
	db 0x7A, 0x7A
	; L_constants + 880:
	db T_string	; "__bin-equal-rr"
	dq 14
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x65, 0x71
	db 0x75, 0x61, 0x6C, 0x2D, 0x72, 0x72
	; L_constants + 903:
	db T_string	; "__bin-equal-qq"
	dq 14
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x65, 0x71
	db 0x75, 0x61, 0x6C, 0x2D, 0x71, 0x71
	; L_constants + 926:
	db T_string	; "__bin-equal-zz"
	dq 14
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x65, 0x71
	db 0x75, 0x61, 0x6C, 0x2D, 0x7A, 0x7A
	; L_constants + 949:
	db T_string	; "quotient"
	dq 8
	db 0x71, 0x75, 0x6F, 0x74, 0x69, 0x65, 0x6E, 0x74
	; L_constants + 966:
	db T_string	; "remainder"
	dq 9
	db 0x72, 0x65, 0x6D, 0x61, 0x69, 0x6E, 0x64, 0x65
	db 0x72
	; L_constants + 984:
	db T_string	; "set-car!"
	dq 8
	db 0x73, 0x65, 0x74, 0x2D, 0x63, 0x61, 0x72, 0x21
	; L_constants + 1001:
	db T_string	; "set-cdr!"
	dq 8
	db 0x73, 0x65, 0x74, 0x2D, 0x63, 0x64, 0x72, 0x21
	; L_constants + 1018:
	db T_string	; "string-ref"
	dq 10
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x72
	db 0x65, 0x66
	; L_constants + 1037:
	db T_string	; "vector-ref"
	dq 10
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x72
	db 0x65, 0x66
	; L_constants + 1056:
	db T_string	; "vector-set!"
	dq 11
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x73
	db 0x65, 0x74, 0x21
	; L_constants + 1076:
	db T_string	; "string-set!"
	dq 11
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x73
	db 0x65, 0x74, 0x21
	; L_constants + 1096:
	db T_string	; "make-vector"
	dq 11
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x76, 0x65, 0x63
	db 0x74, 0x6F, 0x72
	; L_constants + 1116:
	db T_string	; "make-string"
	dq 11
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x73, 0x74, 0x72
	db 0x69, 0x6E, 0x67
	; L_constants + 1136:
	db T_string	; "numerator"
	dq 9
	db 0x6E, 0x75, 0x6D, 0x65, 0x72, 0x61, 0x74, 0x6F
	db 0x72
	; L_constants + 1154:
	db T_string	; "denominator"
	dq 11
	db 0x64, 0x65, 0x6E, 0x6F, 0x6D, 0x69, 0x6E, 0x61
	db 0x74, 0x6F, 0x72
	; L_constants + 1174:
	db T_string	; "eq?"
	dq 3
	db 0x65, 0x71, 0x3F
	; L_constants + 1186:
	db T_string	; "__integer-to-fracti...
	dq 21
	db 0x5F, 0x5F, 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65
	db 0x72, 0x2D, 0x74, 0x6F, 0x2D, 0x66, 0x72, 0x61
	db 0x63, 0x74, 0x69, 0x6F, 0x6E
	; L_constants + 1216:
	db T_string	; "logand"
	dq 6
	db 0x6C, 0x6F, 0x67, 0x61, 0x6E, 0x64
	; L_constants + 1231:
	db T_string	; "logor"
	dq 5
	db 0x6C, 0x6F, 0x67, 0x6F, 0x72
	; L_constants + 1245:
	db T_string	; "logxor"
	dq 6
	db 0x6C, 0x6F, 0x67, 0x78, 0x6F, 0x72
	; L_constants + 1260:
	db T_string	; "lognot"
	dq 6
	db 0x6C, 0x6F, 0x67, 0x6E, 0x6F, 0x74
	; L_constants + 1275:
	db T_string	; "ash"
	dq 3
	db 0x61, 0x73, 0x68
	; L_constants + 1287:
	db T_string	; "symbol?"
	dq 7
	db 0x73, 0x79, 0x6D, 0x62, 0x6F, 0x6C, 0x3F
	; L_constants + 1303:
	db T_string	; "uninterned-symbol?"
	dq 18
	db 0x75, 0x6E, 0x69, 0x6E, 0x74, 0x65, 0x72, 0x6E
	db 0x65, 0x64, 0x2D, 0x73, 0x79, 0x6D, 0x62, 0x6F
	db 0x6C, 0x3F
	; L_constants + 1330:
	db T_string	; "gensym?"
	dq 7
	db 0x67, 0x65, 0x6E, 0x73, 0x79, 0x6D, 0x3F
	; L_constants + 1346:
	db T_string	; "gensym"
	dq 6
	db 0x67, 0x65, 0x6E, 0x73, 0x79, 0x6D
	; L_constants + 1361:
	db T_string	; "frame"
	dq 5
	db 0x66, 0x72, 0x61, 0x6D, 0x65
	; L_constants + 1375:
	db T_string	; "break"
	dq 5
	db 0x62, 0x72, 0x65, 0x61, 0x6B
	; L_constants + 1389:
	db T_string	; "boolean-false?"
	dq 14
	db 0x62, 0x6F, 0x6F, 0x6C, 0x65, 0x61, 0x6E, 0x2D
	db 0x66, 0x61, 0x6C, 0x73, 0x65, 0x3F
	; L_constants + 1412:
	db T_string	; "boolean-true?"
	dq 13
	db 0x62, 0x6F, 0x6F, 0x6C, 0x65, 0x61, 0x6E, 0x2D
	db 0x74, 0x72, 0x75, 0x65, 0x3F
	; L_constants + 1434:
	db T_string	; "primitive?"
	dq 10
	db 0x70, 0x72, 0x69, 0x6D, 0x69, 0x74, 0x69, 0x76
	db 0x65, 0x3F
	; L_constants + 1453:
	db T_string	; "length"
	dq 6
	db 0x6C, 0x65, 0x6E, 0x67, 0x74, 0x68
	; L_constants + 1468:
	db T_string	; "make-list"
	dq 9
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x6C, 0x69, 0x73
	db 0x74
	; L_constants + 1486:
	db T_string	; "return"
	dq 6
	db 0x72, 0x65, 0x74, 0x75, 0x72, 0x6E
	; L_constants + 1501:
	db T_string	; "caar"
	dq 4
	db 0x63, 0x61, 0x61, 0x72
	; L_constants + 1514:
	db T_string	; "cadr"
	dq 4
	db 0x63, 0x61, 0x64, 0x72
	; L_constants + 1527:
	db T_string	; "cdar"
	dq 4
	db 0x63, 0x64, 0x61, 0x72
	; L_constants + 1540:
	db T_string	; "cddr"
	dq 4
	db 0x63, 0x64, 0x64, 0x72
	; L_constants + 1553:
	db T_string	; "caaar"
	dq 5
	db 0x63, 0x61, 0x61, 0x61, 0x72
	; L_constants + 1567:
	db T_string	; "caadr"
	dq 5
	db 0x63, 0x61, 0x61, 0x64, 0x72
	; L_constants + 1581:
	db T_string	; "cadar"
	dq 5
	db 0x63, 0x61, 0x64, 0x61, 0x72
	; L_constants + 1595:
	db T_string	; "caddr"
	dq 5
	db 0x63, 0x61, 0x64, 0x64, 0x72
	; L_constants + 1609:
	db T_string	; "cdaar"
	dq 5
	db 0x63, 0x64, 0x61, 0x61, 0x72
	; L_constants + 1623:
	db T_string	; "cdadr"
	dq 5
	db 0x63, 0x64, 0x61, 0x64, 0x72
	; L_constants + 1637:
	db T_string	; "cddar"
	dq 5
	db 0x63, 0x64, 0x64, 0x61, 0x72
	; L_constants + 1651:
	db T_string	; "cdddr"
	dq 5
	db 0x63, 0x64, 0x64, 0x64, 0x72
	; L_constants + 1665:
	db T_string	; "caaaar"
	dq 6
	db 0x63, 0x61, 0x61, 0x61, 0x61, 0x72
	; L_constants + 1680:
	db T_string	; "caaadr"
	dq 6
	db 0x63, 0x61, 0x61, 0x61, 0x64, 0x72
	; L_constants + 1695:
	db T_string	; "caadar"
	dq 6
	db 0x63, 0x61, 0x61, 0x64, 0x61, 0x72
	; L_constants + 1710:
	db T_string	; "caaddr"
	dq 6
	db 0x63, 0x61, 0x61, 0x64, 0x64, 0x72
	; L_constants + 1725:
	db T_string	; "cadaar"
	dq 6
	db 0x63, 0x61, 0x64, 0x61, 0x61, 0x72
	; L_constants + 1740:
	db T_string	; "cadadr"
	dq 6
	db 0x63, 0x61, 0x64, 0x61, 0x64, 0x72
	; L_constants + 1755:
	db T_string	; "caddar"
	dq 6
	db 0x63, 0x61, 0x64, 0x64, 0x61, 0x72
	; L_constants + 1770:
	db T_string	; "cadddr"
	dq 6
	db 0x63, 0x61, 0x64, 0x64, 0x64, 0x72
	; L_constants + 1785:
	db T_string	; "cdaaar"
	dq 6
	db 0x63, 0x64, 0x61, 0x61, 0x61, 0x72
	; L_constants + 1800:
	db T_string	; "cdaadr"
	dq 6
	db 0x63, 0x64, 0x61, 0x61, 0x64, 0x72
	; L_constants + 1815:
	db T_string	; "cdadar"
	dq 6
	db 0x63, 0x64, 0x61, 0x64, 0x61, 0x72
	; L_constants + 1830:
	db T_string	; "cdaddr"
	dq 6
	db 0x63, 0x64, 0x61, 0x64, 0x64, 0x72
	; L_constants + 1845:
	db T_string	; "cddaar"
	dq 6
	db 0x63, 0x64, 0x64, 0x61, 0x61, 0x72
	; L_constants + 1860:
	db T_string	; "cddadr"
	dq 6
	db 0x63, 0x64, 0x64, 0x61, 0x64, 0x72
	; L_constants + 1875:
	db T_string	; "cdddar"
	dq 6
	db 0x63, 0x64, 0x64, 0x64, 0x61, 0x72
	; L_constants + 1890:
	db T_string	; "cddddr"
	dq 6
	db 0x63, 0x64, 0x64, 0x64, 0x64, 0x72
	; L_constants + 1905:
	db T_string	; "list?"
	dq 5
	db 0x6C, 0x69, 0x73, 0x74, 0x3F
	; L_constants + 1919:
	db T_string	; "list"
	dq 4
	db 0x6C, 0x69, 0x73, 0x74
	; L_constants + 1932:
	db T_string	; "not"
	dq 3
	db 0x6E, 0x6F, 0x74
	; L_constants + 1944:
	db T_string	; "rational?"
	dq 9
	db 0x72, 0x61, 0x74, 0x69, 0x6F, 0x6E, 0x61, 0x6C
	db 0x3F
	; L_constants + 1962:
	db T_string	; "list*"
	dq 5
	db 0x6C, 0x69, 0x73, 0x74, 0x2A
	; L_constants + 1976:
	db T_string	; "whatever"
	dq 8
	db 0x77, 0x68, 0x61, 0x74, 0x65, 0x76, 0x65, 0x72
	; L_constants + 1993:
	db T_interned_symbol	; whatever
	dq L_constants + 1976
	; L_constants + 2002:
	db T_string	; "apply"
	dq 5
	db 0x61, 0x70, 0x70, 0x6C, 0x79
	; L_constants + 2016:
	db T_string	; "ormap"
	dq 5
	db 0x6F, 0x72, 0x6D, 0x61, 0x70
	; L_constants + 2030:
	db T_string	; "map"
	dq 3
	db 0x6D, 0x61, 0x70
	; L_constants + 2042:
	db T_string	; "andmap"
	dq 6
	db 0x61, 0x6E, 0x64, 0x6D, 0x61, 0x70
	; L_constants + 2057:
	db T_string	; "reverse"
	dq 7
	db 0x72, 0x65, 0x76, 0x65, 0x72, 0x73, 0x65
	; L_constants + 2073:
	db T_string	; "fold-left"
	dq 9
	db 0x66, 0x6F, 0x6C, 0x64, 0x2D, 0x6C, 0x65, 0x66
	db 0x74
	; L_constants + 2091:
	db T_string	; "append"
	dq 6
	db 0x61, 0x70, 0x70, 0x65, 0x6E, 0x64
	; L_constants + 2106:
	db T_string	; "fold-right"
	dq 10
	db 0x66, 0x6F, 0x6C, 0x64, 0x2D, 0x72, 0x69, 0x67
	db 0x68, 0x74
	; L_constants + 2125:
	db T_string	; "+"
	dq 1
	db 0x2B
	; L_constants + 2135:
	db T_integer	; 0
	dq 0
	; L_constants + 2144:
	db T_string	; "__bin_integer_to_fr...
	dq 25
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x5F, 0x69, 0x6E
	db 0x74, 0x65, 0x67, 0x65, 0x72, 0x5F, 0x74, 0x6F
	db 0x5F, 0x66, 0x72, 0x61, 0x63, 0x74, 0x69, 0x6F
	db 0x6E
	; L_constants + 2178:
	db T_interned_symbol	; +
	dq L_constants + 2125
	; L_constants + 2187:
	db T_string	; "all arguments need ...
	dq 32
	db 0x61, 0x6C, 0x6C, 0x20, 0x61, 0x72, 0x67, 0x75
	db 0x6D, 0x65, 0x6E, 0x74, 0x73, 0x20, 0x6E, 0x65
	db 0x65, 0x64, 0x20, 0x74, 0x6F, 0x20, 0x62, 0x65
	db 0x20, 0x6E, 0x75, 0x6D, 0x62, 0x65, 0x72, 0x73
	; L_constants + 2228:
	db T_string	; "-"
	dq 1
	db 0x2D
	; L_constants + 2238:
	db T_string	; "real"
	dq 4
	db 0x72, 0x65, 0x61, 0x6C
	; L_constants + 2251:
	db T_interned_symbol	; -
	dq L_constants + 2228
	; L_constants + 2260:
	db T_string	; "*"
	dq 1
	db 0x2A
	; L_constants + 2270:
	db T_integer	; 1
	dq 1
	; L_constants + 2279:
	db T_interned_symbol	; *
	dq L_constants + 2260
	; L_constants + 2288:
	db T_string	; "/"
	dq 1
	db 0x2F
	; L_constants + 2298:
	db T_interned_symbol	; /
	dq L_constants + 2288
	; L_constants + 2307:
	db T_string	; "fact"
	dq 4
	db 0x66, 0x61, 0x63, 0x74
	; L_constants + 2320:
	db T_string	; "<"
	dq 1
	db 0x3C
	; L_constants + 2330:
	db T_string	; "<="
	dq 2
	db 0x3C, 0x3D
	; L_constants + 2341:
	db T_string	; ">"
	dq 1
	db 0x3E
	; L_constants + 2351:
	db T_string	; ">="
	dq 2
	db 0x3E, 0x3D
	; L_constants + 2362:
	db T_string	; "="
	dq 1
	db 0x3D
	; L_constants + 2372:
	db T_string	; "generic-comparator"
	dq 18
	db 0x67, 0x65, 0x6E, 0x65, 0x72, 0x69, 0x63, 0x2D
	db 0x63, 0x6F, 0x6D, 0x70, 0x61, 0x72, 0x61, 0x74
	db 0x6F, 0x72
	; L_constants + 2399:
	db T_interned_symbol	; generic-comparator
	dq L_constants + 2372
	; L_constants + 2408:
	db T_string	; "all the arguments m...
	dq 33
	db 0x61, 0x6C, 0x6C, 0x20, 0x74, 0x68, 0x65, 0x20
	db 0x61, 0x72, 0x67, 0x75, 0x6D, 0x65, 0x6E, 0x74
	db 0x73, 0x20, 0x6D, 0x75, 0x73, 0x74, 0x20, 0x62
	db 0x65, 0x20, 0x6E, 0x75, 0x6D, 0x62, 0x65, 0x72
	db 0x73
	; L_constants + 2450:
	db T_string	; "char<?"
	dq 6
	db 0x63, 0x68, 0x61, 0x72, 0x3C, 0x3F
	; L_constants + 2465:
	db T_string	; "char<=?"
	dq 7
	db 0x63, 0x68, 0x61, 0x72, 0x3C, 0x3D, 0x3F
	; L_constants + 2481:
	db T_string	; "char=?"
	dq 6
	db 0x63, 0x68, 0x61, 0x72, 0x3D, 0x3F
	; L_constants + 2496:
	db T_string	; "char>?"
	dq 6
	db 0x63, 0x68, 0x61, 0x72, 0x3E, 0x3F
	; L_constants + 2511:
	db T_string	; "char>=?"
	dq 7
	db 0x63, 0x68, 0x61, 0x72, 0x3E, 0x3D, 0x3F
	; L_constants + 2527:
	db T_string	; "char-downcase"
	dq 13
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x64, 0x6F, 0x77
	db 0x6E, 0x63, 0x61, 0x73, 0x65
	; L_constants + 2549:
	db T_string	; "char-upcase"
	dq 11
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x75, 0x70, 0x63
	db 0x61, 0x73, 0x65
	; L_constants + 2569:
	db T_char, 0x41	; #\A
	; L_constants + 2571:
	db T_char, 0x5A	; #\Z
	; L_constants + 2573:
	db T_char, 0x61	; #\a
	; L_constants + 2575:
	db T_char, 0x7A	; #\z
	; L_constants + 2577:
	db T_string	; "char-ci<?"
	dq 9
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x63, 0x69, 0x3C
	db 0x3F
	; L_constants + 2595:
	db T_string	; "char-ci<=?"
	dq 10
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x63, 0x69, 0x3C
	db 0x3D, 0x3F
	; L_constants + 2614:
	db T_string	; "char-ci=?"
	dq 9
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x63, 0x69, 0x3D
	db 0x3F
	; L_constants + 2632:
	db T_string	; "char-ci>?"
	dq 9
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x63, 0x69, 0x3E
	db 0x3F
	; L_constants + 2650:
	db T_string	; "char-ci>=?"
	dq 10
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x63, 0x69, 0x3E
	db 0x3D, 0x3F
	; L_constants + 2669:
	db T_string	; "string-downcase"
	dq 15
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x64
	db 0x6F, 0x77, 0x6E, 0x63, 0x61, 0x73, 0x65
	; L_constants + 2693:
	db T_string	; "string-upcase"
	dq 13
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x75
	db 0x70, 0x63, 0x61, 0x73, 0x65
	; L_constants + 2715:
	db T_string	; "list->string"
	dq 12
	db 0x6C, 0x69, 0x73, 0x74, 0x2D, 0x3E, 0x73, 0x74
	db 0x72, 0x69, 0x6E, 0x67
	; L_constants + 2736:
	db T_string	; "string->list"
	dq 12
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x3E
	db 0x6C, 0x69, 0x73, 0x74
	; L_constants + 2757:
	db T_string	; "string<?"
	dq 8
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3C, 0x3F
	; L_constants + 2774:
	db T_string	; "string<=?"
	dq 9
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3C, 0x3D
	db 0x3F
	; L_constants + 2792:
	db T_string	; "string=?"
	dq 8
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3D, 0x3F
	; L_constants + 2809:
	db T_string	; "string>=?"
	dq 9
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3E, 0x3D
	db 0x3F
	; L_constants + 2827:
	db T_string	; "string>?"
	dq 8
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3E, 0x3F
	; L_constants + 2844:
	db T_string	; "string-ci<?"
	dq 11
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x63
	db 0x69, 0x3C, 0x3F
	; L_constants + 2864:
	db T_string	; "string-ci<=?"
	dq 12
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x63
	db 0x69, 0x3C, 0x3D, 0x3F
	; L_constants + 2885:
	db T_string	; "string-ci=?"
	dq 11
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x63
	db 0x69, 0x3D, 0x3F
	; L_constants + 2905:
	db T_string	; "string-ci>=?"
	dq 12
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x63
	db 0x69, 0x3E, 0x3D, 0x3F
	; L_constants + 2926:
	db T_string	; "string-ci>?"
	dq 11
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x63
	db 0x69, 0x3E, 0x3F
	; L_constants + 2946:
	db T_interned_symbol	; make-vector
	dq L_constants + 1096
	; L_constants + 2955:
	db T_string	; "Usage: (make-vector...
	dq 43
	db 0x55, 0x73, 0x61, 0x67, 0x65, 0x3A, 0x20, 0x28
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x76, 0x65, 0x63
	db 0x74, 0x6F, 0x72, 0x20, 0x73, 0x69, 0x7A, 0x65
	db 0x20, 0x3F, 0x6F, 0x70, 0x74, 0x69, 0x6F, 0x6E
	db 0x61, 0x6C, 0x2D, 0x64, 0x65, 0x66, 0x61, 0x75
	db 0x6C, 0x74, 0x29
	; L_constants + 3007:
	db T_interned_symbol	; make-string
	dq L_constants + 1116
	; L_constants + 3016:
	db T_string	; "Usage: (make-string...
	dq 43
	db 0x55, 0x73, 0x61, 0x67, 0x65, 0x3A, 0x20, 0x28
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x73, 0x74, 0x72
	db 0x69, 0x6E, 0x67, 0x20, 0x73, 0x69, 0x7A, 0x65
	db 0x20, 0x3F, 0x6F, 0x70, 0x74, 0x69, 0x6F, 0x6E
	db 0x61, 0x6C, 0x2D, 0x64, 0x65, 0x66, 0x61, 0x75
	db 0x6C, 0x74, 0x29
	; L_constants + 3068:
	db T_string	; "list->vector"
	dq 12
	db 0x6C, 0x69, 0x73, 0x74, 0x2D, 0x3E, 0x76, 0x65
	db 0x63, 0x74, 0x6F, 0x72
	; L_constants + 3089:
	db T_string	; "vector"
	dq 6
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72
	; L_constants + 3104:
	db T_string	; "vector->list"
	dq 12
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x3E
	db 0x6C, 0x69, 0x73, 0x74
	; L_constants + 3125:
	db T_string	; "random"
	dq 6
	db 0x72, 0x61, 0x6E, 0x64, 0x6F, 0x6D
	; L_constants + 3140:
	db T_string	; "positive?"
	dq 9
	db 0x70, 0x6F, 0x73, 0x69, 0x74, 0x69, 0x76, 0x65
	db 0x3F
	; L_constants + 3158:
	db T_string	; "negative?"
	dq 9
	db 0x6E, 0x65, 0x67, 0x61, 0x74, 0x69, 0x76, 0x65
	db 0x3F
	; L_constants + 3176:
	db T_string	; "even?"
	dq 5
	db 0x65, 0x76, 0x65, 0x6E, 0x3F
	; L_constants + 3190:
	db T_integer	; 2
	dq 2
	; L_constants + 3199:
	db T_string	; "odd?"
	dq 4
	db 0x6F, 0x64, 0x64, 0x3F
	; L_constants + 3212:
	db T_string	; "abs"
	dq 3
	db 0x61, 0x62, 0x73
	; L_constants + 3224:
	db T_string	; "equal?"
	dq 6
	db 0x65, 0x71, 0x75, 0x61, 0x6C, 0x3F
	; L_constants + 3239:
	db T_string	; "assoc"
	dq 5
	db 0x61, 0x73, 0x73, 0x6F, 0x63
	; L_constants + 3253:
	db T_string	; "string-append"
	dq 13
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x61
	db 0x70, 0x70, 0x65, 0x6E, 0x64
	; L_constants + 3275:
	db T_string	; "vector-append"
	dq 13
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x61
	db 0x70, 0x70, 0x65, 0x6E, 0x64
	; L_constants + 3297:
	db T_string	; "string-reverse"
	dq 14
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65
	; L_constants + 3320:
	db T_string	; "vector-reverse"
	dq 14
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65
	; L_constants + 3343:
	db T_string	; "string-reverse!"
	dq 15
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65, 0x21
	; L_constants + 3367:
	db T_string	; "vector-reverse!"
	dq 15
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65, 0x21
	; L_constants + 3391:
	db T_string	; "make-list-thunk"
	dq 15
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x6C, 0x69, 0x73
	db 0x74, 0x2D, 0x74, 0x68, 0x75, 0x6E, 0x6B
	; L_constants + 3415:
	db T_string	; "make-string-thunk"
	dq 17
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x73, 0x74, 0x72
	db 0x69, 0x6E, 0x67, 0x2D, 0x74, 0x68, 0x75, 0x6E
	db 0x6B
	; L_constants + 3441:
	db T_string	; "make-vector-thunk"
	dq 17
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x76, 0x65, 0x63
	db 0x74, 0x6F, 0x72, 0x2D, 0x74, 0x68, 0x75, 0x6E
	db 0x6B
	; L_constants + 3467:
	db T_string	; "logarithm"
	dq 9
	db 0x6C, 0x6F, 0x67, 0x61, 0x72, 0x69, 0x74, 0x68
	db 0x6D
	; L_constants + 3485:
	db T_real	; 1.000000
	dq 1.000000
	; L_constants + 3494:
	db T_string	; "newline"
	dq 7
	db 0x6E, 0x65, 0x77, 0x6C, 0x69, 0x6E, 0x65
	; L_constants + 3510:
	db T_char, 0x0A	; #\newline
	; L_constants + 3512:
	db T_string	; "void"
	dq 4
	db 0x76, 0x6F, 0x69, 0x64
	; L_constants + 3525:
	db T_string	; "with"
	dq 4
	db 0x77, 0x69, 0x74, 0x68
	; L_constants + 3538:
	db T_string	; "moshe"
	dq 5
	db 0x6D, 0x6F, 0x73, 0x68, 0x65
	; L_constants + 3552:
	db T_interned_symbol	; moshe
	dq L_constants + 3538
	; L_constants + 3561:
	db T_string	; "yosi"
	dq 4
	db 0x79, 0x6F, 0x73, 0x69
	; L_constants + 3574:
	db T_interned_symbol	; yosi
	dq L_constants + 3561
	; L_constants + 3583:
	db T_string	; "dana"
	dq 4
	db 0x64, 0x61, 0x6E, 0x61
	; L_constants + 3596:
	db T_interned_symbol	; dana
	dq L_constants + 3583
	; L_constants + 3605:
	db T_string	; "michal"
	dq 6
	db 0x6D, 0x69, 0x63, 0x68, 0x61, 0x6C
	; L_constants + 3620:
	db T_interned_symbol	; michal
	dq L_constants + 3605
	; L_constants + 3629:
	db T_string	; "olga"
	dq 4
	db 0x6F, 0x6C, 0x67, 0x61
	; L_constants + 3642:
	db T_interned_symbol	; olga
	dq L_constants + 3629
	; L_constants + 3651:
	db T_string	; "sonia"
	dq 5
	db 0x73, 0x6F, 0x6E, 0x69, 0x61
	; L_constants + 3665:
	db T_interned_symbol	; sonia
	dq L_constants + 3651
free_var_0:	; location of *
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2260

free_var_1:	; location of +
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2125

free_var_2:	; location of -
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2228

free_var_3:	; location of /
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2288

free_var_4:	; location of <
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2320

free_var_5:	; location of <=
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2330

free_var_6:	; location of =
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2362

free_var_7:	; location of >
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2341

free_var_8:	; location of >=
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2351

free_var_9:	; location of __bin-add-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 617

free_var_10:	; location of __bin-add-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 533

free_var_11:	; location of __bin-add-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 701

free_var_12:	; location of __bin-apply
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 513

free_var_13:	; location of __bin-div-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 680

free_var_14:	; location of __bin-div-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 596

free_var_15:	; location of __bin-div-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 764

free_var_16:	; location of __bin-equal-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 903

free_var_17:	; location of __bin-equal-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 880

free_var_18:	; location of __bin-equal-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 926

free_var_19:	; location of __bin-less-than-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 826

free_var_20:	; location of __bin-less-than-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 799

free_var_21:	; location of __bin-less-than-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 853

free_var_22:	; location of __bin-mul-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 659

free_var_23:	; location of __bin-mul-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 575

free_var_24:	; location of __bin-mul-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 743

free_var_25:	; location of __bin-sub-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 638

free_var_26:	; location of __bin-sub-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 554

free_var_27:	; location of __bin-sub-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 722

free_var_28:	; location of __bin_integer_to_fraction
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2144

free_var_29:	; location of __integer-to-fraction
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1186

free_var_30:	; location of abs
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3212

free_var_31:	; location of andmap
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2042

free_var_32:	; location of append
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2091

free_var_33:	; location of apply
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2002

free_var_34:	; location of assoc
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3239

free_var_35:	; location of caaaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1665

free_var_36:	; location of caaadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1680

free_var_37:	; location of caaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1553

free_var_38:	; location of caadar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1695

free_var_39:	; location of caaddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1710

free_var_40:	; location of caadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1567

free_var_41:	; location of caar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1501

free_var_42:	; location of cadaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1725

free_var_43:	; location of cadadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1740

free_var_44:	; location of cadar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1581

free_var_45:	; location of caddar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1755

free_var_46:	; location of cadddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1770

free_var_47:	; location of caddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1595

free_var_48:	; location of cadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1514

free_var_49:	; location of car
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 277

free_var_50:	; location of cdaaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1785

free_var_51:	; location of cdaadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1800

free_var_52:	; location of cdaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1609

free_var_53:	; location of cdadar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1815

free_var_54:	; location of cdaddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1830

free_var_55:	; location of cdadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1623

free_var_56:	; location of cdar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1527

free_var_57:	; location of cddaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1845

free_var_58:	; location of cddadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1860

free_var_59:	; location of cddar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1637

free_var_60:	; location of cdddar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1875

free_var_61:	; location of cddddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1890

free_var_62:	; location of cdddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1651

free_var_63:	; location of cddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1540

free_var_64:	; location of cdr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 289

free_var_65:	; location of char->integer
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 425

free_var_66:	; location of char-ci<=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2595

free_var_67:	; location of char-ci<?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2577

free_var_68:	; location of char-ci=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2614

free_var_69:	; location of char-ci>=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2650

free_var_70:	; location of char-ci>?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2632

free_var_71:	; location of char-downcase
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2527

free_var_72:	; location of char-upcase
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2549

free_var_73:	; location of char<=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2465

free_var_74:	; location of char<?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2450

free_var_75:	; location of char=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2481

free_var_76:	; location of char>=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2511

free_var_77:	; location of char>?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2496

free_var_78:	; location of char?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 48

free_var_79:	; location of cons
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 223

free_var_80:	; location of eq?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1174

free_var_81:	; location of equal?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3224

free_var_82:	; location of error
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 785

free_var_83:	; location of even?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3176

free_var_84:	; location of fact
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2307

free_var_85:	; location of fold-left
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2073

free_var_86:	; location of fold-right
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2106

free_var_87:	; location of fraction->real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 402

free_var_88:	; location of fraction?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 152

free_var_89:	; location of integer->char
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 447

free_var_90:	; location of integer->real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 380

free_var_91:	; location of integer?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 496

free_var_92:	; location of list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1919

free_var_93:	; location of list*
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1962

free_var_94:	; location of list->string
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2715

free_var_95:	; location of list->vector
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3068

free_var_96:	; location of list?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1905

free_var_97:	; location of logarithm
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3467

free_var_98:	; location of make-list-thunk
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3391

free_var_99:	; location of make-string
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1116

free_var_100:	; location of make-string-thunk
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3415

free_var_101:	; location of make-vector
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1096

free_var_102:	; location of make-vector-thunk
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3441

free_var_103:	; location of map
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2030

free_var_104:	; location of negative?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3158

free_var_105:	; location of newline
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3494

free_var_106:	; location of not
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1932

free_var_107:	; location of null?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 6

free_var_108:	; location of number?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 187

free_var_109:	; location of odd?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3199

free_var_110:	; location of ormap
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2016

free_var_111:	; location of pair?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 20

free_var_112:	; location of positive?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3140

free_var_113:	; location of random
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3125

free_var_114:	; location of rational?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1944

free_var_115:	; location of real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2238

free_var_116:	; location of real?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 138

free_var_117:	; location of remainder
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 966

free_var_118:	; location of reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2057

free_var_119:	; location of string->list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2736

free_var_120:	; location of string-append
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3253

free_var_121:	; location of string-ci<=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2864

free_var_122:	; location of string-ci<?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2844

free_var_123:	; location of string-ci=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2885

free_var_124:	; location of string-ci>=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2905

free_var_125:	; location of string-ci>?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2926

free_var_126:	; location of string-downcase
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2669

free_var_127:	; location of string-length
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 301

free_var_128:	; location of string-ref
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1018

free_var_129:	; location of string-reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3297

free_var_130:	; location of string-reverse!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3343

free_var_131:	; location of string-set!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1076

free_var_132:	; location of string-upcase
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2693

free_var_133:	; location of string<=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2774

free_var_134:	; location of string<?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2757

free_var_135:	; location of string=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2792

free_var_136:	; location of string>=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2809

free_var_137:	; location of string>?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2827

free_var_138:	; location of string?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 62

free_var_139:	; location of trng
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 469

free_var_140:	; location of vector
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3089

free_var_141:	; location of vector->list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3104

free_var_142:	; location of vector-append
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3275

free_var_143:	; location of vector-length
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 323

free_var_144:	; location of vector-ref
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1037

free_var_145:	; location of vector-reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3320

free_var_146:	; location of vector-reverse!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3367

free_var_147:	; location of vector-set!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1056

free_var_148:	; location of vector?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 103

free_var_149:	; location of void
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3512

free_var_150:	; location of with
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3525

free_var_151:	; location of write-char
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 258

free_var_152:	; location of zero?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 482


extern printf, fprintf, stdout, stderr, fwrite, exit, putchar, getchar
global main
section .text
main:
        enter 0, 0
        push 0
        push 0
        push Lend
        enter 0, 0
	; building closure for null?
	mov rdi, free_var_107
	mov rsi, L_code_ptr_is_null
	call bind_primitive

	; building closure for pair?
	mov rdi, free_var_111
	mov rsi, L_code_ptr_is_pair
	call bind_primitive

	; building closure for char?
	mov rdi, free_var_78
	mov rsi, L_code_ptr_is_char
	call bind_primitive

	; building closure for string?
	mov rdi, free_var_138
	mov rsi, L_code_ptr_is_string
	call bind_primitive

	; building closure for vector?
	mov rdi, free_var_148
	mov rsi, L_code_ptr_is_vector
	call bind_primitive

	; building closure for real?
	mov rdi, free_var_116
	mov rsi, L_code_ptr_is_real
	call bind_primitive

	; building closure for fraction?
	mov rdi, free_var_88
	mov rsi, L_code_ptr_is_fraction
	call bind_primitive

	; building closure for number?
	mov rdi, free_var_108
	mov rsi, L_code_ptr_is_number
	call bind_primitive

	; building closure for cons
	mov rdi, free_var_79
	mov rsi, L_code_ptr_cons
	call bind_primitive

	; building closure for write-char
	mov rdi, free_var_151
	mov rsi, L_code_ptr_write_char
	call bind_primitive

	; building closure for car
	mov rdi, free_var_49
	mov rsi, L_code_ptr_car
	call bind_primitive

	; building closure for cdr
	mov rdi, free_var_64
	mov rsi, L_code_ptr_cdr
	call bind_primitive

	; building closure for string-length
	mov rdi, free_var_127
	mov rsi, L_code_ptr_string_length
	call bind_primitive

	; building closure for vector-length
	mov rdi, free_var_143
	mov rsi, L_code_ptr_vector_length
	call bind_primitive

	; building closure for integer->real
	mov rdi, free_var_90
	mov rsi, L_code_ptr_integer_to_real
	call bind_primitive

	; building closure for fraction->real
	mov rdi, free_var_87
	mov rsi, L_code_ptr_fraction_to_real
	call bind_primitive

	; building closure for char->integer
	mov rdi, free_var_65
	mov rsi, L_code_ptr_char_to_integer
	call bind_primitive

	; building closure for integer->char
	mov rdi, free_var_89
	mov rsi, L_code_ptr_integer_to_char
	call bind_primitive

	; building closure for trng
	mov rdi, free_var_139
	mov rsi, L_code_ptr_trng
	call bind_primitive

	; building closure for zero?
	mov rdi, free_var_152
	mov rsi, L_code_ptr_is_zero
	call bind_primitive

	; building closure for integer?
	mov rdi, free_var_91
	mov rsi, L_code_ptr_is_integer
	call bind_primitive

	; building closure for __bin-apply
	mov rdi, free_var_12
	mov rsi, L_code_ptr_bin_apply
	call bind_primitive

	; building closure for __bin-add-rr
	mov rdi, free_var_10
	mov rsi, L_code_ptr_raw_bin_add_rr
	call bind_primitive

	; building closure for __bin-sub-rr
	mov rdi, free_var_26
	mov rsi, L_code_ptr_raw_bin_sub_rr
	call bind_primitive

	; building closure for __bin-mul-rr
	mov rdi, free_var_23
	mov rsi, L_code_ptr_raw_bin_mul_rr
	call bind_primitive

	; building closure for __bin-div-rr
	mov rdi, free_var_14
	mov rsi, L_code_ptr_raw_bin_div_rr
	call bind_primitive

	; building closure for __bin-add-qq
	mov rdi, free_var_9
	mov rsi, L_code_ptr_raw_bin_add_qq
	call bind_primitive

	; building closure for __bin-sub-qq
	mov rdi, free_var_25
	mov rsi, L_code_ptr_raw_bin_sub_qq
	call bind_primitive

	; building closure for __bin-mul-qq
	mov rdi, free_var_22
	mov rsi, L_code_ptr_raw_bin_mul_qq
	call bind_primitive

	; building closure for __bin-div-qq
	mov rdi, free_var_13
	mov rsi, L_code_ptr_raw_bin_div_qq
	call bind_primitive

	; building closure for __bin-add-zz
	mov rdi, free_var_11
	mov rsi, L_code_ptr_raw_bin_add_zz
	call bind_primitive

	; building closure for __bin-sub-zz
	mov rdi, free_var_27
	mov rsi, L_code_ptr_raw_bin_sub_zz
	call bind_primitive

	; building closure for __bin-mul-zz
	mov rdi, free_var_24
	mov rsi, L_code_ptr_raw_bin_mul_zz
	call bind_primitive

	; building closure for __bin-div-zz
	mov rdi, free_var_15
	mov rsi, L_code_ptr_raw_bin_div_zz
	call bind_primitive

	; building closure for error
	mov rdi, free_var_82
	mov rsi, L_code_ptr_error
	call bind_primitive

	; building closure for __bin-less-than-rr
	mov rdi, free_var_20
	mov rsi, L_code_ptr_raw_less_than_rr
	call bind_primitive

	; building closure for __bin-less-than-qq
	mov rdi, free_var_19
	mov rsi, L_code_ptr_raw_less_than_qq
	call bind_primitive

	; building closure for __bin-less-than-zz
	mov rdi, free_var_21
	mov rsi, L_code_ptr_raw_less_than_zz
	call bind_primitive

	; building closure for __bin-equal-rr
	mov rdi, free_var_17
	mov rsi, L_code_ptr_raw_equal_rr
	call bind_primitive

	; building closure for __bin-equal-qq
	mov rdi, free_var_16
	mov rsi, L_code_ptr_raw_equal_qq
	call bind_primitive

	; building closure for __bin-equal-zz
	mov rdi, free_var_18
	mov rsi, L_code_ptr_raw_equal_zz
	call bind_primitive

	; building closure for remainder
	mov rdi, free_var_117
	mov rsi, L_code_ptr_remainder
	call bind_primitive

	; building closure for string-ref
	mov rdi, free_var_128
	mov rsi, L_code_ptr_string_ref
	call bind_primitive

	; building closure for vector-ref
	mov rdi, free_var_144
	mov rsi, L_code_ptr_vector_ref
	call bind_primitive

	; building closure for vector-set!
	mov rdi, free_var_147
	mov rsi, L_code_ptr_vector_set
	call bind_primitive

	; building closure for string-set!
	mov rdi, free_var_131
	mov rsi, L_code_ptr_string_set
	call bind_primitive

	; building closure for make-vector
	mov rdi, free_var_101
	mov rsi, L_code_ptr_make_vector
	call bind_primitive

	; building closure for make-string
	mov rdi, free_var_99
	mov rsi, L_code_ptr_make_string
	call bind_primitive

	; building closure for eq?
	mov rdi, free_var_80
	mov rsi, L_code_ptr_is_eq
	call bind_primitive

	; building closure for __integer-to-fraction
	mov rdi, free_var_29
	mov rsi, L_code_ptr_integer_to_fraction
	call bind_primitive

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_06f4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_06f4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_06f4
.L_lambda_simple_env_end_06f4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_06f4:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_06f4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_06f4
.L_lambda_simple_params_end_06f4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_06f4
	jmp .L_lambda_simple_end_06f4
.L_lambda_simple_code_06f4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07cf
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07cf:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08c7:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08c7
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08c7
	.L_tc_recycle_frame_done_08c7:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_06f4:	; new closure is in rax
	mov qword [free_var_41], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_06f5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_06f5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_06f5
.L_lambda_simple_env_end_06f5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_06f5:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_06f5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_06f5
.L_lambda_simple_params_end_06f5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_06f5
	jmp .L_lambda_simple_end_06f5
.L_lambda_simple_code_06f5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07d0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07d0:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08c8:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08c8
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08c8
	.L_tc_recycle_frame_done_08c8:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_06f5:	; new closure is in rax
	mov qword [free_var_48], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_06f6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_06f6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_06f6
.L_lambda_simple_env_end_06f6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_06f6:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_06f6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_06f6
.L_lambda_simple_params_end_06f6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_06f6
	jmp .L_lambda_simple_end_06f6
.L_lambda_simple_code_06f6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07d1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07d1:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08c9:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08c9
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08c9
	.L_tc_recycle_frame_done_08c9:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_06f6:	; new closure is in rax
	mov qword [free_var_56], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_06f7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_06f7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_06f7
.L_lambda_simple_env_end_06f7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_06f7:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_06f7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_06f7
.L_lambda_simple_params_end_06f7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_06f7
	jmp .L_lambda_simple_end_06f7
.L_lambda_simple_code_06f7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07d2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07d2:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08ca:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08ca
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08ca
	.L_tc_recycle_frame_done_08ca:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_06f7:	; new closure is in rax
	mov qword [free_var_63], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_06f8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_06f8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_06f8
.L_lambda_simple_env_end_06f8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_06f8:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_06f8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_06f8
.L_lambda_simple_params_end_06f8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_06f8
	jmp .L_lambda_simple_end_06f8
.L_lambda_simple_code_06f8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07d3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07d3:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08cb:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08cb
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08cb
	.L_tc_recycle_frame_done_08cb:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_06f8:	; new closure is in rax
	mov qword [free_var_37], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_06f9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_06f9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_06f9
.L_lambda_simple_env_end_06f9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_06f9:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_06f9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_06f9
.L_lambda_simple_params_end_06f9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_06f9
	jmp .L_lambda_simple_end_06f9
.L_lambda_simple_code_06f9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07d4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07d4:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08cc:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08cc
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08cc
	.L_tc_recycle_frame_done_08cc:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_06f9:	; new closure is in rax
	mov qword [free_var_40], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_06fa:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_06fa
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_06fa
.L_lambda_simple_env_end_06fa:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_06fa:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_06fa
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_06fa
.L_lambda_simple_params_end_06fa:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_06fa
	jmp .L_lambda_simple_end_06fa
.L_lambda_simple_code_06fa:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07d5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07d5:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08cd:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08cd
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08cd
	.L_tc_recycle_frame_done_08cd:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_06fa:	; new closure is in rax
	mov qword [free_var_44], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_06fb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_06fb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_06fb
.L_lambda_simple_env_end_06fb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_06fb:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_06fb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_06fb
.L_lambda_simple_params_end_06fb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_06fb
	jmp .L_lambda_simple_end_06fb
.L_lambda_simple_code_06fb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07d6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07d6:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08ce:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08ce
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08ce
	.L_tc_recycle_frame_done_08ce:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_06fb:	; new closure is in rax
	mov qword [free_var_47], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_06fc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_06fc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_06fc
.L_lambda_simple_env_end_06fc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_06fc:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_06fc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_06fc
.L_lambda_simple_params_end_06fc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_06fc
	jmp .L_lambda_simple_end_06fc
.L_lambda_simple_code_06fc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07d7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07d7:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08cf:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08cf
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08cf
	.L_tc_recycle_frame_done_08cf:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_06fc:	; new closure is in rax
	mov qword [free_var_52], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_06fd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_06fd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_06fd
.L_lambda_simple_env_end_06fd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_06fd:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_06fd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_06fd
.L_lambda_simple_params_end_06fd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_06fd
	jmp .L_lambda_simple_end_06fd
.L_lambda_simple_code_06fd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07d8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07d8:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08d0:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08d0
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08d0
	.L_tc_recycle_frame_done_08d0:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_06fd:	; new closure is in rax
	mov qword [free_var_55], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_06fe:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_06fe
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_06fe
.L_lambda_simple_env_end_06fe:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_06fe:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_06fe
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_06fe
.L_lambda_simple_params_end_06fe:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_06fe
	jmp .L_lambda_simple_end_06fe
.L_lambda_simple_code_06fe:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07d9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07d9:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08d1:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08d1
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08d1
	.L_tc_recycle_frame_done_08d1:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_06fe:	; new closure is in rax
	mov qword [free_var_59], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_06ff:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_06ff
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_06ff
.L_lambda_simple_env_end_06ff:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_06ff:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_06ff
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_06ff
.L_lambda_simple_params_end_06ff:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_06ff
	jmp .L_lambda_simple_end_06ff
.L_lambda_simple_code_06ff:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07da
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07da:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08d2:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08d2
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08d2
	.L_tc_recycle_frame_done_08d2:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_06ff:	; new closure is in rax
	mov qword [free_var_62], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0700:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0700
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0700
.L_lambda_simple_env_end_0700:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0700:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0700
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0700
.L_lambda_simple_params_end_0700:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0700
	jmp .L_lambda_simple_end_0700
.L_lambda_simple_code_0700:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07db
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07db:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08d3:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08d3
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08d3
	.L_tc_recycle_frame_done_08d3:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0700:	; new closure is in rax
	mov qword [free_var_35], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0701:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0701
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0701
.L_lambda_simple_env_end_0701:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0701:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0701
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0701
.L_lambda_simple_params_end_0701:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0701
	jmp .L_lambda_simple_end_0701
.L_lambda_simple_code_0701:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07dc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07dc:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08d4:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08d4
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08d4
	.L_tc_recycle_frame_done_08d4:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0701:	; new closure is in rax
	mov qword [free_var_36], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0702:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0702
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0702
.L_lambda_simple_env_end_0702:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0702:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0702
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0702
.L_lambda_simple_params_end_0702:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0702
	jmp .L_lambda_simple_end_0702
.L_lambda_simple_code_0702:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07dd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07dd:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08d5:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08d5
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08d5
	.L_tc_recycle_frame_done_08d5:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0702:	; new closure is in rax
	mov qword [free_var_38], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0703:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0703
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0703
.L_lambda_simple_env_end_0703:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0703:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0703
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0703
.L_lambda_simple_params_end_0703:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0703
	jmp .L_lambda_simple_end_0703
.L_lambda_simple_code_0703:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07de
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07de:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08d6:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08d6
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08d6
	.L_tc_recycle_frame_done_08d6:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0703:	; new closure is in rax
	mov qword [free_var_39], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0704:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0704
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0704
.L_lambda_simple_env_end_0704:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0704:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0704
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0704
.L_lambda_simple_params_end_0704:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0704
	jmp .L_lambda_simple_end_0704
.L_lambda_simple_code_0704:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07df
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07df:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08d7:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08d7
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08d7
	.L_tc_recycle_frame_done_08d7:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0704:	; new closure is in rax
	mov qword [free_var_42], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0705:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0705
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0705
.L_lambda_simple_env_end_0705:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0705:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0705
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0705
.L_lambda_simple_params_end_0705:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0705
	jmp .L_lambda_simple_end_0705
.L_lambda_simple_code_0705:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07e0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07e0:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08d8:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08d8
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08d8
	.L_tc_recycle_frame_done_08d8:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0705:	; new closure is in rax
	mov qword [free_var_43], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0706:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0706
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0706
.L_lambda_simple_env_end_0706:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0706:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0706
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0706
.L_lambda_simple_params_end_0706:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0706
	jmp .L_lambda_simple_end_0706
.L_lambda_simple_code_0706:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07e1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07e1:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08d9:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08d9
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08d9
	.L_tc_recycle_frame_done_08d9:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0706:	; new closure is in rax
	mov qword [free_var_45], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0707:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0707
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0707
.L_lambda_simple_env_end_0707:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0707:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0707
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0707
.L_lambda_simple_params_end_0707:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0707
	jmp .L_lambda_simple_end_0707
.L_lambda_simple_code_0707:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07e2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07e2:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08da:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08da
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08da
	.L_tc_recycle_frame_done_08da:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0707:	; new closure is in rax
	mov qword [free_var_46], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0708:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0708
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0708
.L_lambda_simple_env_end_0708:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0708:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0708
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0708
.L_lambda_simple_params_end_0708:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0708
	jmp .L_lambda_simple_end_0708
.L_lambda_simple_code_0708:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07e3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07e3:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08db:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08db
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08db
	.L_tc_recycle_frame_done_08db:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0708:	; new closure is in rax
	mov qword [free_var_50], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0709:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0709
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0709
.L_lambda_simple_env_end_0709:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0709:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0709
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0709
.L_lambda_simple_params_end_0709:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0709
	jmp .L_lambda_simple_end_0709
.L_lambda_simple_code_0709:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07e4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07e4:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08dc:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08dc
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08dc
	.L_tc_recycle_frame_done_08dc:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0709:	; new closure is in rax
	mov qword [free_var_51], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_070a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_070a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_070a
.L_lambda_simple_env_end_070a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_070a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_070a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_070a
.L_lambda_simple_params_end_070a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_070a
	jmp .L_lambda_simple_end_070a
.L_lambda_simple_code_070a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07e5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07e5:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08dd:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08dd
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08dd
	.L_tc_recycle_frame_done_08dd:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_070a:	; new closure is in rax
	mov qword [free_var_53], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_070b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_070b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_070b
.L_lambda_simple_env_end_070b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_070b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_070b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_070b
.L_lambda_simple_params_end_070b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_070b
	jmp .L_lambda_simple_end_070b
.L_lambda_simple_code_070b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07e6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07e6:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08de:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08de
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08de
	.L_tc_recycle_frame_done_08de:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_070b:	; new closure is in rax
	mov qword [free_var_54], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_070c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_070c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_070c
.L_lambda_simple_env_end_070c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_070c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_070c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_070c
.L_lambda_simple_params_end_070c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_070c
	jmp .L_lambda_simple_end_070c
.L_lambda_simple_code_070c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07e7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07e7:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08df:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08df
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08df
	.L_tc_recycle_frame_done_08df:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_070c:	; new closure is in rax
	mov qword [free_var_57], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_070d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_070d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_070d
.L_lambda_simple_env_end_070d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_070d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_070d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_070d
.L_lambda_simple_params_end_070d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_070d
	jmp .L_lambda_simple_end_070d
.L_lambda_simple_code_070d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07e8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07e8:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08e0:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08e0
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08e0
	.L_tc_recycle_frame_done_08e0:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_070d:	; new closure is in rax
	mov qword [free_var_58], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_070e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_070e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_070e
.L_lambda_simple_env_end_070e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_070e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_070e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_070e
.L_lambda_simple_params_end_070e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_070e
	jmp .L_lambda_simple_end_070e
.L_lambda_simple_code_070e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07e9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07e9:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08e1:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08e1
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08e1
	.L_tc_recycle_frame_done_08e1:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_070e:	; new closure is in rax
	mov qword [free_var_60], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_070f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_070f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_070f
.L_lambda_simple_env_end_070f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_070f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_070f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_070f
.L_lambda_simple_params_end_070f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_070f
	jmp .L_lambda_simple_end_070f
.L_lambda_simple_code_070f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07ea
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07ea:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08e2:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08e2
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08e2
	.L_tc_recycle_frame_done_08e2:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_070f:	; new closure is in rax
	mov qword [free_var_61], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0710:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0710
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0710
.L_lambda_simple_env_end_0710:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0710:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0710
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0710
.L_lambda_simple_params_end_0710:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0710
	jmp .L_lambda_simple_end_0710
.L_lambda_simple_code_0710:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07eb
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07eb:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_if_end_0550
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04d0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_96]	; free var list?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08e3:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08e3
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08e3
	.L_tc_recycle_frame_done_08e3:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0551
.L_if_else_04d0:
	mov rax, L_constants + 2
.L_if_end_0551:
	cmp rax, sob_boolean_false
	jne .L_if_end_0550
.L_if_end_0550:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0710:	; new closure is in rax
	mov qword [free_var_96], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov r9, qword [rbp + 8 * 2]
	mov r9, qword [rbp + 8 * 3]
	mov rdi, 8 * 0	; new rib for optional parameters
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_00dc:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 0
	je .L_lambda_opt_env_end_00dc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00dc
.L_lambda_opt_env_end_00dc:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0292:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_01b7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0292
.L_lambda_opt_params_end_01b7:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00dc
	jmp .L_lambda_opt_end_01b7
.L_lambda_opt_code_00dc:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	jge .L_lambda_simple_arity_check_ok_07ec
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07ec:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 0
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_0294
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_0293: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_0293
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_01b8
	.L_lambda_opt_params_loop_0294:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_0293: ;loop for copying the opt into list
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov rbx, qword [rcx]
	mov SOB_PAIR_CAR(rax), rbx
	mov SOB_PAIR_CDR(rax), r9
	mov r9, rax
	dec rdx
	sub rcx, 8
	cmp rdx, 0
	jne .L_lambda_opt_params_loop_0293
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_0294:
	cmp rdx, 0
	je .L_lambda_opt_params_end_01b8
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_0294
	.L_lambda_opt_params_end_01b8:
	add rsp,rcx
	mov rbx, 0
	mov rbx, qword [rsp + 8 * 2]
	add rbx,3
	sub rbx,r8
	shl rbx, 3
	add rbx, rsp
	mov qword[rbx] , r9
	dec r8
	sub qword [rsp + 8 * 2], r8
	.L_lambda_opt_end_01b8:
	enter 0, 0
	mov rax, PARAM(0)	; param args
	LEAVE
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_01b7:
	mov qword [free_var_92], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0711:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0711
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0711
.L_lambda_simple_env_end_0711:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0711:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0711
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0711
.L_lambda_simple_params_end_0711:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0711
	jmp .L_lambda_simple_end_0711
.L_lambda_simple_code_0711:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07ed
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07ed:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	cmp rax, sob_boolean_false
	je .L_if_else_04d1
	mov rax, L_constants + 2
	jmp .L_if_end_0552
.L_if_else_04d1:
	mov rax, L_constants + 3
.L_if_end_0552:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0711:	; new closure is in rax
	mov qword [free_var_106], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0712:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0712
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0712
.L_lambda_simple_env_end_0712:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0712:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0712
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0712
.L_lambda_simple_params_end_0712:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0712
	jmp .L_lambda_simple_end_0712
.L_lambda_simple_code_0712:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07ee
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07ee:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param q
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_if_end_0553
	; preparing a tail-call
	mov rax, PARAM(0)	; param q
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08e4:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08e4
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08e4
	.L_tc_recycle_frame_done_08e4:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	cmp rax, sob_boolean_false
	jne .L_if_end_0553
.L_if_end_0553:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0712:	; new closure is in rax
	mov qword [free_var_114], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0713:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0713
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0713
.L_lambda_simple_env_end_0713:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0713:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0713
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0713
.L_lambda_simple_params_end_0713:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0713
	jmp .L_lambda_simple_end_0713
.L_lambda_simple_code_0713:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07ef
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07ef:
	enter 0, 0
	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +0)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +0)], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0714:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0714
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0714
.L_lambda_simple_env_end_0714:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0714:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0714
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0714
.L_lambda_simple_params_end_0714:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0714
	jmp .L_lambda_simple_end_0714
.L_lambda_simple_code_0714:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_07f0
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07f0:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04d2
	mov rax, PARAM(0)	; param a
	jmp .L_if_end_0554
.L_if_else_04d2:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_79]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08e5:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08e5
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08e5
	.L_tc_recycle_frame_done_08e5:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0554:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0714:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov r9, qword [rbp + 8 * 2]
	mov r9, qword [rbp + 8 * 3]
	mov rdi, 8 * 1	; new rib for optional parameters
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_00dd:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_00dd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00dd
.L_lambda_opt_env_end_00dd:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0295:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_01b9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0295
.L_lambda_opt_params_end_01b9:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00dd
	jmp .L_lambda_opt_end_01b9
.L_lambda_opt_code_00dd:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_07f1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07f1:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_0297
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_0296: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_0296
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_01ba
	.L_lambda_opt_params_loop_0297:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_0296: ;loop for copying the opt into list
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov rbx, qword [rcx]
	mov SOB_PAIR_CAR(rax), rbx
	mov SOB_PAIR_CDR(rax), r9
	mov r9, rax
	dec rdx
	sub rcx, 8
	cmp rdx, 0
	jne .L_lambda_opt_params_loop_0296
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_0297:
	cmp rdx, 0
	je .L_lambda_opt_params_end_01ba
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_0297
	.L_lambda_opt_params_end_01ba:
	add rsp,rcx
	mov rbx, 1
	mov rbx, qword [rsp + 8 * 2]
	add rbx,3
	sub rbx,r8
	shl rbx, 3
	add rbx, rsp
	mov qword[rbx] , r9
	dec r8
	sub qword [rsp + 8 * 2], r8
	.L_lambda_opt_end_01ba:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08e6:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08e6
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08e6
	.L_tc_recycle_frame_done_08e6:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_01b9:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0713:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_93], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0715:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0715
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0715
.L_lambda_simple_env_end_0715:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0715:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0715
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0715
.L_lambda_simple_params_end_0715:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0715
	jmp .L_lambda_simple_end_0715
.L_lambda_simple_code_0715:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07f2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07f2:
	enter 0, 0
	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +0)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +0)], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0716:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0716
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0716
.L_lambda_simple_env_end_0716:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0716:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0716
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0716
.L_lambda_simple_params_end_0716:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0716
	jmp .L_lambda_simple_end_0716
.L_lambda_simple_code_0716:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_07f3
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07f3:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04d3
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_79]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08e7:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08e7
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08e7
	.L_tc_recycle_frame_done_08e7:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0555
.L_if_else_04d3:
	mov rax, PARAM(0)	; param a
.L_if_end_0555:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0716:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov r9, qword [rbp + 8 * 2]
	mov r9, qword [rbp + 8 * 3]
	mov rdi, 8 * 1	; new rib for optional parameters
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_00de:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_00de
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00de
.L_lambda_opt_env_end_00de:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0298:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_01bb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0298
.L_lambda_opt_params_end_01bb:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00de
	jmp .L_lambda_opt_end_01bb
.L_lambda_opt_code_00de:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_07f4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07f4:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_029a
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_0299: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_0299
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_01bc
	.L_lambda_opt_params_loop_029a:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_0299: ;loop for copying the opt into list
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov rbx, qword [rcx]
	mov SOB_PAIR_CAR(rax), rbx
	mov SOB_PAIR_CDR(rax), r9
	mov r9, rax
	dec rdx
	sub rcx, 8
	cmp rdx, 0
	jne .L_lambda_opt_params_loop_0299
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_029a:
	cmp rdx, 0
	je .L_lambda_opt_params_end_01bc
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_029a
	.L_lambda_opt_params_end_01bc:
	add rsp,rcx
	mov rbx, 1
	mov rbx, qword [rsp + 8 * 2]
	add rbx,3
	sub rbx,r8
	shl rbx, 3
	add rbx, rsp
	mov qword[rbx] , r9
	dec r8
	sub qword [rsp + 8 * 2], r8
	.L_lambda_opt_end_01bc:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_12]	; free var __bin-apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08e8:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08e8
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08e8
	.L_tc_recycle_frame_done_08e8:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_01bb:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0715:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_33], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov r9, qword [rbp + 8 * 2]
	mov r9, qword [rbp + 8 * 3]
	mov rdi, 8 * 0	; new rib for optional parameters
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_00df:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 0
	je .L_lambda_opt_env_end_00df
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00df
.L_lambda_opt_env_end_00df:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_029b:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_01bd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_029b
.L_lambda_opt_params_end_01bd:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00df
	jmp .L_lambda_opt_end_01bd
.L_lambda_opt_code_00df:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_07f5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07f5:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_029d
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_029c: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_029c
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_01be
	.L_lambda_opt_params_loop_029d:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_029c: ;loop for copying the opt into list
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov rbx, qword [rcx]
	mov SOB_PAIR_CAR(rax), rbx
	mov SOB_PAIR_CDR(rax), r9
	mov r9, rax
	dec rdx
	sub rcx, 8
	cmp rdx, 0
	jne .L_lambda_opt_params_loop_029c
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_029d:
	cmp rdx, 0
	je .L_lambda_opt_params_end_01be
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_029d
	.L_lambda_opt_params_end_01be:
	add rsp,rcx
	mov rbx, 1
	mov rbx, qword [rsp + 8 * 2]
	add rbx,3
	sub rbx,r8
	shl rbx, 3
	add rbx, rsp
	mov qword[rbx] , r9
	dec r8
	sub qword [rsp + 8 * 2], r8
	.L_lambda_opt_end_01be:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0717:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0717
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0717
.L_lambda_simple_env_end_0717:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0717:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0717
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0717
.L_lambda_simple_params_end_0717:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0717
	jmp .L_lambda_simple_end_0717
.L_lambda_simple_code_0717:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07f6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07f6:
	enter 0, 0
	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +0)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +0)], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0718:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0718
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0718
.L_lambda_simple_env_end_0718:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0718:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0718
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0718
.L_lambda_simple_params_end_0718:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0718
	jmp .L_lambda_simple_end_0718
.L_lambda_simple_code_0718:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07f7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07f7:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04d4
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_103]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_if_end_0556
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_103]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08ea:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08ea
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08ea
	.L_tc_recycle_frame_done_08ea:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	cmp rax, sob_boolean_false
	jne .L_if_end_0556
.L_if_end_0556:
	jmp .L_if_end_0557
.L_if_else_04d4:
	mov rax, L_constants + 2
.L_if_end_0557:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0718:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param loop
	pop qword [rax]
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04d5
	; preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08eb:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08eb
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08eb
	.L_tc_recycle_frame_done_08eb:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0558
.L_if_else_04d5:
	mov rax, L_constants + 2
.L_if_end_0558:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0717:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08e9:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08e9
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08e9
	.L_tc_recycle_frame_done_08e9:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_01bd:
	mov qword [free_var_110], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov r9, qword [rbp + 8 * 2]
	mov r9, qword [rbp + 8 * 3]
	mov rdi, 8 * 0	; new rib for optional parameters
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_00e0:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 0
	je .L_lambda_opt_env_end_00e0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00e0
.L_lambda_opt_env_end_00e0:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_029e:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_01bf
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_029e
.L_lambda_opt_params_end_01bf:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00e0
	jmp .L_lambda_opt_end_01bf
.L_lambda_opt_code_00e0:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_07f8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07f8:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_02a0
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_029f: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_029f
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_01c0
	.L_lambda_opt_params_loop_02a0:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_029f: ;loop for copying the opt into list
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov rbx, qword [rcx]
	mov SOB_PAIR_CAR(rax), rbx
	mov SOB_PAIR_CDR(rax), r9
	mov r9, rax
	dec rdx
	sub rcx, 8
	cmp rdx, 0
	jne .L_lambda_opt_params_loop_029f
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_02a0:
	cmp rdx, 0
	je .L_lambda_opt_params_end_01c0
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02a0
	.L_lambda_opt_params_end_01c0:
	add rsp,rcx
	mov rbx, 1
	mov rbx, qword [rsp + 8 * 2]
	add rbx,3
	sub rbx,r8
	shl rbx, 3
	add rbx, rsp
	mov qword[rbx] , r9
	dec r8
	sub qword [rsp + 8 * 2], r8
	.L_lambda_opt_end_01c0:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0719:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0719
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0719
.L_lambda_simple_env_end_0719:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0719:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0719
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0719
.L_lambda_simple_params_end_0719:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0719
	jmp .L_lambda_simple_end_0719
.L_lambda_simple_code_0719:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07f9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07f9:
	enter 0, 0
	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +0)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +0)], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_071a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_071a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_071a
.L_lambda_simple_env_end_071a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_071a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_071a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_071a
.L_lambda_simple_params_end_071a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_071a
	jmp .L_lambda_simple_end_071a
.L_lambda_simple_code_071a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07fa
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07fa:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_if_end_0559
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_103]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04d6
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_103]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08ed:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08ed
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08ed
	.L_tc_recycle_frame_done_08ed:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_055a
.L_if_else_04d6:
	mov rax, L_constants + 2
.L_if_end_055a:
	cmp rax, sob_boolean_false
	jne .L_if_end_0559
.L_if_end_0559:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_071a:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param loop
	pop qword [rax]
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_if_end_055b
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04d7
	; preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08ee:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08ee
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08ee
	.L_tc_recycle_frame_done_08ee:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_055c
.L_if_else_04d7:
	mov rax, L_constants + 2
.L_if_end_055c:
	cmp rax, sob_boolean_false
	jne .L_if_end_055b
.L_if_end_055b:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0719:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08ec:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08ec
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08ec
	.L_tc_recycle_frame_done_08ec:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_01bf:
	mov qword [free_var_31], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_071b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_071b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_071b
.L_lambda_simple_env_end_071b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_071b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_071b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_071b
.L_lambda_simple_params_end_071b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_071b
	jmp .L_lambda_simple_end_071b
.L_lambda_simple_code_071b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_07fb
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07fb:
	enter 0, 0
	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +0)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +0)], rax
	mov rax, sob_void

	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +1)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +1)], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_071c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_071c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_071c
.L_lambda_simple_env_end_071c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_071c:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_071c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_071c
.L_lambda_simple_params_end_071c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_071c
	jmp .L_lambda_simple_end_071c
.L_lambda_simple_code_071c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_07fc
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07fc:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04d8
	mov rax, L_constants + 1
	jmp .L_if_end_055d
.L_if_else_04d8:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var map1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param f
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_79]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08ef:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08ef
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08ef
	.L_tc_recycle_frame_done_08ef:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_055d:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_071c:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param map1
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_071d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_071d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_071d
.L_lambda_simple_env_end_071d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_071d:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_071d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_071d
.L_lambda_simple_params_end_071d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_071d
	jmp .L_lambda_simple_end_071d
.L_lambda_simple_code_071d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_07fd
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07fd:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04d9
	mov rax, L_constants + 1
	jmp .L_if_end_055e
.L_if_else_04d9:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var map1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var map-list
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var map1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_79]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08f0:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08f0
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08f0
	.L_tc_recycle_frame_done_08f0:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_055e:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_071d:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param map-list
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov r9, qword [rbp + 8 * 2]
	mov r9, qword [rbp + 8 * 3]
	mov rdi, 8 * 2	; new rib for optional parameters
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_00e1:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_00e1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00e1
.L_lambda_opt_env_end_00e1:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_02a1:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_01c1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_02a1
.L_lambda_opt_params_end_01c1:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00e1
	jmp .L_lambda_opt_end_01c1
.L_lambda_opt_code_00e1:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_07fe
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07fe:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_02a3
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_02a2: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02a2
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_01c2
	.L_lambda_opt_params_loop_02a3:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_02a2: ;loop for copying the opt into list
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov rbx, qword [rcx]
	mov SOB_PAIR_CAR(rax), rbx
	mov SOB_PAIR_CDR(rax), r9
	mov r9, rax
	dec rdx
	sub rcx, 8
	cmp rdx, 0
	jne .L_lambda_opt_params_loop_02a2
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_02a3:
	cmp rdx, 0
	je .L_lambda_opt_params_end_01c2
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02a3
	.L_lambda_opt_params_end_01c2:
	add rsp,rcx
	mov rbx, 1
	mov rbx, qword [rsp + 8 * 2]
	add rbx,3
	sub rbx,r8
	shl rbx, 3
	add rbx, rsp
	mov qword[rbx] , r9
	dec r8
	sub qword [rsp + 8 * 2], r8
	.L_lambda_opt_end_01c2:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04da
	mov rax, L_constants + 1
	jmp .L_if_end_055f
.L_if_else_04da:
	; preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var map-list
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08f1:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08f1
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08f1
	.L_tc_recycle_frame_done_08f1:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_055f:
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_01c1:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_071b:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_103], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_071e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_071e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_071e
.L_lambda_simple_env_end_071e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_071e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_071e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_071e
.L_lambda_simple_params_end_071e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_071e
	jmp .L_lambda_simple_end_071e
.L_lambda_simple_code_071e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_07ff
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_07ff:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, L_constants + 1
	push rax
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_071f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_071f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_071f
.L_lambda_simple_env_end_071f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_071f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_071f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_071f
.L_lambda_simple_params_end_071f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_071f
	jmp .L_lambda_simple_end_071f
.L_lambda_simple_code_071f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0800
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0800:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param r
	push rax
	mov rax, PARAM(1)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_79]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08f3:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08f3
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08f3
	.L_tc_recycle_frame_done_08f3:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_071f:	; new closure is in rax
	push rax
	push 3	; arg count
	mov rax, qword [free_var_85]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 6
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08f2:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08f2
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08f2
	.L_tc_recycle_frame_done_08f2:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_071e:	; new closure is in rax
	mov qword [free_var_118], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0720:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0720
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0720
.L_lambda_simple_env_end_0720:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0720:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0720
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0720
.L_lambda_simple_params_end_0720:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0720
	jmp .L_lambda_simple_end_0720
.L_lambda_simple_code_0720:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0801
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0801:
	enter 0, 0
	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +0)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +0)], rax
	mov rax, sob_void

	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +1)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +1)], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0721:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0721
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0721
.L_lambda_simple_env_end_0721:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0721:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0721
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0721
.L_lambda_simple_params_end_0721:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0721
	jmp .L_lambda_simple_end_0721
.L_lambda_simple_code_0721:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0802
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0802:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param sr
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04db
	mov rax, PARAM(0)	; param s1
	jmp .L_if_end_0560
.L_if_else_04db:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param sr
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param sr
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run-1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param s1
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var run-2
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08f4:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08f4
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08f4
	.L_tc_recycle_frame_done_08f4:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0560:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0721:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run-1
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0722:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0722
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0722
.L_lambda_simple_env_end_0722:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0722:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0722
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0722
.L_lambda_simple_params_end_0722:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0722
	jmp .L_lambda_simple_end_0722
.L_lambda_simple_code_0722:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0803
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0803:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04dc
	mov rax, PARAM(1)	; param s2
	jmp .L_if_end_0561
.L_if_else_04dc:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s2
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var run-2
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_79]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08f5:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08f5
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08f5
	.L_tc_recycle_frame_done_08f5:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0561:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0722:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param run-2
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov r9, qword [rbp + 8 * 2]
	mov r9, qword [rbp + 8 * 3]
	mov rdi, 8 * 2	; new rib for optional parameters
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_00e2:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_00e2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00e2
.L_lambda_opt_env_end_00e2:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_02a4:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_01c3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_02a4
.L_lambda_opt_params_end_01c3:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00e2
	jmp .L_lambda_opt_end_01c3
.L_lambda_opt_code_00e2:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	jge .L_lambda_simple_arity_check_ok_0804
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0804:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 0
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_02a6
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_02a5: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02a5
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_01c4
	.L_lambda_opt_params_loop_02a6:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_02a5: ;loop for copying the opt into list
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov rbx, qword [rcx]
	mov SOB_PAIR_CAR(rax), rbx
	mov SOB_PAIR_CDR(rax), r9
	mov r9, rax
	dec rdx
	sub rcx, 8
	cmp rdx, 0
	jne .L_lambda_opt_params_loop_02a5
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_02a6:
	cmp rdx, 0
	je .L_lambda_opt_params_end_01c4
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02a6
	.L_lambda_opt_params_end_01c4:
	add rsp,rcx
	mov rbx, 0
	mov rbx, qword [rsp + 8 * 2]
	add rbx,3
	sub rbx,r8
	shl rbx, 3
	add rbx, rsp
	mov qword[rbx] , r9
	dec r8
	sub qword [rsp + 8 * 2], r8
	.L_lambda_opt_end_01c4:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04dd
	mov rax, L_constants + 1
	jmp .L_if_end_0562
.L_if_else_04dd:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run-1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08f6:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08f6
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08f6
	.L_tc_recycle_frame_done_08f6:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0562:
	LEAVE
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_01c3:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0720:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_32], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0723:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0723
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0723
.L_lambda_simple_env_end_0723:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0723:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0723
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0723
.L_lambda_simple_params_end_0723:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0723
	jmp .L_lambda_simple_end_0723
.L_lambda_simple_code_0723:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0805
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0805:
	enter 0, 0
	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +0)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +0)], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0724:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0724
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0724
.L_lambda_simple_env_end_0724:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0724:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0724
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0724
.L_lambda_simple_params_end_0724:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0724
	jmp .L_lambda_simple_end_0724
.L_lambda_simple_code_0724:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0806
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0806:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_110]	; free var ormap
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04de
	mov rax, PARAM(1)	; param unit
	jmp .L_if_end_0563
.L_if_else_04de:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_103]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_103]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 6
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08f7:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08f7
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08f7
	.L_tc_recycle_frame_done_08f7:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0563:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0724:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov r9, qword [rbp + 8 * 2]
	mov r9, qword [rbp + 8 * 3]
	mov rdi, 8 * 1	; new rib for optional parameters
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_00e3:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_00e3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00e3
.L_lambda_opt_env_end_00e3:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_02a7:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_01c5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_02a7
.L_lambda_opt_params_end_01c5:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00e3
	jmp .L_lambda_opt_end_01c5
.L_lambda_opt_code_00e3:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 2
	jge .L_lambda_simple_arity_check_ok_0807
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0807:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 2
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_02a9
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_02a8: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02a8
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_01c6
	.L_lambda_opt_params_loop_02a9:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_02a8: ;loop for copying the opt into list
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov rbx, qword [rcx]
	mov SOB_PAIR_CAR(rax), rbx
	mov SOB_PAIR_CDR(rax), r9
	mov r9, rax
	dec rdx
	sub rcx, 8
	cmp rdx, 0
	jne .L_lambda_opt_params_loop_02a8
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_02a9:
	cmp rdx, 0
	je .L_lambda_opt_params_end_01c6
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02a9
	.L_lambda_opt_params_end_01c6:
	add rsp,rcx
	mov rbx, 2
	mov rbx, qword [rsp + 8 * 2]
	add rbx,3
	sub rbx,r8
	shl rbx, 3
	add rbx, rsp
	mov qword[rbx] , r9
	dec r8
	sub qword [rsp + 8 * 2], r8
	.L_lambda_opt_end_01c6:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 6
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08f8:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08f8
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08f8
	.L_tc_recycle_frame_done_08f8:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(3)
.L_lambda_opt_end_01c5:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0723:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_85], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0725:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0725
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0725
.L_lambda_simple_env_end_0725:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0725:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0725
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0725
.L_lambda_simple_params_end_0725:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0725
	jmp .L_lambda_simple_end_0725
.L_lambda_simple_code_0725:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0808
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0808:
	enter 0, 0
	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +0)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +0)], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0726:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0726
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0726
.L_lambda_simple_env_end_0726:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0726:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0726
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0726
.L_lambda_simple_params_end_0726:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0726
	jmp .L_lambda_simple_end_0726
.L_lambda_simple_code_0726:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0809
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0809:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_110]	; free var ormap
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04df
	mov rax, PARAM(1)	; param unit
	jmp .L_if_end_0564
.L_if_else_04df:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 1
	push rax
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_103]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_79]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_103]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_32]	; free var append
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08f9:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08f9
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08f9
	.L_tc_recycle_frame_done_08f9:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0564:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0726:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov r9, qword [rbp + 8 * 2]
	mov r9, qword [rbp + 8 * 3]
	mov rdi, 8 * 1	; new rib for optional parameters
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_00e4:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_00e4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00e4
.L_lambda_opt_env_end_00e4:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_02aa:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_01c7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_02aa
.L_lambda_opt_params_end_01c7:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00e4
	jmp .L_lambda_opt_end_01c7
.L_lambda_opt_code_00e4:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 2
	jge .L_lambda_simple_arity_check_ok_080a
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_080a:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 2
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_02ac
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_02ab: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02ab
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_01c8
	.L_lambda_opt_params_loop_02ac:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_02ab: ;loop for copying the opt into list
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov rbx, qword [rcx]
	mov SOB_PAIR_CAR(rax), rbx
	mov SOB_PAIR_CDR(rax), r9
	mov r9, rax
	dec rdx
	sub rcx, 8
	cmp rdx, 0
	jne .L_lambda_opt_params_loop_02ab
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_02ac:
	cmp rdx, 0
	je .L_lambda_opt_params_end_01c8
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02ac
	.L_lambda_opt_params_end_01c8:
	add rsp,rcx
	mov rbx, 2
	mov rbx, qword [rsp + 8 * 2]
	add rbx,3
	sub rbx,r8
	shl rbx, 3
	add rbx, rsp
	mov qword[rbx] , r9
	dec r8
	sub qword [rsp + 8 * 2], r8
	.L_lambda_opt_end_01c8:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 6
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08fa:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08fa
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08fa
	.L_tc_recycle_frame_done_08fa:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(3)
.L_lambda_opt_end_01c7:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0725:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_86], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0727:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0727
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0727
.L_lambda_simple_env_end_0727:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0727:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0727
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0727
.L_lambda_simple_params_end_0727:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0727
	jmp .L_lambda_simple_end_0727
.L_lambda_simple_code_0727:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_080b
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_080b:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2187
	push rax
	mov rax, L_constants + 2178
	push rax
	push 2	; arg count
	mov rax, qword [free_var_82]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08fb:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08fb
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08fb
	.L_tc_recycle_frame_done_08fb:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0727:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0728:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0728
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0728
.L_lambda_simple_env_end_0728:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0728:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0728
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0728
.L_lambda_simple_params_end_0728:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0728
	jmp .L_lambda_simple_end_0728
.L_lambda_simple_code_0728:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_080c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_080c:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0729:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0729
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0729
.L_lambda_simple_env_end_0729:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0729:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0729
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0729
.L_lambda_simple_params_end_0729:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0729
	jmp .L_lambda_simple_end_0729
.L_lambda_simple_code_0729:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_080d
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_080d:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04eb
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04e2
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_11]	; free var __bin-add-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08fd:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08fd
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08fd
	.L_tc_recycle_frame_done_08fd:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0567
.L_if_else_04e2:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04e1
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_9]	; free var __bin-add-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08fe:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08fe
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08fe
	.L_tc_recycle_frame_done_08fe:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0566
.L_if_else_04e1:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04e0
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_90]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08ff:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08ff
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08ff
	.L_tc_recycle_frame_done_08ff:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0565
.L_if_else_04e0:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 3
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0900:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0900
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0900
	.L_tc_recycle_frame_done_0900:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0565:
.L_if_end_0566:
.L_if_end_0567:
	jmp .L_if_end_0570
.L_if_else_04eb:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04ea
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04e5
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var __bin_integer_to_fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_9]	; free var __bin-add-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0901:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0901
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0901
	.L_tc_recycle_frame_done_0901:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_056a
.L_if_else_04e5:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04e4
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_9]	; free var __bin-add-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0902:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0902
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0902
	.L_tc_recycle_frame_done_0902:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0569
.L_if_else_04e4:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04e3
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_87]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0903:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0903
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0903
	.L_tc_recycle_frame_done_0903:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0568
.L_if_else_04e3:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 3
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0904:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0904
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0904
	.L_tc_recycle_frame_done_0904:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0568:
.L_if_end_0569:
.L_if_end_056a:
	jmp .L_if_end_056f
.L_if_else_04ea:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04e9
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04e8
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_90]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0905:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0905
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0905
	.L_tc_recycle_frame_done_0905:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_056d
.L_if_else_04e8:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04e7
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_87]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0906:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0906
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0906
	.L_tc_recycle_frame_done_0906:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_056c
.L_if_else_04e7:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04e6
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0907:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0907
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0907
	.L_tc_recycle_frame_done_0907:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_056b
.L_if_else_04e6:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 3
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0908:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0908
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0908
	.L_tc_recycle_frame_done_0908:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_056b:
.L_if_end_056c:
.L_if_end_056d:
	jmp .L_if_end_056e
.L_if_else_04e9:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 3
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0909:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0909
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0909
	.L_tc_recycle_frame_done_0909:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_056e:
.L_if_end_056f:
.L_if_end_0570:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0729:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_072a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_072a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_072a
.L_lambda_simple_env_end_072a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_072a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_072a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_072a
.L_lambda_simple_params_end_072a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_072a
	jmp .L_lambda_simple_end_072a
.L_lambda_simple_code_072a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_080e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_080e:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov r9, qword [rbp + 8 * 2]
	mov r9, qword [rbp + 8 * 3]
	mov rdi, 8 * 1	; new rib for optional parameters
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_00e5:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 2
	je .L_lambda_opt_env_end_00e5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00e5
.L_lambda_opt_env_end_00e5:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_02ad:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_01c9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_02ad
.L_lambda_opt_params_end_01c9:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00e5
	jmp .L_lambda_opt_end_01c9
.L_lambda_opt_code_00e5:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	jge .L_lambda_simple_arity_check_ok_080f
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_080f:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 0
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_02af
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_02ae: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02ae
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_01ca
	.L_lambda_opt_params_loop_02af:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_02ae: ;loop for copying the opt into list
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov rbx, qword [rcx]
	mov SOB_PAIR_CAR(rax), rbx
	mov SOB_PAIR_CDR(rax), r9
	mov r9, rax
	dec rdx
	sub rcx, 8
	cmp rdx, 0
	jne .L_lambda_opt_params_loop_02ae
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_02af:
	cmp rdx, 0
	je .L_lambda_opt_params_end_01ca
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02af
	.L_lambda_opt_params_end_01ca:
	add rsp,rcx
	mov rbx, 0
	mov rbx, qword [rsp + 8 * 2]
	add rbx,3
	sub rbx,r8
	shl rbx, 3
	add rbx, rsp
	mov qword[rbx] , r9
	dec r8
	sub qword [rsp + 8 * 2], r8
	.L_lambda_opt_end_01ca:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, L_constants + 2135
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin+
	push rax
	push 3	; arg count
	mov rax, qword [free_var_85]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 6
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_090a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_090a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_090a
	.L_tc_recycle_frame_done_090a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_01c9:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_072a:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_08fc:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_08fc
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_08fc
	.L_tc_recycle_frame_done_08fc:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0728:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_1], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_072b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_072b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_072b
.L_lambda_simple_env_end_072b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_072b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_072b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_072b
.L_lambda_simple_params_end_072b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_072b
	jmp .L_lambda_simple_end_072b
.L_lambda_simple_code_072b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0810
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0810:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2187
	push rax
	mov rax, L_constants + 2251
	push rax
	push 2	; arg count
	mov rax, qword [free_var_82]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_090b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_090b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_090b
	.L_tc_recycle_frame_done_090b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_072b:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_072c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_072c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_072c
.L_lambda_simple_env_end_072c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_072c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_072c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_072c
.L_lambda_simple_params_end_072c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_072c
	jmp .L_lambda_simple_end_072c
.L_lambda_simple_code_072c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0811
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0811:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_072d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_072d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_072d
.L_lambda_simple_env_end_072d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_072d:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_072d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_072d
.L_lambda_simple_params_end_072d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_072d
	jmp .L_lambda_simple_end_072d
.L_lambda_simple_code_072d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0812
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0812:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04f7
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04ee
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_27]	; free var __bin-sub-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_090d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_090d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_090d
	.L_tc_recycle_frame_done_090d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0573
.L_if_else_04ee:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04ed
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_25]	; free var __bin-sub-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_090e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_090e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_090e
	.L_tc_recycle_frame_done_090e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0572
.L_if_else_04ed:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_115]	; free var real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04ec
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_90]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_090f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_090f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_090f
	.L_tc_recycle_frame_done_090f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0571
.L_if_else_04ec:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 3
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0910:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0910
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0910
	.L_tc_recycle_frame_done_0910:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0571:
.L_if_end_0572:
.L_if_end_0573:
	jmp .L_if_end_057c
.L_if_else_04f7:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04f6
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04f1
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_25]	; free var __bin-sub-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0911:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0911
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0911
	.L_tc_recycle_frame_done_0911:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0576
.L_if_else_04f1:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04f0
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_25]	; free var __bin-sub-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0912:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0912
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0912
	.L_tc_recycle_frame_done_0912:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0575
.L_if_else_04f0:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04ef
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_87]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0913:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0913
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0913
	.L_tc_recycle_frame_done_0913:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0574
.L_if_else_04ef:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 3
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0914:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0914
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0914
	.L_tc_recycle_frame_done_0914:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0574:
.L_if_end_0575:
.L_if_end_0576:
	jmp .L_if_end_057b
.L_if_else_04f6:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04f5
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04f4
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_90]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0915:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0915
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0915
	.L_tc_recycle_frame_done_0915:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0579
.L_if_else_04f4:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04f3
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_87]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0916:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0916
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0916
	.L_tc_recycle_frame_done_0916:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0578
.L_if_else_04f3:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04f2
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0917:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0917
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0917
	.L_tc_recycle_frame_done_0917:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0577
.L_if_else_04f2:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 3
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0918:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0918
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0918
	.L_tc_recycle_frame_done_0918:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0577:
.L_if_end_0578:
.L_if_end_0579:
	jmp .L_if_end_057a
.L_if_else_04f5:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 3
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0919:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0919
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0919
	.L_tc_recycle_frame_done_0919:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_057a:
.L_if_end_057b:
.L_if_end_057c:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_072d:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_072e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_072e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_072e
.L_lambda_simple_env_end_072e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_072e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_072e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_072e
.L_lambda_simple_params_end_072e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_072e
	jmp .L_lambda_simple_end_072e
.L_lambda_simple_code_072e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0813
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0813:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov r9, qword [rbp + 8 * 2]
	mov r9, qword [rbp + 8 * 3]
	mov rdi, 8 * 1	; new rib for optional parameters
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_00e6:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 2
	je .L_lambda_opt_env_end_00e6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00e6
.L_lambda_opt_env_end_00e6:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_02b0:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_01cb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_02b0
.L_lambda_opt_params_end_01cb:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00e6
	jmp .L_lambda_opt_end_01cb
.L_lambda_opt_code_00e6:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_0814
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0814:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_02b2
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_02b1: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02b1
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_01cc
	.L_lambda_opt_params_loop_02b2:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_02b1: ;loop for copying the opt into list
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov rbx, qword [rcx]
	mov SOB_PAIR_CAR(rax), rbx
	mov SOB_PAIR_CDR(rax), r9
	mov r9, rax
	dec rdx
	sub rcx, 8
	cmp rdx, 0
	jne .L_lambda_opt_params_loop_02b1
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_02b2:
	cmp rdx, 0
	je .L_lambda_opt_params_end_01cc
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02b2
	.L_lambda_opt_params_end_01cc:
	add rsp,rcx
	mov rbx, 1
	mov rbx, qword [rsp + 8 * 2]
	add rbx,3
	sub rbx,r8
	shl rbx, 3
	add rbx, rsp
	mov qword[rbx] , r9
	dec r8
	sub qword [rsp + 8 * 2], r8
	.L_lambda_opt_end_01cc:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04f8
	; preparing a tail-call
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, L_constants + 2135
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin-
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_091a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_091a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_091a
	.L_tc_recycle_frame_done_091a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_057d
.L_if_else_04f8:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, L_constants + 2135
	push rax
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3	; arg count
	mov rax, qword [free_var_85]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_072f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_072f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_072f
.L_lambda_simple_env_end_072f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_072f:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_072f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_072f
.L_lambda_simple_params_end_072f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_072f
	jmp .L_lambda_simple_end_072f
.L_lambda_simple_code_072f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0815
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0815:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param b
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin-
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_091c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_091c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_091c
	.L_tc_recycle_frame_done_091c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_072f:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_091b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_091b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_091b
	.L_tc_recycle_frame_done_091b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_057d:
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_01cb:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_072e:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_090c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_090c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_090c
	.L_tc_recycle_frame_done_090c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_072c:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_2], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0730:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0730
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0730
.L_lambda_simple_env_end_0730:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0730:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0730
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0730
.L_lambda_simple_params_end_0730:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0730
	jmp .L_lambda_simple_end_0730
.L_lambda_simple_code_0730:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0816
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0816:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2187
	push rax
	mov rax, L_constants + 2279
	push rax
	push 2	; arg count
	mov rax, qword [free_var_82]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_091d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_091d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_091d
	.L_tc_recycle_frame_done_091d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0730:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0731:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0731
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0731
.L_lambda_simple_env_end_0731:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0731:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0731
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0731
.L_lambda_simple_params_end_0731:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0731
	jmp .L_lambda_simple_end_0731
.L_lambda_simple_code_0731:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0817
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0817:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0732:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0732
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0732
.L_lambda_simple_env_end_0732:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0732:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0732
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0732
.L_lambda_simple_params_end_0732:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0732
	jmp .L_lambda_simple_end_0732
.L_lambda_simple_code_0732:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0818
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0818:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0504
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04fb
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_24]	; free var __bin-mul-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_091f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_091f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_091f
	.L_tc_recycle_frame_done_091f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0580
.L_if_else_04fb:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04fa
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_22]	; free var __bin-mul-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0920:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0920
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0920
	.L_tc_recycle_frame_done_0920:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_057f
.L_if_else_04fa:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04f9
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_90]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0921:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0921
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0921
	.L_tc_recycle_frame_done_0921:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_057e
.L_if_else_04f9:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 3
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0922:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0922
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0922
	.L_tc_recycle_frame_done_0922:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_057e:
.L_if_end_057f:
.L_if_end_0580:
	jmp .L_if_end_0589
.L_if_else_0504:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0503
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04fe
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_22]	; free var __bin-mul-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0923:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0923
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0923
	.L_tc_recycle_frame_done_0923:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0583
.L_if_else_04fe:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04fd
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_22]	; free var __bin-mul-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0924:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0924
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0924
	.L_tc_recycle_frame_done_0924:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0582
.L_if_else_04fd:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04fc
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_87]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0925:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0925
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0925
	.L_tc_recycle_frame_done_0925:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0581
.L_if_else_04fc:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 3
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0926:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0926
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0926
	.L_tc_recycle_frame_done_0926:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0581:
.L_if_end_0582:
.L_if_end_0583:
	jmp .L_if_end_0588
.L_if_else_0503:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0502
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0501
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_90]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0927:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0927
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0927
	.L_tc_recycle_frame_done_0927:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0586
.L_if_else_0501:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0500
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_87]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0928:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0928
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0928
	.L_tc_recycle_frame_done_0928:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0585
.L_if_else_0500:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_04ff
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0929:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0929
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0929
	.L_tc_recycle_frame_done_0929:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0584
.L_if_else_04ff:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 3
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_092a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_092a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_092a
	.L_tc_recycle_frame_done_092a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0584:
.L_if_end_0585:
.L_if_end_0586:
	jmp .L_if_end_0587
.L_if_else_0502:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 3
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_092b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_092b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_092b
	.L_tc_recycle_frame_done_092b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0587:
.L_if_end_0588:
.L_if_end_0589:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0732:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0733:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0733
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0733
.L_lambda_simple_env_end_0733:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0733:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0733
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0733
.L_lambda_simple_params_end_0733:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0733
	jmp .L_lambda_simple_end_0733
.L_lambda_simple_code_0733:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0819
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0819:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov r9, qword [rbp + 8 * 2]
	mov r9, qword [rbp + 8 * 3]
	mov rdi, 8 * 1	; new rib for optional parameters
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_00e7:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 2
	je .L_lambda_opt_env_end_00e7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00e7
.L_lambda_opt_env_end_00e7:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_02b3:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_01cd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_02b3
.L_lambda_opt_params_end_01cd:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00e7
	jmp .L_lambda_opt_end_01cd
.L_lambda_opt_code_00e7:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	jge .L_lambda_simple_arity_check_ok_081a
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_081a:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 0
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_02b5
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_02b4: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02b4
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_01ce
	.L_lambda_opt_params_loop_02b5:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_02b4: ;loop for copying the opt into list
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov rbx, qword [rcx]
	mov SOB_PAIR_CAR(rax), rbx
	mov SOB_PAIR_CDR(rax), r9
	mov r9, rax
	dec rdx
	sub rcx, 8
	cmp rdx, 0
	jne .L_lambda_opt_params_loop_02b4
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_02b5:
	cmp rdx, 0
	je .L_lambda_opt_params_end_01ce
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02b5
	.L_lambda_opt_params_end_01ce:
	add rsp,rcx
	mov rbx, 0
	mov rbx, qword [rsp + 8 * 2]
	add rbx,3
	sub rbx,r8
	shl rbx, 3
	add rbx, rsp
	mov qword[rbx] , r9
	dec r8
	sub qword [rsp + 8 * 2], r8
	.L_lambda_opt_end_01ce:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, L_constants + 2270
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin*
	push rax
	push 3	; arg count
	mov rax, qword [free_var_85]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 6
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_092c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_092c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_092c
	.L_tc_recycle_frame_done_092c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_01cd:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0733:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_091e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_091e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_091e
	.L_tc_recycle_frame_done_091e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0731:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_0], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0734:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0734
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0734
.L_lambda_simple_env_end_0734:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0734:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0734
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0734
.L_lambda_simple_params_end_0734:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0734
	jmp .L_lambda_simple_end_0734
.L_lambda_simple_code_0734:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_081b
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_081b:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2187
	push rax
	mov rax, L_constants + 2298
	push rax
	push 2	; arg count
	mov rax, qword [free_var_82]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_092d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_092d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_092d
	.L_tc_recycle_frame_done_092d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0734:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0735:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0735
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0735
.L_lambda_simple_env_end_0735:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0735:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0735
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0735
.L_lambda_simple_params_end_0735:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0735
	jmp .L_lambda_simple_end_0735
.L_lambda_simple_code_0735:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_081c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_081c:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0736:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0736
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0736
.L_lambda_simple_env_end_0736:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0736:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0736
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0736
.L_lambda_simple_params_end_0736:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0736
	jmp .L_lambda_simple_end_0736
.L_lambda_simple_code_0736:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_081d
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_081d:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0510
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0507
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_15]	; free var __bin-div-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_092f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_092f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_092f
	.L_tc_recycle_frame_done_092f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_058c
.L_if_else_0507:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0506
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var __bin-div-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0930:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0930
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0930
	.L_tc_recycle_frame_done_0930:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_058b
.L_if_else_0506:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0505
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_90]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0931:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0931
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0931
	.L_tc_recycle_frame_done_0931:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_058a
.L_if_else_0505:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 3
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0932:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0932
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0932
	.L_tc_recycle_frame_done_0932:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_058a:
.L_if_end_058b:
.L_if_end_058c:
	jmp .L_if_end_0595
.L_if_else_0510:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_050f
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_050a
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var __bin-div-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0933:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0933
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0933
	.L_tc_recycle_frame_done_0933:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_058f
.L_if_else_050a:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0509
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var __bin-div-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0934:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0934
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0934
	.L_tc_recycle_frame_done_0934:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_058e
.L_if_else_0509:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0508
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_87]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0935:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0935
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0935
	.L_tc_recycle_frame_done_0935:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_058d
.L_if_else_0508:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 3
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0936:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0936
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0936
	.L_tc_recycle_frame_done_0936:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_058d:
.L_if_end_058e:
.L_if_end_058f:
	jmp .L_if_end_0594
.L_if_else_050f:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_050e
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_050d
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_90]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0937:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0937
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0937
	.L_tc_recycle_frame_done_0937:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0592
.L_if_else_050d:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_050c
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_87]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0938:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0938
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0938
	.L_tc_recycle_frame_done_0938:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0591
.L_if_else_050c:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_050b
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0939:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0939
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0939
	.L_tc_recycle_frame_done_0939:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0590
.L_if_else_050b:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 3
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_093a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_093a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_093a
	.L_tc_recycle_frame_done_093a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0590:
.L_if_end_0591:
.L_if_end_0592:
	jmp .L_if_end_0593
.L_if_else_050e:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 3
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_093b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_093b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_093b
	.L_tc_recycle_frame_done_093b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0593:
.L_if_end_0594:
.L_if_end_0595:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0736:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0737:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0737
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0737
.L_lambda_simple_env_end_0737:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0737:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0737
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0737
.L_lambda_simple_params_end_0737:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0737
	jmp .L_lambda_simple_end_0737
.L_lambda_simple_code_0737:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_081e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_081e:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov r9, qword [rbp + 8 * 2]
	mov r9, qword [rbp + 8 * 3]
	mov rdi, 8 * 1	; new rib for optional parameters
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_00e8:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 2
	je .L_lambda_opt_env_end_00e8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00e8
.L_lambda_opt_env_end_00e8:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_02b6:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_01cf
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_02b6
.L_lambda_opt_params_end_01cf:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00e8
	jmp .L_lambda_opt_end_01cf
.L_lambda_opt_code_00e8:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_081f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_081f:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_02b8
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_02b7: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02b7
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_01d0
	.L_lambda_opt_params_loop_02b8:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_02b7: ;loop for copying the opt into list
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov rbx, qword [rcx]
	mov SOB_PAIR_CAR(rax), rbx
	mov SOB_PAIR_CDR(rax), r9
	mov r9, rax
	dec rdx
	sub rcx, 8
	cmp rdx, 0
	jne .L_lambda_opt_params_loop_02b7
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_02b8:
	cmp rdx, 0
	je .L_lambda_opt_params_end_01d0
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02b8
	.L_lambda_opt_params_end_01d0:
	add rsp,rcx
	mov rbx, 1
	mov rbx, qword [rsp + 8 * 2]
	add rbx,3
	sub rbx,r8
	shl rbx, 3
	add rbx, rsp
	mov qword[rbx] , r9
	dec r8
	sub qword [rsp + 8 * 2], r8
	.L_lambda_opt_end_01d0:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0511
	; preparing a tail-call
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, L_constants + 2270
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin/
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_093c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_093c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_093c
	.L_tc_recycle_frame_done_093c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0596
.L_if_else_0511:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, L_constants + 2270
	push rax
	mov rax, qword [free_var_0]	; free var *
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3	; arg count
	mov rax, qword [free_var_85]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0738:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0738
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0738
.L_lambda_simple_env_end_0738:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0738:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0738
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0738
.L_lambda_simple_params_end_0738:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0738
	jmp .L_lambda_simple_end_0738
.L_lambda_simple_code_0738:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0820
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0820:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param b
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin/
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_093e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_093e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_093e
	.L_tc_recycle_frame_done_093e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0738:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_093d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_093d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_093d
	.L_tc_recycle_frame_done_093d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0596:
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_01cf:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0737:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_092e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_092e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_092e
	.L_tc_recycle_frame_done_092e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0735:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_3], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0739:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0739
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0739
.L_lambda_simple_env_end_0739:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0739:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0739
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0739
.L_lambda_simple_params_end_0739:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0739
	jmp .L_lambda_simple_end_0739
.L_lambda_simple_code_0739:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0821
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0821:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_152]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0512
	mov rax, L_constants + 2270
	jmp .L_if_end_0597
.L_if_else_0512:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_84]	; free var fact
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_0]	; free var *
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_093f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_093f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_093f
	.L_tc_recycle_frame_done_093f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0597:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0739:	; new closure is in rax
	mov qword [free_var_84], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_4], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_5], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_7], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_8], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_6], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_073a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_073a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_073a
.L_lambda_simple_env_end_073a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_073a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_073a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_073a
.L_lambda_simple_params_end_073a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_073a
	jmp .L_lambda_simple_end_073a
.L_lambda_simple_code_073a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0822
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0822:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2408
	push rax
	mov rax, L_constants + 2399
	push rax
	push 2	; arg count
	mov rax, qword [free_var_82]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0940:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0940
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0940
	.L_tc_recycle_frame_done_0940:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_073a:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_073b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_073b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_073b
.L_lambda_simple_env_end_073b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_073b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_073b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_073b
.L_lambda_simple_params_end_073b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_073b
	jmp .L_lambda_simple_end_073b
.L_lambda_simple_code_073b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0823
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0823:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_073c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_073c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_073c
.L_lambda_simple_env_end_073c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_073c:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_073c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_073c
.L_lambda_simple_params_end_073c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_073c
	jmp .L_lambda_simple_end_073c
.L_lambda_simple_code_073c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0824
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0824:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_073d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_073d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_073d
.L_lambda_simple_env_end_073d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_073d:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_073d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_073d
.L_lambda_simple_params_end_073d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_073d
	jmp .L_lambda_simple_end_073d
.L_lambda_simple_code_073d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0825
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0825:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_051e
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0515
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var comparator-zz
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0942:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0942
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0942
	.L_tc_recycle_frame_done_0942:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_059a
.L_if_else_0515:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0514
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var comparator-qq
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0943:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0943
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0943
	.L_tc_recycle_frame_done_0943:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0599
.L_if_else_0514:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0513
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_90]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0944:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0944
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0944
	.L_tc_recycle_frame_done_0944:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0598
.L_if_else_0513:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var exit
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 3
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0945:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0945
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0945
	.L_tc_recycle_frame_done_0945:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0598:
.L_if_end_0599:
.L_if_end_059a:
	jmp .L_if_end_05a3
.L_if_else_051e:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_051d
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0518
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var comparator-qq
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0946:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0946
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0946
	.L_tc_recycle_frame_done_0946:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_059d
.L_if_else_0518:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0517
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var comparator-qq
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0947:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0947
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0947
	.L_tc_recycle_frame_done_0947:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_059c
.L_if_else_0517:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0516
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_87]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0948:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0948
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0948
	.L_tc_recycle_frame_done_0948:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_059b
.L_if_else_0516:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var exit
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 3
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0949:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0949
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0949
	.L_tc_recycle_frame_done_0949:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_059b:
.L_if_end_059c:
.L_if_end_059d:
	jmp .L_if_end_05a2
.L_if_else_051d:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_051c
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_051b
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_90]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_094a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_094a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_094a
	.L_tc_recycle_frame_done_094a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05a0
.L_if_else_051b:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_051a
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_87]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_094b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_094b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_094b
	.L_tc_recycle_frame_done_094b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_059f
.L_if_else_051a:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0519
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_094c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_094c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_094c
	.L_tc_recycle_frame_done_094c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_059e
.L_if_else_0519:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var exit
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 3
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_094d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_094d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_094d
	.L_tc_recycle_frame_done_094d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_059e:
.L_if_end_059f:
.L_if_end_05a0:
	jmp .L_if_end_05a1
.L_if_else_051c:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var exit
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 3
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_094e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_094e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_094e
	.L_tc_recycle_frame_done_094e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_05a1:
.L_if_end_05a2:
.L_if_end_05a3:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_073d:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_073c:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_073e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_073e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_073e
.L_lambda_simple_env_end_073e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_073e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_073e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_073e
.L_lambda_simple_params_end_073e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_073e
	jmp .L_lambda_simple_end_073e
.L_lambda_simple_code_073e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0826
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0826:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, qword [free_var_20]	; free var __bin-less-than-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_19]	; free var __bin-less-than-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_21]	; free var __bin-less-than-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3	; arg count
	mov rax, PARAM(0)	; param make-bin-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_073f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_073f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_073f
.L_lambda_simple_env_end_073f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_073f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_073f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_073f
.L_lambda_simple_params_end_073f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_073f
	jmp .L_lambda_simple_end_073f
.L_lambda_simple_code_073f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0827
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0827:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, qword [free_var_17]	; free var __bin-equal-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_16]	; free var __bin-equal-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_18]	; free var __bin-equal-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var make-bin-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0740:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0740
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0740
.L_lambda_simple_env_end_0740:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0740:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0740
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0740
.L_lambda_simple_params_end_0740:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0740
	jmp .L_lambda_simple_end_0740
.L_lambda_simple_code_0740:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0828
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0828:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0741:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_0741
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0741
.L_lambda_simple_env_end_0741:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0741:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0741
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0741
.L_lambda_simple_params_end_0741:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0741
	jmp .L_lambda_simple_end_0741
.L_lambda_simple_code_0741:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0829
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0829:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_106]	; free var not
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0952:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0952
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0952
	.L_tc_recycle_frame_done_0952:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0741:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0742:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_0742
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0742
.L_lambda_simple_env_end_0742:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0742:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0742
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0742
.L_lambda_simple_params_end_0742:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0742
	jmp .L_lambda_simple_end_0742
.L_lambda_simple_code_0742:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_082a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_082a:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 6	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0743:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_0743
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0743
.L_lambda_simple_env_end_0743:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0743:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0743
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0743
.L_lambda_simple_params_end_0743:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0743
	jmp .L_lambda_simple_end_0743
.L_lambda_simple_code_0743:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_082b
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_082b:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var bin<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0954:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0954
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0954
	.L_tc_recycle_frame_done_0954:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0743:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 6	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0744:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_0744
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0744
.L_lambda_simple_env_end_0744:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0744:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0744
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0744
.L_lambda_simple_params_end_0744:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0744
	jmp .L_lambda_simple_end_0744
.L_lambda_simple_code_0744:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_082c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_082c:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 7	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0745:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_0745
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0745
.L_lambda_simple_env_end_0745:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0745:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0745
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0745
.L_lambda_simple_params_end_0745:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0745
	jmp .L_lambda_simple_end_0745
.L_lambda_simple_code_0745:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_082d
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_082d:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin>?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_106]	; free var not
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0956:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0956
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0956
	.L_tc_recycle_frame_done_0956:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0745:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 7	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0746:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_0746
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0746
.L_lambda_simple_env_end_0746:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0746:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0746
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0746
.L_lambda_simple_params_end_0746:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0746
	jmp .L_lambda_simple_end_0746
.L_lambda_simple_code_0746:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_082e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_082e:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 8	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0747:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_0747
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0747
.L_lambda_simple_env_end_0747:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0747:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0747
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0747
.L_lambda_simple_params_end_0747:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0747
	jmp .L_lambda_simple_end_0747
.L_lambda_simple_code_0747:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_082f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_082f:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 9	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0748:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 8
	je .L_lambda_simple_env_end_0748
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0748
.L_lambda_simple_env_end_0748:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0748:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0748
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0748
.L_lambda_simple_params_end_0748:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0748
	jmp .L_lambda_simple_end_0748
.L_lambda_simple_code_0748:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0830
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0830:
	enter 0, 0
	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +0)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +0)], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 10	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0749:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 9
	je .L_lambda_simple_env_end_0749
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0749
.L_lambda_simple_env_end_0749:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0749:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0749
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0749
.L_lambda_simple_params_end_0749:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0749
	jmp .L_lambda_simple_end_0749
.L_lambda_simple_code_0749:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0831
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0831:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_if_end_05a4
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin-ordering
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_051f
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0959:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0959
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0959
	.L_tc_recycle_frame_done_0959:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05a5
.L_if_else_051f:
	mov rax, L_constants + 2
.L_if_end_05a5:
	cmp rax, sob_boolean_false
	jne .L_if_end_05a4
.L_if_end_05a4:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0749:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov r9, qword [rbp + 8 * 2]
	mov r9, qword [rbp + 8 * 3]
	mov rdi, 8 * 1	; new rib for optional parameters
	call malloc
	push rax
	mov rdi, 8 * 10	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_00e9:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 9
	je .L_lambda_opt_env_end_00e9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00e9
.L_lambda_opt_env_end_00e9:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_02b9:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_01d1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_02b9
.L_lambda_opt_params_end_01d1:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00e9
	jmp .L_lambda_opt_end_01d1
.L_lambda_opt_code_00e9:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_0832
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0832:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_02bb
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_02ba: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02ba
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_01d2
	.L_lambda_opt_params_loop_02bb:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_02ba: ;loop for copying the opt into list
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov rbx, qword [rcx]
	mov SOB_PAIR_CAR(rax), rbx
	mov SOB_PAIR_CDR(rax), r9
	mov r9, rax
	dec rdx
	sub rcx, 8
	cmp rdx, 0
	jne .L_lambda_opt_params_loop_02ba
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_02bb:
	cmp rdx, 0
	je .L_lambda_opt_params_end_01d2
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02bb
	.L_lambda_opt_params_end_01d2:
	add rsp,rcx
	mov rbx, 1
	mov rbx, qword [rsp + 8 * 2]
	add rbx,3
	sub rbx,r8
	shl rbx, 3
	add rbx, rsp
	mov qword[rbx] , r9
	dec r8
	sub qword [rsp + 8 * 2], r8
	.L_lambda_opt_end_01d2:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_095a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_095a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_095a
	.L_tc_recycle_frame_done_095a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_01d1:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0748:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0958:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0958
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0958
	.L_tc_recycle_frame_done_0958:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0747:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 8	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_074a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_074a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_074a
.L_lambda_simple_env_end_074a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_074a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_074a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_074a
.L_lambda_simple_params_end_074a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_074a
	jmp .L_lambda_simple_end_074a
.L_lambda_simple_code_074a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0833
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0833:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 4]
	mov rax, qword [rax + 8 * 0]	; bound var bin<?
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_4], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin<=?
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_5], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin>?
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_7], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var bin>=?
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_8], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 3]
	mov rax, qword [rax + 8 * 0]	; bound var bin=?
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_6], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_074a:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0957:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0957
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0957
	.L_tc_recycle_frame_done_0957:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0746:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0955:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0955
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0955
	.L_tc_recycle_frame_done_0955:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0744:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0953:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0953
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0953
	.L_tc_recycle_frame_done_0953:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0742:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0951:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0951
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0951
	.L_tc_recycle_frame_done_0951:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0740:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0950:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0950
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0950
	.L_tc_recycle_frame_done_0950:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_073f:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_094f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_094f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_094f
	.L_tc_recycle_frame_done_094f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_073e:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0941:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0941
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0941
	.L_tc_recycle_frame_done_0941:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_073b:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_74], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_73], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_75], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_77], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_76], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_074b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_074b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_074b
.L_lambda_simple_env_end_074b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_074b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_074b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_074b
.L_lambda_simple_params_end_074b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_074b
	jmp .L_lambda_simple_end_074b
.L_lambda_simple_code_074b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0834
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0834:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov r9, qword [rbp + 8 * 2]
	mov r9, qword [rbp + 8 * 3]
	mov rdi, 8 * 1	; new rib for optional parameters
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_00ea:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_00ea
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00ea
.L_lambda_opt_env_end_00ea:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_02bc:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_01d3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_02bc
.L_lambda_opt_params_end_01d3:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00ea
	jmp .L_lambda_opt_end_01d3
.L_lambda_opt_code_00ea:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	jge .L_lambda_simple_arity_check_ok_0835
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0835:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 0
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_02be
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_02bd: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02bd
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_01d4
	.L_lambda_opt_params_loop_02be:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_02bd: ;loop for copying the opt into list
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov rbx, qword [rcx]
	mov SOB_PAIR_CAR(rax), rbx
	mov SOB_PAIR_CDR(rax), r9
	mov r9, rax
	dec rdx
	sub rcx, 8
	cmp rdx, 0
	jne .L_lambda_opt_params_loop_02bd
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_02be:
	cmp rdx, 0
	je .L_lambda_opt_params_end_01d4
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02be
	.L_lambda_opt_params_end_01d4:
	add rsp,rcx
	mov rbx, 0
	mov rbx, qword [rsp + 8 * 2]
	add rbx,3
	sub rbx,r8
	shl rbx, 3
	add rbx, rsp
	mov qword[rbx] , r9
	dec r8
	sub qword [rsp + 8 * 2], r8
	.L_lambda_opt_end_01d4:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_65]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_103]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var comparator
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_095b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_095b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_095b
	.L_tc_recycle_frame_done_095b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_01d3:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_074b:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_074c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_074c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_074c
.L_lambda_simple_env_end_074c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_074c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_074c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_074c
.L_lambda_simple_params_end_074c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_074c
	jmp .L_lambda_simple_end_074c
.L_lambda_simple_code_074c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0836
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0836:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_74], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_5]	; free var <=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_73], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_75], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_7]	; free var >
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_77], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_8]	; free var >=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_76], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_074c:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_71], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_72], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2569
	push rax
	push 1	; arg count
	mov rax, qword [free_var_65]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2573
	push rax
	push 1	; arg count
	mov rax, qword [free_var_65]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_074d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_074d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_074d
.L_lambda_simple_env_end_074d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_074d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_074d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_074d
.L_lambda_simple_params_end_074d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_074d
	jmp .L_lambda_simple_end_074d
.L_lambda_simple_code_074d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0837
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0837:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_074e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_074e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_074e
.L_lambda_simple_env_end_074e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_074e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_074e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_074e
.L_lambda_simple_params_end_074e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_074e
	jmp .L_lambda_simple_end_074e
.L_lambda_simple_code_074e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0838
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0838:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, L_constants + 2571
	push rax
	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, L_constants + 2569
	push rax
	push 3	; arg count
	mov rax, qword [free_var_73]	; free var char<=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0520
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var delta
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	push 1	; arg count
	mov rax, qword [free_var_65]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_89]	; free var integer->char
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_095c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_095c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_095c
	.L_tc_recycle_frame_done_095c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05a6
.L_if_else_0520:
	mov rax, PARAM(0)	; param ch
.L_if_end_05a6:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_074e:	; new closure is in rax
	mov qword [free_var_71], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_074f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_074f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_074f
.L_lambda_simple_env_end_074f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_074f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_074f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_074f
.L_lambda_simple_params_end_074f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_074f
	jmp .L_lambda_simple_end_074f
.L_lambda_simple_code_074f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0839
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0839:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, L_constants + 2575
	push rax
	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, L_constants + 2573
	push rax
	push 3	; arg count
	mov rax, qword [free_var_73]	; free var char<=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0521
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var delta
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	push 1	; arg count
	mov rax, qword [free_var_65]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_89]	; free var integer->char
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_095d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_095d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_095d
	.L_tc_recycle_frame_done_095d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05a7
.L_if_else_0521:
	mov rax, PARAM(0)	; param ch
.L_if_end_05a7:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_074f:	; new closure is in rax
	mov qword [free_var_72], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_074d:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_67], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_66], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_68], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_70], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_69], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0750:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0750
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0750
.L_lambda_simple_env_end_0750:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0750:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0750
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0750
.L_lambda_simple_params_end_0750:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0750
	jmp .L_lambda_simple_end_0750
.L_lambda_simple_code_0750:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_083a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_083a:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov r9, qword [rbp + 8 * 2]
	mov r9, qword [rbp + 8 * 3]
	mov rdi, 8 * 1	; new rib for optional parameters
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_00eb:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_00eb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00eb
.L_lambda_opt_env_end_00eb:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_02bf:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_01d5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_02bf
.L_lambda_opt_params_end_01d5:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00eb
	jmp .L_lambda_opt_end_01d5
.L_lambda_opt_code_00eb:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	jge .L_lambda_simple_arity_check_ok_083b
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_083b:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 0
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_02c1
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_02c0: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02c0
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_01d6
	.L_lambda_opt_params_loop_02c1:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_02c0: ;loop for copying the opt into list
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov rbx, qword [rcx]
	mov SOB_PAIR_CAR(rax), rbx
	mov SOB_PAIR_CDR(rax), r9
	mov r9, rax
	dec rdx
	sub rcx, 8
	cmp rdx, 0
	jne .L_lambda_opt_params_loop_02c0
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_02c1:
	cmp rdx, 0
	je .L_lambda_opt_params_end_01d6
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02c1
	.L_lambda_opt_params_end_01d6:
	add rsp,rcx
	mov rbx, 0
	mov rbx, qword [rsp + 8 * 2]
	add rbx,3
	sub rbx,r8
	shl rbx, 3
	add rbx, rsp
	mov qword[rbx] , r9
	dec r8
	sub qword [rsp + 8 * 2], r8
	.L_lambda_opt_end_01d6:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0751:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0751
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0751
.L_lambda_simple_env_end_0751:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0751:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0751
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0751
.L_lambda_simple_params_end_0751:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0751
	jmp .L_lambda_simple_end_0751
.L_lambda_simple_code_0751:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_083c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_083c:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	push 1	; arg count
	mov rax, qword [free_var_71]	; free var char-downcase
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_65]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_095f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_095f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_095f
	.L_tc_recycle_frame_done_095f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0751:	; new closure is in rax
	push rax
	push 2	; arg count
	mov rax, qword [free_var_103]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var comparator
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_095e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_095e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_095e
	.L_tc_recycle_frame_done_095e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_01d5:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0750:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0752:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0752
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0752
.L_lambda_simple_env_end_0752:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0752:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0752
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0752
.L_lambda_simple_params_end_0752:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0752
	jmp .L_lambda_simple_end_0752
.L_lambda_simple_code_0752:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_083d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_083d:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-ci-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_67], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_5]	; free var <=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-ci-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_66], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-ci-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_68], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_7]	; free var >
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-ci-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_70], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_8]	; free var >=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-ci-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_69], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0752:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_126], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_132], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0753:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0753
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0753
.L_lambda_simple_env_end_0753:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0753:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0753
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0753
.L_lambda_simple_params_end_0753:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0753
	jmp .L_lambda_simple_end_0753
.L_lambda_simple_code_0753:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_083e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_083e:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0754:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0754
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0754
.L_lambda_simple_env_end_0754:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0754:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0754
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0754
.L_lambda_simple_params_end_0754:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0754
	jmp .L_lambda_simple_end_0754
.L_lambda_simple_code_0754:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_083f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_083f:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str
	push rax
	push 1	; arg count
	mov rax, qword [free_var_119]	; free var string->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var char-case-converter
	push rax
	push 2	; arg count
	mov rax, qword [free_var_103]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_94]	; free var list->string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0960:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0960
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0960
	.L_tc_recycle_frame_done_0960:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0754:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0753:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0755:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0755
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0755
.L_lambda_simple_env_end_0755:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0755:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0755
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0755
.L_lambda_simple_params_end_0755:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0755
	jmp .L_lambda_simple_end_0755
.L_lambda_simple_code_0755:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0840
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0840:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, qword [free_var_71]	; free var char-downcase
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-string-case-converter
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_126], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_72]	; free var char-upcase
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-string-case-converter
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_132], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0755:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_134], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_133], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_135], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_136], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_137], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_122], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_121], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_123], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_124], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_125], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0756:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0756
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0756
.L_lambda_simple_env_end_0756:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0756:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0756
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0756
.L_lambda_simple_params_end_0756:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0756
	jmp .L_lambda_simple_end_0756
.L_lambda_simple_code_0756:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0841
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0841:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0757:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0757
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0757
.L_lambda_simple_env_end_0757:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0757:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0757
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0757
.L_lambda_simple_params_end_0757:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0757
	jmp .L_lambda_simple_end_0757
.L_lambda_simple_code_0757:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0842
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0842:
	enter 0, 0
	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +0)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +0)], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0758:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0758
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0758
.L_lambda_simple_env_end_0758:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0758:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0758
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0758
.L_lambda_simple_params_end_0758:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0758
	jmp .L_lambda_simple_end_0758
.L_lambda_simple_code_0758:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_0843
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0843:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0522
	; preparing a non-tail-call
	mov rax, PARAM(4)	; param len2
	push rax
	mov rax, PARAM(2)	; param len1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_05a9
.L_if_else_0522:
	mov rax, L_constants + 2
.L_if_end_05a9:
	cmp rax, sob_boolean_false
	jne .L_if_end_05a8
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0524
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	push 2	; arg count
	mov rax, qword [free_var_128]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_128]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var char<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_if_end_05aa
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	push 2	; arg count
	mov rax, qword [free_var_128]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_128]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 1]	; bound var char=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0523
	; preparing a tail-call
	mov rax, PARAM(4)	; param len2
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 8
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0962:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0962
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0962
	.L_tc_recycle_frame_done_0962:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05ab
.L_if_else_0523:
	mov rax, L_constants + 2
.L_if_end_05ab:
	cmp rax, sob_boolean_false
	jne .L_if_end_05aa
.L_if_end_05aa:
	jmp .L_if_end_05ac
.L_if_else_0524:
	mov rax, L_constants + 2
.L_if_end_05ac:
	cmp rax, sob_boolean_false
	jne .L_if_end_05a8
.L_if_end_05a8:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_0758:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0759:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0759
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0759
.L_lambda_simple_env_end_0759:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0759:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0759
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0759
.L_lambda_simple_params_end_0759:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0759
	jmp .L_lambda_simple_end_0759
.L_lambda_simple_code_0759:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0844
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0844:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param str2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_127]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_127]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_075a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_075a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_075a
.L_lambda_simple_env_end_075a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_075a:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_075a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_075a
.L_lambda_simple_params_end_075a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_075a
	jmp .L_lambda_simple_end_075a
.L_lambda_simple_code_075a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0845
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0845:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, PARAM(0)	; param len1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_5]	; free var <=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0525
	; preparing a tail-call
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var str2
	push rax
	mov rax, PARAM(0)	; param len1
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str1
	push rax
	mov rax, L_constants + 2135
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 8
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0965:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0965
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0965
	.L_tc_recycle_frame_done_0965:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05ad
.L_if_else_0525:
	; preparing a tail-call
	mov rax, PARAM(0)	; param len1
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str1
	push rax
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var str2
	push rax
	mov rax, L_constants + 2135
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 8
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0966:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0966
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0966
	.L_tc_recycle_frame_done_0966:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_05ad:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_075a:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0964:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0964
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0964
	.L_tc_recycle_frame_done_0964:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0759:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_075b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_075b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_075b
.L_lambda_simple_env_end_075b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_075b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_075b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_075b
.L_lambda_simple_params_end_075b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_075b
	jmp .L_lambda_simple_end_075b
.L_lambda_simple_code_075b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0846
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0846:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_075c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_075c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_075c
.L_lambda_simple_env_end_075c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_075c:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_075c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_075c
.L_lambda_simple_params_end_075c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_075c
	jmp .L_lambda_simple_end_075c
.L_lambda_simple_code_075c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0847
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0847:
	enter 0, 0
	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +0)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +0)], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_075d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_075d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_075d
.L_lambda_simple_env_end_075d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_075d:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_075d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_075d
.L_lambda_simple_params_end_075d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_075d
	jmp .L_lambda_simple_end_075d
.L_lambda_simple_code_075d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0848
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0848:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_if_end_05ae
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var binary-string<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0526
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0968:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0968
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0968
	.L_tc_recycle_frame_done_0968:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05af
.L_if_else_0526:
	mov rax, L_constants + 2
.L_if_end_05af:
	cmp rax, sob_boolean_false
	jne .L_if_end_05ae
.L_if_end_05ae:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_075d:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov r9, qword [rbp + 8 * 2]
	mov r9, qword [rbp + 8 * 3]
	mov rdi, 8 * 1	; new rib for optional parameters
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_00ec:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 4
	je .L_lambda_opt_env_end_00ec
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00ec
.L_lambda_opt_env_end_00ec:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_02c2:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_01d7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_02c2
.L_lambda_opt_params_end_01d7:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00ec
	jmp .L_lambda_opt_end_01d7
.L_lambda_opt_code_00ec:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_0849
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0849:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_02c4
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_02c3: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02c3
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_01d8
	.L_lambda_opt_params_loop_02c4:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_02c3: ;loop for copying the opt into list
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov rbx, qword [rcx]
	mov SOB_PAIR_CAR(rax), rbx
	mov SOB_PAIR_CDR(rax), r9
	mov r9, rax
	dec rdx
	sub rcx, 8
	cmp rdx, 0
	jne .L_lambda_opt_params_loop_02c3
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_02c4:
	cmp rdx, 0
	je .L_lambda_opt_params_end_01d8
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02c4
	.L_lambda_opt_params_end_01d8:
	add rsp,rcx
	mov rbx, 1
	mov rbx, qword [rsp + 8 * 2]
	add rbx,3
	sub rbx,r8
	shl rbx, 3
	add rbx, rsp
	mov qword[rbx] , r9
	dec r8
	sub qword [rsp + 8 * 2], r8
	.L_lambda_opt_end_01d8:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0969:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0969
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0969
	.L_tc_recycle_frame_done_0969:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_01d7:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_075c:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0967:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0967
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0967
	.L_tc_recycle_frame_done_0967:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_075b:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0963:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0963
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0963
	.L_tc_recycle_frame_done_0963:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0757:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0961:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0961
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0961
	.L_tc_recycle_frame_done_0961:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0756:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_075e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_075e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_075e
.L_lambda_simple_env_end_075e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_075e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_075e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_075e
.L_lambda_simple_params_end_075e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_075e
	jmp .L_lambda_simple_end_075e
.L_lambda_simple_code_075e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_084a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_084a:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, qword [free_var_75]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_74]	; free var char<?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_134], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_68]	; free var char-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_67]	; free var char-ci<?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_122], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_75]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_77]	; free var char>?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_137], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_68]	; free var char-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_70]	; free var char-ci>?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_125], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_075e:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_075f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_075f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_075f
.L_lambda_simple_env_end_075f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_075f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_075f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_075f
.L_lambda_simple_params_end_075f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_075f
	jmp .L_lambda_simple_end_075f
.L_lambda_simple_code_075f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_084b
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_084b:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0760:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0760
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0760
.L_lambda_simple_env_end_0760:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0760:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0760
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0760
.L_lambda_simple_params_end_0760:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0760
	jmp .L_lambda_simple_end_0760
.L_lambda_simple_code_0760:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_084c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_084c:
	enter 0, 0
	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +0)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +0)], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0761:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0761
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0761
.L_lambda_simple_env_end_0761:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0761:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0761
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0761
.L_lambda_simple_params_end_0761:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0761
	jmp .L_lambda_simple_end_0761
.L_lambda_simple_code_0761:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_084d
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_084d:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_if_end_05b0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	push 2	; arg count
	mov rax, qword [free_var_128]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_128]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var char<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_if_end_05b0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0528
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	push 2	; arg count
	mov rax, qword [free_var_128]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_128]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 1]	; bound var char=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0527
	; preparing a tail-call
	mov rax, PARAM(4)	; param len2
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 8
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_096b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_096b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_096b
	.L_tc_recycle_frame_done_096b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05b1
.L_if_else_0527:
	mov rax, L_constants + 2
.L_if_end_05b1:
	jmp .L_if_end_05b2
.L_if_else_0528:
	mov rax, L_constants + 2
.L_if_end_05b2:
	cmp rax, sob_boolean_false
	jne .L_if_end_05b0
.L_if_end_05b0:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_0761:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0762:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0762
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0762
.L_lambda_simple_env_end_0762:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0762:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0762
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0762
.L_lambda_simple_params_end_0762:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0762
	jmp .L_lambda_simple_end_0762
.L_lambda_simple_code_0762:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_084e
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_084e:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param str2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_127]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_127]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0763:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0763
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0763
.L_lambda_simple_env_end_0763:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0763:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0763
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0763
.L_lambda_simple_params_end_0763:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0763
	jmp .L_lambda_simple_end_0763
.L_lambda_simple_code_0763:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_084f
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_084f:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, PARAM(0)	; param len1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_5]	; free var <=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0529
	; preparing a tail-call
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var str2
	push rax
	mov rax, PARAM(0)	; param len1
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str1
	push rax
	mov rax, L_constants + 2135
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 8
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_096e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_096e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_096e
	.L_tc_recycle_frame_done_096e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05b3
.L_if_else_0529:
	; preparing a tail-call
	mov rax, PARAM(0)	; param len1
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str1
	push rax
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var str2
	push rax
	mov rax, L_constants + 2135
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 8
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_096f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_096f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_096f
	.L_tc_recycle_frame_done_096f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_05b3:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0763:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_096d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_096d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_096d
	.L_tc_recycle_frame_done_096d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0762:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0764:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0764
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0764
.L_lambda_simple_env_end_0764:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0764:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0764
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0764
.L_lambda_simple_params_end_0764:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0764
	jmp .L_lambda_simple_end_0764
.L_lambda_simple_code_0764:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0850
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0850:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0765:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0765
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0765
.L_lambda_simple_env_end_0765:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0765:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0765
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0765
.L_lambda_simple_params_end_0765:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0765
	jmp .L_lambda_simple_end_0765
.L_lambda_simple_code_0765:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0851
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0851:
	enter 0, 0
	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +0)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +0)], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0766:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_0766
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0766
.L_lambda_simple_env_end_0766:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0766:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0766
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0766
.L_lambda_simple_params_end_0766:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0766
	jmp .L_lambda_simple_end_0766
.L_lambda_simple_code_0766:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0852
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0852:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_if_end_05b4
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var binary-string<=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_052a
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0971:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0971
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0971
	.L_tc_recycle_frame_done_0971:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05b5
.L_if_else_052a:
	mov rax, L_constants + 2
.L_if_end_05b5:
	cmp rax, sob_boolean_false
	jne .L_if_end_05b4
.L_if_end_05b4:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0766:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov r9, qword [rbp + 8 * 2]
	mov r9, qword [rbp + 8 * 3]
	mov rdi, 8 * 1	; new rib for optional parameters
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_00ed:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 4
	je .L_lambda_opt_env_end_00ed
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00ed
.L_lambda_opt_env_end_00ed:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_02c5:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_01d9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_02c5
.L_lambda_opt_params_end_01d9:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00ed
	jmp .L_lambda_opt_end_01d9
.L_lambda_opt_code_00ed:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_0853
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0853:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_02c7
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_02c6: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02c6
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_01da
	.L_lambda_opt_params_loop_02c7:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_02c6: ;loop for copying the opt into list
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov rbx, qword [rcx]
	mov SOB_PAIR_CAR(rax), rbx
	mov SOB_PAIR_CDR(rax), r9
	mov r9, rax
	dec rdx
	sub rcx, 8
	cmp rdx, 0
	jne .L_lambda_opt_params_loop_02c6
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_02c7:
	cmp rdx, 0
	je .L_lambda_opt_params_end_01da
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02c7
	.L_lambda_opt_params_end_01da:
	add rsp,rcx
	mov rbx, 1
	mov rbx, qword [rsp + 8 * 2]
	add rbx,3
	sub rbx,r8
	shl rbx, 3
	add rbx, rsp
	mov qword[rbx] , r9
	dec r8
	sub qword [rsp + 8 * 2], r8
	.L_lambda_opt_end_01da:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0972:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0972
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0972
	.L_tc_recycle_frame_done_0972:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_01d9:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0765:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0970:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0970
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0970
	.L_tc_recycle_frame_done_0970:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0764:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_096c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_096c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_096c
	.L_tc_recycle_frame_done_096c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0760:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_096a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_096a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_096a
	.L_tc_recycle_frame_done_096a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_075f:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0767:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0767
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0767
.L_lambda_simple_env_end_0767:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0767:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0767
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0767
.L_lambda_simple_params_end_0767:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0767
	jmp .L_lambda_simple_end_0767
.L_lambda_simple_code_0767:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0854
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0854:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, qword [free_var_75]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_74]	; free var char<?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_133], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_68]	; free var char-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_67]	; free var char-ci<?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_121], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_75]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_77]	; free var char>?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_136], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_68]	; free var char-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_70]	; free var char-ci>?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_124], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0767:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0768:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0768
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0768
.L_lambda_simple_env_end_0768:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0768:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0768
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0768
.L_lambda_simple_params_end_0768:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0768
	jmp .L_lambda_simple_end_0768
.L_lambda_simple_code_0768:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0855
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0855:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0769:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0769
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0769
.L_lambda_simple_env_end_0769:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0769:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0769
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0769
.L_lambda_simple_params_end_0769:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0769
	jmp .L_lambda_simple_end_0769
.L_lambda_simple_code_0769:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0856
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0856:
	enter 0, 0
	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +0)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +0)], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_076a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_076a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_076a
.L_lambda_simple_env_end_076a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_076a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_076a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_076a
.L_lambda_simple_params_end_076a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_076a
	jmp .L_lambda_simple_end_076a
.L_lambda_simple_code_076a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 4
	je .L_lambda_simple_arity_check_ok_0857
	push qword [rsp + 8 * 2]
	push 4
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0857:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(3)	; param len
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_if_end_05b6
	; preparing a non-tail-call
	mov rax, PARAM(3)	; param len
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_052c
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(2)	; param str2
	push rax
	push 2	; arg count
	mov rax, qword [free_var_128]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_128]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var char=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_052b
	; preparing a tail-call
	mov rax, PARAM(3)	; param len
	push rax
	mov rax, PARAM(2)	; param str2
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 4	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 7
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0974:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0974
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0974
	.L_tc_recycle_frame_done_0974:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05b7
.L_if_else_052b:
	mov rax, L_constants + 2
.L_if_end_05b7:
	jmp .L_if_end_05b8
.L_if_else_052c:
	mov rax, L_constants + 2
.L_if_end_05b8:
	cmp rax, sob_boolean_false
	jne .L_if_end_05b6
.L_if_end_05b6:
	leave
	ret AND_KILL_FRAME(4)
.L_lambda_simple_end_076a:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_076b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_076b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_076b
.L_lambda_simple_env_end_076b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_076b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_076b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_076b
.L_lambda_simple_params_end_076b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_076b
	jmp .L_lambda_simple_end_076b
.L_lambda_simple_code_076b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0858
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0858:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param str2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_127]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_127]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_076c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_076c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_076c
.L_lambda_simple_env_end_076c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_076c:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_076c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_076c
.L_lambda_simple_params_end_076c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_076c
	jmp .L_lambda_simple_end_076c
.L_lambda_simple_code_076c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0859
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0859:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, PARAM(0)	; param len1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_052d
	; preparing a tail-call
	mov rax, PARAM(0)	; param len1
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var str2
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str1
	push rax
	mov rax, L_constants + 2135
	push rax
	push 4	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 7
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0977:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0977
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0977
	.L_tc_recycle_frame_done_0977:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05b9
.L_if_else_052d:
	mov rax, L_constants + 2
.L_if_end_05b9:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_076c:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0976:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0976
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0976
	.L_tc_recycle_frame_done_0976:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_076b:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_076d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_076d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_076d
.L_lambda_simple_env_end_076d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_076d:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_076d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_076d
.L_lambda_simple_params_end_076d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_076d
	jmp .L_lambda_simple_end_076d
.L_lambda_simple_code_076d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_085a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_085a:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_076e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_076e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_076e
.L_lambda_simple_env_end_076e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_076e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_076e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_076e
.L_lambda_simple_params_end_076e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_076e
	jmp .L_lambda_simple_end_076e
.L_lambda_simple_code_076e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_085b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_085b:
	enter 0, 0
	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +0)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +0)], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_076f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_076f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_076f
.L_lambda_simple_env_end_076f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_076f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_076f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_076f
.L_lambda_simple_params_end_076f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_076f
	jmp .L_lambda_simple_end_076f
.L_lambda_simple_code_076f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_085c
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_085c:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_if_end_05ba
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var binary-string=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_052e
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0979:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0979
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0979
	.L_tc_recycle_frame_done_0979:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05bb
.L_if_else_052e:
	mov rax, L_constants + 2
.L_if_end_05bb:
	cmp rax, sob_boolean_false
	jne .L_if_end_05ba
.L_if_end_05ba:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_076f:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov r9, qword [rbp + 8 * 2]
	mov r9, qword [rbp + 8 * 3]
	mov rdi, 8 * 1	; new rib for optional parameters
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_00ee:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 4
	je .L_lambda_opt_env_end_00ee
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00ee
.L_lambda_opt_env_end_00ee:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_02c8:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_01db
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_02c8
.L_lambda_opt_params_end_01db:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00ee
	jmp .L_lambda_opt_end_01db
.L_lambda_opt_code_00ee:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_085d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_085d:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_02ca
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_02c9: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02c9
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_01dc
	.L_lambda_opt_params_loop_02ca:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_02c9: ;loop for copying the opt into list
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov rbx, qword [rcx]
	mov SOB_PAIR_CAR(rax), rbx
	mov SOB_PAIR_CDR(rax), r9
	mov r9, rax
	dec rdx
	sub rcx, 8
	cmp rdx, 0
	jne .L_lambda_opt_params_loop_02c9
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_02ca:
	cmp rdx, 0
	je .L_lambda_opt_params_end_01dc
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02ca
	.L_lambda_opt_params_end_01dc:
	add rsp,rcx
	mov rbx, 1
	mov rbx, qword [rsp + 8 * 2]
	add rbx,3
	sub rbx,r8
	shl rbx, 3
	add rbx, rsp
	mov qword[rbx] , r9
	dec r8
	sub qword [rsp + 8 * 2], r8
	.L_lambda_opt_end_01dc:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_097a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_097a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_097a
	.L_tc_recycle_frame_done_097a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_01db:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_076e:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0978:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0978
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0978
	.L_tc_recycle_frame_done_0978:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_076d:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0975:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0975
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0975
	.L_tc_recycle_frame_done_0975:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0769:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0973:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0973
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0973
	.L_tc_recycle_frame_done_0973:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0768:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0770:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0770
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0770
.L_lambda_simple_env_end_0770:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0770:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0770
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0770
.L_lambda_simple_params_end_0770:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0770
	jmp .L_lambda_simple_end_0770
.L_lambda_simple_code_0770:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_085e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_085e:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, qword [free_var_75]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-string=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_135], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_68]	; free var char-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-string=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_123], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0770:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0771:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0771
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0771
.L_lambda_simple_env_end_0771:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0771:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0771
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0771
.L_lambda_simple_params_end_0771:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0771
	jmp .L_lambda_simple_end_0771
.L_lambda_simple_code_0771:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_085f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_085f:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_if_end_05bc
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_052f
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_96]	; free var list?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_097b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_097b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_097b
	.L_tc_recycle_frame_done_097b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05bd
.L_if_else_052f:
	mov rax, L_constants + 2
.L_if_end_05bd:
	cmp rax, sob_boolean_false
	jne .L_if_end_05bc
.L_if_end_05bc:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0771:	; new closure is in rax
	mov qword [free_var_96], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, qword [free_var_101]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0772:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0772
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0772
.L_lambda_simple_env_end_0772:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0772:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0772
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0772
.L_lambda_simple_params_end_0772:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0772
	jmp .L_lambda_simple_end_0772
.L_lambda_simple_code_0772:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0860
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0860:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov r9, qword [rbp + 8 * 2]
	mov r9, qword [rbp + 8 * 3]
	mov rdi, 8 * 1	; new rib for optional parameters
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_00ef:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_00ef
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00ef
.L_lambda_opt_env_end_00ef:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_02cb:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_01dd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_02cb
.L_lambda_opt_params_end_01dd:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00ef
	jmp .L_lambda_opt_end_01dd
.L_lambda_opt_code_00ef:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_0861
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0861:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_02cd
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_02cc: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02cc
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_01de
	.L_lambda_opt_params_loop_02cd:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_02cc: ;loop for copying the opt into list
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov rbx, qword [rcx]
	mov SOB_PAIR_CAR(rax), rbx
	mov SOB_PAIR_CDR(rax), r9
	mov r9, rax
	dec rdx
	sub rcx, 8
	cmp rdx, 0
	jne .L_lambda_opt_params_loop_02cc
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_02cd:
	cmp rdx, 0
	je .L_lambda_opt_params_end_01de
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02cd
	.L_lambda_opt_params_end_01de:
	add rsp,rcx
	mov rbx, 1
	mov rbx, qword [rsp + 8 * 2]
	add rbx,3
	sub rbx,r8
	shl rbx, 3
	add rbx, rsp
	mov qword[rbx] , r9
	dec r8
	sub qword [rsp + 8 * 2], r8
	.L_lambda_opt_end_01de:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param xs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0532
	mov rax, L_constants + 0
	jmp .L_if_end_05c0
.L_if_else_0532:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param xs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0530
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param xs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_05be
.L_if_else_0530:
	mov rax, L_constants + 2
.L_if_end_05be:
	cmp rax, sob_boolean_false
	je .L_if_else_0531
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param xs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_05bf
.L_if_else_0531:
	; preparing a non-tail-call
	mov rax, L_constants + 2955
	push rax
	mov rax, L_constants + 2946
	push rax
	push 2	; arg count
	mov rax, qword [free_var_82]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
.L_if_end_05bf:
.L_if_end_05c0:
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0773:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0773
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0773
.L_lambda_simple_env_end_0773:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0773:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0773
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0773
.L_lambda_simple_params_end_0773:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0773
	jmp .L_lambda_simple_end_0773
.L_lambda_simple_code_0773:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0862
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0862:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var asm-make-vector
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_097d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_097d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_097d
	.L_tc_recycle_frame_done_097d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0773:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_097c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_097c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_097c
	.L_tc_recycle_frame_done_097c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_01dd:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0772:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_101], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, qword [free_var_99]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0774:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0774
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0774
.L_lambda_simple_env_end_0774:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0774:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0774
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0774
.L_lambda_simple_params_end_0774:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0774
	jmp .L_lambda_simple_end_0774
.L_lambda_simple_code_0774:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0863
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0863:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov r9, qword [rbp + 8 * 2]
	mov r9, qword [rbp + 8 * 3]
	mov rdi, 8 * 1	; new rib for optional parameters
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_00f0:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_00f0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00f0
.L_lambda_opt_env_end_00f0:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_02ce:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_01df
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_02ce
.L_lambda_opt_params_end_01df:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00f0
	jmp .L_lambda_opt_end_01df
.L_lambda_opt_code_00f0:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_0864
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0864:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_02d0
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_02cf: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02cf
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_01e0
	.L_lambda_opt_params_loop_02d0:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_02cf: ;loop for copying the opt into list
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov rbx, qword [rcx]
	mov SOB_PAIR_CAR(rax), rbx
	mov SOB_PAIR_CDR(rax), r9
	mov r9, rax
	dec rdx
	sub rcx, 8
	cmp rdx, 0
	jne .L_lambda_opt_params_loop_02cf
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_02d0:
	cmp rdx, 0
	je .L_lambda_opt_params_end_01e0
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02d0
	.L_lambda_opt_params_end_01e0:
	add rsp,rcx
	mov rbx, 1
	mov rbx, qword [rsp + 8 * 2]
	add rbx,3
	sub rbx,r8
	shl rbx, 3
	add rbx, rsp
	mov qword[rbx] , r9
	dec r8
	sub qword [rsp + 8 * 2], r8
	.L_lambda_opt_end_01e0:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param chs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0535
	mov rax, L_constants + 4
	jmp .L_if_end_05c3
.L_if_else_0535:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param chs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0533
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param chs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_05c1
.L_if_else_0533:
	mov rax, L_constants + 2
.L_if_end_05c1:
	cmp rax, sob_boolean_false
	je .L_if_else_0534
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param chs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_05c2
.L_if_else_0534:
	; preparing a non-tail-call
	mov rax, L_constants + 3016
	push rax
	mov rax, L_constants + 3007
	push rax
	push 2	; arg count
	mov rax, qword [free_var_82]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
.L_if_end_05c2:
.L_if_end_05c3:
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0775:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0775
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0775
.L_lambda_simple_env_end_0775:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0775:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0775
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0775
.L_lambda_simple_params_end_0775:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0775
	jmp .L_lambda_simple_end_0775
.L_lambda_simple_code_0775:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0865
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0865:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var asm-make-string
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_097f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_097f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_097f
	.L_tc_recycle_frame_done_097f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0775:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_097e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_097e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_097e
	.L_tc_recycle_frame_done_097e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_01df:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0774:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_99], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0776:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0776
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0776
.L_lambda_simple_env_end_0776:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0776:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0776
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0776
.L_lambda_simple_params_end_0776:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0776
	jmp .L_lambda_simple_end_0776
.L_lambda_simple_code_0776:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0866
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0866:
	enter 0, 0
	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +0)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +0)], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0777:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0777
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0777
.L_lambda_simple_env_end_0777:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0777:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0777
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0777
.L_lambda_simple_params_end_0777:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0777
	jmp .L_lambda_simple_end_0777
.L_lambda_simple_code_0777:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0867
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0867:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0536
	; preparing a tail-call
	mov rax, L_constants + 0
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_101]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0980:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0980
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0980
	.L_tc_recycle_frame_done_0980:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05c4
.L_if_else_0536:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0778:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0778
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0778
.L_lambda_simple_env_end_0778:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0778:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0778
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0778
.L_lambda_simple_params_end_0778:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0778
	jmp .L_lambda_simple_end_0778
.L_lambda_simple_code_0778:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0868
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0868:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push 3	; arg count
	mov rax, qword [free_var_147]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rax, PARAM(0)	; param v
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0778:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0981:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0981
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0981
	.L_tc_recycle_frame_done_0981:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_05c4:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0777:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0779:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0779
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0779
.L_lambda_simple_env_end_0779:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0779:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0779
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0779
.L_lambda_simple_params_end_0779:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0779
	jmp .L_lambda_simple_end_0779
.L_lambda_simple_code_0779:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0869
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0869:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2135
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0982:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0982
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0982
	.L_tc_recycle_frame_done_0982:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0779:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0776:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_95], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_077a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_077a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_077a
.L_lambda_simple_env_end_077a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_077a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_077a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_077a
.L_lambda_simple_params_end_077a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_077a
	jmp .L_lambda_simple_end_077a
.L_lambda_simple_code_077a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_086a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_086a:
	enter 0, 0
	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +0)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +0)], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_077b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_077b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_077b
.L_lambda_simple_env_end_077b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_077b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_077b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_077b
.L_lambda_simple_params_end_077b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_077b
	jmp .L_lambda_simple_end_077b
.L_lambda_simple_code_077b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_086b
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_086b:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0537
	; preparing a tail-call
	mov rax, L_constants + 4
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_99]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0983:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0983
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0983
	.L_tc_recycle_frame_done_0983:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05c5
.L_if_else_0537:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_077c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_077c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_077c
.L_lambda_simple_env_end_077c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_077c:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_077c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_077c
.L_lambda_simple_params_end_077c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_077c
	jmp .L_lambda_simple_end_077c
.L_lambda_simple_code_077c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_086c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_086c:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 3	; arg count
	mov rax, qword [free_var_131]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rax, PARAM(0)	; param str
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_077c:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0984:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0984
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0984
	.L_tc_recycle_frame_done_0984:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_05c5:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_077b:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_077d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_077d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_077d
.L_lambda_simple_env_end_077d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_077d:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_077d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_077d
.L_lambda_simple_params_end_077d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_077d
	jmp .L_lambda_simple_end_077d
.L_lambda_simple_code_077d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_086d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_086d:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2135
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0985:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0985
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0985
	.L_tc_recycle_frame_done_0985:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_077d:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_077a:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_94], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov r9, qword [rbp + 8 * 2]
	mov r9, qword [rbp + 8 * 3]
	mov rdi, 8 * 0	; new rib for optional parameters
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_00f1:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 0
	je .L_lambda_opt_env_end_00f1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00f1
.L_lambda_opt_env_end_00f1:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_02d1:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_01e1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_02d1
.L_lambda_opt_params_end_01e1:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00f1
	jmp .L_lambda_opt_end_01e1
.L_lambda_opt_code_00f1:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	jge .L_lambda_simple_arity_check_ok_086e
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_086e:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 0
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_02d3
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_02d2: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02d2
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_01e2
	.L_lambda_opt_params_loop_02d3:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_02d2: ;loop for copying the opt into list
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov rbx, qword [rcx]
	mov SOB_PAIR_CAR(rax), rbx
	mov SOB_PAIR_CDR(rax), r9
	mov r9, rax
	dec rdx
	sub rcx, 8
	cmp rdx, 0
	jne .L_lambda_opt_params_loop_02d2
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_02d3:
	cmp rdx, 0
	je .L_lambda_opt_params_end_01e2
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02d3
	.L_lambda_opt_params_end_01e2:
	add rsp,rcx
	mov rbx, 0
	mov rbx, qword [rsp + 8 * 2]
	add rbx,3
	sub rbx,r8
	shl rbx, 3
	add rbx, rsp
	mov qword[rbx] , r9
	dec r8
	sub qword [rsp + 8 * 2], r8
	.L_lambda_opt_end_01e2:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_95]	; free var list->vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0986:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0986
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0986
	.L_tc_recycle_frame_done_0986:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_01e1:
	mov qword [free_var_140], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_077e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_077e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_077e
.L_lambda_simple_env_end_077e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_077e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_077e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_077e
.L_lambda_simple_params_end_077e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_077e
	jmp .L_lambda_simple_end_077e
.L_lambda_simple_code_077e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_086f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_086f:
	enter 0, 0
	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +0)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +0)], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_077f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_077f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_077f
.L_lambda_simple_env_end_077f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_077f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_077f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_077f
.L_lambda_simple_params_end_077f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_077f
	jmp .L_lambda_simple_end_077f
.L_lambda_simple_code_077f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0870
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0870:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param n
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0538
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param n
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, qword [free_var_128]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_79]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0987:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0987
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0987
	.L_tc_recycle_frame_done_0987:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05c6
.L_if_else_0538:
	mov rax, L_constants + 1
.L_if_end_05c6:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_077f:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0780:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0780
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0780
.L_lambda_simple_env_end_0780:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0780:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0780
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0780
.L_lambda_simple_params_end_0780:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0780
	jmp .L_lambda_simple_end_0780
.L_lambda_simple_code_0780:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0871
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0871:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str
	push rax
	push 1	; arg count
	mov rax, qword [free_var_127]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2135
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 6
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0988:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0988
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0988
	.L_tc_recycle_frame_done_0988:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0780:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_077e:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_119], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0781:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0781
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0781
.L_lambda_simple_env_end_0781:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0781:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0781
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0781
.L_lambda_simple_params_end_0781:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0781
	jmp .L_lambda_simple_end_0781
.L_lambda_simple_code_0781:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0872
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0872:
	enter 0, 0
	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +0)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +0)], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0782:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0782
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0782
.L_lambda_simple_env_end_0782:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0782:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0782
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0782
.L_lambda_simple_params_end_0782:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0782
	jmp .L_lambda_simple_end_0782
.L_lambda_simple_code_0782:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0873
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0873:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param n
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0539
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param n
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push 2	; arg count
	mov rax, qword [free_var_144]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_79]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0989:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0989
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0989
	.L_tc_recycle_frame_done_0989:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05c7
.L_if_else_0539:
	mov rax, L_constants + 1
.L_if_end_05c7:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0782:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0783:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0783
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0783
.L_lambda_simple_env_end_0783:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0783:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0783
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0783
.L_lambda_simple_params_end_0783:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0783
	jmp .L_lambda_simple_end_0783
.L_lambda_simple_code_0783:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0874
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0874:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param v
	push rax
	push 1	; arg count
	mov rax, qword [free_var_143]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2135
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 6
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_098a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_098a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_098a
	.L_tc_recycle_frame_done_098a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0783:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0781:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_141], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0784:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0784
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0784
.L_lambda_simple_env_end_0784:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0784:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0784
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0784
.L_lambda_simple_params_end_0784:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0784
	jmp .L_lambda_simple_end_0784
.L_lambda_simple_code_0784:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0875
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0875:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param n
	push rax
	; preparing a non-tail-call
	push 0	; arg count
	mov rax, qword [free_var_139]	; free var trng
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_117]	; free var remainder
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_098b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_098b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_098b
	.L_tc_recycle_frame_done_098b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0784:	; new closure is in rax
	mov qword [free_var_113], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0785:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0785
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0785
.L_lambda_simple_env_end_0785:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0785:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0785
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0785
.L_lambda_simple_params_end_0785:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0785
	jmp .L_lambda_simple_end_0785
.L_lambda_simple_code_0785:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0876
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0876:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	mov rax, L_constants + 2135
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_098c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_098c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_098c
	.L_tc_recycle_frame_done_098c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0785:	; new closure is in rax
	mov qword [free_var_112], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0786:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0786
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0786
.L_lambda_simple_env_end_0786:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0786:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0786
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0786
.L_lambda_simple_params_end_0786:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0786
	jmp .L_lambda_simple_end_0786
.L_lambda_simple_code_0786:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0877
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0877:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2135
	push rax
	mov rax, PARAM(0)	; param x
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_098d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_098d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_098d
	.L_tc_recycle_frame_done_098d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0786:	; new closure is in rax
	mov qword [free_var_104], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0787:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0787
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0787
.L_lambda_simple_env_end_0787:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0787:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0787
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0787
.L_lambda_simple_params_end_0787:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0787
	jmp .L_lambda_simple_end_0787
.L_lambda_simple_code_0787:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0878
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0878:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 3190
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_117]	; free var remainder
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_152]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_098e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_098e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_098e
	.L_tc_recycle_frame_done_098e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0787:	; new closure is in rax
	mov qword [free_var_83], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0788:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0788
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0788
.L_lambda_simple_env_end_0788:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0788:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0788
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0788
.L_lambda_simple_params_end_0788:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0788
	jmp .L_lambda_simple_end_0788
.L_lambda_simple_code_0788:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0879
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0879:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_83]	; free var even?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_106]	; free var not
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_098f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_098f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_098f
	.L_tc_recycle_frame_done_098f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0788:	; new closure is in rax
	mov qword [free_var_109], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0789:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0789
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0789
.L_lambda_simple_env_end_0789:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0789:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0789
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0789
.L_lambda_simple_params_end_0789:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0789
	jmp .L_lambda_simple_end_0789
.L_lambda_simple_code_0789:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_087a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_087a:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_104]	; free var negative?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_053a
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0990:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0990
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0990
	.L_tc_recycle_frame_done_0990:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05c8
.L_if_else_053a:
	mov rax, PARAM(0)	; param x
.L_if_end_05c8:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0789:	; new closure is in rax
	mov qword [free_var_30], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_078a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_078a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_078a
.L_lambda_simple_env_end_078a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_078a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_078a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_078a
.L_lambda_simple_params_end_078a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_078a
	jmp .L_lambda_simple_end_078a
.L_lambda_simple_code_078a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_087b
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_087b:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_053b
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_05c9
.L_if_else_053b:
	mov rax, L_constants + 2
.L_if_end_05c9:
	cmp rax, sob_boolean_false
	je .L_if_else_0547
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_81]	; free var equal?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_053c
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_81]	; free var equal?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0991:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0991
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0991
	.L_tc_recycle_frame_done_0991:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05ca
.L_if_else_053c:
	mov rax, L_constants + 2
.L_if_end_05ca:
	jmp .L_if_end_05d5
.L_if_else_0547:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_148]	; free var vector?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_053e
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_148]	; free var vector?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_053d
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_143]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_143]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_05cb
.L_if_else_053d:
	mov rax, L_constants + 2
.L_if_end_05cb:
	jmp .L_if_end_05cc
.L_if_else_053e:
	mov rax, L_constants + 2
.L_if_end_05cc:
	cmp rax, sob_boolean_false
	je .L_if_else_0546
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_141]	; free var vector->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_141]	; free var vector->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_81]	; free var equal?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0992:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0992
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0992
	.L_tc_recycle_frame_done_0992:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05d4
.L_if_else_0546:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_138]	; free var string?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0540
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_138]	; free var string?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_053f
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_127]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_127]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_05cd
.L_if_else_053f:
	mov rax, L_constants + 2
.L_if_end_05cd:
	jmp .L_if_end_05ce
.L_if_else_0540:
	mov rax, L_constants + 2
.L_if_end_05ce:
	cmp rax, sob_boolean_false
	je .L_if_else_0545
	; preparing a tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_135]	; free var string=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0993:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0993
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0993
	.L_tc_recycle_frame_done_0993:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05d3
.L_if_else_0545:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_108]	; free var number?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0541
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_108]	; free var number?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_05cf
.L_if_else_0541:
	mov rax, L_constants + 2
.L_if_end_05cf:
	cmp rax, sob_boolean_false
	je .L_if_else_0544
	; preparing a tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0994:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0994
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0994
	.L_tc_recycle_frame_done_0994:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05d2
.L_if_else_0544:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_78]	; free var char?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0542
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_78]	; free var char?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_05d0
.L_if_else_0542:
	mov rax, L_constants + 2
.L_if_end_05d0:
	cmp rax, sob_boolean_false
	je .L_if_else_0543
	; preparing a tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_75]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0995:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0995
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0995
	.L_tc_recycle_frame_done_0995:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05d1
.L_if_else_0543:
	; preparing a tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_80]	; free var eq?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0996:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0996
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0996
	.L_tc_recycle_frame_done_0996:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_05d1:
.L_if_end_05d2:
.L_if_end_05d3:
.L_if_end_05d4:
.L_if_end_05d5:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_078a:	; new closure is in rax
	mov qword [free_var_81], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_078b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_078b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_078b
.L_lambda_simple_env_end_078b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_078b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_078b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_078b
.L_lambda_simple_params_end_078b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_078b
	jmp .L_lambda_simple_end_078b
.L_lambda_simple_code_078b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_087c
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_087c:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0549
	mov rax, L_constants + 2
	jmp .L_if_end_05d7
.L_if_else_0549:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_80]	; free var eq?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0548
	; preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0997:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0997
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0997
	.L_tc_recycle_frame_done_0997:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05d6
.L_if_else_0548:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_34]	; free var assoc
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0998:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0998
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0998
	.L_tc_recycle_frame_done_0998:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_05d6:
.L_if_end_05d7:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_078b:	; new closure is in rax
	mov qword [free_var_34], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_078c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_078c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_078c
.L_lambda_simple_env_end_078c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_078c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_078c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_078c
.L_lambda_simple_params_end_078c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_078c
	jmp .L_lambda_simple_end_078c
.L_lambda_simple_code_078c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_087d
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_087d:
	enter 0, 0
	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +0)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +0)], rax
	mov rax, sob_void

	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +1)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +1)], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_078d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_078d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_078d
.L_lambda_simple_env_end_078d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_078d:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_078d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_078d
.L_lambda_simple_params_end_078d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_078d
	jmp .L_lambda_simple_end_078d
.L_lambda_simple_code_078d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_087e
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_087e:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_054a
	mov rax, PARAM(0)	; param target
	jmp .L_if_end_05d8
.L_if_else_054a:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_127]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2135
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_078e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_078e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_078e
.L_lambda_simple_env_end_078e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_078e:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_078e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_078e
.L_lambda_simple_params_end_078e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_078e
	jmp .L_lambda_simple_end_078e
.L_lambda_simple_code_078e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_087f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_087f:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var target
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 6
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_099a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_099a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_099a
	.L_tc_recycle_frame_done_099a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_078e:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0999:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0999
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0999
	.L_tc_recycle_frame_done_0999:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_05d8:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_078d:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_078f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_078f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_078f
.L_lambda_simple_env_end_078f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_078f:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_078f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_078f
.L_lambda_simple_params_end_078f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_078f
	jmp .L_lambda_simple_end_078f
.L_lambda_simple_code_078f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_0880
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0880:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(4)	; param limit
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_054b
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(3)	; param j
	push rax
	mov rax, PARAM(2)	; param str
	push rax
	push 2	; arg count
	mov rax, qword [free_var_128]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 3	; arg count
	mov rax, qword [free_var_131]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	mov rax, PARAM(4)	; param limit
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(2)	; param str
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 8
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_099b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_099b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_099b
	.L_tc_recycle_frame_done_099b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05d9
.L_if_else_054b:
	mov rax, PARAM(1)	; param i
.L_if_end_05d9:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_078f:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param add
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov r9, qword [rbp + 8 * 2]
	mov r9, qword [rbp + 8 * 3]
	mov rdi, 8 * 2	; new rib for optional parameters
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_00f2:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_00f2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00f2
.L_lambda_opt_env_end_00f2:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_02d4:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_01e3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_02d4
.L_lambda_opt_params_end_01e3:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00f2
	jmp .L_lambda_opt_end_01e3
.L_lambda_opt_code_00f2:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	jge .L_lambda_simple_arity_check_ok_0881
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0881:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 0
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_02d6
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_02d5: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02d5
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_01e4
	.L_lambda_opt_params_loop_02d6:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_02d5: ;loop for copying the opt into list
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov rbx, qword [rcx]
	mov SOB_PAIR_CAR(rax), rbx
	mov SOB_PAIR_CDR(rax), r9
	mov r9, rax
	dec rdx
	sub rcx, 8
	cmp rdx, 0
	jne .L_lambda_opt_params_loop_02d5
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_02d6:
	cmp rdx, 0
	je .L_lambda_opt_params_end_01e4
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02d6
	.L_lambda_opt_params_end_01e4:
	add rsp,rcx
	mov rbx, 0
	mov rbx, qword [rsp + 8 * 2]
	add rbx,3
	sub rbx,r8
	shl rbx, 3
	add rbx, rsp
	mov qword[rbx] , r9
	dec r8
	sub qword [rsp + 8 * 2], r8
	.L_lambda_opt_end_01e4:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param strings
	push rax
	mov rax, L_constants + 2135
	push rax
	; preparing a non-tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param strings
	push rax
	mov rax, qword [free_var_127]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_103]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_99]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 6
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_099c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_099c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_099c
	.L_tc_recycle_frame_done_099c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_01e3:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_078c:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_120], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0790:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0790
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0790
.L_lambda_simple_env_end_0790:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0790:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0790
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0790
.L_lambda_simple_params_end_0790:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0790
	jmp .L_lambda_simple_end_0790
.L_lambda_simple_code_0790:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0882
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0882:
	enter 0, 0
	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +0)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +0)], rax
	mov rax, sob_void

	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +1)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +1)], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0791:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0791
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0791
.L_lambda_simple_env_end_0791:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0791:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0791
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0791
.L_lambda_simple_params_end_0791:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0791
	jmp .L_lambda_simple_end_0791
.L_lambda_simple_code_0791:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0883
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0883:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_054c
	mov rax, PARAM(0)	; param target
	jmp .L_if_end_05da
.L_if_else_054c:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_143]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2135
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0792:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0792
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0792
.L_lambda_simple_env_end_0792:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0792:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_0792
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0792
.L_lambda_simple_params_end_0792:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0792
	jmp .L_lambda_simple_end_0792
.L_lambda_simple_code_0792:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0884
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0884:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var target
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 6
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_099e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_099e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_099e
	.L_tc_recycle_frame_done_099e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0792:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_099d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_099d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_099d
	.L_tc_recycle_frame_done_099d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_05da:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0791:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0793:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0793
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0793
.L_lambda_simple_env_end_0793:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0793:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0793
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0793
.L_lambda_simple_params_end_0793:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0793
	jmp .L_lambda_simple_end_0793
.L_lambda_simple_code_0793:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_0885
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0885:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(4)	; param limit
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_054d
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(3)	; param j
	push rax
	mov rax, PARAM(2)	; param vec
	push rax
	push 2	; arg count
	mov rax, qword [free_var_144]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 3	; arg count
	mov rax, qword [free_var_147]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	mov rax, PARAM(4)	; param limit
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(2)	; param vec
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 8
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_099f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_099f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_099f
	.L_tc_recycle_frame_done_099f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05db
.L_if_else_054d:
	mov rax, PARAM(1)	; param i
.L_if_end_05db:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_0793:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param add
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov r9, qword [rbp + 8 * 2]
	mov r9, qword [rbp + 8 * 3]
	mov rdi, 8 * 2	; new rib for optional parameters
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_00f3:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_00f3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00f3
.L_lambda_opt_env_end_00f3:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_02d7:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_01e5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_02d7
.L_lambda_opt_params_end_01e5:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00f3
	jmp .L_lambda_opt_end_01e5
.L_lambda_opt_code_00f3:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	jge .L_lambda_simple_arity_check_ok_0886
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0886:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 0
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_02d9
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_02d8: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02d8
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_01e6
	.L_lambda_opt_params_loop_02d9:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_02d8: ;loop for copying the opt into list
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov rbx, qword [rcx]
	mov SOB_PAIR_CAR(rax), rbx
	mov SOB_PAIR_CDR(rax), r9
	mov r9, rax
	dec rdx
	sub rcx, 8
	cmp rdx, 0
	jne .L_lambda_opt_params_loop_02d8
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_02d9:
	cmp rdx, 0
	je .L_lambda_opt_params_end_01e6
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_02d9
	.L_lambda_opt_params_end_01e6:
	add rsp,rcx
	mov rbx, 0
	mov rbx, qword [rsp + 8 * 2]
	add rbx,3
	sub rbx,r8
	shl rbx, 3
	add rbx, rsp
	mov qword[rbx] , r9
	dec r8
	sub qword [rsp + 8 * 2], r8
	.L_lambda_opt_end_01e6:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param vectors
	push rax
	mov rax, L_constants + 2135
	push rax
	; preparing a non-tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param vectors
	push rax
	mov rax, qword [free_var_143]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_103]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_101]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 6
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09a0:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09a0
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09a0
	.L_tc_recycle_frame_done_09a0:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_01e5:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0790:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_142], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0794:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0794
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0794
.L_lambda_simple_env_end_0794:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0794:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0794
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0794
.L_lambda_simple_params_end_0794:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0794
	jmp .L_lambda_simple_end_0794
.L_lambda_simple_code_0794:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0887
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0887:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str
	push rax
	push 1	; arg count
	mov rax, qword [free_var_119]	; free var string->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_118]	; free var reverse
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_94]	; free var list->string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09a1:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09a1
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09a1
	.L_tc_recycle_frame_done_09a1:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0794:	; new closure is in rax
	mov qword [free_var_129], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0795:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0795
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0795
.L_lambda_simple_env_end_0795:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0795:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0795
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0795
.L_lambda_simple_params_end_0795:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0795
	jmp .L_lambda_simple_end_0795
.L_lambda_simple_code_0795:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0888
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0888:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param vec
	push rax
	push 1	; arg count
	mov rax, qword [free_var_141]	; free var vector->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_118]	; free var reverse
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_95]	; free var list->vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09a2:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09a2
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09a2
	.L_tc_recycle_frame_done_09a2:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0795:	; new closure is in rax
	mov qword [free_var_145], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0796:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0796
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0796
.L_lambda_simple_env_end_0796:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0796:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0796
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0796
.L_lambda_simple_params_end_0796:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0796
	jmp .L_lambda_simple_end_0796
.L_lambda_simple_code_0796:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0889
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0889:
	enter 0, 0
	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +0)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +0)], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0797:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0797
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0797
.L_lambda_simple_env_end_0797:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0797:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0797
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0797
.L_lambda_simple_params_end_0797:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0797
	jmp .L_lambda_simple_end_0797
.L_lambda_simple_code_0797:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_088a
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_088a:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param j
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_054e
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, qword [free_var_128]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0798:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0798
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0798
.L_lambda_simple_env_end_0798:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0798:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_0798
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0798
.L_lambda_simple_params_end_0798:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0798
	jmp .L_lambda_simple_end_0798
.L_lambda_simple_code_0798:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_088b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_088b:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 2	; arg count
	mov rax, qword [free_var_128]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3	; arg count
	mov rax, qword [free_var_131]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a non-tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3	; arg count
	mov rax, qword [free_var_131]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 6
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09a4:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09a4
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09a4
	.L_tc_recycle_frame_done_09a4:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0798:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09a3:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09a3
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09a3
	.L_tc_recycle_frame_done_09a3:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05dc
.L_if_else_054e:
	mov rax, PARAM(0)	; param str
.L_if_end_05dc:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0797:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0799:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0799
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0799
.L_lambda_simple_env_end_0799:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0799:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0799
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0799
.L_lambda_simple_params_end_0799:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0799
	jmp .L_lambda_simple_end_0799
.L_lambda_simple_code_0799:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_088c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_088c:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str
	push rax
	push 1	; arg count
	mov rax, qword [free_var_127]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_079a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_079a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_079a
.L_lambda_simple_env_end_079a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_079a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_079a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_079a
.L_lambda_simple_params_end_079a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_079a
	jmp .L_lambda_simple_end_079a
.L_lambda_simple_code_079a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_088d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_088d:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_152]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_054f
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	jmp .L_if_end_05dd
.L_if_else_054f:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2135
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 6
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09a6:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09a6
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09a6
	.L_tc_recycle_frame_done_09a6:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_05dd:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_079a:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09a5:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09a5
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09a5
	.L_tc_recycle_frame_done_09a5:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0799:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0796:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_130], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_079b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_079b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_079b
.L_lambda_simple_env_end_079b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_079b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_079b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_079b
.L_lambda_simple_params_end_079b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_079b
	jmp .L_lambda_simple_end_079b
.L_lambda_simple_code_079b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_088e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_088e:
	enter 0, 0
	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +0)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +0)], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_079c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_079c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_079c
.L_lambda_simple_env_end_079c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_079c:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_079c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_079c
.L_lambda_simple_params_end_079c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_079c
	jmp .L_lambda_simple_end_079c
.L_lambda_simple_code_079c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_088f
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_088f:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param j
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0550
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param vec
	push rax
	push 2	; arg count
	mov rax, qword [free_var_144]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_079d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_079d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_079d
.L_lambda_simple_env_end_079d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_079d:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_079d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_079d
.L_lambda_simple_params_end_079d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_079d
	jmp .L_lambda_simple_end_079d
.L_lambda_simple_code_079d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0890
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0890:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 2	; arg count
	mov rax, qword [free_var_144]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3	; arg count
	mov rax, qword [free_var_147]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a non-tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3	; arg count
	mov rax, qword [free_var_147]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 6
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09a8:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09a8
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09a8
	.L_tc_recycle_frame_done_09a8:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_079d:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09a7:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09a7
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09a7
	.L_tc_recycle_frame_done_09a7:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05de
.L_if_else_0550:
	mov rax, PARAM(0)	; param vec
.L_if_end_05de:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_079c:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_079e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_079e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_079e
.L_lambda_simple_env_end_079e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_079e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_079e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_079e
.L_lambda_simple_params_end_079e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_079e
	jmp .L_lambda_simple_end_079e
.L_lambda_simple_code_079e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0891
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0891:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param vec
	push rax
	push 1	; arg count
	mov rax, qword [free_var_143]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_079f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_079f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_079f
.L_lambda_simple_env_end_079f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_079f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_079f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_079f
.L_lambda_simple_params_end_079f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_079f
	jmp .L_lambda_simple_end_079f
.L_lambda_simple_code_079f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0892
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0892:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_152]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0551
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	jmp .L_if_end_05df
.L_if_else_0551:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2135
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 6
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09aa:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09aa
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09aa
	.L_tc_recycle_frame_done_09aa:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_05df:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_079f:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09a9:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09a9
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09a9
	.L_tc_recycle_frame_done_09a9:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_079e:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_079b:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_146], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_07a0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_07a0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_07a0
.L_lambda_simple_env_end_07a0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_07a0:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_07a0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_07a0
.L_lambda_simple_params_end_07a0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_07a0
	jmp .L_lambda_simple_end_07a0
.L_lambda_simple_code_07a0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0893
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0893:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_07a1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_07a1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_07a1
.L_lambda_simple_env_end_07a1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_07a1:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_07a1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_07a1
.L_lambda_simple_params_end_07a1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_07a1
	jmp .L_lambda_simple_end_07a1
.L_lambda_simple_code_07a1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0894
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0894:
	enter 0, 0
	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +0)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +0)], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_07a2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_07a2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_07a2
.L_lambda_simple_env_end_07a2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_07a2:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_07a2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_07a2
.L_lambda_simple_params_end_07a2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_07a2
	jmp .L_lambda_simple_end_07a2
.L_lambda_simple_code_07a2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0895
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0895:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0552
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 1]	; bound var thunk
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_79]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09ac:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09ac
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09ac
	.L_tc_recycle_frame_done_09ac:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05e0
.L_if_else_0552:
	mov rax, L_constants + 1
.L_if_end_05e0:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_07a2:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	; preparing a tail-call
	mov rax, L_constants + 2135
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09ad:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09ad
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09ad
	.L_tc_recycle_frame_done_09ad:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_07a1:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09ab:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09ab
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09ab
	.L_tc_recycle_frame_done_09ab:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_07a0:	; new closure is in rax
	mov qword [free_var_98], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_07a3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_07a3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_07a3
.L_lambda_simple_env_end_07a3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_07a3:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_07a3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_07a3
.L_lambda_simple_params_end_07a3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_07a3
	jmp .L_lambda_simple_end_07a3
.L_lambda_simple_code_07a3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0896
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0896:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_99]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_07a4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_07a4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_07a4
.L_lambda_simple_env_end_07a4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_07a4:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_07a4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_07a4
.L_lambda_simple_params_end_07a4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_07a4
	jmp .L_lambda_simple_end_07a4
.L_lambda_simple_code_07a4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0897
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0897:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_07a5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_07a5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_07a5
.L_lambda_simple_env_end_07a5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_07a5:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_07a5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_07a5
.L_lambda_simple_params_end_07a5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_07a5
	jmp .L_lambda_simple_end_07a5
.L_lambda_simple_code_07a5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0898
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0898:
	enter 0, 0
	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +0)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +0)], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_07a6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_07a6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_07a6
.L_lambda_simple_env_end_07a6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_07a6:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_07a6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_07a6
.L_lambda_simple_params_end_07a6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_07a6
	jmp .L_lambda_simple_end_07a6
.L_lambda_simple_code_07a6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0899
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0899:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0553
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 1]	; bound var thunk
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3	; arg count
	mov rax, qword [free_var_131]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09b0:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09b0
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09b0
	.L_tc_recycle_frame_done_09b0:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05e1
.L_if_else_0553:
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var str
.L_if_end_05e1:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_07a6:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	; preparing a tail-call
	mov rax, L_constants + 2135
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09b1:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09b1
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09b1
	.L_tc_recycle_frame_done_09b1:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_07a5:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09af:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09af
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09af
	.L_tc_recycle_frame_done_09af:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_07a4:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09ae:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09ae
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09ae
	.L_tc_recycle_frame_done_09ae:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_07a3:	; new closure is in rax
	mov qword [free_var_100], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_07a7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_07a7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_07a7
.L_lambda_simple_env_end_07a7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_07a7:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_07a7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_07a7
.L_lambda_simple_params_end_07a7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_07a7
	jmp .L_lambda_simple_end_07a7
.L_lambda_simple_code_07a7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_089a
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_089a:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_101]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_07a8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_07a8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_07a8
.L_lambda_simple_env_end_07a8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_07a8:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_07a8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_07a8
.L_lambda_simple_params_end_07a8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_07a8
	jmp .L_lambda_simple_end_07a8
.L_lambda_simple_code_07a8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_089b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_089b:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_07a9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_07a9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_07a9
.L_lambda_simple_env_end_07a9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_07a9:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_07a9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_07a9
.L_lambda_simple_params_end_07a9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_07a9
	jmp .L_lambda_simple_end_07a9
.L_lambda_simple_code_07a9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_089c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_089c:
	enter 0, 0
	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +0)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +0)], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_07aa:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_07aa
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_07aa
.L_lambda_simple_env_end_07aa:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_07aa:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_07aa
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_07aa
.L_lambda_simple_params_end_07aa:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_07aa
	jmp .L_lambda_simple_end_07aa
.L_lambda_simple_code_07aa:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_089d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_089d:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0554
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 1]	; bound var thunk
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3	; arg count
	mov rax, qword [free_var_147]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09b4:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09b4
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09b4
	.L_tc_recycle_frame_done_09b4:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05e2
.L_if_else_0554:
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var vec
.L_if_end_05e2:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_07aa:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	; preparing a tail-call
	mov rax, L_constants + 2135
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09b5:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09b5
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09b5
	.L_tc_recycle_frame_done_09b5:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_07a9:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09b3:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09b3
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09b3
	.L_tc_recycle_frame_done_09b3:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_07a8:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09b2:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09b2
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09b2
	.L_tc_recycle_frame_done_09b2:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_07a7:	; new closure is in rax
	mov qword [free_var_102], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_07ab:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_07ab
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_07ab
.L_lambda_simple_env_end_07ab:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_07ab:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_07ab
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_07ab
.L_lambda_simple_params_end_07ab:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_07ab
	jmp .L_lambda_simple_end_07ab
.L_lambda_simple_code_07ab:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_089e
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_089e:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_152]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0557
	mov rax, L_constants + 3485
	jmp .L_if_end_05e5
.L_if_else_0557:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0556
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param n
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2	; arg count
	mov rax, qword [free_var_3]	; free var /
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 3	; arg count
	mov rax, qword [free_var_97]	; free var logarithm
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 3485
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09b6:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09b6
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09b6
	.L_tc_recycle_frame_done_09b6:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_05e4
.L_if_else_0556:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0555
	mov rax, L_constants + 3485
	jmp .L_if_end_05e3
.L_if_else_0555:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(2)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 3	; arg count
	mov rax, qword [free_var_97]	; free var logarithm
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 3485
	push rax
	push 2	; arg count
	mov rax, qword [free_var_3]	; free var /
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09b7:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09b7
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09b7
	.L_tc_recycle_frame_done_09b7:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_05e3:
.L_if_end_05e4:
.L_if_end_05e5:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_07ab:	; new closure is in rax
	mov qword [free_var_97], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_07ac:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_07ac
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_07ac
.L_lambda_simple_env_end_07ac:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_07ac:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_07ac
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_07ac
.L_lambda_simple_params_end_07ac:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_07ac
	jmp .L_lambda_simple_end_07ac
.L_lambda_simple_code_07ac:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_089f
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_089f:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 3510
	push rax
	push 1	; arg count
	mov rax, qword [free_var_151]	; free var write-char
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 4
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09b8:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09b8
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09b8
	.L_tc_recycle_frame_done_09b8:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_07ac:	; new closure is in rax
	mov qword [free_var_105], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_07ad:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_07ad
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_07ad
.L_lambda_simple_env_end_07ad:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_07ad:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_07ad
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_07ad
.L_lambda_simple_params_end_07ad:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_07ad
	jmp .L_lambda_simple_end_07ad
.L_lambda_simple_code_07ad:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_08a0
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_08a0:
	enter 0, 0
	mov rax, L_constants + 0
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_07ad:	; new closure is in rax
	mov qword [free_var_149], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_07ae:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_07ae
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_07ae
.L_lambda_simple_env_end_07ae:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_07ae:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_07ae
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_07ae
.L_lambda_simple_params_end_07ae:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_07ae
	jmp .L_lambda_simple_end_07ae
.L_lambda_simple_code_07ae:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_08a1
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_08a1:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, PARAM(1)	; param f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09b9:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09b9
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09b9
	.L_tc_recycle_frame_done_09b9:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_07ae:	; new closure is in rax
	mov qword [free_var_150], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push 3	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_07af:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_07af
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_07af
.L_lambda_simple_env_end_07af:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_07af:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_07af
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_07af
.L_lambda_simple_params_end_07af:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_07af
	jmp .L_lambda_simple_end_07af
.L_lambda_simple_code_07af:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_08a2
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_08a2:
	enter 0, 0
	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +0)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +0)], rax
	mov rax, sob_void

	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +1)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +1)], rax
	mov rax, sob_void

	mov rdi, 8
	call malloc
	 mov rbx, qword [rbp + 8 * (4 +2)]
	mov qword [rax], rbx
	mov qword [rbp + 8 * (4 +2)], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_07b0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_07b0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_07b0
.L_lambda_simple_env_end_07b0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_07b0:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_07b0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_07b0
.L_lambda_simple_params_end_07b0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_07b0
	jmp .L_lambda_simple_end_07b0
.L_lambda_simple_code_07b0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_08a3
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_08a3:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_152]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0558
	mov rax, PARAM(1)	; param r
	jmp .L_if_end_05e6
.L_if_else_0558:
	; preparing a tail-call
	mov rax, L_constants + 3574
	push rax
	mov rax, L_constants + 3552
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param r
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_0]	; free var *
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 4	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var fact-2
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 7
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09ba:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09ba
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09ba
	.L_tc_recycle_frame_done_09ba:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_05e6:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_07b0:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param fact-1
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_07b1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_07b1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_07b1
.L_lambda_simple_env_end_07b1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_07b1:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_07b1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_07b1
.L_lambda_simple_params_end_07b1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_07b1
	jmp .L_lambda_simple_end_07b1
.L_lambda_simple_code_07b1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 4
	je .L_lambda_simple_arity_check_ok_08a4
	push qword [rsp + 8 * 2]
	push 4
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_08a4:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_152]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0559
	mov rax, PARAM(1)	; param r
	jmp .L_if_end_05e7
.L_if_else_0559:
	; preparing a tail-call
	mov rax, L_constants + 3665
	push rax
	mov rax, L_constants + 3642
	push rax
	mov rax, L_constants + 3620
	push rax
	mov rax, L_constants + 3596
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param r
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_0]	; free var *
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 6	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var fact-3
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 9
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09bb:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09bb
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09bb
	.L_tc_recycle_frame_done_09bb:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_05e7:
	leave
	ret AND_KILL_FRAME(4)
.L_lambda_simple_end_07b1:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param fact-2
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_07b2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_07b2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_07b2
.L_lambda_simple_env_end_07b2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_07b2:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_07b2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_07b2
.L_lambda_simple_params_end_07b2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_07b2
	jmp .L_lambda_simple_end_07b2
.L_lambda_simple_code_07b2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 6
	je .L_lambda_simple_arity_check_ok_08a5
	push qword [rsp + 8 * 2]
	push 6
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_08a5:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_152]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_055a
	mov rax, PARAM(1)	; param r
	jmp .L_if_end_05e8
.L_if_else_055a:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param r
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_0]	; free var *
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var fact-1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09bc:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09bc
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09bc
	.L_tc_recycle_frame_done_09bc:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_05e8:
	leave
	ret AND_KILL_FRAME(6)
.L_lambda_simple_end_07b2:	; new closure is in rax
	push rax
	mov rax, PARAM(2)	; param fact-3
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_07b3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_07b3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_07b3
.L_lambda_simple_env_end_07b3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_07b3:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_07b3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_07b3
.L_lambda_simple_params_end_07b3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_07b3
	jmp .L_lambda_simple_end_07b3
.L_lambda_simple_code_07b3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_08a6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_08a6:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var fact-1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 *1]
	mov r8, rax
	mov rbx, COUNT
	add rbx,3
	shl rbx,3
	add rbx, rbp
	mov rbp, [rbp]
	mov rcx,0
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_09bd:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_09bd
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_09bd
	.L_tc_recycle_frame_done_09bd:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_07b3:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_07af:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_84], rax
	mov rax, sob_void
Lend:
	mov rdi, rax
	call print_sexpr_if_not_void

        mov rdi, fmt_memory_usage
        mov rsi, qword [top_of_memory]
        sub rsi, memory
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, 0
        call exit

L_error_fvar_undefined:
        push rax
        mov rdi, qword [stderr]  ; destination
        mov rsi, fmt_undefined_free_var_1
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        pop rax
        mov rax, qword [rax + 1] ; string
        lea rdi, [rax + 1 + 8]   ; actual characters
        mov rsi, 1               ; sizeof(char)
        mov rdx, qword [rax + 1] ; string-length
        mov rcx, qword [stderr]  ; destination
        mov rax, 0
        ENTER
        call fwrite
        LEAVE
        mov rdi, [stderr]       ; destination
        mov rsi, fmt_undefined_free_var_2
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -10
        call exit

L_error_non_closure:
        mov rdi, qword [stderr]
        mov rsi, fmt_non_closure
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -2
        call exit

L_error_improper_list:
	mov rdi, qword [stderr]
	mov rsi, fmt_error_improper_list
	mov rax, 0
        ENTER
	call fprintf
        LEAVE
	mov rax, -7
	call exit

L_error_incorrect_arity_simple:
        mov rdi, qword [stderr]
        mov rsi, fmt_incorrect_arity_simple
        jmp L_error_incorrect_arity_common
L_error_incorrect_arity_opt:
        mov rdi, qword [stderr]
        mov rsi, fmt_incorrect_arity_opt
L_error_incorrect_arity_common:
        pop rdx
        pop rcx
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -6
        call exit

section .data
fmt_undefined_free_var_1:
        db `!!! The free variable \0`
fmt_undefined_free_var_2:
        db ` was used before it was defined.\n\0`
fmt_incorrect_arity_simple:
        db `!!! Expected %ld arguments, but given %ld\n\0`
fmt_incorrect_arity_opt:
        db `!!! Expected at least %ld arguments, but given %ld\n\0`
fmt_memory_usage:
        db `\n!!! Used %ld bytes of dynamically-allocated memory\n\n\0`
fmt_non_closure:
        db `!!! Attempting to apply a non-closure!\n\0`
fmt_error_improper_list:
	db `!!! The argument is not a proper list!\n\0`

section .bss
memory:
	resb gbytes(1)

section .data
top_of_memory:
        dq memory

section .text
malloc:
        mov rax, qword [top_of_memory]
        add qword [top_of_memory], rdi
        ret

L_code_ptr_return:
	cmp qword [rsp + 8*2], 2
	jne L_error_arg_count_2
	mov rcx, qword [rsp + 8*3]
	assert_integer(rcx)
	mov rcx, qword [rcx + 1]
	cmp rcx, 0
	jl L_error_integer_range
	mov rax, qword [rsp + 8*4]
.L0:
        cmp rcx, 0
        je .L1
	mov rbp, qword [rbp]
	dec rcx
	jg .L0
.L1:
	mov rsp, rbp
	pop rbp
        pop rbx
        mov rcx, qword [rsp + 8*1]
        lea rsp, [rsp + 8*rcx + 8*2]
	jmp rbx

L_code_ptr_make_list:
	enter 0, 0
        cmp COUNT, 1
        je .L0
        cmp COUNT, 2
        je .L1
        jmp L_error_arg_count_12
.L0:
        mov r9, sob_void
        jmp .L2
.L1:
        mov r9, PARAM(1)
.L2:
        mov rcx, PARAM(0)
        assert_integer(rcx)
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl L_error_arg_negative
        mov r8, sob_nil
.L3:
        cmp rcx, 0
        jle .L4
        mov rdi, 1 + 8 + 8
        call malloc
        mov byte [rax], T_pair
        mov qword [rax + 1], r9
        mov qword [rax + 1 + 8], r8
        mov r8, rax
        dec rcx
        jmp .L3
.L4:
        mov rax, r8
        cmp COUNT, 2
        je .L5
        leave
        ret AND_KILL_FRAME(1)
.L5:
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_is_primitive:
	enter 0, 0
	cmp COUNT, 1
	jne L_error_arg_count_1
	mov rax, PARAM(0)
	assert_closure(rax)
	cmp SOB_CLOSURE_ENV(rax), 0
	jne .L_false
	mov rax, sob_boolean_true
	jmp .L_end
.L_false:
	mov rax, sob_boolean_false
.L_end:
	leave
	ret AND_KILL_FRAME(1)

L_code_ptr_length:
	enter 0, 0
	cmp COUNT, 1
	jne L_error_arg_count_1
	mov rbx, PARAM(0)
	mov rdi, 0
.L:
	cmp byte [rbx], T_nil
	je .L_end
	assert_pair(rbx)
	mov rbx, SOB_PAIR_CDR(rbx)
	inc rdi
	jmp .L
.L_end:
	call make_integer
	leave
	ret AND_KILL_FRAME(1)

L_code_ptr_break:
        cmp qword [rsp + 8 * 2], 0
        jne L_error_arg_count_0
        int3
        mov rax, sob_void
        ret AND_KILL_FRAME(0)        

L_code_ptr_frame:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0

        mov rdi, fmt_frame
        mov rsi, qword [rbp]    ; old rbp
        mov rdx, qword [rsi + 8*1] ; ret addr
        mov rcx, qword [rsi + 8*2] ; lexical environment
        mov r8, qword [rsi + 8*3] ; count
        lea r9, [rsi + 8*4]       ; address of argument 0
        push 0
        push r9
        push r8                   ; we'll use it when printing the params
        mov rax, 0
        
        ENTER
        call printf
        LEAVE

.L:
        mov rcx, qword [rsp]
        cmp rcx, 0
        je .L_out
        mov rdi, fmt_frame_param_prefix
        mov rsi, qword [rsp + 8*2]
        mov rax, 0
        
        ENTER
        call printf
        LEAVE

        mov rcx, qword [rsp]
        dec rcx
        mov qword [rsp], rcx    ; dec arg count
        inc qword [rsp + 8*2]   ; increment index of current arg
        mov rdi, qword [rsp + 8*1] ; addr of addr current arg
        lea r9, [rdi + 8]          ; addr of next arg
        mov qword [rsp + 8*1], r9  ; backup addr of next arg
        mov rdi, qword [rdi]       ; addr of current arg
        call print_sexpr
        mov rdi, fmt_newline
        mov rax, 0
        ENTER
        call printf
        LEAVE
        jmp .L
.L_out:
        mov rdi, fmt_frame_continue
        mov rax, 0
        ENTER
        call printf
        call getchar
        LEAVE
        
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(0)
        
print_sexpr_if_not_void:
	cmp rdi, sob_void
	je .done
	call print_sexpr
	mov rdi, fmt_newline
	mov rax, 0
	ENTER
	call printf
	LEAVE
.done:
	ret

section .data
fmt_frame:
        db `RBP = %p; ret addr = %p; lex env = %p; param count = %d\n\0`
fmt_frame_param_prefix:
        db `==[param %d]==> \0`
fmt_frame_continue:
        db `Hit <Enter> to continue...\0`
fmt_newline:
	db `\n\0`
fmt_void:
	db `#<void>\0`
fmt_nil:
	db `()\0`
fmt_boolean_false:
	db `#f\0`
fmt_boolean_true:
	db `#t\0`
fmt_char_backslash:
	db `#\\\\\0`
fmt_char_dquote:
	db `#\\"\0`
fmt_char_simple:
	db `#\\%c\0`
fmt_char_null:
	db `#\\nul\0`
fmt_char_bell:
	db `#\\bell\0`
fmt_char_backspace:
	db `#\\backspace\0`
fmt_char_tab:
	db `#\\tab\0`
fmt_char_newline:
	db `#\\newline\0`
fmt_char_formfeed:
	db `#\\page\0`
fmt_char_return:
	db `#\\return\0`
fmt_char_escape:
	db `#\\esc\0`
fmt_char_space:
	db `#\\space\0`
fmt_char_hex:
	db `#\\x%02X\0`
fmt_gensym:
        db `G%ld\0`
fmt_closure:
	db `#<closure at 0x%08X env=0x%08X code=0x%08X>\0`
fmt_lparen:
	db `(\0`
fmt_dotted_pair:
	db ` . \0`
fmt_rparen:
	db `)\0`
fmt_space:
	db ` \0`
fmt_empty_vector:
	db `#()\0`
fmt_vector:
	db `#(\0`
fmt_real:
	db `%f\0`
fmt_fraction:
	db `%ld/%ld\0`
fmt_zero:
	db `0\0`
fmt_int:
	db `%ld\0`
fmt_unknown_scheme_object_error:
	db `\n\n!!! Error: Unknown Scheme-object (RTTI 0x%02X) `
	db `at address 0x%08X\n\n\0`
fmt_dquote:
	db `\"\0`
fmt_string_char:
        db `%c\0`
fmt_string_char_7:
        db `\\a\0`
fmt_string_char_8:
        db `\\b\0`
fmt_string_char_9:
        db `\\t\0`
fmt_string_char_10:
        db `\\n\0`
fmt_string_char_11:
        db `\\v\0`
fmt_string_char_12:
        db `\\f\0`
fmt_string_char_13:
        db `\\r\0`
fmt_string_char_34:
        db `\\"\0`
fmt_string_char_92:
        db `\\\\\0`
fmt_string_char_hex:
        db `\\x%X;\0`

section .text

print_sexpr:
	enter 0, 0
	mov al, byte [rdi]
	cmp al, T_void
	je .Lvoid
	cmp al, T_nil
	je .Lnil
	cmp al, T_boolean_false
	je .Lboolean_false
	cmp al, T_boolean_true
	je .Lboolean_true
	cmp al, T_char
	je .Lchar
	cmp al, T_interned_symbol
	je .Linterned_symbol
        cmp al, T_uninterned_symbol
        je .Luninterned_symbol
	cmp al, T_pair
	je .Lpair
	cmp al, T_vector
	je .Lvector
	cmp al, T_closure
	je .Lclosure
	cmp al, T_real
	je .Lreal
	cmp al, T_fraction
	je .Lfraction
	cmp al, T_integer
	je .Linteger
	cmp al, T_string
	je .Lstring

	jmp .Lunknown_sexpr_type

.Lvoid:
	mov rdi, fmt_void
	jmp .Lemit

.Lnil:
	mov rdi, fmt_nil
	jmp .Lemit

.Lboolean_false:
	mov rdi, fmt_boolean_false
	jmp .Lemit

.Lboolean_true:
	mov rdi, fmt_boolean_true
	jmp .Lemit

.Lchar:
	mov al, byte [rdi + 1]
	cmp al, ' '
	jle .Lchar_whitespace
	cmp al, 92 		; backslash
	je .Lchar_backslash
	cmp al, '"'
	je .Lchar_dquote
	and rax, 255
	mov rdi, fmt_char_simple
	mov rsi, rax
	jmp .Lemit

.Lchar_whitespace:
	cmp al, 0
	je .Lchar_null
	cmp al, 7
	je .Lchar_bell
	cmp al, 8
	je .Lchar_backspace
	cmp al, 9
	je .Lchar_tab
	cmp al, 10
	je .Lchar_newline
	cmp al, 12
	je .Lchar_formfeed
	cmp al, 13
	je .Lchar_return
	cmp al, 27
	je .Lchar_escape
	and rax, 255
	cmp al, ' '
	je .Lchar_space
	mov rdi, fmt_char_hex
	mov rsi, rax
	jmp .Lemit	

.Lchar_backslash:
	mov rdi, fmt_char_backslash
	jmp .Lemit

.Lchar_dquote:
	mov rdi, fmt_char_dquote
	jmp .Lemit

.Lchar_null:
	mov rdi, fmt_char_null
	jmp .Lemit

.Lchar_bell:
	mov rdi, fmt_char_bell
	jmp .Lemit

.Lchar_backspace:
	mov rdi, fmt_char_backspace
	jmp .Lemit

.Lchar_tab:
	mov rdi, fmt_char_tab
	jmp .Lemit

.Lchar_newline:
	mov rdi, fmt_char_newline
	jmp .Lemit

.Lchar_formfeed:
	mov rdi, fmt_char_formfeed
	jmp .Lemit

.Lchar_return:
	mov rdi, fmt_char_return
	jmp .Lemit

.Lchar_escape:
	mov rdi, fmt_char_escape
	jmp .Lemit

.Lchar_space:
	mov rdi, fmt_char_space
	jmp .Lemit

.Lclosure:
	mov rsi, qword rdi
	mov rdi, fmt_closure
	mov rdx, SOB_CLOSURE_ENV(rsi)
	mov rcx, SOB_CLOSURE_CODE(rsi)
	jmp .Lemit

.Linterned_symbol:
	mov rdi, qword [rdi + 1] ; sob_string
	mov rsi, 1		 ; size = 1 byte
	mov rdx, qword [rdi + 1] ; length
	lea rdi, [rdi + 1 + 8]	 ; actual characters
	mov rcx, qword [stdout]	 ; FILE *
	ENTER
	call fwrite
	LEAVE
	jmp .Lend

.Luninterned_symbol:
        mov rsi, qword [rdi + 1] ; gensym counter
        mov rdi, fmt_gensym
        jmp .Lemit
	
.Lpair:
	push rdi
	mov rdi, fmt_lparen
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rdi, qword [rsp] 	; pair
	mov rdi, SOB_PAIR_CAR(rdi)
	call print_sexpr
	pop rdi 		; pair
	mov rdi, SOB_PAIR_CDR(rdi)
.Lcdr:
	mov al, byte [rdi]
	cmp al, T_nil
	je .Lcdr_nil
	cmp al, T_pair
	je .Lcdr_pair
	push rdi
	mov rdi, fmt_dotted_pair
	mov rax, 0
        ENTER
	call printf
        LEAVE
	pop rdi
	call print_sexpr
	mov rdi, fmt_rparen
	mov rax, 0
        ENTER
	call printf
        LEAVE
	leave
	ret

.Lcdr_nil:
	mov rdi, fmt_rparen
	mov rax, 0
        ENTER
	call printf
        LEAVE
	leave
	ret

.Lcdr_pair:
	push rdi
	mov rdi, fmt_space
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rdi, qword [rsp]
	mov rdi, SOB_PAIR_CAR(rdi)
	call print_sexpr
	pop rdi
	mov rdi, SOB_PAIR_CDR(rdi)
	jmp .Lcdr

.Lvector:
	mov rax, qword [rdi + 1] ; length
	cmp rax, 0
	je .Lvector_empty
	push rdi
	mov rdi, fmt_vector
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rdi, qword [rsp]
	push qword [rdi + 1]
	push 1
	mov rdi, qword [rdi + 1 + 8] ; v[0]
	call print_sexpr
.Lvector_loop:
	; [rsp] index
	; [rsp + 8*1] limit
	; [rsp + 8*2] vector
	mov rax, qword [rsp]
	cmp rax, qword [rsp + 8*1]
	je .Lvector_end
	mov rdi, fmt_space
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rax, qword [rsp]
	mov rbx, qword [rsp + 8*2]
	mov rdi, qword [rbx + 1 + 8 + 8 * rax] ; v[i]
	call print_sexpr
	inc qword [rsp]
	jmp .Lvector_loop

.Lvector_end:
	add rsp, 8*3
	mov rdi, fmt_rparen
	jmp .Lemit	

.Lvector_empty:
	mov rdi, fmt_empty_vector
	jmp .Lemit

.Lreal:
	push qword [rdi + 1]
	movsd xmm0, qword [rsp]
	add rsp, 8*1
	mov rdi, fmt_real
	mov rax, 1
	ENTER
	call printf
	LEAVE
	jmp .Lend

.Lfraction:
	mov rsi, qword [rdi + 1]
	mov rdx, qword [rdi + 1 + 8]
	cmp rsi, 0
	je .Lrat_zero
	cmp rdx, 1
	je .Lrat_int
	mov rdi, fmt_fraction
	jmp .Lemit

.Lrat_zero:
	mov rdi, fmt_zero
	jmp .Lemit

.Lrat_int:
	mov rdi, fmt_int
	jmp .Lemit

.Linteger:
	mov rsi, qword [rdi + 1]
	mov rdi, fmt_int
	jmp .Lemit

.Lstring:
	lea rax, [rdi + 1 + 8]
	push rax
	push qword [rdi + 1]
	mov rdi, fmt_dquote
	mov rax, 0
	ENTER
	call printf
	LEAVE
.Lstring_loop:
	; qword [rsp]: limit
	; qword [rsp + 8*1]: char *
	cmp qword [rsp], 0
	je .Lstring_end
	mov rax, qword [rsp + 8*1]
	mov al, byte [rax]
	and rax, 255
	cmp al, 7
        je .Lstring_char_7
        cmp al, 8
        je .Lstring_char_8
        cmp al, 9
        je .Lstring_char_9
        cmp al, 10
        je .Lstring_char_10
        cmp al, 11
        je .Lstring_char_11
        cmp al, 12
        je .Lstring_char_12
        cmp al, 13
        je .Lstring_char_13
        cmp al, 34
        je .Lstring_char_34
        cmp al, 92              ; \
        je .Lstring_char_92
        cmp al, ' '
        jl .Lstring_char_hex
        mov rdi, fmt_string_char
        mov rsi, rax
.Lstring_char_emit:
        mov rax, 0
        ENTER
        call printf
        LEAVE
        dec qword [rsp]
        inc qword [rsp + 8*1]
        jmp .Lstring_loop

.Lstring_char_7:
        mov rdi, fmt_string_char_7
        jmp .Lstring_char_emit

.Lstring_char_8:
        mov rdi, fmt_string_char_8
        jmp .Lstring_char_emit
        
.Lstring_char_9:
        mov rdi, fmt_string_char_9
        jmp .Lstring_char_emit

.Lstring_char_10:
        mov rdi, fmt_string_char_10
        jmp .Lstring_char_emit

.Lstring_char_11:
        mov rdi, fmt_string_char_11
        jmp .Lstring_char_emit

.Lstring_char_12:
        mov rdi, fmt_string_char_12
        jmp .Lstring_char_emit

.Lstring_char_13:
        mov rdi, fmt_string_char_13
        jmp .Lstring_char_emit

.Lstring_char_34:
        mov rdi, fmt_string_char_34
        jmp .Lstring_char_emit

.Lstring_char_92:
        mov rdi, fmt_string_char_92
        jmp .Lstring_char_emit

.Lstring_char_hex:
        mov rdi, fmt_string_char_hex
        mov rsi, rax
        jmp .Lstring_char_emit        

.Lstring_end:
	add rsp, 8 * 2
	mov rdi, fmt_dquote
	jmp .Lemit

.Lunknown_sexpr_type:
	mov rsi, fmt_unknown_scheme_object_error
	and rax, 255
	mov rdx, rax
	mov rcx, rdi
	mov rdi, qword [stderr]
	mov rax, 0
        ENTER
	call fprintf
        LEAVE
        leave
        ret

.Lemit:
	mov rax, 0
        ENTER
	call printf
        LEAVE
	jmp .Lend

.Lend:
	LEAVE
	ret

;;; rdi: address of free variable
;;; rsi: address of code-pointer
bind_primitive:
        enter 0, 0
        push rdi
        mov rdi, (1 + 8 + 8)
        call malloc
        pop rdi
        mov byte [rax], T_closure
        mov SOB_CLOSURE_ENV(rax), 0 ; dummy, lexical environment
        mov SOB_CLOSURE_CODE(rax), rsi ; code pointer
        mov qword [rdi], rax
        mov rax, sob_void
        leave
        ret

L_code_ptr_ash:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, PARAM(0)
        assert_integer(rdi)
        mov rcx, PARAM(1)
        assert_integer(rcx)
        mov rdi, qword [rdi + 1]
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl .L_negative
.L_loop_positive:
        cmp rcx, 0
        je .L_exit
        sal rdi, cl
        shr rcx, 8
        jmp .L_loop_positive
.L_negative:
        neg rcx
.L_loop_negative:
        cmp rcx, 0
        je .L_exit
        sar rdi, cl
        shr rcx, 8
        jmp .L_loop_negative
.L_exit:
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_logand:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_integer(r8)
        mov r9, PARAM(1)
        assert_integer(r9)
        mov rdi, qword [r8 + 1]
        and rdi, qword [r9 + 1]
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_logor:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_integer(r8)
        mov r9, PARAM(1)
        assert_integer(r9)
        mov rdi, qword [r8 + 1]
        or rdi, qword [r9 + 1]
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_logxor:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_integer(r8)
        mov r9, PARAM(1)
        assert_integer(r9)
        mov rdi, qword [r8 + 1]
        xor rdi, qword [r9 + 1]
        call make_integer
        LEAVE
        ret AND_KILL_FRAME(2)

L_code_ptr_lognot:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        assert_integer(r8)
        mov rdi, qword [r8 + 1]
        not rdi
        call make_integer
        leave
        ret AND_KILL_FRAME(1)


L_code_ptr_bin_apply:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rax, PARAM(1) ; list
        mov rbx,0 ;list length count
.L_length_loop: ;this loop is to iterate through the list and count it's  (stop when encountering nil)
        cmp byte [rax], T_nil ;TODO: check if correct
        je .L_length_loop_exit
        assert_pair(rax)
        mov rax, SOB_PAIR_CDR(rax)
        add rbx,1
        jmp .L_length_loop
.L_length_loop_exit: ;1381
        mov rax, PARAM(1) ; list
        ;rbx contains list's length
        mov rcx, PARAM(0) ; PROC
        assert_closure(rcx)
        mov rdx, 0 ;i in (int i =0;i<list.length;i++)
        mov r8, RET_ADDR
        mov rbp, OLD_RBP
        mov rsp, rbp
.L_loop: ;loop to push list's to stack. not done with push because we need to invert it's order on stack.
        cmp rdx, rbx ; rdx=index, rbx=count
        je .L_loop_exit
        mov r9, rbx
        sub r9, rdx
        add r9, 1
        imul r9, -8
        add r9, rbp
        ;mov [rbp-8*(rbx - rdx + 1)], SOB_PAIR_CAR(rax)
        mov rdi, SOB_PAIR_CAR(rax)
        mov [r9], rdi
        ;;above line should push parameters in backward order (for list (1 2 3) should push 1 2 3 to stack)
        mov rax, SOB_PAIR_CDR(rax)
        add rdx, 1
        jmp .L_loop
.L_loop_exit:
        mov r9, rbx
        add r9,1
        imul r9, -8
        add r9,rbp
       ; mov rsp, rbp- 8 * (rbx + 1) ;fix stack pointer to include added parameters in loop.
        mov rsp, r9
        push rbx
        push SOB_CLOSURE_ENV(rcx)
        push r8
        jmp SOB_CLOSURE_CODE(rcx)


L_code_ptr_is_null:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_nil
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_pair:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_pair
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_is_void:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_void
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_char:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_char
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_string:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_string
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_symbol:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        and byte [r8], T_symbol
        jz .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_uninterned_symbol:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        cmp byte [r8], T_uninterned_symbol
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_interned_symbol:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_interned_symbol
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_gensym:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0
        inc qword [gensym_count]
        mov rdi, (1 + 8)
        call malloc
        mov byte [rax], T_uninterned_symbol
        mov rcx, qword [gensym_count]
        mov qword [rax + 1], rcx
        leave
        ret AND_KILL_FRAME(0)

L_code_ptr_is_vector:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_vector
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_closure:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_closure
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_real:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_real
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_fraction:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_fraction
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_boolean:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        and bl, T_boolean
        je .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_is_boolean_false:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        cmp bl, T_boolean_false
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_boolean_true:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        cmp bl, T_boolean_true
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_number:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        and bl, T_number
        jz .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_is_collection:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        and bl, T_collection
        je .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_cons:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, (1 + 8 + 8)
        call malloc
        mov byte [rax], T_pair
        mov rbx, PARAM(0)
        mov SOB_PAIR_CAR(rax), rbx
        mov rbx, PARAM(1)
        mov SOB_PAIR_CDR(rax), rbx
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_display_sexpr:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rdi, PARAM(0)
        call print_sexpr
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_write_char:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_char(rax)
        mov al, SOB_CHAR_VALUE(rax)
        and rax, 255
        mov rdi, fmt_char
        mov rsi, rax
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_car:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rax, SOB_PAIR_CAR(rax)
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_cdr:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rax, SOB_PAIR_CDR(rax)
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_string_length:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_string(rax)
        mov rdi, SOB_STRING_LENGTH(rax)
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_vector_length:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_vector(rax)
        mov rdi, SOB_VECTOR_LENGTH(rax)
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_real_to_integer:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rbx, PARAM(0)
        assert_real(rbx)
        movsd xmm0, qword [rbx + 1]
        cvttsd2si rdi, xmm0
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_exit:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0
        mov rax, 0
        call exit

L_code_ptr_integer_to_real:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_integer(rax)
        push qword [rax + 1]
        cvtsi2sd xmm0, qword [rsp]
        call make_real
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_fraction_to_real:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_fraction(rax)
        push qword [rax + 1]
        cvtsi2sd xmm0, qword [rsp]
        push qword [rax + 1 + 8]
        cvtsi2sd xmm1, qword [rsp]
        divsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_char_to_integer:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_char(rax)
        mov al, byte [rax + 1]
        and rax, 255
        mov rdi, rax
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_integer_to_fraction:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        assert_integer(r8)
        mov rdi, (1 + 8 + 8)
        call malloc
        mov rbx, qword [r8 + 1]
        mov byte [rax], T_fraction
        mov qword [rax + 1], rbx
        mov qword [rax + 1 + 8], 1
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_integer_to_char:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_integer(rax)
        mov rbx, qword [rax + 1]
        cmp rbx, 0
        jle L_error_integer_range
        cmp rbx, 256
        jge L_error_integer_range
        mov rdi, (1 + 1)
        call malloc
        mov byte [rax], T_char
        mov byte [rax + 1], bl
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_trng:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0
        rdrand rdi
        shr rdi, 1
        call make_integer
        leave
        ret AND_KILL_FRAME(0)

L_code_ptr_is_zero:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_integer
        je .L_integer
        cmp byte [rax], T_fraction
        je .L_fraction
        cmp byte [rax], T_real
        je .L_real
        jmp L_error_incorrect_type
.L_integer:
        cmp qword [rax + 1], 0
        je .L_zero
        jmp .L_not_zero
.L_fraction:
        cmp qword [rax + 1], 0
        je .L_zero
        jmp .L_not_zero
.L_real:
        pxor xmm0, xmm0
        push qword [rax + 1]
        movsd xmm1, qword [rsp]
        ucomisd xmm0, xmm1
        je .L_zero
.L_not_zero:
        mov rax, sob_boolean_false
        jmp .L_end
.L_zero:
        mov rax, sob_boolean_true
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_integer:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_integer
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_raw_bin_add_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        addsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_sub_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        subsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_mul_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        mulsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_div_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        pxor xmm2, xmm2
        ucomisd xmm1, xmm2
        je L_error_division_by_zero
        divsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_add_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	add rdi, qword [r9 + 1]
	call make_integer
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_add_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1 + 8] ; den 2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1]     ; num2
        cqo
        imul rbx
        add rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1 + 8] ; den2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_sub_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	sub rdi, qword [r9 + 1]
	call make_integer
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_sub_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1 + 8] ; den 2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1]     ; num2
        cqo
        imul rbx
        sub rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1 + 8] ; den2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_mul_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	cqo
	mov rax, qword [r8 + 1]
	mul qword [r9 + 1]
	mov rdi, rax
	call make_integer
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_mul_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1] ; num2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1 + 8] ; den2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_raw_bin_div_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r9 + 1]
	cmp rdi, 0
	je L_error_division_by_zero
	mov rsi, qword [r8 + 1]
	call normalize_fraction
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_div_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        cmp qword [r9 + 1], 0
        je L_error_division_by_zero
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1 + 8] ; den 2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1] ; num2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)
        
normalize_fraction:
        push rsi
        push rdi
        call gcd
        mov rbx, rax
        pop rax
        cqo
        idiv rbx
        mov r8, rax
        pop rax
        cqo
        idiv rbx
        mov r9, rax
        cmp r9, 0
        je .L_zero
        cmp r8, 1
        je .L_int
        mov rdi, (1 + 8 + 8)
        call malloc
        mov byte [rax], T_fraction
        mov qword [rax + 1], r9
        mov qword [rax + 1 + 8], r8
        ret
.L_zero:
        mov rdi, 0
        call make_integer
        ret
.L_int:
        mov rdi, r9
        call make_integer
        ret

iabs:
        mov rax, rdi
        cmp rax, 0
        jl .Lneg
        ret
.Lneg:
        neg rax
        ret

gcd:
        call iabs
        mov rbx, rax
        mov rdi, rsi
        call iabs
        cmp rax, 0
        jne .L0
        xchg rax, rbx
.L0:
        cmp rbx, 0
        je .L1
        cqo
        div rbx
        mov rax, rdx
        xchg rax, rbx
        jmp .L0
.L1:
        ret

L_code_ptr_error:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_interned_symbol(rsi)
        mov rsi, PARAM(1)
        assert_string(rsi)
        mov rdi, fmt_scheme_error_part_1
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rdi, PARAM(0)
        call print_sexpr
        mov rdi, fmt_scheme_error_part_2
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, PARAM(1)       ; sob_string
        mov rsi, 1              ; size = 1 byte
        mov rdx, qword [rax + 1] ; length
        lea rdi, [rax + 1 + 8]   ; actual characters
        mov rcx, qword [stdout]  ; FILE*
	ENTER
        call fwrite
	LEAVE
        mov rdi, fmt_scheme_error_part_3
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, -9
        call exit

L_code_ptr_raw_less_than_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_real(rsi)
        mov rdi, PARAM(1)
        assert_real(rdi)
        movsd xmm0, qword [rsi + 1]
        movsd xmm1, qword [rdi + 1]
        comisd xmm0, xmm1
        jae .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_raw_less_than_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	cmp rdi, qword [r9 + 1]
	jge .L_false
	mov rax, sob_boolean_true
	jmp .L_exit
.L_false:
	mov rax, sob_boolean_false
.L_exit:
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_less_than_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_fraction(rsi)
        mov rdi, PARAM(1)
        assert_fraction(rdi)
        mov rax, qword [rsi + 1] ; num1
        cqo
        imul qword [rdi + 1 + 8] ; den2
        mov rcx, rax
        mov rax, qword [rsi + 1 + 8] ; den1
        cqo
        imul qword [rdi + 1]          ; num2
        sub rcx, rax
        jge .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_equal_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_real(rsi)
        mov rdi, PARAM(1)
        assert_real(rdi)
        movsd xmm0, qword [rsi + 1]
        movsd xmm1, qword [rdi + 1]
        comisd xmm0, xmm1
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_raw_equal_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	cmp rdi, qword [r9 + 1]
	jne .L_false
	mov rax, sob_boolean_true
	jmp .L_exit
.L_false:
	mov rax, sob_boolean_false
.L_exit:
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_equal_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_fraction(rsi)
        mov rdi, PARAM(1)
        assert_fraction(rdi)
        mov rax, qword [rsi + 1] ; num1
        cqo
        imul qword [rdi + 1 + 8] ; den2
        mov rcx, rax
        mov rax, qword [rdi + 1 + 8] ; den1
        cqo
        imul qword [rdi + 1]          ; num2
        sub rcx, rax
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_quotient:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_integer(rsi)
        mov rdi, PARAM(1)
        assert_integer(rdi)
        mov rax, qword [rsi + 1]
        mov rbx, qword [rdi + 1]
        cmp rbx, 0
        je L_error_division_by_zero
        cqo
        idiv rbx
        mov rdi, rax
        call make_integer
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_remainder:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_integer(rsi)
        mov rdi, PARAM(1)
        assert_integer(rdi)
        mov rax, qword [rsi + 1]
        mov rbx, qword [rdi + 1]
        cmp rbx, 0
        je L_error_division_by_zero
        cqo
        idiv rbx
        mov rdi, rdx
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_set_car:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rbx, PARAM(1)
        mov SOB_PAIR_CAR(rax), rbx
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_set_cdr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rbx, PARAM(1)
        mov SOB_PAIR_CDR(rax), rbx
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_string_ref:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, PARAM(0)
        assert_string(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov bl, byte [rdi + 1 + 8 + 1 * rcx]
        mov rdi, 2
        call malloc
        mov byte [rax], T_char
        mov byte [rax + 1], bl
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_vector_ref:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, PARAM(0)
        assert_vector(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov rax, [rdi + 1 + 8 + 8 * rcx]
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_vector_set:
        enter 0, 0
        cmp COUNT, 3
        jne L_error_arg_count_3
        mov rdi, PARAM(0)
        assert_vector(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov rax, PARAM(2)
        mov qword [rdi + 1 + 8 + 8 * rcx], rax
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(3)

L_code_ptr_string_set:
        enter 0, 0
        cmp COUNT, 3
        jne L_error_arg_count_3
        mov rdi, PARAM(0)
        assert_string(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov rax, PARAM(2)
        assert_char(rax)
        mov al, byte [rax + 1]
        mov byte [rdi + 1 + 8 + 1 * rcx], al
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(3)

L_code_ptr_make_vector:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rcx, PARAM(0)
        assert_integer(rcx)
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl L_error_integer_range
        mov rdx, PARAM(1)
        lea rdi, [1 + 8 + 8 * rcx]
        call malloc
        mov byte [rax], T_vector
        mov qword [rax + 1], rcx
        mov r8, 0
.L0:
        cmp r8, rcx
        je .L1
        mov qword [rax + 1 + 8 + 8 * r8], rdx
        inc r8
        jmp .L0
.L1:
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_make_string:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rcx, PARAM(0)
        assert_integer(rcx)
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl L_error_integer_range
        mov rdx, PARAM(1)
        assert_char(rdx)
        mov dl, byte [rdx + 1]
        lea rdi, [1 + 8 + 1 * rcx]
        call malloc
        mov byte [rax], T_string
        mov qword [rax + 1], rcx
        mov r8, 0
.L0:
        cmp r8, rcx
        je .L1
        mov byte [rax + 1 + 8 + 1 * r8], dl
        inc r8
        jmp .L0
.L1:
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_numerator:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_fraction(rax)
        mov rdi, qword [rax + 1]
        call make_integer
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_denominator:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_fraction(rax)
        mov rdi, qword [rax + 1 + 8]
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_eq:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov rdi, PARAM(0)
	mov rsi, PARAM(1)
	cmp rdi, rsi
	je .L_eq_true
	mov dl, byte [rdi]
	cmp dl, byte [rsi]
	jne .L_eq_false
	cmp dl, T_char
	je .L_char
	cmp dl, T_interned_symbol
	je .L_interned_symbol
        cmp dl, T_uninterned_symbol
        je .L_uninterned_symbol
	cmp dl, T_real
	je .L_real
	cmp dl, T_fraction
	je .L_fraction
        cmp dl, T_integer
        je .L_integer
	jmp .L_eq_false
.L_integer:
        mov rax, qword [rsi + 1]
        cmp rax, qword [rdi + 1]
        jne .L_eq_false
        jmp .L_eq_true
.L_fraction:
	mov rax, qword [rsi + 1]
	cmp rax, qword [rdi + 1]
	jne .L_eq_false
	mov rax, qword [rsi + 1 + 8]
	cmp rax, qword [rdi + 1 + 8]
	jne .L_eq_false
	jmp .L_eq_true
.L_real:
	mov rax, qword [rsi + 1]
	cmp rax, qword [rdi + 1]
.L_interned_symbol:
	; never reached, because interned_symbols are static!
	; but I'm keeping it in case, I'll ever change
	; the implementation
	mov rax, qword [rsi + 1]
	cmp rax, qword [rdi + 1]
.L_uninterned_symbol:
        mov r8, qword [rdi + 1]
        cmp r8, qword [rsi + 1]
        jne .L_eq_false
        jmp .L_eq_true
.L_char:
	mov bl, byte [rsi + 1]
	cmp bl, byte [rdi + 1]
	jne .L_eq_false
.L_eq_true:
	mov rax, sob_boolean_true
	jmp .L_eq_exit
.L_eq_false:
	mov rax, sob_boolean_false
.L_eq_exit:
	leave
	ret AND_KILL_FRAME(2)

make_real:
        enter 0, 0
        mov rdi, (1 + 8)
        call malloc
        mov byte [rax], T_real
        movsd qword [rax + 1], xmm0
        leave 
        ret
        
make_integer:
        enter 0, 0
        mov rsi, rdi
        mov rdi, (1 + 8)
        call malloc
        mov byte [rax], T_integer
        mov qword [rax + 1], rsi
        leave
        ret
        
L_error_integer_range:
        mov rdi, qword [stderr]
        mov rsi, fmt_integer_range
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -5
        call exit

L_error_arg_negative:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_negative
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_0:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_0
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_1:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_1
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_2:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_2
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_12:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_12
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_3:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_3
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit
        
L_error_incorrect_type:
        mov rdi, qword [stderr]
        mov rsi, fmt_type
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -4
        call exit

L_error_division_by_zero:
        mov rdi, qword [stderr]
        mov rsi, fmt_division_by_zero
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -8
        call exit

section .data
gensym_count:
        dq 0
fmt_char:
        db `%c\0`
fmt_arg_negative:
        db `!!! The argument cannot be negative.\n\0`
fmt_arg_count_0:
        db `!!! Expecting zero arguments. Found %d\n\0`
fmt_arg_count_1:
        db `!!! Expecting one argument. Found %d\n\0`
fmt_arg_count_12:
        db `!!! Expecting one required and one optional argument. Found %d\n\0`
fmt_arg_count_2:
        db `!!! Expecting two arguments. Found %d\n\0`
fmt_arg_count_3:
        db `!!! Expecting three arguments. Found %d\n\0`
fmt_type:
        db `!!! Function passed incorrect type\n\0`
fmt_integer_range:
        db `!!! Incorrect integer range\n\0`
fmt_division_by_zero:
        db `!!! Division by zero\n\0`
fmt_scheme_error_part_1:
        db `\n!!! The procedure \0`
fmt_scheme_error_part_2:
        db ` asked to terminate the program\n`
        db `    with the following message:\n\n\0`
fmt_scheme_error_part_3:
        db `\n\nGoodbye!\n\n\0`
