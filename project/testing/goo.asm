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
	db T_string	; "test"
	dq 4
	db 0x74, 0x65, 0x73, 0x74
	; L_constants + 3538:
	db T_string	; "a"
	dq 1
	db 0x61
	; L_constants + 3548:
	db T_interned_symbol	; a
	dq L_constants + 3538
	; L_constants + 3557:
	db T_string	; "b"
	dq 1
	db 0x62
	; L_constants + 3567:
	db T_interned_symbol	; b
	dq L_constants + 3557
	; L_constants + 3576:
	db T_string	; "c"
	dq 1
	db 0x63
	; L_constants + 3586:
	db T_interned_symbol	; c
	dq L_constants + 3576
	; L_constants + 3595:
	db T_string	; "d"
	dq 1
	db 0x64
	; L_constants + 3605:
	db T_interned_symbol	; d
	dq L_constants + 3595
	; L_constants + 3614:
	db T_string	; "e"
	dq 1
	db 0x65
	; L_constants + 3624:
	db T_interned_symbol	; e
	dq L_constants + 3614
	; L_constants + 3633:
	db T_string	; "f"
	dq 1
	db 0x66
	; L_constants + 3643:
	db T_interned_symbol	; f
	dq L_constants + 3633
	; L_constants + 3652:
	db T_string	; "g"
	dq 1
	db 0x67
	; L_constants + 3662:
	db T_interned_symbol	; g
	dq L_constants + 3652
	; L_constants + 3671:
	db T_string	; "h"
	dq 1
	db 0x68
	; L_constants + 3681:
	db T_interned_symbol	; h
	dq L_constants + 3671
	; L_constants + 3690:
	db T_string	; "i"
	dq 1
	db 0x69
	; L_constants + 3700:
	db T_interned_symbol	; i
	dq L_constants + 3690
	; L_constants + 3709:
	db T_string	; "j"
	dq 1
	db 0x6A
	; L_constants + 3719:
	db T_interned_symbol	; j
	dq L_constants + 3709
	; L_constants + 3728:
	db T_pair	; (j)
	dq L_constants + 3719, L_constants + 1
	; L_constants + 3745:
	db T_pair	; (i j)
	dq L_constants + 3700, L_constants + 3728
	; L_constants + 3762:
	db T_pair	; (h i j)
	dq L_constants + 3681, L_constants + 3745
	; L_constants + 3779:
	db T_pair	; (g h i j)
	dq L_constants + 3662, L_constants + 3762
	; L_constants + 3796:
	db T_pair	; (f g h i j)
	dq L_constants + 3643, L_constants + 3779
	; L_constants + 3813:
	db T_pair	; (e f g h i j)
	dq L_constants + 3624, L_constants + 3796
	; L_constants + 3830:
	db T_pair	; (d e f g h i j)
	dq L_constants + 3605, L_constants + 3813
	; L_constants + 3847:
	db T_pair	; (c d e f g h i j)
	dq L_constants + 3586, L_constants + 3830
	; L_constants + 3864:
	db T_pair	; (b c d e f g h i j)
	dq L_constants + 3567, L_constants + 3847
	; L_constants + 3881:
	db T_pair	; (a b c d e f g h i j...
	dq L_constants + 3548, L_constants + 3864
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

free_var_139:	; location of test
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3525

free_var_140:	; location of trng
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 469

free_var_141:	; location of vector
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3089

free_var_142:	; location of vector->list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3104

free_var_143:	; location of vector-append
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3275

free_var_144:	; location of vector-length
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 323

free_var_145:	; location of vector-ref
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1037

free_var_146:	; location of vector-reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3320

free_var_147:	; location of vector-reverse!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3367

free_var_148:	; location of vector-set!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1056

free_var_149:	; location of vector?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 103

free_var_150:	; location of void
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3512

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
	mov rdi, free_var_149
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
	mov rdi, free_var_144
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
	mov rdi, free_var_140
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
	mov rdi, free_var_145
	mov rsi, L_code_ptr_vector_ref
	call bind_primitive

	; building closure for vector-set!
	mov rdi, free_var_148
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
.L_lambda_simple_env_loop_017d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_017d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_017d
.L_lambda_simple_env_end_017d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_017d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_017d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_017d
.L_lambda_simple_params_end_017d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_017d
	jmp .L_lambda_simple_end_017d
.L_lambda_simple_code_017d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01ad
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01ad:
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
	.L_tc_recycle_frame_loop_01e9:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_01e9
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_01e9
	.L_tc_recycle_frame_done_01e9:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_017d:	; new closure is in rax
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
.L_lambda_simple_env_loop_017e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_017e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_017e
.L_lambda_simple_env_end_017e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_017e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_017e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_017e
.L_lambda_simple_params_end_017e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_017e
	jmp .L_lambda_simple_end_017e
.L_lambda_simple_code_017e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01ae
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01ae:
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
	.L_tc_recycle_frame_loop_01ea:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_01ea
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_01ea
	.L_tc_recycle_frame_done_01ea:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_017e:	; new closure is in rax
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
.L_lambda_simple_env_loop_017f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_017f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_017f
.L_lambda_simple_env_end_017f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_017f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_017f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_017f
.L_lambda_simple_params_end_017f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_017f
	jmp .L_lambda_simple_end_017f
.L_lambda_simple_code_017f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01af
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01af:
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
	.L_tc_recycle_frame_loop_01eb:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_01eb
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_01eb
	.L_tc_recycle_frame_done_01eb:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_017f:	; new closure is in rax
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
.L_lambda_simple_env_loop_0180:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0180
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0180
.L_lambda_simple_env_end_0180:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0180:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0180
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0180
.L_lambda_simple_params_end_0180:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0180
	jmp .L_lambda_simple_end_0180
.L_lambda_simple_code_0180:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01b0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01b0:
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
	.L_tc_recycle_frame_loop_01ec:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_01ec
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_01ec
	.L_tc_recycle_frame_done_01ec:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0180:	; new closure is in rax
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
.L_lambda_simple_env_loop_0181:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0181
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0181
.L_lambda_simple_env_end_0181:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0181:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0181
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0181
.L_lambda_simple_params_end_0181:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0181
	jmp .L_lambda_simple_end_0181
.L_lambda_simple_code_0181:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01b1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01b1:
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
	.L_tc_recycle_frame_loop_01ed:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_01ed
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_01ed
	.L_tc_recycle_frame_done_01ed:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0181:	; new closure is in rax
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
.L_lambda_simple_env_loop_0182:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0182
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0182
.L_lambda_simple_env_end_0182:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0182:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0182
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0182
.L_lambda_simple_params_end_0182:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0182
	jmp .L_lambda_simple_end_0182
.L_lambda_simple_code_0182:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01b2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01b2:
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
	.L_tc_recycle_frame_loop_01ee:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_01ee
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_01ee
	.L_tc_recycle_frame_done_01ee:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0182:	; new closure is in rax
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
.L_lambda_simple_env_loop_0183:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0183
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0183
.L_lambda_simple_env_end_0183:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0183:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0183
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0183
.L_lambda_simple_params_end_0183:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0183
	jmp .L_lambda_simple_end_0183
.L_lambda_simple_code_0183:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01b3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01b3:
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
	.L_tc_recycle_frame_loop_01ef:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_01ef
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_01ef
	.L_tc_recycle_frame_done_01ef:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0183:	; new closure is in rax
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
.L_lambda_simple_env_loop_0184:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0184
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0184
.L_lambda_simple_env_end_0184:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0184:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0184
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0184
.L_lambda_simple_params_end_0184:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0184
	jmp .L_lambda_simple_end_0184
.L_lambda_simple_code_0184:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01b4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01b4:
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
	.L_tc_recycle_frame_loop_01f0:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_01f0
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_01f0
	.L_tc_recycle_frame_done_01f0:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0184:	; new closure is in rax
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
.L_lambda_simple_env_loop_0185:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0185
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0185
.L_lambda_simple_env_end_0185:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0185:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0185
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0185
.L_lambda_simple_params_end_0185:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0185
	jmp .L_lambda_simple_end_0185
.L_lambda_simple_code_0185:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01b5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01b5:
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
	.L_tc_recycle_frame_loop_01f1:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_01f1
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_01f1
	.L_tc_recycle_frame_done_01f1:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0185:	; new closure is in rax
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
.L_lambda_simple_env_loop_0186:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0186
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0186
.L_lambda_simple_env_end_0186:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0186:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0186
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0186
.L_lambda_simple_params_end_0186:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0186
	jmp .L_lambda_simple_end_0186
.L_lambda_simple_code_0186:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01b6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01b6:
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
	.L_tc_recycle_frame_loop_01f2:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_01f2
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_01f2
	.L_tc_recycle_frame_done_01f2:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0186:	; new closure is in rax
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
.L_lambda_simple_env_loop_0187:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0187
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0187
.L_lambda_simple_env_end_0187:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0187:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0187
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0187
.L_lambda_simple_params_end_0187:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0187
	jmp .L_lambda_simple_end_0187
.L_lambda_simple_code_0187:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01b7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01b7:
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
	.L_tc_recycle_frame_loop_01f3:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_01f3
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_01f3
	.L_tc_recycle_frame_done_01f3:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0187:	; new closure is in rax
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
.L_lambda_simple_env_loop_0188:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0188
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0188
.L_lambda_simple_env_end_0188:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0188:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0188
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0188
.L_lambda_simple_params_end_0188:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0188
	jmp .L_lambda_simple_end_0188
.L_lambda_simple_code_0188:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01b8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01b8:
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
	.L_tc_recycle_frame_loop_01f4:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_01f4
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_01f4
	.L_tc_recycle_frame_done_01f4:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0188:	; new closure is in rax
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
.L_lambda_simple_env_loop_0189:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0189
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0189
.L_lambda_simple_env_end_0189:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0189:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0189
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0189
.L_lambda_simple_params_end_0189:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0189
	jmp .L_lambda_simple_end_0189
.L_lambda_simple_code_0189:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01b9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01b9:
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
	.L_tc_recycle_frame_loop_01f5:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_01f5
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_01f5
	.L_tc_recycle_frame_done_01f5:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0189:	; new closure is in rax
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
.L_lambda_simple_env_loop_018a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_018a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_018a
.L_lambda_simple_env_end_018a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_018a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_018a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_018a
.L_lambda_simple_params_end_018a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_018a
	jmp .L_lambda_simple_end_018a
.L_lambda_simple_code_018a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01ba
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01ba:
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
	.L_tc_recycle_frame_loop_01f6:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_01f6
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_01f6
	.L_tc_recycle_frame_done_01f6:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_018a:	; new closure is in rax
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
.L_lambda_simple_env_loop_018b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_018b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_018b
.L_lambda_simple_env_end_018b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_018b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_018b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_018b
.L_lambda_simple_params_end_018b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_018b
	jmp .L_lambda_simple_end_018b
.L_lambda_simple_code_018b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01bb
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01bb:
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
	.L_tc_recycle_frame_loop_01f7:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_01f7
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_01f7
	.L_tc_recycle_frame_done_01f7:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_018b:	; new closure is in rax
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
.L_lambda_simple_env_loop_018c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_018c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_018c
.L_lambda_simple_env_end_018c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_018c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_018c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_018c
.L_lambda_simple_params_end_018c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_018c
	jmp .L_lambda_simple_end_018c
.L_lambda_simple_code_018c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01bc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01bc:
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
	.L_tc_recycle_frame_loop_01f8:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_01f8
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_01f8
	.L_tc_recycle_frame_done_01f8:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_018c:	; new closure is in rax
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
.L_lambda_simple_env_loop_018d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_018d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_018d
.L_lambda_simple_env_end_018d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_018d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_018d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_018d
.L_lambda_simple_params_end_018d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_018d
	jmp .L_lambda_simple_end_018d
.L_lambda_simple_code_018d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01bd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01bd:
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
	.L_tc_recycle_frame_loop_01f9:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_01f9
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_01f9
	.L_tc_recycle_frame_done_01f9:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_018d:	; new closure is in rax
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
.L_lambda_simple_env_loop_018e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_018e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_018e
.L_lambda_simple_env_end_018e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_018e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_018e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_018e
.L_lambda_simple_params_end_018e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_018e
	jmp .L_lambda_simple_end_018e
.L_lambda_simple_code_018e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01be
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01be:
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
	.L_tc_recycle_frame_loop_01fa:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_01fa
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_01fa
	.L_tc_recycle_frame_done_01fa:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_018e:	; new closure is in rax
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
.L_lambda_simple_env_loop_018f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_018f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_018f
.L_lambda_simple_env_end_018f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_018f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_018f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_018f
.L_lambda_simple_params_end_018f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_018f
	jmp .L_lambda_simple_end_018f
.L_lambda_simple_code_018f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01bf
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01bf:
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
	.L_tc_recycle_frame_loop_01fb:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_01fb
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_01fb
	.L_tc_recycle_frame_done_01fb:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_018f:	; new closure is in rax
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
.L_lambda_simple_env_loop_0190:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0190
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0190
.L_lambda_simple_env_end_0190:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0190:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0190
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0190
.L_lambda_simple_params_end_0190:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0190
	jmp .L_lambda_simple_end_0190
.L_lambda_simple_code_0190:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01c0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01c0:
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
	.L_tc_recycle_frame_loop_01fc:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_01fc
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_01fc
	.L_tc_recycle_frame_done_01fc:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0190:	; new closure is in rax
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
.L_lambda_simple_env_loop_0191:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0191
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0191
.L_lambda_simple_env_end_0191:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0191:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0191
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0191
.L_lambda_simple_params_end_0191:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0191
	jmp .L_lambda_simple_end_0191
.L_lambda_simple_code_0191:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01c1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01c1:
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
	.L_tc_recycle_frame_loop_01fd:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_01fd
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_01fd
	.L_tc_recycle_frame_done_01fd:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0191:	; new closure is in rax
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
.L_lambda_simple_env_loop_0192:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0192
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0192
.L_lambda_simple_env_end_0192:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0192:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0192
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0192
.L_lambda_simple_params_end_0192:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0192
	jmp .L_lambda_simple_end_0192
.L_lambda_simple_code_0192:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01c2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01c2:
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
	.L_tc_recycle_frame_loop_01fe:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_01fe
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_01fe
	.L_tc_recycle_frame_done_01fe:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0192:	; new closure is in rax
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
.L_lambda_simple_env_loop_0193:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0193
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0193
.L_lambda_simple_env_end_0193:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0193:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0193
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0193
.L_lambda_simple_params_end_0193:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0193
	jmp .L_lambda_simple_end_0193
.L_lambda_simple_code_0193:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01c3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01c3:
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
	.L_tc_recycle_frame_loop_01ff:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_01ff
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_01ff
	.L_tc_recycle_frame_done_01ff:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0193:	; new closure is in rax
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
.L_lambda_simple_env_loop_0194:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0194
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0194
.L_lambda_simple_env_end_0194:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0194:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0194
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0194
.L_lambda_simple_params_end_0194:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0194
	jmp .L_lambda_simple_end_0194
.L_lambda_simple_code_0194:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01c4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01c4:
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
	.L_tc_recycle_frame_loop_0200:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0200
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0200
	.L_tc_recycle_frame_done_0200:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0194:	; new closure is in rax
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
.L_lambda_simple_env_loop_0195:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0195
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0195
.L_lambda_simple_env_end_0195:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0195:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0195
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0195
.L_lambda_simple_params_end_0195:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0195
	jmp .L_lambda_simple_end_0195
.L_lambda_simple_code_0195:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01c5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01c5:
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
	.L_tc_recycle_frame_loop_0201:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0201
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0201
	.L_tc_recycle_frame_done_0201:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0195:	; new closure is in rax
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
.L_lambda_simple_env_loop_0196:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0196
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0196
.L_lambda_simple_env_end_0196:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0196:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0196
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0196
.L_lambda_simple_params_end_0196:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0196
	jmp .L_lambda_simple_end_0196
.L_lambda_simple_code_0196:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01c6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01c6:
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
	.L_tc_recycle_frame_loop_0202:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0202
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0202
	.L_tc_recycle_frame_done_0202:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0196:	; new closure is in rax
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
.L_lambda_simple_env_loop_0197:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0197
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0197
.L_lambda_simple_env_end_0197:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0197:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0197
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0197
.L_lambda_simple_params_end_0197:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0197
	jmp .L_lambda_simple_end_0197
.L_lambda_simple_code_0197:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01c7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01c7:
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
	.L_tc_recycle_frame_loop_0203:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0203
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0203
	.L_tc_recycle_frame_done_0203:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0197:	; new closure is in rax
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
.L_lambda_simple_env_loop_0198:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0198
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0198
.L_lambda_simple_env_end_0198:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0198:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0198
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0198
.L_lambda_simple_params_end_0198:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0198
	jmp .L_lambda_simple_end_0198
.L_lambda_simple_code_0198:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01c8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01c8:
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
	.L_tc_recycle_frame_loop_0204:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0204
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0204
	.L_tc_recycle_frame_done_0204:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0198:	; new closure is in rax
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
.L_lambda_simple_env_loop_0199:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0199
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0199
.L_lambda_simple_env_end_0199:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0199:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0199
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0199
.L_lambda_simple_params_end_0199:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0199
	jmp .L_lambda_simple_end_0199
.L_lambda_simple_code_0199:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01c9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01c9:
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
	jne .L_if_end_012d
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
	je .L_if_else_0111
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
	.L_tc_recycle_frame_loop_0205:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0205
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0205
	.L_tc_recycle_frame_done_0205:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_012e
.L_if_else_0111:
	mov rax, L_constants + 2
.L_if_end_012e:
	cmp rax, sob_boolean_false
	jne .L_if_end_012d
.L_if_end_012d:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0199:	; new closure is in rax
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
.L_lambda_opt_env_loop_0031:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 0
	je .L_lambda_opt_env_end_0031
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0031
.L_lambda_opt_env_end_0031:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0091:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_0061
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0091
.L_lambda_opt_params_end_0061:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0031
	jmp .L_lambda_opt_end_0061
.L_lambda_opt_code_0031:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	jge .L_lambda_simple_arity_check_ok_01ca
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01ca:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 0
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_0093
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_0092: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_0092
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0062
	.L_lambda_opt_params_loop_0093:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_0092: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_0092
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_0093:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0062
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_0093
	.L_lambda_opt_params_end_0062:
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
	.L_lambda_opt_end_0062:
	enter 0, 0
	mov rax, PARAM(0)	; param args
	LEAVE
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0061:
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
.L_lambda_simple_env_loop_019a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_019a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_019a
.L_lambda_simple_env_end_019a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_019a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_019a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_019a
.L_lambda_simple_params_end_019a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_019a
	jmp .L_lambda_simple_end_019a
.L_lambda_simple_code_019a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01cb
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01cb:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	cmp rax, sob_boolean_false
	je .L_if_else_0112
	mov rax, L_constants + 2
	jmp .L_if_end_012f
.L_if_else_0112:
	mov rax, L_constants + 3
.L_if_end_012f:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_019a:	; new closure is in rax
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
.L_lambda_simple_env_loop_019b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_019b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_019b
.L_lambda_simple_env_end_019b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_019b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_019b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_019b
.L_lambda_simple_params_end_019b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_019b
	jmp .L_lambda_simple_end_019b
.L_lambda_simple_code_019b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01cc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01cc:
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
	jne .L_if_end_0130
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
	.L_tc_recycle_frame_loop_0206:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0206
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0206
	.L_tc_recycle_frame_done_0206:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	cmp rax, sob_boolean_false
	jne .L_if_end_0130
.L_if_end_0130:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_019b:	; new closure is in rax
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
.L_lambda_simple_env_loop_019c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_019c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_019c
.L_lambda_simple_env_end_019c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_019c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_019c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_019c
.L_lambda_simple_params_end_019c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_019c
	jmp .L_lambda_simple_end_019c
.L_lambda_simple_code_019c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01cd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01cd:
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
.L_lambda_simple_env_loop_019d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_019d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_019d
.L_lambda_simple_env_end_019d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_019d:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_019d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_019d
.L_lambda_simple_params_end_019d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_019d
	jmp .L_lambda_simple_end_019d
.L_lambda_simple_code_019d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01ce
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01ce:
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
	je .L_if_else_0113
	mov rax, PARAM(0)	; param a
	jmp .L_if_end_0131
.L_if_else_0113:
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
	.L_tc_recycle_frame_loop_0207:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0207
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0207
	.L_tc_recycle_frame_done_0207:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0131:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_019d:	; new closure is in rax
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
.L_lambda_opt_env_loop_0032:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_0032
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0032
.L_lambda_opt_env_end_0032:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0094:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0063
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0094
.L_lambda_opt_params_end_0063:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0032
	jmp .L_lambda_opt_end_0063
.L_lambda_opt_code_0032:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_01cf
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01cf:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_0096
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_0095: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_0095
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0064
	.L_lambda_opt_params_loop_0096:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_0095: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_0095
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_0096:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0064
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_0096
	.L_lambda_opt_params_end_0064:
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
	.L_lambda_opt_end_0064:
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
	.L_tc_recycle_frame_loop_0208:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0208
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0208
	.L_tc_recycle_frame_done_0208:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0063:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_019c:	; new closure is in rax
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
.L_lambda_simple_env_loop_019e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_019e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_019e
.L_lambda_simple_env_end_019e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_019e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_019e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_019e
.L_lambda_simple_params_end_019e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_019e
	jmp .L_lambda_simple_end_019e
.L_lambda_simple_code_019e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01d0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01d0:
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
.L_lambda_simple_env_loop_019f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_019f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_019f
.L_lambda_simple_env_end_019f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_019f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_019f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_019f
.L_lambda_simple_params_end_019f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_019f
	jmp .L_lambda_simple_end_019f
.L_lambda_simple_code_019f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01d1
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01d1:
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
	je .L_if_else_0114
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
	.L_tc_recycle_frame_loop_0209:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0209
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0209
	.L_tc_recycle_frame_done_0209:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0132
.L_if_else_0114:
	mov rax, PARAM(0)	; param a
.L_if_end_0132:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_019f:	; new closure is in rax
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
.L_lambda_opt_env_loop_0033:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_0033
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0033
.L_lambda_opt_env_end_0033:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0097:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0065
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0097
.L_lambda_opt_params_end_0065:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0033
	jmp .L_lambda_opt_end_0065
.L_lambda_opt_code_0033:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_01d2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01d2:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_0099
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_0098: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_0098
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0066
	.L_lambda_opt_params_loop_0099:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_0098: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_0098
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_0099:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0066
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_0099
	.L_lambda_opt_params_end_0066:
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
	.L_lambda_opt_end_0066:
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
	.L_tc_recycle_frame_loop_020a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_020a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_020a
	.L_tc_recycle_frame_done_020a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0065:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_019e:	; new closure is in rax
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
.L_lambda_opt_env_loop_0034:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 0
	je .L_lambda_opt_env_end_0034
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0034
.L_lambda_opt_env_end_0034:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_009a:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_0067
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_009a
.L_lambda_opt_params_end_0067:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0034
	jmp .L_lambda_opt_end_0067
.L_lambda_opt_code_0034:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_01d3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01d3:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_009c
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_009b: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_009b
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0068
	.L_lambda_opt_params_loop_009c:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_009b: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_009b
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_009c:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0068
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_009c
	.L_lambda_opt_params_end_0068:
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
	.L_lambda_opt_end_0068:
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
.L_lambda_simple_env_loop_01a0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_01a0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01a0
.L_lambda_simple_env_end_01a0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01a0:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_01a0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01a0
.L_lambda_simple_params_end_01a0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01a0
	jmp .L_lambda_simple_end_01a0
.L_lambda_simple_code_01a0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01d4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01d4:
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
.L_lambda_simple_env_loop_01a1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_01a1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01a1
.L_lambda_simple_env_end_01a1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01a1:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01a1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01a1
.L_lambda_simple_params_end_01a1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01a1
	jmp .L_lambda_simple_end_01a1
.L_lambda_simple_code_01a1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01d5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01d5:
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
	je .L_if_else_0115
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
	jne .L_if_end_0133
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
	.L_tc_recycle_frame_loop_020c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_020c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_020c
	.L_tc_recycle_frame_done_020c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	cmp rax, sob_boolean_false
	jne .L_if_end_0133
.L_if_end_0133:
	jmp .L_if_end_0134
.L_if_else_0115:
	mov rax, L_constants + 2
.L_if_end_0134:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01a1:	; new closure is in rax
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
	je .L_if_else_0116
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
	.L_tc_recycle_frame_loop_020d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_020d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_020d
	.L_tc_recycle_frame_done_020d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0135
.L_if_else_0116:
	mov rax, L_constants + 2
.L_if_end_0135:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01a0:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_020b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_020b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_020b
	.L_tc_recycle_frame_done_020b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0067:
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
.L_lambda_opt_env_loop_0035:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 0
	je .L_lambda_opt_env_end_0035
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0035
.L_lambda_opt_env_end_0035:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_009d:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_0069
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_009d
.L_lambda_opt_params_end_0069:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0035
	jmp .L_lambda_opt_end_0069
.L_lambda_opt_code_0035:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_01d6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01d6:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_009f
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_009e: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_009e
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_006a
	.L_lambda_opt_params_loop_009f:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_009e: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_009e
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_009f:
	cmp rdx, 0
	je .L_lambda_opt_params_end_006a
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_009f
	.L_lambda_opt_params_end_006a:
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
	.L_lambda_opt_end_006a:
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
.L_lambda_simple_env_loop_01a2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_01a2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01a2
.L_lambda_simple_env_end_01a2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01a2:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_01a2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01a2
.L_lambda_simple_params_end_01a2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01a2
	jmp .L_lambda_simple_end_01a2
.L_lambda_simple_code_01a2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01d7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01d7:
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
.L_lambda_simple_env_loop_01a3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_01a3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01a3
.L_lambda_simple_env_end_01a3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01a3:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01a3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01a3
.L_lambda_simple_params_end_01a3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01a3
	jmp .L_lambda_simple_end_01a3
.L_lambda_simple_code_01a3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01d8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01d8:
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
	jne .L_if_end_0136
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
	je .L_if_else_0117
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
	.L_tc_recycle_frame_loop_020f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_020f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_020f
	.L_tc_recycle_frame_done_020f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0137
.L_if_else_0117:
	mov rax, L_constants + 2
.L_if_end_0137:
	cmp rax, sob_boolean_false
	jne .L_if_end_0136
.L_if_end_0136:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01a3:	; new closure is in rax
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
	jne .L_if_end_0138
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
	je .L_if_else_0118
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
	.L_tc_recycle_frame_loop_0210:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0210
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0210
	.L_tc_recycle_frame_done_0210:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0139
.L_if_else_0118:
	mov rax, L_constants + 2
.L_if_end_0139:
	cmp rax, sob_boolean_false
	jne .L_if_end_0138
.L_if_end_0138:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01a2:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_020e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_020e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_020e
	.L_tc_recycle_frame_done_020e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0069:
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
.L_lambda_simple_env_loop_01a4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01a4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01a4
.L_lambda_simple_env_end_01a4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01a4:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01a4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01a4
.L_lambda_simple_params_end_01a4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01a4
	jmp .L_lambda_simple_end_01a4
.L_lambda_simple_code_01a4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01d9
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01d9:
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
.L_lambda_simple_env_loop_01a5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_01a5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01a5
.L_lambda_simple_env_end_01a5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01a5:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_01a5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01a5
.L_lambda_simple_params_end_01a5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01a5
	jmp .L_lambda_simple_end_01a5
.L_lambda_simple_code_01a5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01da
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01da:
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
	je .L_if_else_0119
	mov rax, L_constants + 1
	jmp .L_if_end_013a
.L_if_else_0119:
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
	.L_tc_recycle_frame_loop_0211:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0211
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0211
	.L_tc_recycle_frame_done_0211:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_013a:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01a5:	; new closure is in rax
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
.L_lambda_simple_env_loop_01a6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_01a6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01a6
.L_lambda_simple_env_end_01a6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01a6:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_01a6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01a6
.L_lambda_simple_params_end_01a6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01a6
	jmp .L_lambda_simple_end_01a6
.L_lambda_simple_code_01a6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01db
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01db:
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
	je .L_if_else_011a
	mov rax, L_constants + 1
	jmp .L_if_end_013b
.L_if_else_011a:
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
	.L_tc_recycle_frame_loop_0212:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0212
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0212
	.L_tc_recycle_frame_done_0212:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_013b:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01a6:	; new closure is in rax
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
.L_lambda_opt_env_loop_0036:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_0036
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0036
.L_lambda_opt_env_end_0036:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00a0:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_006b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00a0
.L_lambda_opt_params_end_006b:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0036
	jmp .L_lambda_opt_end_006b
.L_lambda_opt_code_0036:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_01dc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01dc:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_00a2
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_00a1: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00a1
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_006c
	.L_lambda_opt_params_loop_00a2:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_00a1: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_00a1
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_00a2:
	cmp rdx, 0
	je .L_lambda_opt_params_end_006c
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00a2
	.L_lambda_opt_params_end_006c:
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
	.L_lambda_opt_end_006c:
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
	je .L_if_else_011b
	mov rax, L_constants + 1
	jmp .L_if_end_013c
.L_if_else_011b:
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
	.L_tc_recycle_frame_loop_0213:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0213
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0213
	.L_tc_recycle_frame_done_0213:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_013c:
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_006b:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01a4:	; new closure is in rax
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
.L_lambda_simple_env_loop_01a7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01a7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01a7
.L_lambda_simple_env_end_01a7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01a7:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01a7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01a7
.L_lambda_simple_params_end_01a7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01a7
	jmp .L_lambda_simple_end_01a7
.L_lambda_simple_code_01a7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01dd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01dd:
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
.L_lambda_simple_env_loop_01a8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_01a8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01a8
.L_lambda_simple_env_end_01a8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01a8:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01a8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01a8
.L_lambda_simple_params_end_01a8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01a8
	jmp .L_lambda_simple_end_01a8
.L_lambda_simple_code_01a8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01de
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01de:
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
	.L_tc_recycle_frame_loop_0215:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0215
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0215
	.L_tc_recycle_frame_done_0215:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01a8:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_0214:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0214
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0214
	.L_tc_recycle_frame_done_0214:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01a7:	; new closure is in rax
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
.L_lambda_simple_env_loop_01a9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01a9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01a9
.L_lambda_simple_env_end_01a9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01a9:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01a9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01a9
.L_lambda_simple_params_end_01a9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01a9
	jmp .L_lambda_simple_end_01a9
.L_lambda_simple_code_01a9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01df
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01df:
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
.L_lambda_simple_env_loop_01aa:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_01aa
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01aa
.L_lambda_simple_env_end_01aa:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01aa:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_01aa
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01aa
.L_lambda_simple_params_end_01aa:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01aa
	jmp .L_lambda_simple_end_01aa
.L_lambda_simple_code_01aa:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01e0
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01e0:
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
	je .L_if_else_011c
	mov rax, PARAM(0)	; param s1
	jmp .L_if_end_013d
.L_if_else_011c:
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
	.L_tc_recycle_frame_loop_0216:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0216
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0216
	.L_tc_recycle_frame_done_0216:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_013d:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01aa:	; new closure is in rax
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
.L_lambda_simple_env_loop_01ab:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_01ab
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01ab
.L_lambda_simple_env_end_01ab:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01ab:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_01ab
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01ab
.L_lambda_simple_params_end_01ab:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01ab
	jmp .L_lambda_simple_end_01ab
.L_lambda_simple_code_01ab:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01e1
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01e1:
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
	je .L_if_else_011d
	mov rax, PARAM(1)	; param s2
	jmp .L_if_end_013e
.L_if_else_011d:
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
	.L_tc_recycle_frame_loop_0217:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0217
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0217
	.L_tc_recycle_frame_done_0217:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_013e:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01ab:	; new closure is in rax
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
.L_lambda_opt_env_loop_0037:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_0037
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0037
.L_lambda_opt_env_end_0037:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00a3:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_006d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00a3
.L_lambda_opt_params_end_006d:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0037
	jmp .L_lambda_opt_end_006d
.L_lambda_opt_code_0037:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	jge .L_lambda_simple_arity_check_ok_01e2
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01e2:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 0
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_00a5
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_00a4: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00a4
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_006e
	.L_lambda_opt_params_loop_00a5:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_00a4: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_00a4
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_00a5:
	cmp rdx, 0
	je .L_lambda_opt_params_end_006e
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00a5
	.L_lambda_opt_params_end_006e:
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
	.L_lambda_opt_end_006e:
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
	je .L_if_else_011e
	mov rax, L_constants + 1
	jmp .L_if_end_013f
.L_if_else_011e:
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
	.L_tc_recycle_frame_loop_0218:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0218
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0218
	.L_tc_recycle_frame_done_0218:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_013f:
	LEAVE
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_006d:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01a9:	; new closure is in rax
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
.L_lambda_simple_env_loop_01ac:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01ac
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01ac
.L_lambda_simple_env_end_01ac:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01ac:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01ac
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01ac
.L_lambda_simple_params_end_01ac:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01ac
	jmp .L_lambda_simple_end_01ac
.L_lambda_simple_code_01ac:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01e3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01e3:
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
.L_lambda_simple_env_loop_01ad:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_01ad
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01ad
.L_lambda_simple_env_end_01ad:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01ad:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01ad
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01ad
.L_lambda_simple_params_end_01ad:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01ad
	jmp .L_lambda_simple_end_01ad
.L_lambda_simple_code_01ad:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_01e4
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01e4:
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
	je .L_if_else_011f
	mov rax, PARAM(1)	; param unit
	jmp .L_if_end_0140
.L_if_else_011f:
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
	.L_tc_recycle_frame_loop_0219:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0219
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0219
	.L_tc_recycle_frame_done_0219:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0140:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_01ad:	; new closure is in rax
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
.L_lambda_opt_env_loop_0038:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_0038
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0038
.L_lambda_opt_env_end_0038:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00a6:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_006f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00a6
.L_lambda_opt_params_end_006f:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0038
	jmp .L_lambda_opt_end_006f
.L_lambda_opt_code_0038:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 2
	jge .L_lambda_simple_arity_check_ok_01e5
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01e5:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 2
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_00a8
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_00a7: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00a7
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0070
	.L_lambda_opt_params_loop_00a8:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_00a7: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_00a7
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_00a8:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0070
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00a8
	.L_lambda_opt_params_end_0070:
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
	.L_lambda_opt_end_0070:
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
	.L_tc_recycle_frame_loop_021a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_021a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_021a
	.L_tc_recycle_frame_done_021a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(3)
.L_lambda_opt_end_006f:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01ac:	; new closure is in rax
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
.L_lambda_simple_env_loop_01ae:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01ae
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01ae
.L_lambda_simple_env_end_01ae:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01ae:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01ae
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01ae
.L_lambda_simple_params_end_01ae:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01ae
	jmp .L_lambda_simple_end_01ae
.L_lambda_simple_code_01ae:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01e6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01e6:
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
.L_lambda_simple_env_loop_01af:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_01af
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01af
.L_lambda_simple_env_end_01af:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01af:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01af
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01af
.L_lambda_simple_params_end_01af:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01af
	jmp .L_lambda_simple_end_01af
.L_lambda_simple_code_01af:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_01e7
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01e7:
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
	je .L_if_else_0120
	mov rax, PARAM(1)	; param unit
	jmp .L_if_end_0141
.L_if_else_0120:
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
	.L_tc_recycle_frame_loop_021b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_021b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_021b
	.L_tc_recycle_frame_done_021b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0141:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_01af:	; new closure is in rax
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
.L_lambda_opt_env_loop_0039:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_0039
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0039
.L_lambda_opt_env_end_0039:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00a9:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0071
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00a9
.L_lambda_opt_params_end_0071:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0039
	jmp .L_lambda_opt_end_0071
.L_lambda_opt_code_0039:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 2
	jge .L_lambda_simple_arity_check_ok_01e8
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01e8:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 2
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_00ab
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_00aa: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00aa
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0072
	.L_lambda_opt_params_loop_00ab:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_00aa: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_00aa
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_00ab:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0072
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00ab
	.L_lambda_opt_params_end_0072:
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
	.L_lambda_opt_end_0072:
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
	.L_tc_recycle_frame_loop_021c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_021c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_021c
	.L_tc_recycle_frame_done_021c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(3)
.L_lambda_opt_end_0071:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01ae:	; new closure is in rax
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
.L_lambda_simple_env_loop_01b0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01b0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01b0
.L_lambda_simple_env_end_01b0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01b0:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01b0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01b0
.L_lambda_simple_params_end_01b0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01b0
	jmp .L_lambda_simple_end_01b0
.L_lambda_simple_code_01b0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_01e9
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01e9:
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
	.L_tc_recycle_frame_loop_021d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_021d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_021d
	.L_tc_recycle_frame_done_021d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_01b0:	; new closure is in rax
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
.L_lambda_simple_env_loop_01b1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01b1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01b1
.L_lambda_simple_env_end_01b1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01b1:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01b1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01b1
.L_lambda_simple_params_end_01b1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01b1
	jmp .L_lambda_simple_end_01b1
.L_lambda_simple_code_01b1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01ea
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01ea:
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
.L_lambda_simple_env_loop_01b2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_01b2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01b2
.L_lambda_simple_env_end_01b2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01b2:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01b2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01b2
.L_lambda_simple_params_end_01b2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01b2
	jmp .L_lambda_simple_end_01b2
.L_lambda_simple_code_01b2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01eb
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01eb:
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
	je .L_if_else_012c
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
	je .L_if_else_0123
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
	.L_tc_recycle_frame_loop_021f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_021f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_021f
	.L_tc_recycle_frame_done_021f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0144
.L_if_else_0123:
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
	je .L_if_else_0122
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
	.L_tc_recycle_frame_loop_0220:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0220
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0220
	.L_tc_recycle_frame_done_0220:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0143
.L_if_else_0122:
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
	je .L_if_else_0121
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
	.L_tc_recycle_frame_loop_0221:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0221
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0221
	.L_tc_recycle_frame_done_0221:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0142
.L_if_else_0121:
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
	.L_tc_recycle_frame_loop_0222:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0222
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0222
	.L_tc_recycle_frame_done_0222:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0142:
.L_if_end_0143:
.L_if_end_0144:
	jmp .L_if_end_014d
.L_if_else_012c:
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
	je .L_if_else_012b
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
	je .L_if_else_0126
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
	.L_tc_recycle_frame_loop_0223:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0223
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0223
	.L_tc_recycle_frame_done_0223:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0147
.L_if_else_0126:
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
	je .L_if_else_0125
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
	.L_tc_recycle_frame_loop_0224:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0224
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0224
	.L_tc_recycle_frame_done_0224:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0146
.L_if_else_0125:
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
	je .L_if_else_0124
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
	.L_tc_recycle_frame_loop_0225:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0225
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0225
	.L_tc_recycle_frame_done_0225:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0145
.L_if_else_0124:
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
	.L_tc_recycle_frame_loop_0226:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0226
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0226
	.L_tc_recycle_frame_done_0226:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0145:
.L_if_end_0146:
.L_if_end_0147:
	jmp .L_if_end_014c
.L_if_else_012b:
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
	je .L_if_else_012a
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
	je .L_if_else_0129
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
	.L_tc_recycle_frame_loop_0227:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0227
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0227
	.L_tc_recycle_frame_done_0227:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_014a
.L_if_else_0129:
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
	je .L_if_else_0128
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
	.L_tc_recycle_frame_loop_0228:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0228
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0228
	.L_tc_recycle_frame_done_0228:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0149
.L_if_else_0128:
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
	je .L_if_else_0127
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
	.L_tc_recycle_frame_loop_0229:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0229
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0229
	.L_tc_recycle_frame_done_0229:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0148
.L_if_else_0127:
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
	.L_tc_recycle_frame_loop_022a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_022a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_022a
	.L_tc_recycle_frame_done_022a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0148:
.L_if_end_0149:
.L_if_end_014a:
	jmp .L_if_end_014b
.L_if_else_012a:
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
	.L_tc_recycle_frame_loop_022b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_022b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_022b
	.L_tc_recycle_frame_done_022b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_014b:
.L_if_end_014c:
.L_if_end_014d:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01b2:	; new closure is in rax
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
.L_lambda_simple_env_loop_01b3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_01b3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01b3
.L_lambda_simple_env_end_01b3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01b3:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01b3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01b3
.L_lambda_simple_params_end_01b3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01b3
	jmp .L_lambda_simple_end_01b3
.L_lambda_simple_code_01b3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01ec
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01ec:
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
.L_lambda_opt_env_loop_003a:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 2
	je .L_lambda_opt_env_end_003a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_003a
.L_lambda_opt_env_end_003a:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00ac:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0073
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00ac
.L_lambda_opt_params_end_0073:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_003a
	jmp .L_lambda_opt_end_0073
.L_lambda_opt_code_003a:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	jge .L_lambda_simple_arity_check_ok_01ed
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01ed:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 0
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_00ae
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_00ad: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00ad
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0074
	.L_lambda_opt_params_loop_00ae:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_00ad: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_00ad
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_00ae:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0074
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00ae
	.L_lambda_opt_params_end_0074:
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
	.L_lambda_opt_end_0074:
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
	.L_tc_recycle_frame_loop_022c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_022c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_022c
	.L_tc_recycle_frame_done_022c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0073:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01b3:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_021e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_021e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_021e
	.L_tc_recycle_frame_done_021e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01b1:	; new closure is in rax
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
.L_lambda_simple_env_loop_01b4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01b4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01b4
.L_lambda_simple_env_end_01b4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01b4:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01b4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01b4
.L_lambda_simple_params_end_01b4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01b4
	jmp .L_lambda_simple_end_01b4
.L_lambda_simple_code_01b4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_01ee
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01ee:
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
	.L_tc_recycle_frame_loop_022d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_022d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_022d
	.L_tc_recycle_frame_done_022d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_01b4:	; new closure is in rax
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
.L_lambda_simple_env_loop_01b5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01b5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01b5
.L_lambda_simple_env_end_01b5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01b5:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01b5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01b5
.L_lambda_simple_params_end_01b5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01b5
	jmp .L_lambda_simple_end_01b5
.L_lambda_simple_code_01b5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01ef
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01ef:
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
.L_lambda_simple_env_loop_01b6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_01b6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01b6
.L_lambda_simple_env_end_01b6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01b6:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01b6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01b6
.L_lambda_simple_params_end_01b6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01b6
	jmp .L_lambda_simple_end_01b6
.L_lambda_simple_code_01b6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01f0
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01f0:
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
	je .L_if_else_0138
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
	je .L_if_else_012f
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
	.L_tc_recycle_frame_loop_022f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_022f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_022f
	.L_tc_recycle_frame_done_022f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0150
.L_if_else_012f:
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
	je .L_if_else_012e
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
	.L_tc_recycle_frame_loop_0230:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0230
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0230
	.L_tc_recycle_frame_done_0230:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_014f
.L_if_else_012e:
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
	je .L_if_else_012d
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
	.L_tc_recycle_frame_loop_0231:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0231
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0231
	.L_tc_recycle_frame_done_0231:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_014e
.L_if_else_012d:
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
	.L_tc_recycle_frame_loop_0232:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0232
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0232
	.L_tc_recycle_frame_done_0232:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_014e:
.L_if_end_014f:
.L_if_end_0150:
	jmp .L_if_end_0159
.L_if_else_0138:
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
	je .L_if_else_0137
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
	je .L_if_else_0132
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
	.L_tc_recycle_frame_loop_0233:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0233
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0233
	.L_tc_recycle_frame_done_0233:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0153
.L_if_else_0132:
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
	je .L_if_else_0131
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
	.L_tc_recycle_frame_loop_0234:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0234
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0234
	.L_tc_recycle_frame_done_0234:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0152
.L_if_else_0131:
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
	je .L_if_else_0130
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
	.L_tc_recycle_frame_loop_0235:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0235
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0235
	.L_tc_recycle_frame_done_0235:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0151
.L_if_else_0130:
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
	.L_tc_recycle_frame_loop_0236:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0236
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0236
	.L_tc_recycle_frame_done_0236:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0151:
.L_if_end_0152:
.L_if_end_0153:
	jmp .L_if_end_0158
.L_if_else_0137:
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
	je .L_if_else_0136
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
	je .L_if_else_0135
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
	.L_tc_recycle_frame_loop_0237:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0237
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0237
	.L_tc_recycle_frame_done_0237:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0156
.L_if_else_0135:
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
	je .L_if_else_0134
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
	.L_tc_recycle_frame_loop_0238:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0238
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0238
	.L_tc_recycle_frame_done_0238:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0155
.L_if_else_0134:
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
	je .L_if_else_0133
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
	.L_tc_recycle_frame_loop_0239:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0239
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0239
	.L_tc_recycle_frame_done_0239:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0154
.L_if_else_0133:
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
	.L_tc_recycle_frame_loop_023a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_023a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_023a
	.L_tc_recycle_frame_done_023a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0154:
.L_if_end_0155:
.L_if_end_0156:
	jmp .L_if_end_0157
.L_if_else_0136:
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
	.L_tc_recycle_frame_loop_023b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_023b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_023b
	.L_tc_recycle_frame_done_023b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0157:
.L_if_end_0158:
.L_if_end_0159:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01b6:	; new closure is in rax
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
.L_lambda_simple_env_loop_01b7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_01b7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01b7
.L_lambda_simple_env_end_01b7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01b7:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01b7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01b7
.L_lambda_simple_params_end_01b7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01b7
	jmp .L_lambda_simple_end_01b7
.L_lambda_simple_code_01b7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01f1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01f1:
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
.L_lambda_opt_env_loop_003b:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 2
	je .L_lambda_opt_env_end_003b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_003b
.L_lambda_opt_env_end_003b:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00af:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0075
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00af
.L_lambda_opt_params_end_0075:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_003b
	jmp .L_lambda_opt_end_0075
.L_lambda_opt_code_003b:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_01f2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01f2:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_00b1
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_00b0: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00b0
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0076
	.L_lambda_opt_params_loop_00b1:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_00b0: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_00b0
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_00b1:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0076
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00b1
	.L_lambda_opt_params_end_0076:
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
	.L_lambda_opt_end_0076:
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
	je .L_if_else_0139
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
	.L_tc_recycle_frame_loop_023c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_023c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_023c
	.L_tc_recycle_frame_done_023c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_015a
.L_if_else_0139:
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
.L_lambda_simple_env_loop_01b8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_01b8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01b8
.L_lambda_simple_env_end_01b8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01b8:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_01b8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01b8
.L_lambda_simple_params_end_01b8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01b8
	jmp .L_lambda_simple_end_01b8
.L_lambda_simple_code_01b8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01f3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01f3:
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
	.L_tc_recycle_frame_loop_023e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_023e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_023e
	.L_tc_recycle_frame_done_023e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01b8:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_023d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_023d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_023d
	.L_tc_recycle_frame_done_023d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_015a:
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0075:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01b7:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_022e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_022e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_022e
	.L_tc_recycle_frame_done_022e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01b5:	; new closure is in rax
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
.L_lambda_simple_env_loop_01b9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01b9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01b9
.L_lambda_simple_env_end_01b9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01b9:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01b9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01b9
.L_lambda_simple_params_end_01b9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01b9
	jmp .L_lambda_simple_end_01b9
.L_lambda_simple_code_01b9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_01f4
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01f4:
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
	.L_tc_recycle_frame_loop_023f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_023f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_023f
	.L_tc_recycle_frame_done_023f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_01b9:	; new closure is in rax
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
.L_lambda_simple_env_loop_01ba:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01ba
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01ba
.L_lambda_simple_env_end_01ba:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01ba:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01ba
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01ba
.L_lambda_simple_params_end_01ba:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01ba
	jmp .L_lambda_simple_end_01ba
.L_lambda_simple_code_01ba:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01f5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01f5:
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
.L_lambda_simple_env_loop_01bb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_01bb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01bb
.L_lambda_simple_env_end_01bb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01bb:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01bb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01bb
.L_lambda_simple_params_end_01bb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01bb
	jmp .L_lambda_simple_end_01bb
.L_lambda_simple_code_01bb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01f6
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01f6:
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
	je .L_if_else_0145
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
	je .L_if_else_013c
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
	.L_tc_recycle_frame_loop_0241:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0241
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0241
	.L_tc_recycle_frame_done_0241:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_015d
.L_if_else_013c:
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
	je .L_if_else_013b
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
	.L_tc_recycle_frame_loop_0242:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0242
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0242
	.L_tc_recycle_frame_done_0242:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_015c
.L_if_else_013b:
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
	je .L_if_else_013a
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
	.L_tc_recycle_frame_loop_0243:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0243
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0243
	.L_tc_recycle_frame_done_0243:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_015b
.L_if_else_013a:
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
	.L_tc_recycle_frame_loop_0244:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0244
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0244
	.L_tc_recycle_frame_done_0244:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_015b:
.L_if_end_015c:
.L_if_end_015d:
	jmp .L_if_end_0166
.L_if_else_0145:
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
	je .L_if_else_0144
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
	je .L_if_else_013f
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
	.L_tc_recycle_frame_loop_0245:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0245
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0245
	.L_tc_recycle_frame_done_0245:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0160
.L_if_else_013f:
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
	je .L_if_else_013e
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
	.L_tc_recycle_frame_loop_0246:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0246
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0246
	.L_tc_recycle_frame_done_0246:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_015f
.L_if_else_013e:
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
	je .L_if_else_013d
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
	.L_tc_recycle_frame_loop_0247:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0247
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0247
	.L_tc_recycle_frame_done_0247:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_015e
.L_if_else_013d:
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
	.L_tc_recycle_frame_loop_0248:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0248
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0248
	.L_tc_recycle_frame_done_0248:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_015e:
.L_if_end_015f:
.L_if_end_0160:
	jmp .L_if_end_0165
.L_if_else_0144:
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
	je .L_if_else_0143
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
	je .L_if_else_0142
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
	.L_tc_recycle_frame_loop_0249:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0249
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0249
	.L_tc_recycle_frame_done_0249:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0163
.L_if_else_0142:
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
	je .L_if_else_0141
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
	.L_tc_recycle_frame_loop_024a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_024a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_024a
	.L_tc_recycle_frame_done_024a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0162
.L_if_else_0141:
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
	je .L_if_else_0140
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
	.L_tc_recycle_frame_loop_024b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_024b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_024b
	.L_tc_recycle_frame_done_024b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0161
.L_if_else_0140:
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
	.L_tc_recycle_frame_loop_024c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_024c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_024c
	.L_tc_recycle_frame_done_024c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0161:
.L_if_end_0162:
.L_if_end_0163:
	jmp .L_if_end_0164
.L_if_else_0143:
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
	.L_tc_recycle_frame_loop_024d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_024d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_024d
	.L_tc_recycle_frame_done_024d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0164:
.L_if_end_0165:
.L_if_end_0166:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01bb:	; new closure is in rax
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
.L_lambda_simple_env_loop_01bc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_01bc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01bc
.L_lambda_simple_env_end_01bc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01bc:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01bc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01bc
.L_lambda_simple_params_end_01bc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01bc
	jmp .L_lambda_simple_end_01bc
.L_lambda_simple_code_01bc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01f7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01f7:
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
.L_lambda_opt_env_loop_003c:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 2
	je .L_lambda_opt_env_end_003c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_003c
.L_lambda_opt_env_end_003c:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00b2:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0077
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00b2
.L_lambda_opt_params_end_0077:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_003c
	jmp .L_lambda_opt_end_0077
.L_lambda_opt_code_003c:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	jge .L_lambda_simple_arity_check_ok_01f8
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01f8:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 0
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_00b4
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_00b3: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00b3
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0078
	.L_lambda_opt_params_loop_00b4:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_00b3: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_00b3
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_00b4:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0078
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00b4
	.L_lambda_opt_params_end_0078:
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
	.L_lambda_opt_end_0078:
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
	.L_tc_recycle_frame_loop_024e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_024e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_024e
	.L_tc_recycle_frame_done_024e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0077:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01bc:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_0240:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0240
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0240
	.L_tc_recycle_frame_done_0240:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01ba:	; new closure is in rax
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
.L_lambda_simple_env_loop_01bd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01bd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01bd
.L_lambda_simple_env_end_01bd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01bd:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01bd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01bd
.L_lambda_simple_params_end_01bd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01bd
	jmp .L_lambda_simple_end_01bd
.L_lambda_simple_code_01bd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_01f9
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01f9:
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
	.L_tc_recycle_frame_loop_024f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_024f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_024f
	.L_tc_recycle_frame_done_024f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_01bd:	; new closure is in rax
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
.L_lambda_simple_env_loop_01be:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01be
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01be
.L_lambda_simple_env_end_01be:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01be:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01be
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01be
.L_lambda_simple_params_end_01be:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01be
	jmp .L_lambda_simple_end_01be
.L_lambda_simple_code_01be:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01fa
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01fa:
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
.L_lambda_simple_env_loop_01bf:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_01bf
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01bf
.L_lambda_simple_env_end_01bf:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01bf:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01bf
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01bf
.L_lambda_simple_params_end_01bf:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01bf
	jmp .L_lambda_simple_end_01bf
.L_lambda_simple_code_01bf:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01fb
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01fb:
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
	je .L_if_else_0151
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
	je .L_if_else_0148
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
	.L_tc_recycle_frame_loop_0251:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0251
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0251
	.L_tc_recycle_frame_done_0251:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0169
.L_if_else_0148:
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
	je .L_if_else_0147
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
	.L_tc_recycle_frame_loop_0252:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0252
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0252
	.L_tc_recycle_frame_done_0252:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0168
.L_if_else_0147:
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
	je .L_if_else_0146
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
	.L_tc_recycle_frame_loop_0253:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0253
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0253
	.L_tc_recycle_frame_done_0253:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0167
.L_if_else_0146:
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
	.L_tc_recycle_frame_loop_0254:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0254
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0254
	.L_tc_recycle_frame_done_0254:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0167:
.L_if_end_0168:
.L_if_end_0169:
	jmp .L_if_end_0172
.L_if_else_0151:
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
	je .L_if_else_0150
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
	je .L_if_else_014b
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
	.L_tc_recycle_frame_loop_0255:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0255
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0255
	.L_tc_recycle_frame_done_0255:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_016c
.L_if_else_014b:
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
	je .L_if_else_014a
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
	.L_tc_recycle_frame_loop_0256:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0256
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0256
	.L_tc_recycle_frame_done_0256:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_016b
.L_if_else_014a:
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
	je .L_if_else_0149
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
	.L_tc_recycle_frame_loop_0257:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0257
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0257
	.L_tc_recycle_frame_done_0257:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_016a
.L_if_else_0149:
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
	.L_tc_recycle_frame_loop_0258:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0258
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0258
	.L_tc_recycle_frame_done_0258:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_016a:
.L_if_end_016b:
.L_if_end_016c:
	jmp .L_if_end_0171
.L_if_else_0150:
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
	je .L_if_else_014f
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
	je .L_if_else_014e
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
	.L_tc_recycle_frame_loop_0259:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0259
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0259
	.L_tc_recycle_frame_done_0259:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_016f
.L_if_else_014e:
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
	je .L_if_else_014d
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
	.L_tc_recycle_frame_loop_025a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_025a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_025a
	.L_tc_recycle_frame_done_025a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_016e
.L_if_else_014d:
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
	je .L_if_else_014c
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
	.L_tc_recycle_frame_loop_025b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_025b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_025b
	.L_tc_recycle_frame_done_025b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_016d
.L_if_else_014c:
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
	.L_tc_recycle_frame_loop_025c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_025c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_025c
	.L_tc_recycle_frame_done_025c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_016d:
.L_if_end_016e:
.L_if_end_016f:
	jmp .L_if_end_0170
.L_if_else_014f:
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
	.L_tc_recycle_frame_loop_025d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_025d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_025d
	.L_tc_recycle_frame_done_025d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0170:
.L_if_end_0171:
.L_if_end_0172:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01bf:	; new closure is in rax
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
.L_lambda_simple_env_loop_01c0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_01c0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01c0
.L_lambda_simple_env_end_01c0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01c0:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01c0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01c0
.L_lambda_simple_params_end_01c0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01c0
	jmp .L_lambda_simple_end_01c0
.L_lambda_simple_code_01c0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01fc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01fc:
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
.L_lambda_opt_env_loop_003d:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 2
	je .L_lambda_opt_env_end_003d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_003d
.L_lambda_opt_env_end_003d:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00b5:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0079
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00b5
.L_lambda_opt_params_end_0079:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_003d
	jmp .L_lambda_opt_end_0079
.L_lambda_opt_code_003d:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_01fd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01fd:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_00b7
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_00b6: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00b6
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_007a
	.L_lambda_opt_params_loop_00b7:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_00b6: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_00b6
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_00b7:
	cmp rdx, 0
	je .L_lambda_opt_params_end_007a
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00b7
	.L_lambda_opt_params_end_007a:
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
	.L_lambda_opt_end_007a:
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
	je .L_if_else_0152
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
	.L_tc_recycle_frame_loop_025e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_025e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_025e
	.L_tc_recycle_frame_done_025e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0173
.L_if_else_0152:
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
.L_lambda_simple_env_loop_01c1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_01c1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01c1
.L_lambda_simple_env_end_01c1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01c1:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_01c1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01c1
.L_lambda_simple_params_end_01c1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01c1
	jmp .L_lambda_simple_end_01c1
.L_lambda_simple_code_01c1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01fe
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01fe:
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
	.L_tc_recycle_frame_loop_0260:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0260
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0260
	.L_tc_recycle_frame_done_0260:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01c1:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_025f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_025f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_025f
	.L_tc_recycle_frame_done_025f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0173:
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0079:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01c0:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_0250:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0250
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0250
	.L_tc_recycle_frame_done_0250:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01be:	; new closure is in rax
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
.L_lambda_simple_env_loop_01c2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01c2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01c2
.L_lambda_simple_env_end_01c2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01c2:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01c2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01c2
.L_lambda_simple_params_end_01c2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01c2
	jmp .L_lambda_simple_end_01c2
.L_lambda_simple_code_01c2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01ff
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01ff:
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
	je .L_if_else_0153
	mov rax, L_constants + 2270
	jmp .L_if_end_0174
.L_if_else_0153:
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
	.L_tc_recycle_frame_loop_0261:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0261
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0261
	.L_tc_recycle_frame_done_0261:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0174:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01c2:	; new closure is in rax
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
.L_lambda_simple_env_loop_01c3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01c3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01c3
.L_lambda_simple_env_end_01c3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01c3:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01c3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01c3
.L_lambda_simple_params_end_01c3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01c3
	jmp .L_lambda_simple_end_01c3
.L_lambda_simple_code_01c3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0200
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0200:
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
	.L_tc_recycle_frame_loop_0262:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0262
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0262
	.L_tc_recycle_frame_done_0262:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_01c3:	; new closure is in rax
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
.L_lambda_simple_env_loop_01c4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01c4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01c4
.L_lambda_simple_env_end_01c4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01c4:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01c4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01c4
.L_lambda_simple_params_end_01c4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01c4
	jmp .L_lambda_simple_end_01c4
.L_lambda_simple_code_01c4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0201
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0201:
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
.L_lambda_simple_env_loop_01c5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_01c5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01c5
.L_lambda_simple_env_end_01c5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01c5:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01c5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01c5
.L_lambda_simple_params_end_01c5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01c5
	jmp .L_lambda_simple_end_01c5
.L_lambda_simple_code_01c5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0202
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0202:
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
.L_lambda_simple_env_loop_01c6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_01c6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01c6
.L_lambda_simple_env_end_01c6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01c6:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_01c6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01c6
.L_lambda_simple_params_end_01c6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01c6
	jmp .L_lambda_simple_end_01c6
.L_lambda_simple_code_01c6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0203
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0203:
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
	je .L_if_else_015f
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
	je .L_if_else_0156
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
	.L_tc_recycle_frame_loop_0264:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0264
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0264
	.L_tc_recycle_frame_done_0264:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0177
.L_if_else_0156:
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
	je .L_if_else_0155
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
	.L_tc_recycle_frame_loop_0265:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0265
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0265
	.L_tc_recycle_frame_done_0265:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0176
.L_if_else_0155:
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
	je .L_if_else_0154
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
	.L_tc_recycle_frame_loop_0266:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0266
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0266
	.L_tc_recycle_frame_done_0266:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0175
.L_if_else_0154:
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
	.L_tc_recycle_frame_loop_0267:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0267
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0267
	.L_tc_recycle_frame_done_0267:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0175:
.L_if_end_0176:
.L_if_end_0177:
	jmp .L_if_end_0180
.L_if_else_015f:
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
	je .L_if_else_015e
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
	je .L_if_else_0159
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
	.L_tc_recycle_frame_loop_0268:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0268
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0268
	.L_tc_recycle_frame_done_0268:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_017a
.L_if_else_0159:
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
	je .L_if_else_0158
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
	.L_tc_recycle_frame_loop_0269:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0269
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0269
	.L_tc_recycle_frame_done_0269:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0179
.L_if_else_0158:
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
	je .L_if_else_0157
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
	.L_tc_recycle_frame_loop_026a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_026a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_026a
	.L_tc_recycle_frame_done_026a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0178
.L_if_else_0157:
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
	.L_tc_recycle_frame_loop_026b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_026b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_026b
	.L_tc_recycle_frame_done_026b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0178:
.L_if_end_0179:
.L_if_end_017a:
	jmp .L_if_end_017f
.L_if_else_015e:
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
	je .L_if_else_015d
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
	je .L_if_else_015c
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
	.L_tc_recycle_frame_loop_026c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_026c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_026c
	.L_tc_recycle_frame_done_026c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_017d
.L_if_else_015c:
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
	je .L_if_else_015b
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
	.L_tc_recycle_frame_loop_026d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_026d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_026d
	.L_tc_recycle_frame_done_026d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_017c
.L_if_else_015b:
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
	je .L_if_else_015a
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
	.L_tc_recycle_frame_loop_026e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_026e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_026e
	.L_tc_recycle_frame_done_026e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_017b
.L_if_else_015a:
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
	.L_tc_recycle_frame_loop_026f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_026f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_026f
	.L_tc_recycle_frame_done_026f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_017b:
.L_if_end_017c:
.L_if_end_017d:
	jmp .L_if_end_017e
.L_if_else_015d:
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
	.L_tc_recycle_frame_loop_0270:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0270
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0270
	.L_tc_recycle_frame_done_0270:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_017e:
.L_if_end_017f:
.L_if_end_0180:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01c6:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_01c5:	; new closure is in rax
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
.L_lambda_simple_env_loop_01c7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_01c7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01c7
.L_lambda_simple_env_end_01c7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01c7:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01c7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01c7
.L_lambda_simple_params_end_01c7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01c7
	jmp .L_lambda_simple_end_01c7
.L_lambda_simple_code_01c7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0204
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0204:
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
.L_lambda_simple_env_loop_01c8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_01c8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01c8
.L_lambda_simple_env_end_01c8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01c8:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01c8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01c8
.L_lambda_simple_params_end_01c8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01c8
	jmp .L_lambda_simple_end_01c8
.L_lambda_simple_code_01c8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0205
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0205:
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
.L_lambda_simple_env_loop_01c9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_01c9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01c9
.L_lambda_simple_env_end_01c9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01c9:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01c9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01c9
.L_lambda_simple_params_end_01c9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01c9
	jmp .L_lambda_simple_end_01c9
.L_lambda_simple_code_01c9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0206
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0206:
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
.L_lambda_simple_env_loop_01ca:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_01ca
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01ca
.L_lambda_simple_env_end_01ca:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01ca:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01ca
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01ca
.L_lambda_simple_params_end_01ca:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01ca
	jmp .L_lambda_simple_end_01ca
.L_lambda_simple_code_01ca:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0207
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0207:
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
	.L_tc_recycle_frame_loop_0274:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0274
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0274
	.L_tc_recycle_frame_done_0274:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01ca:	; new closure is in rax
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
.L_lambda_simple_env_loop_01cb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_01cb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01cb
.L_lambda_simple_env_end_01cb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01cb:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01cb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01cb
.L_lambda_simple_params_end_01cb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01cb
	jmp .L_lambda_simple_end_01cb
.L_lambda_simple_code_01cb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0208
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0208:
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
.L_lambda_simple_env_loop_01cc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_01cc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01cc
.L_lambda_simple_env_end_01cc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01cc:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01cc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01cc
.L_lambda_simple_params_end_01cc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01cc
	jmp .L_lambda_simple_end_01cc
.L_lambda_simple_code_01cc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0209
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0209:
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
	.L_tc_recycle_frame_loop_0276:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0276
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0276
	.L_tc_recycle_frame_done_0276:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01cc:	; new closure is in rax
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
.L_lambda_simple_env_loop_01cd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_01cd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01cd
.L_lambda_simple_env_end_01cd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01cd:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01cd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01cd
.L_lambda_simple_params_end_01cd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01cd
	jmp .L_lambda_simple_end_01cd
.L_lambda_simple_code_01cd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_020a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_020a:
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
.L_lambda_simple_env_loop_01ce:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_01ce
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01ce
.L_lambda_simple_env_end_01ce:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01ce:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01ce
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01ce
.L_lambda_simple_params_end_01ce:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01ce
	jmp .L_lambda_simple_end_01ce
.L_lambda_simple_code_01ce:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_020b
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_020b:
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
	.L_tc_recycle_frame_loop_0278:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0278
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0278
	.L_tc_recycle_frame_done_0278:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01ce:	; new closure is in rax
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
.L_lambda_simple_env_loop_01cf:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_01cf
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01cf
.L_lambda_simple_env_end_01cf:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01cf:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01cf
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01cf
.L_lambda_simple_params_end_01cf:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01cf
	jmp .L_lambda_simple_end_01cf
.L_lambda_simple_code_01cf:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_020c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_020c:
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
.L_lambda_simple_env_loop_01d0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_01d0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01d0
.L_lambda_simple_env_end_01d0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01d0:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01d0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01d0
.L_lambda_simple_params_end_01d0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01d0
	jmp .L_lambda_simple_end_01d0
.L_lambda_simple_code_01d0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_020d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_020d:
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
.L_lambda_simple_env_loop_01d1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 8
	je .L_lambda_simple_env_end_01d1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01d1
.L_lambda_simple_env_end_01d1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01d1:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01d1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01d1
.L_lambda_simple_params_end_01d1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01d1
	jmp .L_lambda_simple_end_01d1
.L_lambda_simple_code_01d1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_020e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_020e:
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
.L_lambda_simple_env_loop_01d2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 9
	je .L_lambda_simple_env_end_01d2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01d2
.L_lambda_simple_env_end_01d2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01d2:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01d2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01d2
.L_lambda_simple_params_end_01d2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01d2
	jmp .L_lambda_simple_end_01d2
.L_lambda_simple_code_01d2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_020f
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_020f:
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
	jne .L_if_end_0181
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
	je .L_if_else_0160
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
	.L_tc_recycle_frame_loop_027b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_027b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_027b
	.L_tc_recycle_frame_done_027b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0182
.L_if_else_0160:
	mov rax, L_constants + 2
.L_if_end_0182:
	cmp rax, sob_boolean_false
	jne .L_if_end_0181
.L_if_end_0181:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01d2:	; new closure is in rax
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
.L_lambda_opt_env_loop_003e:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 9
	je .L_lambda_opt_env_end_003e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_003e
.L_lambda_opt_env_end_003e:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00b8:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_007b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00b8
.L_lambda_opt_params_end_007b:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_003e
	jmp .L_lambda_opt_end_007b
.L_lambda_opt_code_003e:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_0210
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0210:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_00ba
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_00b9: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00b9
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_007c
	.L_lambda_opt_params_loop_00ba:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_00b9: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_00b9
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_00ba:
	cmp rdx, 0
	je .L_lambda_opt_params_end_007c
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00ba
	.L_lambda_opt_params_end_007c:
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
	.L_lambda_opt_end_007c:
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
	.L_tc_recycle_frame_loop_027c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_027c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_027c
	.L_tc_recycle_frame_done_027c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_007b:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01d1:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_027a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_027a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_027a
	.L_tc_recycle_frame_done_027a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01d0:	; new closure is in rax
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
.L_lambda_simple_env_loop_01d3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_01d3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01d3
.L_lambda_simple_env_end_01d3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01d3:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01d3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01d3
.L_lambda_simple_params_end_01d3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01d3
	jmp .L_lambda_simple_end_01d3
.L_lambda_simple_code_01d3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0211
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0211:
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
.L_lambda_simple_end_01d3:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_0279:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0279
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0279
	.L_tc_recycle_frame_done_0279:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01cf:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_0277:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0277
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0277
	.L_tc_recycle_frame_done_0277:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01cd:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_0275:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0275
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0275
	.L_tc_recycle_frame_done_0275:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01cb:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_0273:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0273
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0273
	.L_tc_recycle_frame_done_0273:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01c9:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_0272:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0272
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0272
	.L_tc_recycle_frame_done_0272:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01c8:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_0271:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0271
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0271
	.L_tc_recycle_frame_done_0271:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01c7:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_0263:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0263
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0263
	.L_tc_recycle_frame_done_0263:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01c4:	; new closure is in rax
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
.L_lambda_simple_env_loop_01d4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01d4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01d4
.L_lambda_simple_env_end_01d4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01d4:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01d4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01d4
.L_lambda_simple_params_end_01d4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01d4
	jmp .L_lambda_simple_end_01d4
.L_lambda_simple_code_01d4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0212
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0212:
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
.L_lambda_opt_env_loop_003f:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_003f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_003f
.L_lambda_opt_env_end_003f:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00bb:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_007d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00bb
.L_lambda_opt_params_end_007d:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_003f
	jmp .L_lambda_opt_end_007d
.L_lambda_opt_code_003f:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	jge .L_lambda_simple_arity_check_ok_0213
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0213:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 0
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_00bd
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_00bc: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00bc
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_007e
	.L_lambda_opt_params_loop_00bd:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_00bc: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_00bc
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_00bd:
	cmp rdx, 0
	je .L_lambda_opt_params_end_007e
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00bd
	.L_lambda_opt_params_end_007e:
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
	.L_lambda_opt_end_007e:
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
	.L_tc_recycle_frame_loop_027d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_027d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_027d
	.L_tc_recycle_frame_done_027d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_007d:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01d4:	; new closure is in rax
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
.L_lambda_simple_env_loop_01d5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01d5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01d5
.L_lambda_simple_env_end_01d5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01d5:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01d5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01d5
.L_lambda_simple_params_end_01d5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01d5
	jmp .L_lambda_simple_end_01d5
.L_lambda_simple_code_01d5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0214
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0214:
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
.L_lambda_simple_end_01d5:	; new closure is in rax
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
.L_lambda_simple_env_loop_01d6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01d6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01d6
.L_lambda_simple_env_end_01d6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01d6:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01d6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01d6
.L_lambda_simple_params_end_01d6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01d6
	jmp .L_lambda_simple_end_01d6
.L_lambda_simple_code_01d6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0215
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0215:
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
.L_lambda_simple_env_loop_01d7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_01d7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01d7
.L_lambda_simple_env_end_01d7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01d7:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01d7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01d7
.L_lambda_simple_params_end_01d7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01d7
	jmp .L_lambda_simple_end_01d7
.L_lambda_simple_code_01d7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0216
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0216:
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
	je .L_if_else_0161
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
	.L_tc_recycle_frame_loop_027e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_027e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_027e
	.L_tc_recycle_frame_done_027e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0183
.L_if_else_0161:
	mov rax, PARAM(0)	; param ch
.L_if_end_0183:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01d7:	; new closure is in rax
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
.L_lambda_simple_env_loop_01d8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_01d8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01d8
.L_lambda_simple_env_end_01d8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01d8:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01d8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01d8
.L_lambda_simple_params_end_01d8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01d8
	jmp .L_lambda_simple_end_01d8
.L_lambda_simple_code_01d8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0217
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0217:
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
	je .L_if_else_0162
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
	.L_tc_recycle_frame_loop_027f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_027f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_027f
	.L_tc_recycle_frame_done_027f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0184
.L_if_else_0162:
	mov rax, PARAM(0)	; param ch
.L_if_end_0184:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01d8:	; new closure is in rax
	mov qword [free_var_72], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01d6:	; new closure is in rax
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
.L_lambda_simple_env_loop_01d9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01d9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01d9
.L_lambda_simple_env_end_01d9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01d9:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01d9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01d9
.L_lambda_simple_params_end_01d9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01d9
	jmp .L_lambda_simple_end_01d9
.L_lambda_simple_code_01d9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0218
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0218:
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
.L_lambda_opt_env_loop_0040:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_0040
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0040
.L_lambda_opt_env_end_0040:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00be:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_007f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00be
.L_lambda_opt_params_end_007f:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0040
	jmp .L_lambda_opt_end_007f
.L_lambda_opt_code_0040:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	jge .L_lambda_simple_arity_check_ok_0219
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0219:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 0
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_00c0
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_00bf: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00bf
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0080
	.L_lambda_opt_params_loop_00c0:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_00bf: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_00bf
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_00c0:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0080
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00c0
	.L_lambda_opt_params_end_0080:
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
	.L_lambda_opt_end_0080:
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
.L_lambda_simple_env_loop_01da:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_01da
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01da
.L_lambda_simple_env_end_01da:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01da:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01da
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01da
.L_lambda_simple_params_end_01da:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01da
	jmp .L_lambda_simple_end_01da
.L_lambda_simple_code_01da:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_021a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_021a:
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
	.L_tc_recycle_frame_loop_0281:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0281
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0281
	.L_tc_recycle_frame_done_0281:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01da:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_0280:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0280
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0280
	.L_tc_recycle_frame_done_0280:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_007f:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01d9:	; new closure is in rax
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
.L_lambda_simple_env_loop_01db:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01db
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01db
.L_lambda_simple_env_end_01db:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01db:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01db
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01db
.L_lambda_simple_params_end_01db:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01db
	jmp .L_lambda_simple_end_01db
.L_lambda_simple_code_01db:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_021b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_021b:
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
.L_lambda_simple_end_01db:	; new closure is in rax
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
.L_lambda_simple_env_loop_01dc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01dc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01dc
.L_lambda_simple_env_end_01dc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01dc:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01dc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01dc
.L_lambda_simple_params_end_01dc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01dc
	jmp .L_lambda_simple_end_01dc
.L_lambda_simple_code_01dc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_021c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_021c:
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
.L_lambda_simple_env_loop_01dd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_01dd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01dd
.L_lambda_simple_env_end_01dd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01dd:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01dd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01dd
.L_lambda_simple_params_end_01dd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01dd
	jmp .L_lambda_simple_end_01dd
.L_lambda_simple_code_01dd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_021d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_021d:
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
	.L_tc_recycle_frame_loop_0282:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0282
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0282
	.L_tc_recycle_frame_done_0282:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01dd:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01dc:	; new closure is in rax
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
.L_lambda_simple_env_loop_01de:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01de
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01de
.L_lambda_simple_env_end_01de:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01de:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01de
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01de
.L_lambda_simple_params_end_01de:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01de
	jmp .L_lambda_simple_end_01de
.L_lambda_simple_code_01de:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_021e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_021e:
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
.L_lambda_simple_end_01de:	; new closure is in rax
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
.L_lambda_simple_env_loop_01df:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01df
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01df
.L_lambda_simple_env_end_01df:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01df:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01df
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01df
.L_lambda_simple_params_end_01df:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01df
	jmp .L_lambda_simple_end_01df
.L_lambda_simple_code_01df:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_021f
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_021f:
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
.L_lambda_simple_env_loop_01e0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_01e0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01e0
.L_lambda_simple_env_end_01e0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01e0:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_01e0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01e0
.L_lambda_simple_params_end_01e0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01e0
	jmp .L_lambda_simple_end_01e0
.L_lambda_simple_code_01e0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0220
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0220:
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
.L_lambda_simple_env_loop_01e1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_01e1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01e1
.L_lambda_simple_env_end_01e1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01e1:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01e1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01e1
.L_lambda_simple_params_end_01e1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01e1
	jmp .L_lambda_simple_end_01e1
.L_lambda_simple_code_01e1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_0221
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0221:
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
	je .L_if_else_0163
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
	jmp .L_if_end_0186
.L_if_else_0163:
	mov rax, L_constants + 2
.L_if_end_0186:
	cmp rax, sob_boolean_false
	jne .L_if_end_0185
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
	je .L_if_else_0165
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
	jne .L_if_end_0187
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
	je .L_if_else_0164
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
	.L_tc_recycle_frame_loop_0284:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0284
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0284
	.L_tc_recycle_frame_done_0284:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0188
.L_if_else_0164:
	mov rax, L_constants + 2
.L_if_end_0188:
	cmp rax, sob_boolean_false
	jne .L_if_end_0187
.L_if_end_0187:
	jmp .L_if_end_0189
.L_if_else_0165:
	mov rax, L_constants + 2
.L_if_end_0189:
	cmp rax, sob_boolean_false
	jne .L_if_end_0185
.L_if_end_0185:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_01e1:	; new closure is in rax
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
.L_lambda_simple_env_loop_01e2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_01e2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01e2
.L_lambda_simple_env_end_01e2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01e2:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01e2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01e2
.L_lambda_simple_params_end_01e2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01e2
	jmp .L_lambda_simple_end_01e2
.L_lambda_simple_code_01e2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0222
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0222:
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
.L_lambda_simple_env_loop_01e3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_01e3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01e3
.L_lambda_simple_env_end_01e3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01e3:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_01e3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01e3
.L_lambda_simple_params_end_01e3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01e3
	jmp .L_lambda_simple_end_01e3
.L_lambda_simple_code_01e3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0223
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0223:
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
	je .L_if_else_0166
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
	.L_tc_recycle_frame_loop_0287:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0287
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0287
	.L_tc_recycle_frame_done_0287:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_018a
.L_if_else_0166:
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
	.L_tc_recycle_frame_loop_0288:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0288
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0288
	.L_tc_recycle_frame_done_0288:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_018a:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01e3:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_0286:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0286
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0286
	.L_tc_recycle_frame_done_0286:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01e2:	; new closure is in rax
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
.L_lambda_simple_env_loop_01e4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_01e4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01e4
.L_lambda_simple_env_end_01e4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01e4:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01e4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01e4
.L_lambda_simple_params_end_01e4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01e4
	jmp .L_lambda_simple_end_01e4
.L_lambda_simple_code_01e4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0224
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0224:
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
.L_lambda_simple_env_loop_01e5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_01e5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01e5
.L_lambda_simple_env_end_01e5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01e5:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01e5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01e5
.L_lambda_simple_params_end_01e5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01e5
	jmp .L_lambda_simple_end_01e5
.L_lambda_simple_code_01e5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0225
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0225:
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
.L_lambda_simple_env_loop_01e6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_01e6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01e6
.L_lambda_simple_env_end_01e6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01e6:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01e6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01e6
.L_lambda_simple_params_end_01e6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01e6
	jmp .L_lambda_simple_end_01e6
.L_lambda_simple_code_01e6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0226
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0226:
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
	jne .L_if_end_018b
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
	je .L_if_else_0167
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
	.L_tc_recycle_frame_loop_028a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_028a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_028a
	.L_tc_recycle_frame_done_028a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_018c
.L_if_else_0167:
	mov rax, L_constants + 2
.L_if_end_018c:
	cmp rax, sob_boolean_false
	jne .L_if_end_018b
.L_if_end_018b:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01e6:	; new closure is in rax
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
.L_lambda_opt_env_loop_0041:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 4
	je .L_lambda_opt_env_end_0041
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0041
.L_lambda_opt_env_end_0041:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00c1:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0081
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00c1
.L_lambda_opt_params_end_0081:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0041
	jmp .L_lambda_opt_end_0081
.L_lambda_opt_code_0041:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_0227
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0227:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_00c3
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_00c2: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00c2
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0082
	.L_lambda_opt_params_loop_00c3:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_00c2: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_00c2
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_00c3:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0082
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00c3
	.L_lambda_opt_params_end_0082:
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
	.L_lambda_opt_end_0082:
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
	.L_tc_recycle_frame_loop_028b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_028b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_028b
	.L_tc_recycle_frame_done_028b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0081:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01e5:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_0289:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0289
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0289
	.L_tc_recycle_frame_done_0289:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01e4:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_0285:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0285
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0285
	.L_tc_recycle_frame_done_0285:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01e0:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_0283:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0283
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0283
	.L_tc_recycle_frame_done_0283:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01df:	; new closure is in rax
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
.L_lambda_simple_env_loop_01e7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01e7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01e7
.L_lambda_simple_env_end_01e7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01e7:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01e7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01e7
.L_lambda_simple_params_end_01e7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01e7
	jmp .L_lambda_simple_end_01e7
.L_lambda_simple_code_01e7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0228
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0228:
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
.L_lambda_simple_end_01e7:	; new closure is in rax
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
.L_lambda_simple_env_loop_01e8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01e8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01e8
.L_lambda_simple_env_end_01e8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01e8:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01e8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01e8
.L_lambda_simple_params_end_01e8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01e8
	jmp .L_lambda_simple_end_01e8
.L_lambda_simple_code_01e8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0229
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0229:
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
.L_lambda_simple_env_loop_01e9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_01e9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01e9
.L_lambda_simple_env_end_01e9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01e9:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_01e9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01e9
.L_lambda_simple_params_end_01e9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01e9
	jmp .L_lambda_simple_end_01e9
.L_lambda_simple_code_01e9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_022a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_022a:
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
.L_lambda_simple_env_loop_01ea:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_01ea
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01ea
.L_lambda_simple_env_end_01ea:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01ea:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01ea
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01ea
.L_lambda_simple_params_end_01ea:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01ea
	jmp .L_lambda_simple_end_01ea
.L_lambda_simple_code_01ea:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_022b
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_022b:
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
	jne .L_if_end_018d
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
	jne .L_if_end_018d
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
	je .L_if_else_0169
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
	je .L_if_else_0168
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
	.L_tc_recycle_frame_loop_028d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_028d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_028d
	.L_tc_recycle_frame_done_028d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_018e
.L_if_else_0168:
	mov rax, L_constants + 2
.L_if_end_018e:
	jmp .L_if_end_018f
.L_if_else_0169:
	mov rax, L_constants + 2
.L_if_end_018f:
	cmp rax, sob_boolean_false
	jne .L_if_end_018d
.L_if_end_018d:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_01ea:	; new closure is in rax
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
.L_lambda_simple_env_loop_01eb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_01eb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01eb
.L_lambda_simple_env_end_01eb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01eb:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01eb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01eb
.L_lambda_simple_params_end_01eb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01eb
	jmp .L_lambda_simple_end_01eb
.L_lambda_simple_code_01eb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_022c
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_022c:
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
.L_lambda_simple_env_loop_01ec:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_01ec
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01ec
.L_lambda_simple_env_end_01ec:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01ec:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_01ec
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01ec
.L_lambda_simple_params_end_01ec:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01ec
	jmp .L_lambda_simple_end_01ec
.L_lambda_simple_code_01ec:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_022d
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_022d:
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
	je .L_if_else_016a
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
	.L_tc_recycle_frame_loop_0290:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0290
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0290
	.L_tc_recycle_frame_done_0290:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0190
.L_if_else_016a:
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
	.L_tc_recycle_frame_loop_0291:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0291
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0291
	.L_tc_recycle_frame_done_0291:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0190:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01ec:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_028f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_028f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_028f
	.L_tc_recycle_frame_done_028f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01eb:	; new closure is in rax
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
.L_lambda_simple_env_loop_01ed:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_01ed
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01ed
.L_lambda_simple_env_end_01ed:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01ed:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01ed
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01ed
.L_lambda_simple_params_end_01ed:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01ed
	jmp .L_lambda_simple_end_01ed
.L_lambda_simple_code_01ed:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_022e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_022e:
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
.L_lambda_simple_env_loop_01ee:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_01ee
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01ee
.L_lambda_simple_env_end_01ee:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01ee:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01ee
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01ee
.L_lambda_simple_params_end_01ee:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01ee
	jmp .L_lambda_simple_end_01ee
.L_lambda_simple_code_01ee:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_022f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_022f:
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
.L_lambda_simple_env_loop_01ef:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_01ef
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01ef
.L_lambda_simple_env_end_01ef:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01ef:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01ef
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01ef
.L_lambda_simple_params_end_01ef:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01ef
	jmp .L_lambda_simple_end_01ef
.L_lambda_simple_code_01ef:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0230
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0230:
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
	jne .L_if_end_0191
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
	je .L_if_else_016b
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
	.L_tc_recycle_frame_loop_0293:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0293
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0293
	.L_tc_recycle_frame_done_0293:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0192
.L_if_else_016b:
	mov rax, L_constants + 2
.L_if_end_0192:
	cmp rax, sob_boolean_false
	jne .L_if_end_0191
.L_if_end_0191:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01ef:	; new closure is in rax
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
.L_lambda_opt_env_loop_0042:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 4
	je .L_lambda_opt_env_end_0042
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0042
.L_lambda_opt_env_end_0042:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00c4:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0083
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00c4
.L_lambda_opt_params_end_0083:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0042
	jmp .L_lambda_opt_end_0083
.L_lambda_opt_code_0042:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_0231
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0231:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_00c6
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_00c5: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00c5
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0084
	.L_lambda_opt_params_loop_00c6:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_00c5: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_00c5
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_00c6:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0084
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00c6
	.L_lambda_opt_params_end_0084:
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
	.L_lambda_opt_end_0084:
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
	.L_tc_recycle_frame_loop_0294:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0294
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0294
	.L_tc_recycle_frame_done_0294:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0083:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01ee:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_0292:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0292
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0292
	.L_tc_recycle_frame_done_0292:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01ed:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_028e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_028e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_028e
	.L_tc_recycle_frame_done_028e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01e9:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_028c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_028c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_028c
	.L_tc_recycle_frame_done_028c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01e8:	; new closure is in rax
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
.L_lambda_simple_env_loop_01f0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01f0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01f0
.L_lambda_simple_env_end_01f0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01f0:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01f0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01f0
.L_lambda_simple_params_end_01f0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01f0
	jmp .L_lambda_simple_end_01f0
.L_lambda_simple_code_01f0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0232
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0232:
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
.L_lambda_simple_end_01f0:	; new closure is in rax
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
.L_lambda_simple_env_loop_01f1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01f1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01f1
.L_lambda_simple_env_end_01f1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01f1:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01f1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01f1
.L_lambda_simple_params_end_01f1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01f1
	jmp .L_lambda_simple_end_01f1
.L_lambda_simple_code_01f1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0233
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0233:
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
.L_lambda_simple_env_loop_01f2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_01f2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01f2
.L_lambda_simple_env_end_01f2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01f2:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01f2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01f2
.L_lambda_simple_params_end_01f2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01f2
	jmp .L_lambda_simple_end_01f2
.L_lambda_simple_code_01f2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0234
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0234:
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
.L_lambda_simple_env_loop_01f3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_01f3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01f3
.L_lambda_simple_env_end_01f3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01f3:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01f3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01f3
.L_lambda_simple_params_end_01f3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01f3
	jmp .L_lambda_simple_end_01f3
.L_lambda_simple_code_01f3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 4
	je .L_lambda_simple_arity_check_ok_0235
	push qword [rsp + 8 * 2]
	push 4
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0235:
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
	jne .L_if_end_0193
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
	je .L_if_else_016d
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
	je .L_if_else_016c
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
	.L_tc_recycle_frame_loop_0296:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0296
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0296
	.L_tc_recycle_frame_done_0296:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0194
.L_if_else_016c:
	mov rax, L_constants + 2
.L_if_end_0194:
	jmp .L_if_end_0195
.L_if_else_016d:
	mov rax, L_constants + 2
.L_if_end_0195:
	cmp rax, sob_boolean_false
	jne .L_if_end_0193
.L_if_end_0193:
	leave
	ret AND_KILL_FRAME(4)
.L_lambda_simple_end_01f3:	; new closure is in rax
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
.L_lambda_simple_env_loop_01f4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_01f4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01f4
.L_lambda_simple_env_end_01f4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01f4:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01f4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01f4
.L_lambda_simple_params_end_01f4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01f4
	jmp .L_lambda_simple_end_01f4
.L_lambda_simple_code_01f4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0236
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0236:
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
.L_lambda_simple_env_loop_01f5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_01f5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01f5
.L_lambda_simple_env_end_01f5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01f5:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_01f5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01f5
.L_lambda_simple_params_end_01f5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01f5
	jmp .L_lambda_simple_end_01f5
.L_lambda_simple_code_01f5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0237
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0237:
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
	je .L_if_else_016e
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
	.L_tc_recycle_frame_loop_0299:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0299
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0299
	.L_tc_recycle_frame_done_0299:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0196
.L_if_else_016e:
	mov rax, L_constants + 2
.L_if_end_0196:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01f5:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_0298:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0298
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0298
	.L_tc_recycle_frame_done_0298:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01f4:	; new closure is in rax
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
.L_lambda_simple_env_loop_01f6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_01f6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01f6
.L_lambda_simple_env_end_01f6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01f6:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01f6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01f6
.L_lambda_simple_params_end_01f6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01f6
	jmp .L_lambda_simple_end_01f6
.L_lambda_simple_code_01f6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0238
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0238:
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
.L_lambda_simple_env_loop_01f7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_01f7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01f7
.L_lambda_simple_env_end_01f7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01f7:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01f7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01f7
.L_lambda_simple_params_end_01f7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01f7
	jmp .L_lambda_simple_end_01f7
.L_lambda_simple_code_01f7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0239
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0239:
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
.L_lambda_simple_env_loop_01f8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_01f8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01f8
.L_lambda_simple_env_end_01f8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01f8:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_01f8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01f8
.L_lambda_simple_params_end_01f8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01f8
	jmp .L_lambda_simple_end_01f8
.L_lambda_simple_code_01f8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_023a
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_023a:
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
	jne .L_if_end_0197
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
	je .L_if_else_016f
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
	.L_tc_recycle_frame_loop_029b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_029b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_029b
	.L_tc_recycle_frame_done_029b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0198
.L_if_else_016f:
	mov rax, L_constants + 2
.L_if_end_0198:
	cmp rax, sob_boolean_false
	jne .L_if_end_0197
.L_if_end_0197:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01f8:	; new closure is in rax
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
.L_lambda_opt_env_loop_0043:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 4
	je .L_lambda_opt_env_end_0043
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0043
.L_lambda_opt_env_end_0043:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00c7:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0085
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00c7
.L_lambda_opt_params_end_0085:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0043
	jmp .L_lambda_opt_end_0085
.L_lambda_opt_code_0043:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_023b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_023b:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_00c9
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_00c8: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00c8
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0086
	.L_lambda_opt_params_loop_00c9:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_00c8: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_00c8
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_00c9:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0086
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00c9
	.L_lambda_opt_params_end_0086:
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
	.L_lambda_opt_end_0086:
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
	.L_tc_recycle_frame_loop_029c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_029c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_029c
	.L_tc_recycle_frame_done_029c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0085:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01f7:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_029a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_029a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_029a
	.L_tc_recycle_frame_done_029a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01f6:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_0297:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0297
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0297
	.L_tc_recycle_frame_done_0297:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01f2:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_0295:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0295
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0295
	.L_tc_recycle_frame_done_0295:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01f1:	; new closure is in rax
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
.L_lambda_simple_env_loop_01f9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01f9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01f9
.L_lambda_simple_env_end_01f9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01f9:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01f9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01f9
.L_lambda_simple_params_end_01f9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01f9
	jmp .L_lambda_simple_end_01f9
.L_lambda_simple_code_01f9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_023c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_023c:
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
.L_lambda_simple_end_01f9:	; new closure is in rax
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
.L_lambda_simple_env_loop_01fa:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01fa
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01fa
.L_lambda_simple_env_end_01fa:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01fa:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01fa
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01fa
.L_lambda_simple_params_end_01fa:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01fa
	jmp .L_lambda_simple_end_01fa
.L_lambda_simple_code_01fa:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_023d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_023d:
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
	jne .L_if_end_0199
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
	je .L_if_else_0170
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
	.L_tc_recycle_frame_loop_029d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_029d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_029d
	.L_tc_recycle_frame_done_029d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_019a
.L_if_else_0170:
	mov rax, L_constants + 2
.L_if_end_019a:
	cmp rax, sob_boolean_false
	jne .L_if_end_0199
.L_if_end_0199:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01fa:	; new closure is in rax
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
.L_lambda_simple_env_loop_01fb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01fb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01fb
.L_lambda_simple_env_end_01fb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01fb:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01fb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01fb
.L_lambda_simple_params_end_01fb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01fb
	jmp .L_lambda_simple_end_01fb
.L_lambda_simple_code_01fb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_023e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_023e:
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
.L_lambda_opt_env_loop_0044:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_0044
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0044
.L_lambda_opt_env_end_0044:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00ca:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0087
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00ca
.L_lambda_opt_params_end_0087:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0044
	jmp .L_lambda_opt_end_0087
.L_lambda_opt_code_0044:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_023f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_023f:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_00cc
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_00cb: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00cb
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0088
	.L_lambda_opt_params_loop_00cc:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_00cb: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_00cb
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_00cc:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0088
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00cc
	.L_lambda_opt_params_end_0088:
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
	.L_lambda_opt_end_0088:
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
	je .L_if_else_0173
	mov rax, L_constants + 0
	jmp .L_if_end_019d
.L_if_else_0173:
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
	je .L_if_else_0171
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
	jmp .L_if_end_019b
.L_if_else_0171:
	mov rax, L_constants + 2
.L_if_end_019b:
	cmp rax, sob_boolean_false
	je .L_if_else_0172
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
	jmp .L_if_end_019c
.L_if_else_0172:
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
.L_if_end_019c:
.L_if_end_019d:
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
.L_lambda_simple_env_loop_01fc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_01fc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01fc
.L_lambda_simple_env_end_01fc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01fc:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_01fc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01fc
.L_lambda_simple_params_end_01fc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01fc
	jmp .L_lambda_simple_end_01fc
.L_lambda_simple_code_01fc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0240
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0240:
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
	.L_tc_recycle_frame_loop_029f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_029f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_029f
	.L_tc_recycle_frame_done_029f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01fc:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_029e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_029e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_029e
	.L_tc_recycle_frame_done_029e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0087:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01fb:	; new closure is in rax
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
.L_lambda_simple_env_loop_01fd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01fd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01fd
.L_lambda_simple_env_end_01fd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01fd:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01fd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01fd
.L_lambda_simple_params_end_01fd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01fd
	jmp .L_lambda_simple_end_01fd
.L_lambda_simple_code_01fd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0241
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0241:
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
.L_lambda_opt_env_loop_0045:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_0045
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0045
.L_lambda_opt_env_end_0045:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00cd:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0089
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00cd
.L_lambda_opt_params_end_0089:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0045
	jmp .L_lambda_opt_end_0089
.L_lambda_opt_code_0045:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_0242
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0242:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_00cf
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_00ce: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00ce
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_008a
	.L_lambda_opt_params_loop_00cf:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_00ce: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_00ce
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_00cf:
	cmp rdx, 0
	je .L_lambda_opt_params_end_008a
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00cf
	.L_lambda_opt_params_end_008a:
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
	.L_lambda_opt_end_008a:
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
	je .L_if_else_0176
	mov rax, L_constants + 4
	jmp .L_if_end_01a0
.L_if_else_0176:
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
	je .L_if_else_0174
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
	jmp .L_if_end_019e
.L_if_else_0174:
	mov rax, L_constants + 2
.L_if_end_019e:
	cmp rax, sob_boolean_false
	je .L_if_else_0175
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
	jmp .L_if_end_019f
.L_if_else_0175:
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
.L_if_end_019f:
.L_if_end_01a0:
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
.L_lambda_simple_env_loop_01fe:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_01fe
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01fe
.L_lambda_simple_env_end_01fe:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01fe:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_01fe
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01fe
.L_lambda_simple_params_end_01fe:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01fe
	jmp .L_lambda_simple_end_01fe
.L_lambda_simple_code_01fe:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0243
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0243:
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
	.L_tc_recycle_frame_loop_02a1:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02a1
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02a1
	.L_tc_recycle_frame_done_02a1:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01fe:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_02a0:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02a0
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02a0
	.L_tc_recycle_frame_done_02a0:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0089:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01fd:	; new closure is in rax
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
.L_lambda_simple_env_loop_01ff:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_01ff
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_01ff
.L_lambda_simple_env_end_01ff:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_01ff:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_01ff
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_01ff
.L_lambda_simple_params_end_01ff:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_01ff
	jmp .L_lambda_simple_end_01ff
.L_lambda_simple_code_01ff:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0244
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0244:
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
.L_lambda_simple_env_loop_0200:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0200
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0200
.L_lambda_simple_env_end_0200:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0200:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0200
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0200
.L_lambda_simple_params_end_0200:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0200
	jmp .L_lambda_simple_end_0200
.L_lambda_simple_code_0200:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0245
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0245:
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
	je .L_if_else_0177
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
	.L_tc_recycle_frame_loop_02a2:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02a2
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02a2
	.L_tc_recycle_frame_done_02a2:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_01a1
.L_if_else_0177:
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
.L_lambda_simple_env_loop_0201:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0201
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0201
.L_lambda_simple_env_end_0201:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0201:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0201
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0201
.L_lambda_simple_params_end_0201:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0201
	jmp .L_lambda_simple_end_0201
.L_lambda_simple_code_0201:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0246
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0246:
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
	mov rax, qword [free_var_148]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rax, PARAM(0)	; param v
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0201:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_02a3:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02a3
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02a3
	.L_tc_recycle_frame_done_02a3:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_01a1:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0200:	; new closure is in rax
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
.L_lambda_simple_env_loop_0202:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0202
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0202
.L_lambda_simple_env_end_0202:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0202:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0202
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0202
.L_lambda_simple_params_end_0202:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0202
	jmp .L_lambda_simple_end_0202
.L_lambda_simple_code_0202:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0247
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0247:
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
	.L_tc_recycle_frame_loop_02a4:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02a4
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02a4
	.L_tc_recycle_frame_done_02a4:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0202:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01ff:	; new closure is in rax
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
.L_lambda_simple_env_loop_0203:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0203
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0203
.L_lambda_simple_env_end_0203:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0203:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0203
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0203
.L_lambda_simple_params_end_0203:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0203
	jmp .L_lambda_simple_end_0203
.L_lambda_simple_code_0203:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0248
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0248:
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
.L_lambda_simple_env_loop_0204:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0204
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0204
.L_lambda_simple_env_end_0204:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0204:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0204
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0204
.L_lambda_simple_params_end_0204:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0204
	jmp .L_lambda_simple_end_0204
.L_lambda_simple_code_0204:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0249
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0249:
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
	je .L_if_else_0178
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
	.L_tc_recycle_frame_loop_02a5:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02a5
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02a5
	.L_tc_recycle_frame_done_02a5:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_01a2
.L_if_else_0178:
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
.L_lambda_simple_env_loop_0205:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0205
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0205
.L_lambda_simple_env_end_0205:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0205:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0205
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0205
.L_lambda_simple_params_end_0205:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0205
	jmp .L_lambda_simple_end_0205
.L_lambda_simple_code_0205:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_024a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_024a:
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
.L_lambda_simple_end_0205:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_02a6:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02a6
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02a6
	.L_tc_recycle_frame_done_02a6:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_01a2:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0204:	; new closure is in rax
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
.L_lambda_simple_env_loop_0206:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0206
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0206
.L_lambda_simple_env_end_0206:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0206:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0206
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0206
.L_lambda_simple_params_end_0206:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0206
	jmp .L_lambda_simple_end_0206
.L_lambda_simple_code_0206:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_024b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_024b:
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
	.L_tc_recycle_frame_loop_02a7:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02a7
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02a7
	.L_tc_recycle_frame_done_02a7:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0206:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0203:	; new closure is in rax
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
.L_lambda_opt_env_loop_0046:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 0
	je .L_lambda_opt_env_end_0046
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0046
.L_lambda_opt_env_end_0046:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00d0:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_008b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00d0
.L_lambda_opt_params_end_008b:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0046
	jmp .L_lambda_opt_end_008b
.L_lambda_opt_code_0046:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	jge .L_lambda_simple_arity_check_ok_024c
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_024c:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 0
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_00d2
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_00d1: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00d1
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_008c
	.L_lambda_opt_params_loop_00d2:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_00d1: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_00d1
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_00d2:
	cmp rdx, 0
	je .L_lambda_opt_params_end_008c
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00d2
	.L_lambda_opt_params_end_008c:
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
	.L_lambda_opt_end_008c:
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
	.L_tc_recycle_frame_loop_02a8:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02a8
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02a8
	.L_tc_recycle_frame_done_02a8:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_008b:
	mov qword [free_var_141], rax
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
.L_lambda_simple_env_loop_0207:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0207
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0207
.L_lambda_simple_env_end_0207:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0207:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0207
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0207
.L_lambda_simple_params_end_0207:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0207
	jmp .L_lambda_simple_end_0207
.L_lambda_simple_code_0207:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_024d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_024d:
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
.L_lambda_simple_env_loop_0208:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0208
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0208
.L_lambda_simple_env_end_0208:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0208:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0208
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0208
.L_lambda_simple_params_end_0208:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0208
	jmp .L_lambda_simple_end_0208
.L_lambda_simple_code_0208:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_024e
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_024e:
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
	je .L_if_else_0179
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
	.L_tc_recycle_frame_loop_02a9:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02a9
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02a9
	.L_tc_recycle_frame_done_02a9:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_01a3
.L_if_else_0179:
	mov rax, L_constants + 1
.L_if_end_01a3:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0208:	; new closure is in rax
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
.L_lambda_simple_env_loop_0209:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0209
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0209
.L_lambda_simple_env_end_0209:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0209:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0209
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0209
.L_lambda_simple_params_end_0209:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0209
	jmp .L_lambda_simple_end_0209
.L_lambda_simple_code_0209:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_024f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_024f:
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
	.L_tc_recycle_frame_loop_02aa:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02aa
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02aa
	.L_tc_recycle_frame_done_02aa:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0209:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0207:	; new closure is in rax
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
.L_lambda_simple_env_loop_020a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_020a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_020a
.L_lambda_simple_env_end_020a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_020a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_020a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_020a
.L_lambda_simple_params_end_020a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_020a
	jmp .L_lambda_simple_end_020a
.L_lambda_simple_code_020a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0250
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0250:
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
.L_lambda_simple_env_loop_020b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_020b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_020b
.L_lambda_simple_env_end_020b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_020b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_020b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_020b
.L_lambda_simple_params_end_020b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_020b
	jmp .L_lambda_simple_end_020b
.L_lambda_simple_code_020b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0251
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0251:
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
	je .L_if_else_017a
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
	mov rax, qword [free_var_145]	; free var vector-ref
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
	.L_tc_recycle_frame_loop_02ab:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02ab
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02ab
	.L_tc_recycle_frame_done_02ab:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_01a4
.L_if_else_017a:
	mov rax, L_constants + 1
.L_if_end_01a4:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_020b:	; new closure is in rax
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
.L_lambda_simple_env_loop_020c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_020c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_020c
.L_lambda_simple_env_end_020c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_020c:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_020c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_020c
.L_lambda_simple_params_end_020c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_020c
	jmp .L_lambda_simple_end_020c
.L_lambda_simple_code_020c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0252
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0252:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param v
	push rax
	push 1	; arg count
	mov rax, qword [free_var_144]	; free var vector-length
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
	.L_tc_recycle_frame_loop_02ac:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02ac
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02ac
	.L_tc_recycle_frame_done_02ac:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_020c:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_020a:	; new closure is in rax
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
.L_lambda_simple_env_loop_020d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_020d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_020d
.L_lambda_simple_env_end_020d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_020d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_020d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_020d
.L_lambda_simple_params_end_020d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_020d
	jmp .L_lambda_simple_end_020d
.L_lambda_simple_code_020d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0253
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0253:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param n
	push rax
	; preparing a non-tail-call
	push 0	; arg count
	mov rax, qword [free_var_140]	; free var trng
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
	.L_tc_recycle_frame_loop_02ad:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02ad
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02ad
	.L_tc_recycle_frame_done_02ad:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_020d:	; new closure is in rax
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
.L_lambda_simple_env_loop_020e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_020e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_020e
.L_lambda_simple_env_end_020e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_020e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_020e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_020e
.L_lambda_simple_params_end_020e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_020e
	jmp .L_lambda_simple_end_020e
.L_lambda_simple_code_020e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0254
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0254:
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
	.L_tc_recycle_frame_loop_02ae:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02ae
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02ae
	.L_tc_recycle_frame_done_02ae:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_020e:	; new closure is in rax
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
.L_lambda_simple_env_loop_020f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_020f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_020f
.L_lambda_simple_env_end_020f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_020f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_020f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_020f
.L_lambda_simple_params_end_020f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_020f
	jmp .L_lambda_simple_end_020f
.L_lambda_simple_code_020f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0255
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0255:
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
	.L_tc_recycle_frame_loop_02af:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02af
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02af
	.L_tc_recycle_frame_done_02af:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_020f:	; new closure is in rax
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
.L_lambda_simple_env_loop_0210:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0210
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0210
.L_lambda_simple_env_end_0210:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0210:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0210
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0210
.L_lambda_simple_params_end_0210:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0210
	jmp .L_lambda_simple_end_0210
.L_lambda_simple_code_0210:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0256
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0256:
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
	.L_tc_recycle_frame_loop_02b0:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02b0
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02b0
	.L_tc_recycle_frame_done_02b0:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0210:	; new closure is in rax
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
.L_lambda_simple_env_loop_0211:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0211
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0211
.L_lambda_simple_env_end_0211:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0211:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0211
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0211
.L_lambda_simple_params_end_0211:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0211
	jmp .L_lambda_simple_end_0211
.L_lambda_simple_code_0211:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0257
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0257:
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
	.L_tc_recycle_frame_loop_02b1:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02b1
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02b1
	.L_tc_recycle_frame_done_02b1:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0211:	; new closure is in rax
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
.L_lambda_simple_env_loop_0212:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0212
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0212
.L_lambda_simple_env_end_0212:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0212:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0212
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0212
.L_lambda_simple_params_end_0212:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0212
	jmp .L_lambda_simple_end_0212
.L_lambda_simple_code_0212:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0258
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0258:
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
	je .L_if_else_017b
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
	.L_tc_recycle_frame_loop_02b2:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02b2
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02b2
	.L_tc_recycle_frame_done_02b2:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_01a5
.L_if_else_017b:
	mov rax, PARAM(0)	; param x
.L_if_end_01a5:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0212:	; new closure is in rax
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
.L_lambda_simple_env_loop_0213:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0213
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0213
.L_lambda_simple_env_end_0213:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0213:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0213
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0213
.L_lambda_simple_params_end_0213:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0213
	jmp .L_lambda_simple_end_0213
.L_lambda_simple_code_0213:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0259
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0259:
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
	je .L_if_else_017c
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
	jmp .L_if_end_01a6
.L_if_else_017c:
	mov rax, L_constants + 2
.L_if_end_01a6:
	cmp rax, sob_boolean_false
	je .L_if_else_0188
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
	je .L_if_else_017d
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
	.L_tc_recycle_frame_loop_02b3:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02b3
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02b3
	.L_tc_recycle_frame_done_02b3:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_01a7
.L_if_else_017d:
	mov rax, L_constants + 2
.L_if_end_01a7:
	jmp .L_if_end_01b2
.L_if_else_0188:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_149]	; free var vector?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_017f
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_149]	; free var vector?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_017e
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_144]	; free var vector-length
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
	mov rax, qword [free_var_144]	; free var vector-length
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
	jmp .L_if_end_01a8
.L_if_else_017e:
	mov rax, L_constants + 2
.L_if_end_01a8:
	jmp .L_if_end_01a9
.L_if_else_017f:
	mov rax, L_constants + 2
.L_if_end_01a9:
	cmp rax, sob_boolean_false
	je .L_if_else_0187
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_142]	; free var vector->list
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
	mov rax, qword [free_var_142]	; free var vector->list
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
	.L_tc_recycle_frame_loop_02b4:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02b4
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02b4
	.L_tc_recycle_frame_done_02b4:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_01b1
.L_if_else_0187:
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
	je .L_if_else_0181
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
	je .L_if_else_0180
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
	jmp .L_if_end_01aa
.L_if_else_0180:
	mov rax, L_constants + 2
.L_if_end_01aa:
	jmp .L_if_end_01ab
.L_if_else_0181:
	mov rax, L_constants + 2
.L_if_end_01ab:
	cmp rax, sob_boolean_false
	je .L_if_else_0186
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
	.L_tc_recycle_frame_loop_02b5:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02b5
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02b5
	.L_tc_recycle_frame_done_02b5:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_01b0
.L_if_else_0186:
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
	je .L_if_else_0182
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
	jmp .L_if_end_01ac
.L_if_else_0182:
	mov rax, L_constants + 2
.L_if_end_01ac:
	cmp rax, sob_boolean_false
	je .L_if_else_0185
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
	.L_tc_recycle_frame_loop_02b6:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02b6
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02b6
	.L_tc_recycle_frame_done_02b6:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_01af
.L_if_else_0185:
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
	je .L_if_else_0183
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
	jmp .L_if_end_01ad
.L_if_else_0183:
	mov rax, L_constants + 2
.L_if_end_01ad:
	cmp rax, sob_boolean_false
	je .L_if_else_0184
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
	.L_tc_recycle_frame_loop_02b7:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02b7
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02b7
	.L_tc_recycle_frame_done_02b7:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_01ae
.L_if_else_0184:
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
	.L_tc_recycle_frame_loop_02b8:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02b8
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02b8
	.L_tc_recycle_frame_done_02b8:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_01ae:
.L_if_end_01af:
.L_if_end_01b0:
.L_if_end_01b1:
.L_if_end_01b2:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0213:	; new closure is in rax
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
.L_lambda_simple_env_loop_0214:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0214
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0214
.L_lambda_simple_env_end_0214:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0214:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0214
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0214
.L_lambda_simple_params_end_0214:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0214
	jmp .L_lambda_simple_end_0214
.L_lambda_simple_code_0214:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_025a
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_025a:
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
	je .L_if_else_018a
	mov rax, L_constants + 2
	jmp .L_if_end_01b4
.L_if_else_018a:
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
	je .L_if_else_0189
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
	.L_tc_recycle_frame_loop_02b9:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02b9
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02b9
	.L_tc_recycle_frame_done_02b9:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_01b3
.L_if_else_0189:
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
	.L_tc_recycle_frame_loop_02ba:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02ba
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02ba
	.L_tc_recycle_frame_done_02ba:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_01b3:
.L_if_end_01b4:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0214:	; new closure is in rax
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
.L_lambda_simple_env_loop_0215:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0215
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0215
.L_lambda_simple_env_end_0215:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0215:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0215
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0215
.L_lambda_simple_params_end_0215:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0215
	jmp .L_lambda_simple_end_0215
.L_lambda_simple_code_0215:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_025b
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_025b:
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
.L_lambda_simple_env_loop_0216:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0216
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0216
.L_lambda_simple_env_end_0216:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0216:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0216
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0216
.L_lambda_simple_params_end_0216:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0216
	jmp .L_lambda_simple_end_0216
.L_lambda_simple_code_0216:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_025c
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_025c:
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
	je .L_if_else_018b
	mov rax, PARAM(0)	; param target
	jmp .L_if_end_01b5
.L_if_else_018b:
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
.L_lambda_simple_env_loop_0217:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0217
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0217
.L_lambda_simple_env_end_0217:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0217:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_0217
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0217
.L_lambda_simple_params_end_0217:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0217
	jmp .L_lambda_simple_end_0217
.L_lambda_simple_code_0217:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_025d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_025d:
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
	.L_tc_recycle_frame_loop_02bc:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02bc
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02bc
	.L_tc_recycle_frame_done_02bc:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0217:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_02bb:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02bb
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02bb
	.L_tc_recycle_frame_done_02bb:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_01b5:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0216:	; new closure is in rax
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
.L_lambda_simple_env_loop_0218:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0218
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0218
.L_lambda_simple_env_end_0218:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0218:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0218
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0218
.L_lambda_simple_params_end_0218:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0218
	jmp .L_lambda_simple_end_0218
.L_lambda_simple_code_0218:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_025e
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_025e:
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
	je .L_if_else_018c
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
	.L_tc_recycle_frame_loop_02bd:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02bd
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02bd
	.L_tc_recycle_frame_done_02bd:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_01b6
.L_if_else_018c:
	mov rax, PARAM(1)	; param i
.L_if_end_01b6:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_0218:	; new closure is in rax
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
.L_lambda_opt_env_loop_0047:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_0047
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0047
.L_lambda_opt_env_end_0047:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00d3:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_008d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00d3
.L_lambda_opt_params_end_008d:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0047
	jmp .L_lambda_opt_end_008d
.L_lambda_opt_code_0047:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	jge .L_lambda_simple_arity_check_ok_025f
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_025f:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 0
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_00d5
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_00d4: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00d4
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_008e
	.L_lambda_opt_params_loop_00d5:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_00d4: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_00d4
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_00d5:
	cmp rdx, 0
	je .L_lambda_opt_params_end_008e
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00d5
	.L_lambda_opt_params_end_008e:
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
	.L_lambda_opt_end_008e:
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
	.L_tc_recycle_frame_loop_02be:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02be
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02be
	.L_tc_recycle_frame_done_02be:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_008d:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0215:	; new closure is in rax
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
.L_lambda_simple_env_loop_0219:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0219
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0219
.L_lambda_simple_env_end_0219:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0219:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0219
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0219
.L_lambda_simple_params_end_0219:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0219
	jmp .L_lambda_simple_end_0219
.L_lambda_simple_code_0219:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0260
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0260:
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
.L_lambda_simple_env_loop_021a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_021a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_021a
.L_lambda_simple_env_end_021a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_021a:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_021a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_021a
.L_lambda_simple_params_end_021a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_021a
	jmp .L_lambda_simple_end_021a
.L_lambda_simple_code_021a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0261
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0261:
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
	je .L_if_else_018d
	mov rax, PARAM(0)	; param target
	jmp .L_if_end_01b7
.L_if_else_018d:
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
	mov rax, qword [free_var_144]	; free var vector-length
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
.L_lambda_simple_env_loop_021b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_021b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_021b
.L_lambda_simple_env_end_021b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_021b:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_021b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_021b
.L_lambda_simple_params_end_021b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_021b
	jmp .L_lambda_simple_end_021b
.L_lambda_simple_code_021b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0262
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0262:
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
	.L_tc_recycle_frame_loop_02c0:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02c0
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02c0
	.L_tc_recycle_frame_done_02c0:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_021b:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_02bf:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02bf
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02bf
	.L_tc_recycle_frame_done_02bf:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_01b7:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_021a:	; new closure is in rax
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
.L_lambda_simple_env_loop_021c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_021c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_021c
.L_lambda_simple_env_end_021c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_021c:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_021c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_021c
.L_lambda_simple_params_end_021c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_021c
	jmp .L_lambda_simple_end_021c
.L_lambda_simple_code_021c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_0263
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0263:
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
	je .L_if_else_018e
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(3)	; param j
	push rax
	mov rax, PARAM(2)	; param vec
	push rax
	push 2	; arg count
	mov rax, qword [free_var_145]	; free var vector-ref
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
	mov rax, qword [free_var_148]	; free var vector-set!
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
	.L_tc_recycle_frame_loop_02c1:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02c1
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02c1
	.L_tc_recycle_frame_done_02c1:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_01b8
.L_if_else_018e:
	mov rax, PARAM(1)	; param i
.L_if_end_01b8:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_021c:	; new closure is in rax
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
.L_lambda_opt_env_loop_0048:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_0048
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0048
.L_lambda_opt_env_end_0048:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00d6:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_008f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00d6
.L_lambda_opt_params_end_008f:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0048
	jmp .L_lambda_opt_end_008f
.L_lambda_opt_code_0048:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	jge .L_lambda_simple_arity_check_ok_0264
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0264:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 0
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_00d8
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_00d7: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00d7
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0090
	.L_lambda_opt_params_loop_00d8:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_00d7: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_00d7
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_00d8:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0090
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_00d8
	.L_lambda_opt_params_end_0090:
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
	.L_lambda_opt_end_0090:
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
	mov rax, qword [free_var_144]	; free var vector-length
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
	.L_tc_recycle_frame_loop_02c2:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02c2
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02c2
	.L_tc_recycle_frame_done_02c2:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_008f:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0219:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_143], rax
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
.L_lambda_simple_env_loop_021d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_021d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_021d
.L_lambda_simple_env_end_021d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_021d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_021d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_021d
.L_lambda_simple_params_end_021d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_021d
	jmp .L_lambda_simple_end_021d
.L_lambda_simple_code_021d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0265
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0265:
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
	.L_tc_recycle_frame_loop_02c3:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02c3
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02c3
	.L_tc_recycle_frame_done_02c3:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_021d:	; new closure is in rax
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
.L_lambda_simple_env_loop_021e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_021e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_021e
.L_lambda_simple_env_end_021e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_021e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_021e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_021e
.L_lambda_simple_params_end_021e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_021e
	jmp .L_lambda_simple_end_021e
.L_lambda_simple_code_021e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0266
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0266:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param vec
	push rax
	push 1	; arg count
	mov rax, qword [free_var_142]	; free var vector->list
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
	.L_tc_recycle_frame_loop_02c4:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02c4
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02c4
	.L_tc_recycle_frame_done_02c4:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_021e:	; new closure is in rax
	mov qword [free_var_146], rax
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
.L_lambda_simple_env_loop_021f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_021f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_021f
.L_lambda_simple_env_end_021f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_021f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_021f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_021f
.L_lambda_simple_params_end_021f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_021f
	jmp .L_lambda_simple_end_021f
.L_lambda_simple_code_021f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0267
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0267:
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
.L_lambda_simple_env_loop_0220:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0220
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0220
.L_lambda_simple_env_end_0220:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0220:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0220
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0220
.L_lambda_simple_params_end_0220:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0220
	jmp .L_lambda_simple_end_0220
.L_lambda_simple_code_0220:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0268
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0268:
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
	je .L_if_else_018f
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
.L_lambda_simple_env_loop_0221:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0221
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0221
.L_lambda_simple_env_end_0221:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0221:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_0221
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0221
.L_lambda_simple_params_end_0221:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0221
	jmp .L_lambda_simple_end_0221
.L_lambda_simple_code_0221:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0269
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0269:
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
	.L_tc_recycle_frame_loop_02c6:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02c6
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02c6
	.L_tc_recycle_frame_done_02c6:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0221:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_02c5:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02c5
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02c5
	.L_tc_recycle_frame_done_02c5:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_01b9
.L_if_else_018f:
	mov rax, PARAM(0)	; param str
.L_if_end_01b9:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0220:	; new closure is in rax
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
.L_lambda_simple_env_loop_0222:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0222
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0222
.L_lambda_simple_env_end_0222:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0222:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0222
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0222
.L_lambda_simple_params_end_0222:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0222
	jmp .L_lambda_simple_end_0222
.L_lambda_simple_code_0222:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_026a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_026a:
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
.L_lambda_simple_env_loop_0223:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0223
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0223
.L_lambda_simple_env_end_0223:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0223:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0223
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0223
.L_lambda_simple_params_end_0223:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0223
	jmp .L_lambda_simple_end_0223
.L_lambda_simple_code_0223:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_026b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_026b:
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
	je .L_if_else_0190
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	jmp .L_if_end_01ba
.L_if_else_0190:
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
	.L_tc_recycle_frame_loop_02c8:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02c8
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02c8
	.L_tc_recycle_frame_done_02c8:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_01ba:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0223:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_02c7:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02c7
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02c7
	.L_tc_recycle_frame_done_02c7:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0222:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_021f:	; new closure is in rax
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
.L_lambda_simple_env_loop_0224:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0224
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0224
.L_lambda_simple_env_end_0224:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0224:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0224
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0224
.L_lambda_simple_params_end_0224:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0224
	jmp .L_lambda_simple_end_0224
.L_lambda_simple_code_0224:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_026c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_026c:
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
.L_lambda_simple_env_loop_0225:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0225
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0225
.L_lambda_simple_env_end_0225:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0225:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0225
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0225
.L_lambda_simple_params_end_0225:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0225
	jmp .L_lambda_simple_end_0225
.L_lambda_simple_code_0225:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_026d
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_026d:
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
	je .L_if_else_0191
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param vec
	push rax
	push 2	; arg count
	mov rax, qword [free_var_145]	; free var vector-ref
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
.L_lambda_simple_env_loop_0226:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0226
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0226
.L_lambda_simple_env_end_0226:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0226:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_0226
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0226
.L_lambda_simple_params_end_0226:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0226
	jmp .L_lambda_simple_end_0226
.L_lambda_simple_code_0226:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_026e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_026e:
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
	mov rax, qword [free_var_145]	; free var vector-ref
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
	mov rax, qword [free_var_148]	; free var vector-set!
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
	mov rax, qword [free_var_148]	; free var vector-set!
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
	.L_tc_recycle_frame_loop_02ca:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02ca
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02ca
	.L_tc_recycle_frame_done_02ca:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0226:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_02c9:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02c9
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02c9
	.L_tc_recycle_frame_done_02c9:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_01bb
.L_if_else_0191:
	mov rax, PARAM(0)	; param vec
.L_if_end_01bb:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0225:	; new closure is in rax
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
.L_lambda_simple_env_loop_0227:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0227
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0227
.L_lambda_simple_env_end_0227:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0227:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0227
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0227
.L_lambda_simple_params_end_0227:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0227
	jmp .L_lambda_simple_end_0227
.L_lambda_simple_code_0227:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_026f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_026f:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param vec
	push rax
	push 1	; arg count
	mov rax, qword [free_var_144]	; free var vector-length
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
.L_lambda_simple_env_loop_0228:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0228
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0228
.L_lambda_simple_env_end_0228:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0228:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0228
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0228
.L_lambda_simple_params_end_0228:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0228
	jmp .L_lambda_simple_end_0228
.L_lambda_simple_code_0228:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0270
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0270:
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
	je .L_if_else_0192
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	jmp .L_if_end_01bc
.L_if_else_0192:
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
	.L_tc_recycle_frame_loop_02cc:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02cc
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02cc
	.L_tc_recycle_frame_done_02cc:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_01bc:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0228:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_02cb:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02cb
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02cb
	.L_tc_recycle_frame_done_02cb:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0227:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0224:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_147], rax
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
.L_lambda_simple_env_loop_0229:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0229
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0229
.L_lambda_simple_env_end_0229:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0229:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0229
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0229
.L_lambda_simple_params_end_0229:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0229
	jmp .L_lambda_simple_end_0229
.L_lambda_simple_code_0229:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0271
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0271:
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
.L_lambda_simple_env_loop_022a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_022a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_022a
.L_lambda_simple_env_end_022a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_022a:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_022a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_022a
.L_lambda_simple_params_end_022a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_022a
	jmp .L_lambda_simple_end_022a
.L_lambda_simple_code_022a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0272
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0272:
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
.L_lambda_simple_env_loop_022b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_022b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_022b
.L_lambda_simple_env_end_022b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_022b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_022b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_022b
.L_lambda_simple_params_end_022b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_022b
	jmp .L_lambda_simple_end_022b
.L_lambda_simple_code_022b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0273
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0273:
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
	je .L_if_else_0193
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
	.L_tc_recycle_frame_loop_02ce:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02ce
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02ce
	.L_tc_recycle_frame_done_02ce:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_01bd
.L_if_else_0193:
	mov rax, L_constants + 1
.L_if_end_01bd:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_022b:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_02cf:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02cf
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02cf
	.L_tc_recycle_frame_done_02cf:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_022a:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_02cd:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02cd
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02cd
	.L_tc_recycle_frame_done_02cd:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0229:	; new closure is in rax
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
.L_lambda_simple_env_loop_022c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_022c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_022c
.L_lambda_simple_env_end_022c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_022c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_022c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_022c
.L_lambda_simple_params_end_022c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_022c
	jmp .L_lambda_simple_end_022c
.L_lambda_simple_code_022c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0274
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0274:
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
.L_lambda_simple_env_loop_022d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_022d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_022d
.L_lambda_simple_env_end_022d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_022d:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_022d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_022d
.L_lambda_simple_params_end_022d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_022d
	jmp .L_lambda_simple_end_022d
.L_lambda_simple_code_022d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0275
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0275:
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
.L_lambda_simple_env_loop_022e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_022e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_022e
.L_lambda_simple_env_end_022e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_022e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_022e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_022e
.L_lambda_simple_params_end_022e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_022e
	jmp .L_lambda_simple_end_022e
.L_lambda_simple_code_022e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0276
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0276:
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
.L_lambda_simple_env_loop_022f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_022f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_022f
.L_lambda_simple_env_end_022f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_022f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_022f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_022f
.L_lambda_simple_params_end_022f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_022f
	jmp .L_lambda_simple_end_022f
.L_lambda_simple_code_022f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0277
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0277:
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
	je .L_if_else_0194
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
	.L_tc_recycle_frame_loop_02d2:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02d2
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02d2
	.L_tc_recycle_frame_done_02d2:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_01be
.L_if_else_0194:
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var str
.L_if_end_01be:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_022f:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_02d3:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02d3
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02d3
	.L_tc_recycle_frame_done_02d3:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_022e:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_02d1:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02d1
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02d1
	.L_tc_recycle_frame_done_02d1:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_022d:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_02d0:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02d0
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02d0
	.L_tc_recycle_frame_done_02d0:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_022c:	; new closure is in rax
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
.L_lambda_simple_env_loop_0230:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0230
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0230
.L_lambda_simple_env_end_0230:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0230:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0230
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0230
.L_lambda_simple_params_end_0230:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0230
	jmp .L_lambda_simple_end_0230
.L_lambda_simple_code_0230:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0278
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0278:
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
.L_lambda_simple_env_loop_0231:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0231
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0231
.L_lambda_simple_env_end_0231:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0231:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0231
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0231
.L_lambda_simple_params_end_0231:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0231
	jmp .L_lambda_simple_end_0231
.L_lambda_simple_code_0231:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0279
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0279:
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
.L_lambda_simple_env_loop_0232:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0232
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0232
.L_lambda_simple_env_end_0232:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0232:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0232
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0232
.L_lambda_simple_params_end_0232:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0232
	jmp .L_lambda_simple_end_0232
.L_lambda_simple_code_0232:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_027a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_027a:
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
.L_lambda_simple_env_loop_0233:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0233
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0233
.L_lambda_simple_env_end_0233:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0233:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0233
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0233
.L_lambda_simple_params_end_0233:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0233
	jmp .L_lambda_simple_end_0233
.L_lambda_simple_code_0233:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_027b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_027b:
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
	je .L_if_else_0195
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
	mov rax, qword [free_var_148]	; free var vector-set!
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
	.L_tc_recycle_frame_loop_02d6:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02d6
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02d6
	.L_tc_recycle_frame_done_02d6:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_01bf
.L_if_else_0195:
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var vec
.L_if_end_01bf:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0233:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_02d7:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02d7
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02d7
	.L_tc_recycle_frame_done_02d7:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0232:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_02d5:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02d5
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02d5
	.L_tc_recycle_frame_done_02d5:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0231:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_02d4:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02d4
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02d4
	.L_tc_recycle_frame_done_02d4:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0230:	; new closure is in rax
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
.L_lambda_simple_env_loop_0234:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0234
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0234
.L_lambda_simple_env_end_0234:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0234:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0234
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0234
.L_lambda_simple_params_end_0234:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0234
	jmp .L_lambda_simple_end_0234
.L_lambda_simple_code_0234:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_027c
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_027c:
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
	je .L_if_else_0198
	mov rax, L_constants + 3485
	jmp .L_if_end_01c2
.L_if_else_0198:
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
	je .L_if_else_0197
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
	.L_tc_recycle_frame_loop_02d8:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02d8
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02d8
	.L_tc_recycle_frame_done_02d8:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_01c1
.L_if_else_0197:
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
	je .L_if_else_0196
	mov rax, L_constants + 3485
	jmp .L_if_end_01c0
.L_if_else_0196:
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
	.L_tc_recycle_frame_loop_02d9:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02d9
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02d9
	.L_tc_recycle_frame_done_02d9:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_01c0:
.L_if_end_01c1:
.L_if_end_01c2:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0234:	; new closure is in rax
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
.L_lambda_simple_env_loop_0235:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0235
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0235
.L_lambda_simple_env_end_0235:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0235:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0235
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0235
.L_lambda_simple_params_end_0235:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0235
	jmp .L_lambda_simple_end_0235
.L_lambda_simple_code_0235:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_027d
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_027d:
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
	.L_tc_recycle_frame_loop_02da:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02da
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02da
	.L_tc_recycle_frame_done_02da:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0235:	; new closure is in rax
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
.L_lambda_simple_env_loop_0236:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0236
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0236
.L_lambda_simple_env_end_0236:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0236:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0236
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0236
.L_lambda_simple_params_end_0236:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0236
	jmp .L_lambda_simple_end_0236
.L_lambda_simple_code_0236:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_027e
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_027e:
	enter 0, 0
	mov rax, L_constants + 0
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0236:	; new closure is in rax
	mov qword [free_var_150], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 3881
	push rax
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
.L_lambda_simple_env_loop_0237:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0237
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0237
.L_lambda_simple_env_end_0237:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0237:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0237
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0237
.L_lambda_simple_params_end_0237:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0237
	jmp .L_lambda_simple_end_0237
.L_lambda_simple_code_0237:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 10
	je .L_lambda_simple_arity_check_ok_027f
	push qword [rsp + 8 * 2]
	push 10
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_027f:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 10	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0238:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0238
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0238
.L_lambda_simple_env_end_0238:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0238:	; copy params
	cmp rsi, 10
	je .L_lambda_simple_params_end_0238
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0238
.L_lambda_simple_params_end_0238:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0238
	jmp .L_lambda_simple_end_0238
.L_lambda_simple_code_0238:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0280
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0280:
	enter 0, 0
	; preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x1
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 9]	; bound var x10
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 8]	; bound var x9
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 7]	; bound var x8
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 6]	; bound var x7
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 5]	; bound var x6
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 4]	; bound var x5
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 3]	; bound var x4
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var x3
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var x2
	push rax
	push 10	; arg count
	mov rax, PARAM(0)	; param z
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
	mov rdx, 13
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_02db:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02db
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02db
	.L_tc_recycle_frame_done_02db:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0238:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(10)
.L_lambda_simple_end_0237:	; new closure is in rax
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
.L_lambda_simple_env_loop_0239:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0239
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0239
.L_lambda_simple_env_end_0239:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0239:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0239
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0239
.L_lambda_simple_params_end_0239:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0239
	jmp .L_lambda_simple_end_0239
.L_lambda_simple_code_0239:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0281
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0281:
	enter 0, 0
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
.L_lambda_simple_env_loop_023a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_023a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_023a
.L_lambda_simple_env_end_023a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_023a:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_023a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_023a
.L_lambda_simple_params_end_023a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_023a
	jmp .L_lambda_simple_end_023a
.L_lambda_simple_code_023a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0282
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0282:
	enter 0, 0
	; preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	; preparing a non-tail-call
	mov rax, qword [free_var_92]	; free var list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var p1
	push rax
	push 1	; arg count
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var p1
	push rax
	push 1	; arg count
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var p1
	push rax
	push 1	; arg count
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var p1
	push rax
	push 1	; arg count
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var p1
	push rax
	push 1	; arg count
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var p1
	push rax
	push 1	; arg count
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var p1
	push rax
	push 1	; arg count
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var p1
	push rax
	push 1	; arg count
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var p1
	push rax
	push 1	; arg count
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var p1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
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
	.L_tc_recycle_frame_loop_02dc:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_02dc
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_02dc
	.L_tc_recycle_frame_done_02dc:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_023a:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0239:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_139], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	push 0	; arg count
	mov rax, qword [free_var_139]	; free var test
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
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
        cmp qword [rsp + 16], 2
        jne L_error_arg_count_2
        mov r12, qword [rsp + 24]
        assert_closure(r12)
        lea r10, [rsp + 32]
        mov r11, qword [r10]
        mov r9, qword [rsp]
        xor rcx, rcx
        mov rsi, r11
.L0_loop:
        cmp rsi, sob_nil
        je .L0_done
        assert_pair(rsi)
        inc rcx
        mov rsi, SOB_PAIR_CDR(rsi)
        jmp .L0_loop
.L0_done:
        lea rbx, [8 * rcx - 16]
        sub rsp, rbx
        mov rdi, rsp
        cld
        mov rax, r9
        stosq
        mov rax, SOB_CLOSURE_ENV(r12)
        stosq
        mov rax, rcx
        stosq
.L1_loop:
        test rcx, rcx
        je .L1_done
        mov rax, SOB_PAIR_CAR(r11)
        stosq
        mov r11, SOB_PAIR_CDR(r11)
        dec rcx
        jmp .L1_loop
.L1_done:
        sub rdi, 8
        cmp r10, rdi
        jne .L_error_stack
        jmp SOB_CLOSURE_CODE(r12)
.L_error_stack:
        int3





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
