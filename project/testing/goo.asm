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

free_var_150:	; location of write-char
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 258

free_var_151:	; location of zero?
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
	mov rdi, free_var_150
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
	mov rdi, free_var_151
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
.L_lambda_simple_env_loop_097c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_097c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_097c
.L_lambda_simple_env_end_097c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_097c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_097c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_097c
.L_lambda_simple_params_end_097c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_097c
	jmp .L_lambda_simple_end_097c
.L_lambda_simple_code_097c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0aa4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0aa4:
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
	.L_tc_recycle_frame_loop_0bc0:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bc0
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bc0
	.L_tc_recycle_frame_done_0bc0:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_097c:	; new closure is in rax
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
.L_lambda_simple_env_loop_097d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_097d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_097d
.L_lambda_simple_env_end_097d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_097d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_097d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_097d
.L_lambda_simple_params_end_097d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_097d
	jmp .L_lambda_simple_end_097d
.L_lambda_simple_code_097d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0aa5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0aa5:
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
	.L_tc_recycle_frame_loop_0bc1:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bc1
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bc1
	.L_tc_recycle_frame_done_0bc1:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_097d:	; new closure is in rax
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
.L_lambda_simple_env_loop_097e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_097e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_097e
.L_lambda_simple_env_end_097e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_097e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_097e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_097e
.L_lambda_simple_params_end_097e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_097e
	jmp .L_lambda_simple_end_097e
.L_lambda_simple_code_097e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0aa6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0aa6:
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
	.L_tc_recycle_frame_loop_0bc2:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bc2
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bc2
	.L_tc_recycle_frame_done_0bc2:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_097e:	; new closure is in rax
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
.L_lambda_simple_env_loop_097f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_097f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_097f
.L_lambda_simple_env_end_097f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_097f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_097f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_097f
.L_lambda_simple_params_end_097f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_097f
	jmp .L_lambda_simple_end_097f
.L_lambda_simple_code_097f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0aa7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0aa7:
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
	.L_tc_recycle_frame_loop_0bc3:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bc3
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bc3
	.L_tc_recycle_frame_done_0bc3:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_097f:	; new closure is in rax
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
.L_lambda_simple_env_loop_0980:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0980
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0980
.L_lambda_simple_env_end_0980:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0980:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0980
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0980
.L_lambda_simple_params_end_0980:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0980
	jmp .L_lambda_simple_end_0980
.L_lambda_simple_code_0980:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0aa8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0aa8:
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
	.L_tc_recycle_frame_loop_0bc4:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bc4
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bc4
	.L_tc_recycle_frame_done_0bc4:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0980:	; new closure is in rax
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
.L_lambda_simple_env_loop_0981:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0981
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0981
.L_lambda_simple_env_end_0981:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0981:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0981
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0981
.L_lambda_simple_params_end_0981:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0981
	jmp .L_lambda_simple_end_0981
.L_lambda_simple_code_0981:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0aa9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0aa9:
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
	.L_tc_recycle_frame_loop_0bc5:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bc5
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bc5
	.L_tc_recycle_frame_done_0bc5:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0981:	; new closure is in rax
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
.L_lambda_simple_env_loop_0982:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0982
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0982
.L_lambda_simple_env_end_0982:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0982:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0982
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0982
.L_lambda_simple_params_end_0982:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0982
	jmp .L_lambda_simple_end_0982
.L_lambda_simple_code_0982:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0aaa
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0aaa:
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
	.L_tc_recycle_frame_loop_0bc6:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bc6
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bc6
	.L_tc_recycle_frame_done_0bc6:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0982:	; new closure is in rax
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
.L_lambda_simple_env_loop_0983:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0983
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0983
.L_lambda_simple_env_end_0983:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0983:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0983
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0983
.L_lambda_simple_params_end_0983:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0983
	jmp .L_lambda_simple_end_0983
.L_lambda_simple_code_0983:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0aab
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0aab:
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
	.L_tc_recycle_frame_loop_0bc7:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bc7
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bc7
	.L_tc_recycle_frame_done_0bc7:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0983:	; new closure is in rax
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
.L_lambda_simple_env_loop_0984:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0984
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0984
.L_lambda_simple_env_end_0984:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0984:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0984
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0984
.L_lambda_simple_params_end_0984:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0984
	jmp .L_lambda_simple_end_0984
.L_lambda_simple_code_0984:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0aac
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0aac:
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
	.L_tc_recycle_frame_loop_0bc8:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bc8
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bc8
	.L_tc_recycle_frame_done_0bc8:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0984:	; new closure is in rax
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
.L_lambda_simple_env_loop_0985:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0985
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0985
.L_lambda_simple_env_end_0985:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0985:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0985
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0985
.L_lambda_simple_params_end_0985:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0985
	jmp .L_lambda_simple_end_0985
.L_lambda_simple_code_0985:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0aad
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0aad:
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
	.L_tc_recycle_frame_loop_0bc9:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bc9
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bc9
	.L_tc_recycle_frame_done_0bc9:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0985:	; new closure is in rax
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
.L_lambda_simple_env_loop_0986:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0986
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0986
.L_lambda_simple_env_end_0986:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0986:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0986
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0986
.L_lambda_simple_params_end_0986:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0986
	jmp .L_lambda_simple_end_0986
.L_lambda_simple_code_0986:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0aae
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0aae:
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
	.L_tc_recycle_frame_loop_0bca:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bca
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bca
	.L_tc_recycle_frame_done_0bca:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0986:	; new closure is in rax
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
.L_lambda_simple_env_loop_0987:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0987
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0987
.L_lambda_simple_env_end_0987:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0987:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0987
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0987
.L_lambda_simple_params_end_0987:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0987
	jmp .L_lambda_simple_end_0987
.L_lambda_simple_code_0987:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0aaf
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0aaf:
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
	.L_tc_recycle_frame_loop_0bcb:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bcb
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bcb
	.L_tc_recycle_frame_done_0bcb:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0987:	; new closure is in rax
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
.L_lambda_simple_env_loop_0988:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0988
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0988
.L_lambda_simple_env_end_0988:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0988:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0988
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0988
.L_lambda_simple_params_end_0988:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0988
	jmp .L_lambda_simple_end_0988
.L_lambda_simple_code_0988:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0ab0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ab0:
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
	.L_tc_recycle_frame_loop_0bcc:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bcc
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bcc
	.L_tc_recycle_frame_done_0bcc:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0988:	; new closure is in rax
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
.L_lambda_simple_env_loop_0989:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0989
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0989
.L_lambda_simple_env_end_0989:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0989:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0989
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0989
.L_lambda_simple_params_end_0989:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0989
	jmp .L_lambda_simple_end_0989
.L_lambda_simple_code_0989:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0ab1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ab1:
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
	.L_tc_recycle_frame_loop_0bcd:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bcd
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bcd
	.L_tc_recycle_frame_done_0bcd:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0989:	; new closure is in rax
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
.L_lambda_simple_env_loop_098a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_098a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_098a
.L_lambda_simple_env_end_098a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_098a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_098a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_098a
.L_lambda_simple_params_end_098a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_098a
	jmp .L_lambda_simple_end_098a
.L_lambda_simple_code_098a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0ab2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ab2:
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
	.L_tc_recycle_frame_loop_0bce:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bce
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bce
	.L_tc_recycle_frame_done_0bce:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_098a:	; new closure is in rax
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
.L_lambda_simple_env_loop_098b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_098b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_098b
.L_lambda_simple_env_end_098b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_098b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_098b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_098b
.L_lambda_simple_params_end_098b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_098b
	jmp .L_lambda_simple_end_098b
.L_lambda_simple_code_098b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0ab3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ab3:
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
	.L_tc_recycle_frame_loop_0bcf:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bcf
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bcf
	.L_tc_recycle_frame_done_0bcf:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_098b:	; new closure is in rax
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
.L_lambda_simple_env_loop_098c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_098c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_098c
.L_lambda_simple_env_end_098c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_098c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_098c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_098c
.L_lambda_simple_params_end_098c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_098c
	jmp .L_lambda_simple_end_098c
.L_lambda_simple_code_098c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0ab4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ab4:
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
	.L_tc_recycle_frame_loop_0bd0:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bd0
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bd0
	.L_tc_recycle_frame_done_0bd0:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_098c:	; new closure is in rax
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
.L_lambda_simple_env_loop_098d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_098d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_098d
.L_lambda_simple_env_end_098d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_098d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_098d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_098d
.L_lambda_simple_params_end_098d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_098d
	jmp .L_lambda_simple_end_098d
.L_lambda_simple_code_098d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0ab5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ab5:
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
	.L_tc_recycle_frame_loop_0bd1:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bd1
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bd1
	.L_tc_recycle_frame_done_0bd1:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_098d:	; new closure is in rax
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
.L_lambda_simple_env_loop_098e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_098e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_098e
.L_lambda_simple_env_end_098e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_098e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_098e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_098e
.L_lambda_simple_params_end_098e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_098e
	jmp .L_lambda_simple_end_098e
.L_lambda_simple_code_098e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0ab6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ab6:
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
	.L_tc_recycle_frame_loop_0bd2:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bd2
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bd2
	.L_tc_recycle_frame_done_0bd2:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_098e:	; new closure is in rax
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
.L_lambda_simple_env_loop_098f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_098f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_098f
.L_lambda_simple_env_end_098f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_098f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_098f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_098f
.L_lambda_simple_params_end_098f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_098f
	jmp .L_lambda_simple_end_098f
.L_lambda_simple_code_098f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0ab7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ab7:
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
	.L_tc_recycle_frame_loop_0bd3:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bd3
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bd3
	.L_tc_recycle_frame_done_0bd3:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_098f:	; new closure is in rax
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
.L_lambda_simple_env_loop_0990:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0990
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0990
.L_lambda_simple_env_end_0990:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0990:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0990
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0990
.L_lambda_simple_params_end_0990:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0990
	jmp .L_lambda_simple_end_0990
.L_lambda_simple_code_0990:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0ab8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ab8:
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
	.L_tc_recycle_frame_loop_0bd4:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bd4
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bd4
	.L_tc_recycle_frame_done_0bd4:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0990:	; new closure is in rax
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
.L_lambda_simple_env_loop_0991:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0991
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0991
.L_lambda_simple_env_end_0991:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0991:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0991
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0991
.L_lambda_simple_params_end_0991:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0991
	jmp .L_lambda_simple_end_0991
.L_lambda_simple_code_0991:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0ab9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ab9:
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
	.L_tc_recycle_frame_loop_0bd5:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bd5
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bd5
	.L_tc_recycle_frame_done_0bd5:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0991:	; new closure is in rax
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
.L_lambda_simple_env_loop_0992:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0992
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0992
.L_lambda_simple_env_end_0992:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0992:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0992
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0992
.L_lambda_simple_params_end_0992:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0992
	jmp .L_lambda_simple_end_0992
.L_lambda_simple_code_0992:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0aba
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0aba:
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
	.L_tc_recycle_frame_loop_0bd6:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bd6
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bd6
	.L_tc_recycle_frame_done_0bd6:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0992:	; new closure is in rax
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
.L_lambda_simple_env_loop_0993:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0993
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0993
.L_lambda_simple_env_end_0993:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0993:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0993
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0993
.L_lambda_simple_params_end_0993:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0993
	jmp .L_lambda_simple_end_0993
.L_lambda_simple_code_0993:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0abb
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0abb:
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
	.L_tc_recycle_frame_loop_0bd7:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bd7
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bd7
	.L_tc_recycle_frame_done_0bd7:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0993:	; new closure is in rax
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
.L_lambda_simple_env_loop_0994:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0994
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0994
.L_lambda_simple_env_end_0994:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0994:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0994
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0994
.L_lambda_simple_params_end_0994:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0994
	jmp .L_lambda_simple_end_0994
.L_lambda_simple_code_0994:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0abc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0abc:
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
	.L_tc_recycle_frame_loop_0bd8:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bd8
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bd8
	.L_tc_recycle_frame_done_0bd8:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0994:	; new closure is in rax
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
.L_lambda_simple_env_loop_0995:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0995
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0995
.L_lambda_simple_env_end_0995:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0995:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0995
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0995
.L_lambda_simple_params_end_0995:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0995
	jmp .L_lambda_simple_end_0995
.L_lambda_simple_code_0995:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0abd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0abd:
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
	.L_tc_recycle_frame_loop_0bd9:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bd9
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bd9
	.L_tc_recycle_frame_done_0bd9:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0995:	; new closure is in rax
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
.L_lambda_simple_env_loop_0996:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0996
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0996
.L_lambda_simple_env_end_0996:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0996:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0996
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0996
.L_lambda_simple_params_end_0996:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0996
	jmp .L_lambda_simple_end_0996
.L_lambda_simple_code_0996:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0abe
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0abe:
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
	.L_tc_recycle_frame_loop_0bda:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bda
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bda
	.L_tc_recycle_frame_done_0bda:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0996:	; new closure is in rax
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
.L_lambda_simple_env_loop_0997:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0997
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0997
.L_lambda_simple_env_end_0997:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0997:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0997
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0997
.L_lambda_simple_params_end_0997:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0997
	jmp .L_lambda_simple_end_0997
.L_lambda_simple_code_0997:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0abf
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0abf:
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
	.L_tc_recycle_frame_loop_0bdb:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bdb
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bdb
	.L_tc_recycle_frame_done_0bdb:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0997:	; new closure is in rax
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
.L_lambda_simple_env_loop_0998:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0998
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0998
.L_lambda_simple_env_end_0998:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0998:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0998
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0998
.L_lambda_simple_params_end_0998:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0998
	jmp .L_lambda_simple_end_0998
.L_lambda_simple_code_0998:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0ac0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ac0:
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
	jne .L_if_end_071d
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
	je .L_if_else_0675
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
	.L_tc_recycle_frame_loop_0bdc:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bdc
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bdc
	.L_tc_recycle_frame_done_0bdc:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_071e
.L_if_else_0675:
	mov rax, L_constants + 2
.L_if_end_071e:
	cmp rax, sob_boolean_false
	jne .L_if_end_071d
.L_if_end_071d:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0998:	; new closure is in rax
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
.L_lambda_opt_env_loop_0129:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 0
	je .L_lambda_opt_env_end_0129
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0129
.L_lambda_opt_env_end_0129:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0379:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_0251
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0379
.L_lambda_opt_params_end_0251:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0129
	jmp .L_lambda_opt_end_0251
.L_lambda_opt_code_0129:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	jge .L_lambda_simple_arity_check_ok_0ac1
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ac1:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 0
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_037b
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_037a: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_037a
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0252
	.L_lambda_opt_params_loop_037b:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_037a: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_037a
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_037b:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0252
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_037b
	.L_lambda_opt_params_end_0252:
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
	.L_lambda_opt_end_0252:
	enter 0, 0
	mov rax, PARAM(0)	; param args
	LEAVE
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0251:
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
.L_lambda_simple_env_loop_0999:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0999
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0999
.L_lambda_simple_env_end_0999:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0999:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0999
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0999
.L_lambda_simple_params_end_0999:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0999
	jmp .L_lambda_simple_end_0999
.L_lambda_simple_code_0999:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0ac2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ac2:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	cmp rax, sob_boolean_false
	je .L_if_else_0676
	mov rax, L_constants + 2
	jmp .L_if_end_071f
.L_if_else_0676:
	mov rax, L_constants + 3
.L_if_end_071f:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0999:	; new closure is in rax
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
.L_lambda_simple_env_loop_099a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_099a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_099a
.L_lambda_simple_env_end_099a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_099a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_099a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_099a
.L_lambda_simple_params_end_099a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_099a
	jmp .L_lambda_simple_end_099a
.L_lambda_simple_code_099a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0ac3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ac3:
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
	jne .L_if_end_0720
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
	.L_tc_recycle_frame_loop_0bdd:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bdd
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bdd
	.L_tc_recycle_frame_done_0bdd:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	cmp rax, sob_boolean_false
	jne .L_if_end_0720
.L_if_end_0720:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_099a:	; new closure is in rax
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
.L_lambda_simple_env_loop_099b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_099b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_099b
.L_lambda_simple_env_end_099b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_099b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_099b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_099b
.L_lambda_simple_params_end_099b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_099b
	jmp .L_lambda_simple_end_099b
.L_lambda_simple_code_099b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0ac4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ac4:
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
.L_lambda_simple_env_loop_099c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_099c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_099c
.L_lambda_simple_env_end_099c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_099c:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_099c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_099c
.L_lambda_simple_params_end_099c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_099c
	jmp .L_lambda_simple_end_099c
.L_lambda_simple_code_099c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0ac5
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ac5:
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
	je .L_if_else_0677
	mov rax, PARAM(0)	; param a
	jmp .L_if_end_0721
.L_if_else_0677:
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
	.L_tc_recycle_frame_loop_0bde:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bde
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bde
	.L_tc_recycle_frame_done_0bde:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0721:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_099c:	; new closure is in rax
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
.L_lambda_opt_env_loop_012a:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_012a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_012a
.L_lambda_opt_env_end_012a:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_037c:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0253
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_037c
.L_lambda_opt_params_end_0253:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_012a
	jmp .L_lambda_opt_end_0253
.L_lambda_opt_code_012a:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_0ac6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ac6:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_037e
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_037d: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_037d
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0254
	.L_lambda_opt_params_loop_037e:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_037d: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_037d
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_037e:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0254
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_037e
	.L_lambda_opt_params_end_0254:
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
	.L_lambda_opt_end_0254:
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
	.L_tc_recycle_frame_loop_0bdf:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bdf
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bdf
	.L_tc_recycle_frame_done_0bdf:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0253:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_099b:	; new closure is in rax
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
.L_lambda_simple_env_loop_099d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_099d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_099d
.L_lambda_simple_env_end_099d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_099d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_099d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_099d
.L_lambda_simple_params_end_099d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_099d
	jmp .L_lambda_simple_end_099d
.L_lambda_simple_code_099d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0ac7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ac7:
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
.L_lambda_simple_env_loop_099e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_099e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_099e
.L_lambda_simple_env_end_099e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_099e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_099e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_099e
.L_lambda_simple_params_end_099e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_099e
	jmp .L_lambda_simple_end_099e
.L_lambda_simple_code_099e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0ac8
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ac8:
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
	je .L_if_else_0678
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
	.L_tc_recycle_frame_loop_0be0:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0be0
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0be0
	.L_tc_recycle_frame_done_0be0:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0722
.L_if_else_0678:
	mov rax, PARAM(0)	; param a
.L_if_end_0722:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_099e:	; new closure is in rax
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
.L_lambda_opt_env_loop_012b:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_012b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_012b
.L_lambda_opt_env_end_012b:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_037f:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0255
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_037f
.L_lambda_opt_params_end_0255:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_012b
	jmp .L_lambda_opt_end_0255
.L_lambda_opt_code_012b:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_0ac9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ac9:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_0381
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_0380: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_0380
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0256
	.L_lambda_opt_params_loop_0381:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_0380: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_0380
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_0381:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0256
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_0381
	.L_lambda_opt_params_end_0256:
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
	.L_lambda_opt_end_0256:
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
	.L_tc_recycle_frame_loop_0be1:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0be1
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0be1
	.L_tc_recycle_frame_done_0be1:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0255:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_099d:	; new closure is in rax
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
.L_lambda_opt_env_loop_012c:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 0
	je .L_lambda_opt_env_end_012c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_012c
.L_lambda_opt_env_end_012c:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0382:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_0257
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0382
.L_lambda_opt_params_end_0257:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_012c
	jmp .L_lambda_opt_end_0257
.L_lambda_opt_code_012c:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_0aca
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0aca:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_0384
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_0383: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_0383
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0258
	.L_lambda_opt_params_loop_0384:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_0383: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_0383
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_0384:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0258
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_0384
	.L_lambda_opt_params_end_0258:
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
	.L_lambda_opt_end_0258:
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
.L_lambda_simple_env_loop_099f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_099f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_099f
.L_lambda_simple_env_end_099f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_099f:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_099f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_099f
.L_lambda_simple_params_end_099f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_099f
	jmp .L_lambda_simple_end_099f
.L_lambda_simple_code_099f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0acb
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0acb:
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
.L_lambda_simple_env_loop_09a0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_09a0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09a0
.L_lambda_simple_env_end_09a0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09a0:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09a0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09a0
.L_lambda_simple_params_end_09a0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09a0
	jmp .L_lambda_simple_end_09a0
.L_lambda_simple_code_09a0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0acc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0acc:
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
	je .L_if_else_0679
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
	jne .L_if_end_0723
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
	.L_tc_recycle_frame_loop_0be3:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0be3
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0be3
	.L_tc_recycle_frame_done_0be3:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	cmp rax, sob_boolean_false
	jne .L_if_end_0723
.L_if_end_0723:
	jmp .L_if_end_0724
.L_if_else_0679:
	mov rax, L_constants + 2
.L_if_end_0724:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09a0:	; new closure is in rax
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
	je .L_if_else_067a
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
	.L_tc_recycle_frame_loop_0be4:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0be4
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0be4
	.L_tc_recycle_frame_done_0be4:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0725
.L_if_else_067a:
	mov rax, L_constants + 2
.L_if_end_0725:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_099f:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0be2:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0be2
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0be2
	.L_tc_recycle_frame_done_0be2:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0257:
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
.L_lambda_opt_env_loop_012d:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 0
	je .L_lambda_opt_env_end_012d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_012d
.L_lambda_opt_env_end_012d:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0385:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_0259
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0385
.L_lambda_opt_params_end_0259:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_012d
	jmp .L_lambda_opt_end_0259
.L_lambda_opt_code_012d:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_0acd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0acd:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_0387
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_0386: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_0386
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_025a
	.L_lambda_opt_params_loop_0387:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_0386: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_0386
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_0387:
	cmp rdx, 0
	je .L_lambda_opt_params_end_025a
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_0387
	.L_lambda_opt_params_end_025a:
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
	.L_lambda_opt_end_025a:
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
.L_lambda_simple_env_loop_09a1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_09a1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09a1
.L_lambda_simple_env_end_09a1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09a1:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_09a1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09a1
.L_lambda_simple_params_end_09a1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09a1
	jmp .L_lambda_simple_end_09a1
.L_lambda_simple_code_09a1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0ace
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ace:
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
.L_lambda_simple_env_loop_09a2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_09a2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09a2
.L_lambda_simple_env_end_09a2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09a2:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09a2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09a2
.L_lambda_simple_params_end_09a2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09a2
	jmp .L_lambda_simple_end_09a2
.L_lambda_simple_code_09a2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0acf
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0acf:
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
	jne .L_if_end_0726
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
	je .L_if_else_067b
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
	.L_tc_recycle_frame_loop_0be6:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0be6
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0be6
	.L_tc_recycle_frame_done_0be6:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0727
.L_if_else_067b:
	mov rax, L_constants + 2
.L_if_end_0727:
	cmp rax, sob_boolean_false
	jne .L_if_end_0726
.L_if_end_0726:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09a2:	; new closure is in rax
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
	jne .L_if_end_0728
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
	je .L_if_else_067c
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
	.L_tc_recycle_frame_loop_0be7:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0be7
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0be7
	.L_tc_recycle_frame_done_0be7:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0729
.L_if_else_067c:
	mov rax, L_constants + 2
.L_if_end_0729:
	cmp rax, sob_boolean_false
	jne .L_if_end_0728
.L_if_end_0728:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09a1:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0be5:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0be5
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0be5
	.L_tc_recycle_frame_done_0be5:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0259:
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
.L_lambda_simple_env_loop_09a3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09a3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09a3
.L_lambda_simple_env_end_09a3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09a3:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09a3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09a3
.L_lambda_simple_params_end_09a3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09a3
	jmp .L_lambda_simple_end_09a3
.L_lambda_simple_code_09a3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0ad0
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ad0:
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
.L_lambda_simple_env_loop_09a4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_09a4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09a4
.L_lambda_simple_env_end_09a4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09a4:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_09a4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09a4
.L_lambda_simple_params_end_09a4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09a4
	jmp .L_lambda_simple_end_09a4
.L_lambda_simple_code_09a4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0ad1
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ad1:
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
	je .L_if_else_067d
	mov rax, L_constants + 1
	jmp .L_if_end_072a
.L_if_else_067d:
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
	.L_tc_recycle_frame_loop_0be8:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0be8
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0be8
	.L_tc_recycle_frame_done_0be8:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_072a:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_09a4:	; new closure is in rax
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
.L_lambda_simple_env_loop_09a5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_09a5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09a5
.L_lambda_simple_env_end_09a5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09a5:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_09a5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09a5
.L_lambda_simple_params_end_09a5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09a5
	jmp .L_lambda_simple_end_09a5
.L_lambda_simple_code_09a5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0ad2
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ad2:
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
	je .L_if_else_067e
	mov rax, L_constants + 1
	jmp .L_if_end_072b
.L_if_else_067e:
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
	.L_tc_recycle_frame_loop_0be9:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0be9
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0be9
	.L_tc_recycle_frame_done_0be9:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_072b:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_09a5:	; new closure is in rax
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
.L_lambda_opt_env_loop_012e:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_012e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_012e
.L_lambda_opt_env_end_012e:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0388:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_025b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0388
.L_lambda_opt_params_end_025b:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_012e
	jmp .L_lambda_opt_end_025b
.L_lambda_opt_code_012e:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_0ad3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ad3:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_038a
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_0389: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_0389
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_025c
	.L_lambda_opt_params_loop_038a:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_0389: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_0389
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_038a:
	cmp rdx, 0
	je .L_lambda_opt_params_end_025c
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_038a
	.L_lambda_opt_params_end_025c:
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
	.L_lambda_opt_end_025c:
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
	je .L_if_else_067f
	mov rax, L_constants + 1
	jmp .L_if_end_072c
.L_if_else_067f:
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
	.L_tc_recycle_frame_loop_0bea:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bea
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bea
	.L_tc_recycle_frame_done_0bea:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_072c:
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_025b:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_09a3:	; new closure is in rax
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
.L_lambda_simple_env_loop_09a6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09a6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09a6
.L_lambda_simple_env_end_09a6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09a6:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09a6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09a6
.L_lambda_simple_params_end_09a6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09a6
	jmp .L_lambda_simple_end_09a6
.L_lambda_simple_code_09a6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0ad4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ad4:
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
.L_lambda_simple_env_loop_09a7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_09a7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09a7
.L_lambda_simple_env_end_09a7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09a7:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09a7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09a7
.L_lambda_simple_params_end_09a7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09a7
	jmp .L_lambda_simple_end_09a7
.L_lambda_simple_code_09a7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0ad5
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ad5:
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
	.L_tc_recycle_frame_loop_0bec:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bec
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bec
	.L_tc_recycle_frame_done_0bec:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_09a7:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_0beb:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0beb
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0beb
	.L_tc_recycle_frame_done_0beb:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09a6:	; new closure is in rax
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
.L_lambda_simple_env_loop_09a8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09a8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09a8
.L_lambda_simple_env_end_09a8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09a8:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09a8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09a8
.L_lambda_simple_params_end_09a8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09a8
	jmp .L_lambda_simple_end_09a8
.L_lambda_simple_code_09a8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0ad6
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ad6:
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
.L_lambda_simple_env_loop_09a9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_09a9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09a9
.L_lambda_simple_env_end_09a9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09a9:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_09a9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09a9
.L_lambda_simple_params_end_09a9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09a9
	jmp .L_lambda_simple_end_09a9
.L_lambda_simple_code_09a9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0ad7
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ad7:
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
	je .L_if_else_0680
	mov rax, PARAM(0)	; param s1
	jmp .L_if_end_072d
.L_if_else_0680:
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
	.L_tc_recycle_frame_loop_0bed:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bed
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bed
	.L_tc_recycle_frame_done_0bed:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_072d:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_09a9:	; new closure is in rax
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
.L_lambda_simple_env_loop_09aa:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_09aa
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09aa
.L_lambda_simple_env_end_09aa:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09aa:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_09aa
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09aa
.L_lambda_simple_params_end_09aa:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09aa
	jmp .L_lambda_simple_end_09aa
.L_lambda_simple_code_09aa:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0ad8
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ad8:
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
	je .L_if_else_0681
	mov rax, PARAM(1)	; param s2
	jmp .L_if_end_072e
.L_if_else_0681:
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
	.L_tc_recycle_frame_loop_0bee:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bee
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bee
	.L_tc_recycle_frame_done_0bee:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_072e:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_09aa:	; new closure is in rax
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
.L_lambda_opt_env_loop_012f:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_012f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_012f
.L_lambda_opt_env_end_012f:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_038b:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_025d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_038b
.L_lambda_opt_params_end_025d:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_012f
	jmp .L_lambda_opt_end_025d
.L_lambda_opt_code_012f:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	jge .L_lambda_simple_arity_check_ok_0ad9
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ad9:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 0
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_038d
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_038c: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_038c
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_025e
	.L_lambda_opt_params_loop_038d:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_038c: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_038c
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_038d:
	cmp rdx, 0
	je .L_lambda_opt_params_end_025e
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_038d
	.L_lambda_opt_params_end_025e:
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
	.L_lambda_opt_end_025e:
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
	je .L_if_else_0682
	mov rax, L_constants + 1
	jmp .L_if_end_072f
.L_if_else_0682:
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
	.L_tc_recycle_frame_loop_0bef:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bef
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bef
	.L_tc_recycle_frame_done_0bef:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_072f:
	LEAVE
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_025d:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_09a8:	; new closure is in rax
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
.L_lambda_simple_env_loop_09ab:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09ab
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09ab
.L_lambda_simple_env_end_09ab:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09ab:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09ab
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09ab
.L_lambda_simple_params_end_09ab:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09ab
	jmp .L_lambda_simple_end_09ab
.L_lambda_simple_code_09ab:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0ada
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ada:
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
.L_lambda_simple_env_loop_09ac:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_09ac
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09ac
.L_lambda_simple_env_end_09ac:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09ac:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09ac
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09ac
.L_lambda_simple_params_end_09ac:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09ac
	jmp .L_lambda_simple_end_09ac
.L_lambda_simple_code_09ac:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0adb
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0adb:
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
	je .L_if_else_0683
	mov rax, PARAM(1)	; param unit
	jmp .L_if_end_0730
.L_if_else_0683:
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
	.L_tc_recycle_frame_loop_0bf0:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bf0
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bf0
	.L_tc_recycle_frame_done_0bf0:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0730:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_09ac:	; new closure is in rax
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
.L_lambda_opt_env_loop_0130:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_0130
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0130
.L_lambda_opt_env_end_0130:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_038e:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_025f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_038e
.L_lambda_opt_params_end_025f:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0130
	jmp .L_lambda_opt_end_025f
.L_lambda_opt_code_0130:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 2
	jge .L_lambda_simple_arity_check_ok_0adc
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0adc:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 2
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_0390
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_038f: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_038f
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0260
	.L_lambda_opt_params_loop_0390:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_038f: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_038f
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_0390:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0260
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_0390
	.L_lambda_opt_params_end_0260:
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
	.L_lambda_opt_end_0260:
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
	.L_tc_recycle_frame_loop_0bf1:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bf1
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bf1
	.L_tc_recycle_frame_done_0bf1:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(3)
.L_lambda_opt_end_025f:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09ab:	; new closure is in rax
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
.L_lambda_simple_env_loop_09ad:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09ad
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09ad
.L_lambda_simple_env_end_09ad:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09ad:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09ad
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09ad
.L_lambda_simple_params_end_09ad:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09ad
	jmp .L_lambda_simple_end_09ad
.L_lambda_simple_code_09ad:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0add
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0add:
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
.L_lambda_simple_env_loop_09ae:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_09ae
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09ae
.L_lambda_simple_env_end_09ae:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09ae:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09ae
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09ae
.L_lambda_simple_params_end_09ae:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09ae
	jmp .L_lambda_simple_end_09ae
.L_lambda_simple_code_09ae:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0ade
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ade:
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
	je .L_if_else_0684
	mov rax, PARAM(1)	; param unit
	jmp .L_if_end_0731
.L_if_else_0684:
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
	.L_tc_recycle_frame_loop_0bf2:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bf2
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bf2
	.L_tc_recycle_frame_done_0bf2:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0731:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_09ae:	; new closure is in rax
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
.L_lambda_opt_env_loop_0131:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_0131
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0131
.L_lambda_opt_env_end_0131:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0391:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0261
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0391
.L_lambda_opt_params_end_0261:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0131
	jmp .L_lambda_opt_end_0261
.L_lambda_opt_code_0131:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 2
	jge .L_lambda_simple_arity_check_ok_0adf
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0adf:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 2
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_0393
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_0392: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_0392
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0262
	.L_lambda_opt_params_loop_0393:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_0392: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_0392
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_0393:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0262
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_0393
	.L_lambda_opt_params_end_0262:
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
	.L_lambda_opt_end_0262:
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
	.L_tc_recycle_frame_loop_0bf3:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bf3
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bf3
	.L_tc_recycle_frame_done_0bf3:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(3)
.L_lambda_opt_end_0261:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09ad:	; new closure is in rax
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
.L_lambda_simple_env_loop_09af:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09af
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09af
.L_lambda_simple_env_end_09af:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09af:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09af
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09af
.L_lambda_simple_params_end_09af:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09af
	jmp .L_lambda_simple_end_09af
.L_lambda_simple_code_09af:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0ae0
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ae0:
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
	.L_tc_recycle_frame_loop_0bf4:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bf4
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bf4
	.L_tc_recycle_frame_done_0bf4:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_09af:	; new closure is in rax
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
.L_lambda_simple_env_loop_09b0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09b0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09b0
.L_lambda_simple_env_end_09b0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09b0:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09b0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09b0
.L_lambda_simple_params_end_09b0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09b0
	jmp .L_lambda_simple_end_09b0
.L_lambda_simple_code_09b0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0ae1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ae1:
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
.L_lambda_simple_env_loop_09b1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_09b1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09b1
.L_lambda_simple_env_end_09b1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09b1:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09b1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09b1
.L_lambda_simple_params_end_09b1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09b1
	jmp .L_lambda_simple_end_09b1
.L_lambda_simple_code_09b1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0ae2
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ae2:
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
	je .L_if_else_0690
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
	je .L_if_else_0687
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
	.L_tc_recycle_frame_loop_0bf6:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bf6
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bf6
	.L_tc_recycle_frame_done_0bf6:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0734
.L_if_else_0687:
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
	je .L_if_else_0686
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
	.L_tc_recycle_frame_loop_0bf7:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bf7
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bf7
	.L_tc_recycle_frame_done_0bf7:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0733
.L_if_else_0686:
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
	je .L_if_else_0685
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
	.L_tc_recycle_frame_loop_0bf8:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bf8
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bf8
	.L_tc_recycle_frame_done_0bf8:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0732
.L_if_else_0685:
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
	.L_tc_recycle_frame_loop_0bf9:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bf9
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bf9
	.L_tc_recycle_frame_done_0bf9:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0732:
.L_if_end_0733:
.L_if_end_0734:
	jmp .L_if_end_073d
.L_if_else_0690:
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
	je .L_if_else_068f
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
	je .L_if_else_068a
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
	.L_tc_recycle_frame_loop_0bfa:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bfa
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bfa
	.L_tc_recycle_frame_done_0bfa:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0737
.L_if_else_068a:
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
	je .L_if_else_0689
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
	.L_tc_recycle_frame_loop_0bfb:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bfb
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bfb
	.L_tc_recycle_frame_done_0bfb:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0736
.L_if_else_0689:
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
	je .L_if_else_0688
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
	.L_tc_recycle_frame_loop_0bfc:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bfc
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bfc
	.L_tc_recycle_frame_done_0bfc:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0735
.L_if_else_0688:
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
	.L_tc_recycle_frame_loop_0bfd:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bfd
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bfd
	.L_tc_recycle_frame_done_0bfd:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0735:
.L_if_end_0736:
.L_if_end_0737:
	jmp .L_if_end_073c
.L_if_else_068f:
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
	je .L_if_else_068e
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
	je .L_if_else_068d
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
	.L_tc_recycle_frame_loop_0bfe:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bfe
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bfe
	.L_tc_recycle_frame_done_0bfe:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_073a
.L_if_else_068d:
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
	je .L_if_else_068c
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
	.L_tc_recycle_frame_loop_0bff:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bff
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bff
	.L_tc_recycle_frame_done_0bff:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0739
.L_if_else_068c:
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
	je .L_if_else_068b
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
	.L_tc_recycle_frame_loop_0c00:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c00
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c00
	.L_tc_recycle_frame_done_0c00:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0738
.L_if_else_068b:
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
	.L_tc_recycle_frame_loop_0c01:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c01
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c01
	.L_tc_recycle_frame_done_0c01:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0738:
.L_if_end_0739:
.L_if_end_073a:
	jmp .L_if_end_073b
.L_if_else_068e:
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
	.L_tc_recycle_frame_loop_0c02:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c02
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c02
	.L_tc_recycle_frame_done_0c02:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_073b:
.L_if_end_073c:
.L_if_end_073d:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_09b1:	; new closure is in rax
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
.L_lambda_simple_env_loop_09b2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_09b2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09b2
.L_lambda_simple_env_end_09b2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09b2:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09b2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09b2
.L_lambda_simple_params_end_09b2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09b2
	jmp .L_lambda_simple_end_09b2
.L_lambda_simple_code_09b2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0ae3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ae3:
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
.L_lambda_opt_env_loop_0132:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 2
	je .L_lambda_opt_env_end_0132
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0132
.L_lambda_opt_env_end_0132:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0394:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0263
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0394
.L_lambda_opt_params_end_0263:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0132
	jmp .L_lambda_opt_end_0263
.L_lambda_opt_code_0132:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	jge .L_lambda_simple_arity_check_ok_0ae4
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ae4:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 0
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_0396
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_0395: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_0395
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0264
	.L_lambda_opt_params_loop_0396:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_0395: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_0395
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_0396:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0264
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_0396
	.L_lambda_opt_params_end_0264:
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
	.L_lambda_opt_end_0264:
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
	.L_tc_recycle_frame_loop_0c03:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c03
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c03
	.L_tc_recycle_frame_done_0c03:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0263:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09b2:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0bf5:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0bf5
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0bf5
	.L_tc_recycle_frame_done_0bf5:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09b0:	; new closure is in rax
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
.L_lambda_simple_env_loop_09b3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09b3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09b3
.L_lambda_simple_env_end_09b3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09b3:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09b3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09b3
.L_lambda_simple_params_end_09b3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09b3
	jmp .L_lambda_simple_end_09b3
.L_lambda_simple_code_09b3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0ae5
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ae5:
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
	.L_tc_recycle_frame_loop_0c04:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c04
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c04
	.L_tc_recycle_frame_done_0c04:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_09b3:	; new closure is in rax
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
.L_lambda_simple_env_loop_09b4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09b4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09b4
.L_lambda_simple_env_end_09b4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09b4:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09b4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09b4
.L_lambda_simple_params_end_09b4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09b4
	jmp .L_lambda_simple_end_09b4
.L_lambda_simple_code_09b4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0ae6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ae6:
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
.L_lambda_simple_env_loop_09b5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_09b5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09b5
.L_lambda_simple_env_end_09b5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09b5:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09b5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09b5
.L_lambda_simple_params_end_09b5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09b5
	jmp .L_lambda_simple_end_09b5
.L_lambda_simple_code_09b5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0ae7
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ae7:
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
	je .L_if_else_069c
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
	je .L_if_else_0693
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
	.L_tc_recycle_frame_loop_0c06:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c06
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c06
	.L_tc_recycle_frame_done_0c06:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0740
.L_if_else_0693:
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
	je .L_if_else_0692
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
	.L_tc_recycle_frame_loop_0c07:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c07
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c07
	.L_tc_recycle_frame_done_0c07:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_073f
.L_if_else_0692:
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
	je .L_if_else_0691
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
	.L_tc_recycle_frame_loop_0c08:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c08
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c08
	.L_tc_recycle_frame_done_0c08:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_073e
.L_if_else_0691:
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
	.L_tc_recycle_frame_loop_0c09:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c09
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c09
	.L_tc_recycle_frame_done_0c09:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_073e:
.L_if_end_073f:
.L_if_end_0740:
	jmp .L_if_end_0749
.L_if_else_069c:
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
	je .L_if_else_069b
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
	je .L_if_else_0696
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
	.L_tc_recycle_frame_loop_0c0a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c0a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c0a
	.L_tc_recycle_frame_done_0c0a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0743
.L_if_else_0696:
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
	je .L_if_else_0695
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
	.L_tc_recycle_frame_loop_0c0b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c0b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c0b
	.L_tc_recycle_frame_done_0c0b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0742
.L_if_else_0695:
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
	je .L_if_else_0694
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
	.L_tc_recycle_frame_loop_0c0c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c0c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c0c
	.L_tc_recycle_frame_done_0c0c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0741
.L_if_else_0694:
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
	.L_tc_recycle_frame_loop_0c0d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c0d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c0d
	.L_tc_recycle_frame_done_0c0d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0741:
.L_if_end_0742:
.L_if_end_0743:
	jmp .L_if_end_0748
.L_if_else_069b:
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
	je .L_if_else_069a
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
	je .L_if_else_0699
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
	.L_tc_recycle_frame_loop_0c0e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c0e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c0e
	.L_tc_recycle_frame_done_0c0e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0746
.L_if_else_0699:
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
	je .L_if_else_0698
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
	.L_tc_recycle_frame_loop_0c0f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c0f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c0f
	.L_tc_recycle_frame_done_0c0f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0745
.L_if_else_0698:
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
	je .L_if_else_0697
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
	.L_tc_recycle_frame_loop_0c10:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c10
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c10
	.L_tc_recycle_frame_done_0c10:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0744
.L_if_else_0697:
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
	.L_tc_recycle_frame_loop_0c11:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c11
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c11
	.L_tc_recycle_frame_done_0c11:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0744:
.L_if_end_0745:
.L_if_end_0746:
	jmp .L_if_end_0747
.L_if_else_069a:
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
	.L_tc_recycle_frame_loop_0c12:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c12
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c12
	.L_tc_recycle_frame_done_0c12:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0747:
.L_if_end_0748:
.L_if_end_0749:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_09b5:	; new closure is in rax
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
.L_lambda_simple_env_loop_09b6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_09b6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09b6
.L_lambda_simple_env_end_09b6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09b6:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09b6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09b6
.L_lambda_simple_params_end_09b6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09b6
	jmp .L_lambda_simple_end_09b6
.L_lambda_simple_code_09b6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0ae8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ae8:
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
.L_lambda_opt_env_loop_0133:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 2
	je .L_lambda_opt_env_end_0133
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0133
.L_lambda_opt_env_end_0133:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0397:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0265
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0397
.L_lambda_opt_params_end_0265:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0133
	jmp .L_lambda_opt_end_0265
.L_lambda_opt_code_0133:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_0ae9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0ae9:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_0399
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_0398: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_0398
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0266
	.L_lambda_opt_params_loop_0399:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_0398: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_0398
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_0399:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0266
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_0399
	.L_lambda_opt_params_end_0266:
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
	.L_lambda_opt_end_0266:
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
	je .L_if_else_069d
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
	.L_tc_recycle_frame_loop_0c13:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c13
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c13
	.L_tc_recycle_frame_done_0c13:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_074a
.L_if_else_069d:
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
.L_lambda_simple_env_loop_09b7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_09b7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09b7
.L_lambda_simple_env_end_09b7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09b7:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_09b7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09b7
.L_lambda_simple_params_end_09b7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09b7
	jmp .L_lambda_simple_end_09b7
.L_lambda_simple_code_09b7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0aea
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0aea:
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
	.L_tc_recycle_frame_loop_0c15:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c15
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c15
	.L_tc_recycle_frame_done_0c15:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09b7:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c14:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c14
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c14
	.L_tc_recycle_frame_done_0c14:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_074a:
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0265:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09b6:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c05:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c05
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c05
	.L_tc_recycle_frame_done_0c05:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09b4:	; new closure is in rax
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
.L_lambda_simple_env_loop_09b8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09b8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09b8
.L_lambda_simple_env_end_09b8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09b8:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09b8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09b8
.L_lambda_simple_params_end_09b8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09b8
	jmp .L_lambda_simple_end_09b8
.L_lambda_simple_code_09b8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0aeb
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0aeb:
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
	.L_tc_recycle_frame_loop_0c16:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c16
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c16
	.L_tc_recycle_frame_done_0c16:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_09b8:	; new closure is in rax
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
.L_lambda_simple_env_loop_09b9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09b9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09b9
.L_lambda_simple_env_end_09b9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09b9:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09b9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09b9
.L_lambda_simple_params_end_09b9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09b9
	jmp .L_lambda_simple_end_09b9
.L_lambda_simple_code_09b9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0aec
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0aec:
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
.L_lambda_simple_env_loop_09ba:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_09ba
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09ba
.L_lambda_simple_env_end_09ba:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09ba:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09ba
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09ba
.L_lambda_simple_params_end_09ba:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09ba
	jmp .L_lambda_simple_end_09ba
.L_lambda_simple_code_09ba:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0aed
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0aed:
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
	je .L_if_else_06a9
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
	je .L_if_else_06a0
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
	.L_tc_recycle_frame_loop_0c18:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c18
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c18
	.L_tc_recycle_frame_done_0c18:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_074d
.L_if_else_06a0:
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
	je .L_if_else_069f
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
	.L_tc_recycle_frame_loop_0c19:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c19
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c19
	.L_tc_recycle_frame_done_0c19:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_074c
.L_if_else_069f:
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
	je .L_if_else_069e
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
	.L_tc_recycle_frame_loop_0c1a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c1a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c1a
	.L_tc_recycle_frame_done_0c1a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_074b
.L_if_else_069e:
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
	.L_tc_recycle_frame_loop_0c1b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c1b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c1b
	.L_tc_recycle_frame_done_0c1b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_074b:
.L_if_end_074c:
.L_if_end_074d:
	jmp .L_if_end_0756
.L_if_else_06a9:
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
	je .L_if_else_06a8
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
	je .L_if_else_06a3
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
	.L_tc_recycle_frame_loop_0c1c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c1c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c1c
	.L_tc_recycle_frame_done_0c1c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0750
.L_if_else_06a3:
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
	je .L_if_else_06a2
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
	.L_tc_recycle_frame_loop_0c1d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c1d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c1d
	.L_tc_recycle_frame_done_0c1d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_074f
.L_if_else_06a2:
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
	je .L_if_else_06a1
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
	.L_tc_recycle_frame_loop_0c1e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c1e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c1e
	.L_tc_recycle_frame_done_0c1e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_074e
.L_if_else_06a1:
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
	.L_tc_recycle_frame_loop_0c1f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c1f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c1f
	.L_tc_recycle_frame_done_0c1f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_074e:
.L_if_end_074f:
.L_if_end_0750:
	jmp .L_if_end_0755
.L_if_else_06a8:
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
	je .L_if_else_06a7
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
	je .L_if_else_06a6
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
	.L_tc_recycle_frame_loop_0c20:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c20
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c20
	.L_tc_recycle_frame_done_0c20:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0753
.L_if_else_06a6:
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
	je .L_if_else_06a5
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
	.L_tc_recycle_frame_loop_0c21:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c21
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c21
	.L_tc_recycle_frame_done_0c21:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0752
.L_if_else_06a5:
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
	je .L_if_else_06a4
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
	.L_tc_recycle_frame_loop_0c22:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c22
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c22
	.L_tc_recycle_frame_done_0c22:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0751
.L_if_else_06a4:
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
	.L_tc_recycle_frame_loop_0c23:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c23
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c23
	.L_tc_recycle_frame_done_0c23:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0751:
.L_if_end_0752:
.L_if_end_0753:
	jmp .L_if_end_0754
.L_if_else_06a7:
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
	.L_tc_recycle_frame_loop_0c24:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c24
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c24
	.L_tc_recycle_frame_done_0c24:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0754:
.L_if_end_0755:
.L_if_end_0756:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_09ba:	; new closure is in rax
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
.L_lambda_simple_env_loop_09bb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_09bb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09bb
.L_lambda_simple_env_end_09bb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09bb:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09bb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09bb
.L_lambda_simple_params_end_09bb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09bb
	jmp .L_lambda_simple_end_09bb
.L_lambda_simple_code_09bb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0aee
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0aee:
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
.L_lambda_opt_env_loop_0134:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 2
	je .L_lambda_opt_env_end_0134
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0134
.L_lambda_opt_env_end_0134:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_039a:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0267
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_039a
.L_lambda_opt_params_end_0267:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0134
	jmp .L_lambda_opt_end_0267
.L_lambda_opt_code_0134:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	jge .L_lambda_simple_arity_check_ok_0aef
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0aef:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 0
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_039c
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_039b: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_039b
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0268
	.L_lambda_opt_params_loop_039c:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_039b: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_039b
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_039c:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0268
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_039c
	.L_lambda_opt_params_end_0268:
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
	.L_lambda_opt_end_0268:
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
	.L_tc_recycle_frame_loop_0c25:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c25
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c25
	.L_tc_recycle_frame_done_0c25:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0267:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09bb:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c17:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c17
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c17
	.L_tc_recycle_frame_done_0c17:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09b9:	; new closure is in rax
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
.L_lambda_simple_env_loop_09bc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09bc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09bc
.L_lambda_simple_env_end_09bc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09bc:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09bc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09bc
.L_lambda_simple_params_end_09bc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09bc
	jmp .L_lambda_simple_end_09bc
.L_lambda_simple_code_09bc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0af0
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0af0:
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
	.L_tc_recycle_frame_loop_0c26:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c26
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c26
	.L_tc_recycle_frame_done_0c26:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_09bc:	; new closure is in rax
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
.L_lambda_simple_env_loop_09bd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09bd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09bd
.L_lambda_simple_env_end_09bd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09bd:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09bd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09bd
.L_lambda_simple_params_end_09bd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09bd
	jmp .L_lambda_simple_end_09bd
.L_lambda_simple_code_09bd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0af1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0af1:
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
.L_lambda_simple_env_loop_09be:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_09be
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09be
.L_lambda_simple_env_end_09be:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09be:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09be
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09be
.L_lambda_simple_params_end_09be:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09be
	jmp .L_lambda_simple_end_09be
.L_lambda_simple_code_09be:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0af2
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0af2:
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
	je .L_if_else_06b5
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
	je .L_if_else_06ac
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
	.L_tc_recycle_frame_loop_0c28:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c28
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c28
	.L_tc_recycle_frame_done_0c28:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0759
.L_if_else_06ac:
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
	je .L_if_else_06ab
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
	.L_tc_recycle_frame_loop_0c29:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c29
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c29
	.L_tc_recycle_frame_done_0c29:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0758
.L_if_else_06ab:
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
	je .L_if_else_06aa
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
	.L_tc_recycle_frame_loop_0c2a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c2a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c2a
	.L_tc_recycle_frame_done_0c2a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0757
.L_if_else_06aa:
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
	.L_tc_recycle_frame_loop_0c2b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c2b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c2b
	.L_tc_recycle_frame_done_0c2b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0757:
.L_if_end_0758:
.L_if_end_0759:
	jmp .L_if_end_0762
.L_if_else_06b5:
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
	je .L_if_else_06b4
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
	je .L_if_else_06af
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
	.L_tc_recycle_frame_loop_0c2c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c2c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c2c
	.L_tc_recycle_frame_done_0c2c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_075c
.L_if_else_06af:
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
	je .L_if_else_06ae
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
	.L_tc_recycle_frame_loop_0c2d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c2d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c2d
	.L_tc_recycle_frame_done_0c2d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_075b
.L_if_else_06ae:
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
	je .L_if_else_06ad
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
	.L_tc_recycle_frame_loop_0c2e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c2e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c2e
	.L_tc_recycle_frame_done_0c2e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_075a
.L_if_else_06ad:
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
	.L_tc_recycle_frame_loop_0c2f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c2f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c2f
	.L_tc_recycle_frame_done_0c2f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_075a:
.L_if_end_075b:
.L_if_end_075c:
	jmp .L_if_end_0761
.L_if_else_06b4:
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
	je .L_if_else_06b3
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
	je .L_if_else_06b2
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
	.L_tc_recycle_frame_loop_0c30:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c30
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c30
	.L_tc_recycle_frame_done_0c30:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_075f
.L_if_else_06b2:
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
	je .L_if_else_06b1
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
	.L_tc_recycle_frame_loop_0c31:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c31
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c31
	.L_tc_recycle_frame_done_0c31:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_075e
.L_if_else_06b1:
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
	je .L_if_else_06b0
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
	.L_tc_recycle_frame_loop_0c32:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c32
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c32
	.L_tc_recycle_frame_done_0c32:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_075d
.L_if_else_06b0:
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
	.L_tc_recycle_frame_loop_0c33:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c33
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c33
	.L_tc_recycle_frame_done_0c33:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_075d:
.L_if_end_075e:
.L_if_end_075f:
	jmp .L_if_end_0760
.L_if_else_06b3:
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
	.L_tc_recycle_frame_loop_0c34:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c34
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c34
	.L_tc_recycle_frame_done_0c34:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0760:
.L_if_end_0761:
.L_if_end_0762:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_09be:	; new closure is in rax
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
.L_lambda_simple_env_loop_09bf:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_09bf
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09bf
.L_lambda_simple_env_end_09bf:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09bf:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09bf
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09bf
.L_lambda_simple_params_end_09bf:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09bf
	jmp .L_lambda_simple_end_09bf
.L_lambda_simple_code_09bf:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0af3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0af3:
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
.L_lambda_opt_env_loop_0135:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 2
	je .L_lambda_opt_env_end_0135
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0135
.L_lambda_opt_env_end_0135:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_039d:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0269
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_039d
.L_lambda_opt_params_end_0269:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0135
	jmp .L_lambda_opt_end_0269
.L_lambda_opt_code_0135:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_0af4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0af4:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_039f
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_039e: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_039e
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_026a
	.L_lambda_opt_params_loop_039f:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_039e: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_039e
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_039f:
	cmp rdx, 0
	je .L_lambda_opt_params_end_026a
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_039f
	.L_lambda_opt_params_end_026a:
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
	.L_lambda_opt_end_026a:
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
	je .L_if_else_06b6
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
	.L_tc_recycle_frame_loop_0c35:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c35
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c35
	.L_tc_recycle_frame_done_0c35:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0763
.L_if_else_06b6:
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
.L_lambda_simple_env_loop_09c0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_09c0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09c0
.L_lambda_simple_env_end_09c0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09c0:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_09c0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09c0
.L_lambda_simple_params_end_09c0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09c0
	jmp .L_lambda_simple_end_09c0
.L_lambda_simple_code_09c0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0af5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0af5:
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
	.L_tc_recycle_frame_loop_0c37:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c37
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c37
	.L_tc_recycle_frame_done_0c37:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09c0:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c36:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c36
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c36
	.L_tc_recycle_frame_done_0c36:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0763:
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0269:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09bf:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c27:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c27
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c27
	.L_tc_recycle_frame_done_0c27:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09bd:	; new closure is in rax
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
.L_lambda_simple_env_loop_09c1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09c1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09c1
.L_lambda_simple_env_end_09c1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09c1:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09c1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09c1
.L_lambda_simple_params_end_09c1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09c1
	jmp .L_lambda_simple_end_09c1
.L_lambda_simple_code_09c1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0af6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0af6:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_151]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_06b7
	mov rax, L_constants + 2270
	jmp .L_if_end_0764
.L_if_else_06b7:
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
	.L_tc_recycle_frame_loop_0c38:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c38
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c38
	.L_tc_recycle_frame_done_0c38:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0764:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09c1:	; new closure is in rax
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
.L_lambda_simple_env_loop_09c2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09c2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09c2
.L_lambda_simple_env_end_09c2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09c2:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09c2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09c2
.L_lambda_simple_params_end_09c2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09c2
	jmp .L_lambda_simple_end_09c2
.L_lambda_simple_code_09c2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0af7
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0af7:
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
	.L_tc_recycle_frame_loop_0c39:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c39
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c39
	.L_tc_recycle_frame_done_0c39:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_09c2:	; new closure is in rax
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
.L_lambda_simple_env_loop_09c3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09c3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09c3
.L_lambda_simple_env_end_09c3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09c3:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09c3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09c3
.L_lambda_simple_params_end_09c3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09c3
	jmp .L_lambda_simple_end_09c3
.L_lambda_simple_code_09c3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0af8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0af8:
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
.L_lambda_simple_env_loop_09c4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_09c4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09c4
.L_lambda_simple_env_end_09c4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09c4:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09c4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09c4
.L_lambda_simple_params_end_09c4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09c4
	jmp .L_lambda_simple_end_09c4
.L_lambda_simple_code_09c4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0af9
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0af9:
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
.L_lambda_simple_env_loop_09c5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_09c5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09c5
.L_lambda_simple_env_end_09c5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09c5:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_09c5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09c5
.L_lambda_simple_params_end_09c5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09c5
	jmp .L_lambda_simple_end_09c5
.L_lambda_simple_code_09c5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0afa
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0afa:
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
	je .L_if_else_06c3
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
	je .L_if_else_06ba
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
	.L_tc_recycle_frame_loop_0c3b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c3b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c3b
	.L_tc_recycle_frame_done_0c3b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0767
.L_if_else_06ba:
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
	je .L_if_else_06b9
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
	.L_tc_recycle_frame_loop_0c3c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c3c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c3c
	.L_tc_recycle_frame_done_0c3c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0766
.L_if_else_06b9:
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
	je .L_if_else_06b8
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
	.L_tc_recycle_frame_loop_0c3d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c3d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c3d
	.L_tc_recycle_frame_done_0c3d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0765
.L_if_else_06b8:
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
	.L_tc_recycle_frame_loop_0c3e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c3e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c3e
	.L_tc_recycle_frame_done_0c3e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0765:
.L_if_end_0766:
.L_if_end_0767:
	jmp .L_if_end_0770
.L_if_else_06c3:
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
	je .L_if_else_06c2
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
	je .L_if_else_06bd
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
	.L_tc_recycle_frame_loop_0c3f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c3f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c3f
	.L_tc_recycle_frame_done_0c3f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_076a
.L_if_else_06bd:
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
	je .L_if_else_06bc
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
	.L_tc_recycle_frame_loop_0c40:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c40
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c40
	.L_tc_recycle_frame_done_0c40:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0769
.L_if_else_06bc:
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
	je .L_if_else_06bb
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
	.L_tc_recycle_frame_loop_0c41:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c41
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c41
	.L_tc_recycle_frame_done_0c41:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0768
.L_if_else_06bb:
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
	.L_tc_recycle_frame_loop_0c42:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c42
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c42
	.L_tc_recycle_frame_done_0c42:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0768:
.L_if_end_0769:
.L_if_end_076a:
	jmp .L_if_end_076f
.L_if_else_06c2:
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
	je .L_if_else_06c1
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
	je .L_if_else_06c0
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
	.L_tc_recycle_frame_loop_0c43:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c43
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c43
	.L_tc_recycle_frame_done_0c43:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_076d
.L_if_else_06c0:
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
	je .L_if_else_06bf
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
	.L_tc_recycle_frame_loop_0c44:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c44
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c44
	.L_tc_recycle_frame_done_0c44:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_076c
.L_if_else_06bf:
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
	je .L_if_else_06be
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
	.L_tc_recycle_frame_loop_0c45:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c45
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c45
	.L_tc_recycle_frame_done_0c45:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_076b
.L_if_else_06be:
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
	.L_tc_recycle_frame_loop_0c46:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c46
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c46
	.L_tc_recycle_frame_done_0c46:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_076b:
.L_if_end_076c:
.L_if_end_076d:
	jmp .L_if_end_076e
.L_if_else_06c1:
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
	.L_tc_recycle_frame_loop_0c47:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c47
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c47
	.L_tc_recycle_frame_done_0c47:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_076e:
.L_if_end_076f:
.L_if_end_0770:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_09c5:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_09c4:	; new closure is in rax
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
.L_lambda_simple_env_loop_09c6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_09c6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09c6
.L_lambda_simple_env_end_09c6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09c6:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09c6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09c6
.L_lambda_simple_params_end_09c6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09c6
	jmp .L_lambda_simple_end_09c6
.L_lambda_simple_code_09c6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0afb
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0afb:
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
.L_lambda_simple_env_loop_09c7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_09c7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09c7
.L_lambda_simple_env_end_09c7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09c7:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09c7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09c7
.L_lambda_simple_params_end_09c7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09c7
	jmp .L_lambda_simple_end_09c7
.L_lambda_simple_code_09c7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0afc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0afc:
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
.L_lambda_simple_env_loop_09c8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_09c8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09c8
.L_lambda_simple_env_end_09c8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09c8:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09c8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09c8
.L_lambda_simple_params_end_09c8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09c8
	jmp .L_lambda_simple_end_09c8
.L_lambda_simple_code_09c8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0afd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0afd:
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
.L_lambda_simple_env_loop_09c9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_09c9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09c9
.L_lambda_simple_env_end_09c9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09c9:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09c9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09c9
.L_lambda_simple_params_end_09c9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09c9
	jmp .L_lambda_simple_end_09c9
.L_lambda_simple_code_09c9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0afe
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0afe:
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
	.L_tc_recycle_frame_loop_0c4b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c4b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c4b
	.L_tc_recycle_frame_done_0c4b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_09c9:	; new closure is in rax
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
.L_lambda_simple_env_loop_09ca:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_09ca
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09ca
.L_lambda_simple_env_end_09ca:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09ca:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09ca
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09ca
.L_lambda_simple_params_end_09ca:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09ca
	jmp .L_lambda_simple_end_09ca
.L_lambda_simple_code_09ca:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0aff
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0aff:
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
.L_lambda_simple_env_loop_09cb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_09cb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09cb
.L_lambda_simple_env_end_09cb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09cb:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09cb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09cb
.L_lambda_simple_params_end_09cb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09cb
	jmp .L_lambda_simple_end_09cb
.L_lambda_simple_code_09cb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b00
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b00:
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
	.L_tc_recycle_frame_loop_0c4d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c4d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c4d
	.L_tc_recycle_frame_done_0c4d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_09cb:	; new closure is in rax
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
.L_lambda_simple_env_loop_09cc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_09cc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09cc
.L_lambda_simple_env_end_09cc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09cc:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09cc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09cc
.L_lambda_simple_params_end_09cc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09cc
	jmp .L_lambda_simple_end_09cc
.L_lambda_simple_code_09cc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b01
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b01:
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
.L_lambda_simple_env_loop_09cd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_09cd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09cd
.L_lambda_simple_env_end_09cd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09cd:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09cd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09cd
.L_lambda_simple_params_end_09cd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09cd
	jmp .L_lambda_simple_end_09cd
.L_lambda_simple_code_09cd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b02
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b02:
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
	.L_tc_recycle_frame_loop_0c4f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c4f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c4f
	.L_tc_recycle_frame_done_0c4f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_09cd:	; new closure is in rax
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
.L_lambda_simple_env_loop_09ce:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_09ce
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09ce
.L_lambda_simple_env_end_09ce:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09ce:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09ce
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09ce
.L_lambda_simple_params_end_09ce:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09ce
	jmp .L_lambda_simple_end_09ce
.L_lambda_simple_code_09ce:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b03
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b03:
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
.L_lambda_simple_env_loop_09cf:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_09cf
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09cf
.L_lambda_simple_env_end_09cf:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09cf:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09cf
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09cf
.L_lambda_simple_params_end_09cf:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09cf
	jmp .L_lambda_simple_end_09cf
.L_lambda_simple_code_09cf:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b04
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b04:
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
.L_lambda_simple_env_loop_09d0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 8
	je .L_lambda_simple_env_end_09d0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09d0
.L_lambda_simple_env_end_09d0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09d0:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09d0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09d0
.L_lambda_simple_params_end_09d0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09d0
	jmp .L_lambda_simple_end_09d0
.L_lambda_simple_code_09d0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b05
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b05:
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
.L_lambda_simple_env_loop_09d1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 9
	je .L_lambda_simple_env_end_09d1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09d1
.L_lambda_simple_env_end_09d1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09d1:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09d1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09d1
.L_lambda_simple_params_end_09d1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09d1
	jmp .L_lambda_simple_end_09d1
.L_lambda_simple_code_09d1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b06
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b06:
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
	jne .L_if_end_0771
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
	je .L_if_else_06c4
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
	.L_tc_recycle_frame_loop_0c52:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c52
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c52
	.L_tc_recycle_frame_done_0c52:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0772
.L_if_else_06c4:
	mov rax, L_constants + 2
.L_if_end_0772:
	cmp rax, sob_boolean_false
	jne .L_if_end_0771
.L_if_end_0771:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_09d1:	; new closure is in rax
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
.L_lambda_opt_env_loop_0136:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 9
	je .L_lambda_opt_env_end_0136
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0136
.L_lambda_opt_env_end_0136:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_03a0:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_026b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_03a0
.L_lambda_opt_params_end_026b:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0136
	jmp .L_lambda_opt_end_026b
.L_lambda_opt_code_0136:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_0b07
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b07:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_03a2
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_03a1: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_03a1
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_026c
	.L_lambda_opt_params_loop_03a2:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_03a1: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_03a1
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_03a2:
	cmp rdx, 0
	je .L_lambda_opt_params_end_026c
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_03a2
	.L_lambda_opt_params_end_026c:
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
	.L_lambda_opt_end_026c:
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
	.L_tc_recycle_frame_loop_0c53:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c53
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c53
	.L_tc_recycle_frame_done_0c53:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_026b:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09d0:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c51:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c51
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c51
	.L_tc_recycle_frame_done_0c51:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09cf:	; new closure is in rax
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
.L_lambda_simple_env_loop_09d2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_09d2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09d2
.L_lambda_simple_env_end_09d2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09d2:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09d2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09d2
.L_lambda_simple_params_end_09d2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09d2
	jmp .L_lambda_simple_end_09d2
.L_lambda_simple_code_09d2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b08
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b08:
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
.L_lambda_simple_end_09d2:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c50:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c50
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c50
	.L_tc_recycle_frame_done_0c50:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09ce:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c4e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c4e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c4e
	.L_tc_recycle_frame_done_0c4e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09cc:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c4c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c4c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c4c
	.L_tc_recycle_frame_done_0c4c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09ca:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c4a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c4a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c4a
	.L_tc_recycle_frame_done_0c4a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09c8:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c49:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c49
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c49
	.L_tc_recycle_frame_done_0c49:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09c7:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c48:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c48
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c48
	.L_tc_recycle_frame_done_0c48:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09c6:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c3a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c3a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c3a
	.L_tc_recycle_frame_done_0c3a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09c3:	; new closure is in rax
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
.L_lambda_simple_env_loop_09d3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09d3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09d3
.L_lambda_simple_env_end_09d3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09d3:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09d3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09d3
.L_lambda_simple_params_end_09d3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09d3
	jmp .L_lambda_simple_end_09d3
.L_lambda_simple_code_09d3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b09
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b09:
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
.L_lambda_opt_env_loop_0137:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_0137
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0137
.L_lambda_opt_env_end_0137:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_03a3:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_026d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_03a3
.L_lambda_opt_params_end_026d:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0137
	jmp .L_lambda_opt_end_026d
.L_lambda_opt_code_0137:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	jge .L_lambda_simple_arity_check_ok_0b0a
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b0a:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 0
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_03a5
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_03a4: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_03a4
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_026e
	.L_lambda_opt_params_loop_03a5:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_03a4: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_03a4
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_03a5:
	cmp rdx, 0
	je .L_lambda_opt_params_end_026e
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_03a5
	.L_lambda_opt_params_end_026e:
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
	.L_lambda_opt_end_026e:
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
	.L_tc_recycle_frame_loop_0c54:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c54
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c54
	.L_tc_recycle_frame_done_0c54:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_026d:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09d3:	; new closure is in rax
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
.L_lambda_simple_env_loop_09d4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09d4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09d4
.L_lambda_simple_env_end_09d4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09d4:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09d4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09d4
.L_lambda_simple_params_end_09d4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09d4
	jmp .L_lambda_simple_end_09d4
.L_lambda_simple_code_09d4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b0b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b0b:
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
.L_lambda_simple_end_09d4:	; new closure is in rax
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
.L_lambda_simple_env_loop_09d5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09d5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09d5
.L_lambda_simple_env_end_09d5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09d5:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09d5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09d5
.L_lambda_simple_params_end_09d5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09d5
	jmp .L_lambda_simple_end_09d5
.L_lambda_simple_code_09d5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b0c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b0c:
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
.L_lambda_simple_env_loop_09d6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_09d6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09d6
.L_lambda_simple_env_end_09d6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09d6:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09d6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09d6
.L_lambda_simple_params_end_09d6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09d6
	jmp .L_lambda_simple_end_09d6
.L_lambda_simple_code_09d6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b0d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b0d:
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
	je .L_if_else_06c5
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
	.L_tc_recycle_frame_loop_0c55:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c55
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c55
	.L_tc_recycle_frame_done_0c55:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0773
.L_if_else_06c5:
	mov rax, PARAM(0)	; param ch
.L_if_end_0773:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09d6:	; new closure is in rax
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
.L_lambda_simple_env_loop_09d7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_09d7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09d7
.L_lambda_simple_env_end_09d7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09d7:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09d7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09d7
.L_lambda_simple_params_end_09d7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09d7
	jmp .L_lambda_simple_end_09d7
.L_lambda_simple_code_09d7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b0e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b0e:
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
	je .L_if_else_06c6
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
	.L_tc_recycle_frame_loop_0c56:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c56
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c56
	.L_tc_recycle_frame_done_0c56:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0774
.L_if_else_06c6:
	mov rax, PARAM(0)	; param ch
.L_if_end_0774:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09d7:	; new closure is in rax
	mov qword [free_var_72], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09d5:	; new closure is in rax
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
.L_lambda_simple_env_loop_09d8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09d8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09d8
.L_lambda_simple_env_end_09d8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09d8:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09d8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09d8
.L_lambda_simple_params_end_09d8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09d8
	jmp .L_lambda_simple_end_09d8
.L_lambda_simple_code_09d8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b0f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b0f:
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
.L_lambda_opt_env_loop_0138:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_0138
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0138
.L_lambda_opt_env_end_0138:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_03a6:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_026f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_03a6
.L_lambda_opt_params_end_026f:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0138
	jmp .L_lambda_opt_end_026f
.L_lambda_opt_code_0138:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	jge .L_lambda_simple_arity_check_ok_0b10
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b10:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 0
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_03a8
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_03a7: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_03a7
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0270
	.L_lambda_opt_params_loop_03a8:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_03a7: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_03a7
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_03a8:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0270
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_03a8
	.L_lambda_opt_params_end_0270:
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
	.L_lambda_opt_end_0270:
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
.L_lambda_simple_env_loop_09d9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_09d9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09d9
.L_lambda_simple_env_end_09d9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09d9:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09d9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09d9
.L_lambda_simple_params_end_09d9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09d9
	jmp .L_lambda_simple_end_09d9
.L_lambda_simple_code_09d9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b11
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b11:
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
	.L_tc_recycle_frame_loop_0c58:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c58
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c58
	.L_tc_recycle_frame_done_0c58:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09d9:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_0c57:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c57
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c57
	.L_tc_recycle_frame_done_0c57:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_026f:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09d8:	; new closure is in rax
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
.L_lambda_simple_env_loop_09da:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09da
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09da
.L_lambda_simple_env_end_09da:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09da:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09da
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09da
.L_lambda_simple_params_end_09da:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09da
	jmp .L_lambda_simple_end_09da
.L_lambda_simple_code_09da:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b12
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b12:
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
.L_lambda_simple_end_09da:	; new closure is in rax
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
.L_lambda_simple_env_loop_09db:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09db
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09db
.L_lambda_simple_env_end_09db:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09db:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09db
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09db
.L_lambda_simple_params_end_09db:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09db
	jmp .L_lambda_simple_end_09db
.L_lambda_simple_code_09db:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b13
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b13:
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
.L_lambda_simple_env_loop_09dc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_09dc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09dc
.L_lambda_simple_env_end_09dc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09dc:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09dc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09dc
.L_lambda_simple_params_end_09dc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09dc
	jmp .L_lambda_simple_end_09dc
.L_lambda_simple_code_09dc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b14
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b14:
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
	.L_tc_recycle_frame_loop_0c59:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c59
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c59
	.L_tc_recycle_frame_done_0c59:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09dc:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09db:	; new closure is in rax
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
.L_lambda_simple_env_loop_09dd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09dd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09dd
.L_lambda_simple_env_end_09dd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09dd:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09dd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09dd
.L_lambda_simple_params_end_09dd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09dd
	jmp .L_lambda_simple_end_09dd
.L_lambda_simple_code_09dd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b15
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b15:
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
.L_lambda_simple_end_09dd:	; new closure is in rax
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
.L_lambda_simple_env_loop_09de:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09de
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09de
.L_lambda_simple_env_end_09de:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09de:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09de
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09de
.L_lambda_simple_params_end_09de:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09de
	jmp .L_lambda_simple_end_09de
.L_lambda_simple_code_09de:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b16
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b16:
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
.L_lambda_simple_env_loop_09df:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_09df
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09df
.L_lambda_simple_env_end_09df:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09df:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_09df
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09df
.L_lambda_simple_params_end_09df:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09df
	jmp .L_lambda_simple_end_09df
.L_lambda_simple_code_09df:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b17
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b17:
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
.L_lambda_simple_env_loop_09e0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_09e0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09e0
.L_lambda_simple_env_end_09e0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09e0:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09e0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09e0
.L_lambda_simple_params_end_09e0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09e0
	jmp .L_lambda_simple_end_09e0
.L_lambda_simple_code_09e0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_0b18
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b18:
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
	je .L_if_else_06c7
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
	jmp .L_if_end_0776
.L_if_else_06c7:
	mov rax, L_constants + 2
.L_if_end_0776:
	cmp rax, sob_boolean_false
	jne .L_if_end_0775
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
	je .L_if_else_06c9
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
	jne .L_if_end_0777
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
	je .L_if_else_06c8
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
	.L_tc_recycle_frame_loop_0c5b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c5b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c5b
	.L_tc_recycle_frame_done_0c5b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0778
.L_if_else_06c8:
	mov rax, L_constants + 2
.L_if_end_0778:
	cmp rax, sob_boolean_false
	jne .L_if_end_0777
.L_if_end_0777:
	jmp .L_if_end_0779
.L_if_else_06c9:
	mov rax, L_constants + 2
.L_if_end_0779:
	cmp rax, sob_boolean_false
	jne .L_if_end_0775
.L_if_end_0775:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_09e0:	; new closure is in rax
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
.L_lambda_simple_env_loop_09e1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_09e1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09e1
.L_lambda_simple_env_end_09e1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09e1:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09e1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09e1
.L_lambda_simple_params_end_09e1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09e1
	jmp .L_lambda_simple_end_09e1
.L_lambda_simple_code_09e1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b19
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b19:
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
.L_lambda_simple_env_loop_09e2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_09e2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09e2
.L_lambda_simple_env_end_09e2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09e2:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_09e2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09e2
.L_lambda_simple_params_end_09e2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09e2
	jmp .L_lambda_simple_end_09e2
.L_lambda_simple_code_09e2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b1a
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b1a:
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
	je .L_if_else_06ca
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
	.L_tc_recycle_frame_loop_0c5e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c5e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c5e
	.L_tc_recycle_frame_done_0c5e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_077a
.L_if_else_06ca:
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
	.L_tc_recycle_frame_loop_0c5f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c5f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c5f
	.L_tc_recycle_frame_done_0c5f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_077a:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_09e2:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c5d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c5d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c5d
	.L_tc_recycle_frame_done_0c5d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_09e1:	; new closure is in rax
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
.L_lambda_simple_env_loop_09e3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_09e3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09e3
.L_lambda_simple_env_end_09e3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09e3:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09e3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09e3
.L_lambda_simple_params_end_09e3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09e3
	jmp .L_lambda_simple_end_09e3
.L_lambda_simple_code_09e3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b1b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b1b:
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
.L_lambda_simple_env_loop_09e4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_09e4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09e4
.L_lambda_simple_env_end_09e4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09e4:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09e4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09e4
.L_lambda_simple_params_end_09e4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09e4
	jmp .L_lambda_simple_end_09e4
.L_lambda_simple_code_09e4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b1c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b1c:
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
.L_lambda_simple_env_loop_09e5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_09e5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09e5
.L_lambda_simple_env_end_09e5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09e5:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09e5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09e5
.L_lambda_simple_params_end_09e5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09e5
	jmp .L_lambda_simple_end_09e5
.L_lambda_simple_code_09e5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b1d
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b1d:
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
	jne .L_if_end_077b
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
	je .L_if_else_06cb
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
	.L_tc_recycle_frame_loop_0c61:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c61
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c61
	.L_tc_recycle_frame_done_0c61:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_077c
.L_if_else_06cb:
	mov rax, L_constants + 2
.L_if_end_077c:
	cmp rax, sob_boolean_false
	jne .L_if_end_077b
.L_if_end_077b:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_09e5:	; new closure is in rax
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
.L_lambda_opt_env_loop_0139:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 4
	je .L_lambda_opt_env_end_0139
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0139
.L_lambda_opt_env_end_0139:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_03a9:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0271
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_03a9
.L_lambda_opt_params_end_0271:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0139
	jmp .L_lambda_opt_end_0271
.L_lambda_opt_code_0139:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_0b1e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b1e:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_03ab
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_03aa: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_03aa
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0272
	.L_lambda_opt_params_loop_03ab:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_03aa: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_03aa
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_03ab:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0272
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_03ab
	.L_lambda_opt_params_end_0272:
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
	.L_lambda_opt_end_0272:
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
	.L_tc_recycle_frame_loop_0c62:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c62
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c62
	.L_tc_recycle_frame_done_0c62:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0271:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09e4:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c60:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c60
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c60
	.L_tc_recycle_frame_done_0c60:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09e3:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c5c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c5c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c5c
	.L_tc_recycle_frame_done_0c5c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09df:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c5a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c5a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c5a
	.L_tc_recycle_frame_done_0c5a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_09de:	; new closure is in rax
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
.L_lambda_simple_env_loop_09e6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09e6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09e6
.L_lambda_simple_env_end_09e6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09e6:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09e6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09e6
.L_lambda_simple_params_end_09e6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09e6
	jmp .L_lambda_simple_end_09e6
.L_lambda_simple_code_09e6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b1f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b1f:
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
.L_lambda_simple_end_09e6:	; new closure is in rax
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
.L_lambda_simple_env_loop_09e7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09e7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09e7
.L_lambda_simple_env_end_09e7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09e7:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09e7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09e7
.L_lambda_simple_params_end_09e7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09e7
	jmp .L_lambda_simple_end_09e7
.L_lambda_simple_code_09e7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b20
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b20:
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
.L_lambda_simple_env_loop_09e8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_09e8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09e8
.L_lambda_simple_env_end_09e8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09e8:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_09e8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09e8
.L_lambda_simple_params_end_09e8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09e8
	jmp .L_lambda_simple_end_09e8
.L_lambda_simple_code_09e8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b21
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b21:
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
.L_lambda_simple_env_loop_09e9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_09e9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09e9
.L_lambda_simple_env_end_09e9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09e9:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09e9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09e9
.L_lambda_simple_params_end_09e9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09e9
	jmp .L_lambda_simple_end_09e9
.L_lambda_simple_code_09e9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_0b22
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b22:
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
	jne .L_if_end_077d
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
	jne .L_if_end_077d
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
	je .L_if_else_06cd
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
	je .L_if_else_06cc
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
	.L_tc_recycle_frame_loop_0c64:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c64
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c64
	.L_tc_recycle_frame_done_0c64:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_077e
.L_if_else_06cc:
	mov rax, L_constants + 2
.L_if_end_077e:
	jmp .L_if_end_077f
.L_if_else_06cd:
	mov rax, L_constants + 2
.L_if_end_077f:
	cmp rax, sob_boolean_false
	jne .L_if_end_077d
.L_if_end_077d:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_09e9:	; new closure is in rax
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
.L_lambda_simple_env_loop_09ea:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_09ea
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09ea
.L_lambda_simple_env_end_09ea:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09ea:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09ea
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09ea
.L_lambda_simple_params_end_09ea:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09ea
	jmp .L_lambda_simple_end_09ea
.L_lambda_simple_code_09ea:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b23
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b23:
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
.L_lambda_simple_env_loop_09eb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_09eb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09eb
.L_lambda_simple_env_end_09eb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09eb:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_09eb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09eb
.L_lambda_simple_params_end_09eb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09eb
	jmp .L_lambda_simple_end_09eb
.L_lambda_simple_code_09eb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b24
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b24:
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
	je .L_if_else_06ce
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
	.L_tc_recycle_frame_loop_0c67:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c67
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c67
	.L_tc_recycle_frame_done_0c67:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0780
.L_if_else_06ce:
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
	.L_tc_recycle_frame_loop_0c68:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c68
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c68
	.L_tc_recycle_frame_done_0c68:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0780:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_09eb:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c66:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c66
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c66
	.L_tc_recycle_frame_done_0c66:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_09ea:	; new closure is in rax
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
.L_lambda_simple_env_loop_09ec:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_09ec
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09ec
.L_lambda_simple_env_end_09ec:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09ec:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09ec
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09ec
.L_lambda_simple_params_end_09ec:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09ec
	jmp .L_lambda_simple_end_09ec
.L_lambda_simple_code_09ec:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b25
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b25:
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
.L_lambda_simple_env_loop_09ed:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_09ed
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09ed
.L_lambda_simple_env_end_09ed:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09ed:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09ed
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09ed
.L_lambda_simple_params_end_09ed:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09ed
	jmp .L_lambda_simple_end_09ed
.L_lambda_simple_code_09ed:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b26
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b26:
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
.L_lambda_simple_env_loop_09ee:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_09ee
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09ee
.L_lambda_simple_env_end_09ee:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09ee:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09ee
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09ee
.L_lambda_simple_params_end_09ee:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09ee
	jmp .L_lambda_simple_end_09ee
.L_lambda_simple_code_09ee:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b27
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b27:
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
	jne .L_if_end_0781
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
	je .L_if_else_06cf
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
	.L_tc_recycle_frame_loop_0c6a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c6a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c6a
	.L_tc_recycle_frame_done_0c6a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0782
.L_if_else_06cf:
	mov rax, L_constants + 2
.L_if_end_0782:
	cmp rax, sob_boolean_false
	jne .L_if_end_0781
.L_if_end_0781:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_09ee:	; new closure is in rax
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
.L_lambda_opt_env_loop_013a:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 4
	je .L_lambda_opt_env_end_013a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_013a
.L_lambda_opt_env_end_013a:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_03ac:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0273
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_03ac
.L_lambda_opt_params_end_0273:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_013a
	jmp .L_lambda_opt_end_0273
.L_lambda_opt_code_013a:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_0b28
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b28:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_03ae
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_03ad: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_03ad
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0274
	.L_lambda_opt_params_loop_03ae:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_03ad: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_03ad
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_03ae:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0274
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_03ae
	.L_lambda_opt_params_end_0274:
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
	.L_lambda_opt_end_0274:
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
	.L_tc_recycle_frame_loop_0c6b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c6b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c6b
	.L_tc_recycle_frame_done_0c6b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0273:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09ed:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c69:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c69
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c69
	.L_tc_recycle_frame_done_0c69:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09ec:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c65:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c65
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c65
	.L_tc_recycle_frame_done_0c65:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09e8:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c63:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c63
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c63
	.L_tc_recycle_frame_done_0c63:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_09e7:	; new closure is in rax
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
.L_lambda_simple_env_loop_09ef:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09ef
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09ef
.L_lambda_simple_env_end_09ef:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09ef:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09ef
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09ef
.L_lambda_simple_params_end_09ef:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09ef
	jmp .L_lambda_simple_end_09ef
.L_lambda_simple_code_09ef:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b29
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b29:
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
.L_lambda_simple_end_09ef:	; new closure is in rax
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
.L_lambda_simple_env_loop_09f0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09f0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09f0
.L_lambda_simple_env_end_09f0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09f0:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09f0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09f0
.L_lambda_simple_params_end_09f0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09f0
	jmp .L_lambda_simple_end_09f0
.L_lambda_simple_code_09f0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b2a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b2a:
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
.L_lambda_simple_env_loop_09f1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_09f1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09f1
.L_lambda_simple_env_end_09f1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09f1:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09f1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09f1
.L_lambda_simple_params_end_09f1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09f1
	jmp .L_lambda_simple_end_09f1
.L_lambda_simple_code_09f1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b2b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b2b:
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
.L_lambda_simple_env_loop_09f2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_09f2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09f2
.L_lambda_simple_env_end_09f2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09f2:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09f2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09f2
.L_lambda_simple_params_end_09f2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09f2
	jmp .L_lambda_simple_end_09f2
.L_lambda_simple_code_09f2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 4
	je .L_lambda_simple_arity_check_ok_0b2c
	push qword [rsp + 8 * 2]
	push 4
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b2c:
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
	jne .L_if_end_0783
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
	je .L_if_else_06d1
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
	je .L_if_else_06d0
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
	.L_tc_recycle_frame_loop_0c6d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c6d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c6d
	.L_tc_recycle_frame_done_0c6d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0784
.L_if_else_06d0:
	mov rax, L_constants + 2
.L_if_end_0784:
	jmp .L_if_end_0785
.L_if_else_06d1:
	mov rax, L_constants + 2
.L_if_end_0785:
	cmp rax, sob_boolean_false
	jne .L_if_end_0783
.L_if_end_0783:
	leave
	ret AND_KILL_FRAME(4)
.L_lambda_simple_end_09f2:	; new closure is in rax
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
.L_lambda_simple_env_loop_09f3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_09f3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09f3
.L_lambda_simple_env_end_09f3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09f3:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09f3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09f3
.L_lambda_simple_params_end_09f3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09f3
	jmp .L_lambda_simple_end_09f3
.L_lambda_simple_code_09f3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b2d
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b2d:
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
.L_lambda_simple_env_loop_09f4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_09f4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09f4
.L_lambda_simple_env_end_09f4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09f4:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_09f4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09f4
.L_lambda_simple_params_end_09f4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09f4
	jmp .L_lambda_simple_end_09f4
.L_lambda_simple_code_09f4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b2e
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b2e:
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
	je .L_if_else_06d2
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
	.L_tc_recycle_frame_loop_0c70:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c70
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c70
	.L_tc_recycle_frame_done_0c70:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0786
.L_if_else_06d2:
	mov rax, L_constants + 2
.L_if_end_0786:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_09f4:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c6f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c6f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c6f
	.L_tc_recycle_frame_done_0c6f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_09f3:	; new closure is in rax
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
.L_lambda_simple_env_loop_09f5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_09f5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09f5
.L_lambda_simple_env_end_09f5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09f5:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09f5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09f5
.L_lambda_simple_params_end_09f5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09f5
	jmp .L_lambda_simple_end_09f5
.L_lambda_simple_code_09f5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b2f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b2f:
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
.L_lambda_simple_env_loop_09f6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_09f6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09f6
.L_lambda_simple_env_end_09f6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09f6:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09f6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09f6
.L_lambda_simple_params_end_09f6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09f6
	jmp .L_lambda_simple_end_09f6
.L_lambda_simple_code_09f6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b30
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b30:
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
.L_lambda_simple_env_loop_09f7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_09f7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09f7
.L_lambda_simple_env_end_09f7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09f7:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09f7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09f7
.L_lambda_simple_params_end_09f7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09f7
	jmp .L_lambda_simple_end_09f7
.L_lambda_simple_code_09f7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b31
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b31:
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
	jne .L_if_end_0787
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
	je .L_if_else_06d3
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
	.L_tc_recycle_frame_loop_0c72:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c72
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c72
	.L_tc_recycle_frame_done_0c72:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0788
.L_if_else_06d3:
	mov rax, L_constants + 2
.L_if_end_0788:
	cmp rax, sob_boolean_false
	jne .L_if_end_0787
.L_if_end_0787:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_09f7:	; new closure is in rax
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
.L_lambda_opt_env_loop_013b:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 4
	je .L_lambda_opt_env_end_013b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_013b
.L_lambda_opt_env_end_013b:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_03af:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0275
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_03af
.L_lambda_opt_params_end_0275:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_013b
	jmp .L_lambda_opt_end_0275
.L_lambda_opt_code_013b:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_0b32
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b32:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_03b1
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_03b0: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_03b0
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0276
	.L_lambda_opt_params_loop_03b1:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_03b0: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_03b0
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_03b1:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0276
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_03b1
	.L_lambda_opt_params_end_0276:
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
	.L_lambda_opt_end_0276:
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
	.L_tc_recycle_frame_loop_0c73:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c73
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c73
	.L_tc_recycle_frame_done_0c73:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0275:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09f6:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c71:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c71
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c71
	.L_tc_recycle_frame_done_0c71:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09f5:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c6e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c6e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c6e
	.L_tc_recycle_frame_done_0c6e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09f1:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c6c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c6c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c6c
	.L_tc_recycle_frame_done_0c6c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09f0:	; new closure is in rax
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
.L_lambda_simple_env_loop_09f8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09f8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09f8
.L_lambda_simple_env_end_09f8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09f8:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09f8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09f8
.L_lambda_simple_params_end_09f8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09f8
	jmp .L_lambda_simple_end_09f8
.L_lambda_simple_code_09f8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b33
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b33:
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
.L_lambda_simple_end_09f8:	; new closure is in rax
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
.L_lambda_simple_env_loop_09f9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09f9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09f9
.L_lambda_simple_env_end_09f9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09f9:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09f9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09f9
.L_lambda_simple_params_end_09f9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09f9
	jmp .L_lambda_simple_end_09f9
.L_lambda_simple_code_09f9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b34
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b34:
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
	jne .L_if_end_0789
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
	je .L_if_else_06d4
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
	.L_tc_recycle_frame_loop_0c74:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c74
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c74
	.L_tc_recycle_frame_done_0c74:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_078a
.L_if_else_06d4:
	mov rax, L_constants + 2
.L_if_end_078a:
	cmp rax, sob_boolean_false
	jne .L_if_end_0789
.L_if_end_0789:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09f9:	; new closure is in rax
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
.L_lambda_simple_env_loop_09fa:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09fa
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09fa
.L_lambda_simple_env_end_09fa:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09fa:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09fa
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09fa
.L_lambda_simple_params_end_09fa:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09fa
	jmp .L_lambda_simple_end_09fa
.L_lambda_simple_code_09fa:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b35
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b35:
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
.L_lambda_opt_env_loop_013c:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_013c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_013c
.L_lambda_opt_env_end_013c:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_03b2:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0277
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_03b2
.L_lambda_opt_params_end_0277:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_013c
	jmp .L_lambda_opt_end_0277
.L_lambda_opt_code_013c:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_0b36
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b36:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_03b4
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_03b3: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_03b3
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0278
	.L_lambda_opt_params_loop_03b4:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_03b3: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_03b3
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_03b4:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0278
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_03b4
	.L_lambda_opt_params_end_0278:
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
	.L_lambda_opt_end_0278:
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
	je .L_if_else_06d7
	mov rax, L_constants + 0
	jmp .L_if_end_078d
.L_if_else_06d7:
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
	je .L_if_else_06d5
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
	jmp .L_if_end_078b
.L_if_else_06d5:
	mov rax, L_constants + 2
.L_if_end_078b:
	cmp rax, sob_boolean_false
	je .L_if_else_06d6
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
	jmp .L_if_end_078c
.L_if_else_06d6:
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
.L_if_end_078c:
.L_if_end_078d:
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
.L_lambda_simple_env_loop_09fb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_09fb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09fb
.L_lambda_simple_env_end_09fb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09fb:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_09fb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09fb
.L_lambda_simple_params_end_09fb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09fb
	jmp .L_lambda_simple_end_09fb
.L_lambda_simple_code_09fb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b37
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b37:
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
	.L_tc_recycle_frame_loop_0c76:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c76
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c76
	.L_tc_recycle_frame_done_0c76:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09fb:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c75:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c75
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c75
	.L_tc_recycle_frame_done_0c75:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0277:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09fa:	; new closure is in rax
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
.L_lambda_simple_env_loop_09fc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09fc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09fc
.L_lambda_simple_env_end_09fc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09fc:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09fc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09fc
.L_lambda_simple_params_end_09fc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09fc
	jmp .L_lambda_simple_end_09fc
.L_lambda_simple_code_09fc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b38
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b38:
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
.L_lambda_opt_env_loop_013d:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_013d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_013d
.L_lambda_opt_env_end_013d:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_03b5:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0279
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_03b5
.L_lambda_opt_params_end_0279:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_013d
	jmp .L_lambda_opt_end_0279
.L_lambda_opt_code_013d:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	jge .L_lambda_simple_arity_check_ok_0b39
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b39:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 1
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_03b7
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_03b6: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_03b6
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_027a
	.L_lambda_opt_params_loop_03b7:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_03b6: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_03b6
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_03b7:
	cmp rdx, 0
	je .L_lambda_opt_params_end_027a
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_03b7
	.L_lambda_opt_params_end_027a:
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
	.L_lambda_opt_end_027a:
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
	je .L_if_else_06da
	mov rax, L_constants + 4
	jmp .L_if_end_0790
.L_if_else_06da:
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
	je .L_if_else_06d8
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
	jmp .L_if_end_078e
.L_if_else_06d8:
	mov rax, L_constants + 2
.L_if_end_078e:
	cmp rax, sob_boolean_false
	je .L_if_else_06d9
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
	jmp .L_if_end_078f
.L_if_else_06d9:
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
.L_if_end_078f:
.L_if_end_0790:
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
.L_lambda_simple_env_loop_09fd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_09fd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09fd
.L_lambda_simple_env_end_09fd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09fd:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_09fd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09fd
.L_lambda_simple_params_end_09fd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09fd
	jmp .L_lambda_simple_end_09fd
.L_lambda_simple_code_09fd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b3a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b3a:
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
	.L_tc_recycle_frame_loop_0c78:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c78
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c78
	.L_tc_recycle_frame_done_0c78:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09fd:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c77:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c77
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c77
	.L_tc_recycle_frame_done_0c77:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0279:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09fc:	; new closure is in rax
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
.L_lambda_simple_env_loop_09fe:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_09fe
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09fe
.L_lambda_simple_env_end_09fe:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09fe:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_09fe
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09fe
.L_lambda_simple_params_end_09fe:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09fe
	jmp .L_lambda_simple_end_09fe
.L_lambda_simple_code_09fe:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b3b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b3b:
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
.L_lambda_simple_env_loop_09ff:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_09ff
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_09ff
.L_lambda_simple_env_end_09ff:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_09ff:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_09ff
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_09ff
.L_lambda_simple_params_end_09ff:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_09ff
	jmp .L_lambda_simple_end_09ff
.L_lambda_simple_code_09ff:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b3c
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b3c:
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
	je .L_if_else_06db
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
	.L_tc_recycle_frame_loop_0c79:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c79
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c79
	.L_tc_recycle_frame_done_0c79:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0791
.L_if_else_06db:
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
.L_lambda_simple_env_loop_0a00:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0a00
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a00
.L_lambda_simple_env_end_0a00:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a00:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0a00
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a00
.L_lambda_simple_params_end_0a00:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a00
	jmp .L_lambda_simple_end_0a00
.L_lambda_simple_code_0a00:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b3d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b3d:
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
.L_lambda_simple_end_0a00:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c7a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c7a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c7a
	.L_tc_recycle_frame_done_0c7a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0791:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_09ff:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a01:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0a01
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a01
.L_lambda_simple_env_end_0a01:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a01:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0a01
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a01
.L_lambda_simple_params_end_0a01:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a01
	jmp .L_lambda_simple_end_0a01
.L_lambda_simple_code_0a01:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b3e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b3e:
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
	.L_tc_recycle_frame_loop_0c7b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c7b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c7b
	.L_tc_recycle_frame_done_0c7b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a01:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_09fe:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a02:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a02
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a02
.L_lambda_simple_env_end_0a02:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a02:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a02
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a02
.L_lambda_simple_params_end_0a02:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a02
	jmp .L_lambda_simple_end_0a02
.L_lambda_simple_code_0a02:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b3f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b3f:
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
.L_lambda_simple_env_loop_0a03:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0a03
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a03
.L_lambda_simple_env_end_0a03:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a03:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0a03
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a03
.L_lambda_simple_params_end_0a03:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a03
	jmp .L_lambda_simple_end_0a03
.L_lambda_simple_code_0a03:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b40
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b40:
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
	je .L_if_else_06dc
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
	.L_tc_recycle_frame_loop_0c7c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c7c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c7c
	.L_tc_recycle_frame_done_0c7c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0792
.L_if_else_06dc:
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
.L_lambda_simple_env_loop_0a04:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0a04
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a04
.L_lambda_simple_env_end_0a04:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a04:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0a04
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a04
.L_lambda_simple_params_end_0a04:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a04
	jmp .L_lambda_simple_end_0a04
.L_lambda_simple_code_0a04:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b41
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b41:
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
.L_lambda_simple_end_0a04:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c7d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c7d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c7d
	.L_tc_recycle_frame_done_0c7d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_0792:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0a03:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a05:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0a05
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a05
.L_lambda_simple_env_end_0a05:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a05:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0a05
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a05
.L_lambda_simple_params_end_0a05:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a05
	jmp .L_lambda_simple_end_0a05
.L_lambda_simple_code_0a05:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b42
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b42:
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
	.L_tc_recycle_frame_loop_0c7e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c7e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c7e
	.L_tc_recycle_frame_done_0c7e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a05:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a02:	; new closure is in rax
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
.L_lambda_opt_env_loop_013e:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 0
	je .L_lambda_opt_env_end_013e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_013e
.L_lambda_opt_env_end_013e:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_03b8:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_027b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_03b8
.L_lambda_opt_params_end_027b:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_013e
	jmp .L_lambda_opt_end_027b
.L_lambda_opt_code_013e:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	jge .L_lambda_simple_arity_check_ok_0b43
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b43:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 0
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_03ba
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_03b9: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_03b9
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_027c
	.L_lambda_opt_params_loop_03ba:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_03b9: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_03b9
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_03ba:
	cmp rdx, 0
	je .L_lambda_opt_params_end_027c
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_03ba
	.L_lambda_opt_params_end_027c:
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
	.L_lambda_opt_end_027c:
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
	.L_tc_recycle_frame_loop_0c7f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c7f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c7f
	.L_tc_recycle_frame_done_0c7f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_027b:
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
.L_lambda_simple_env_loop_0a06:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a06
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a06
.L_lambda_simple_env_end_0a06:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a06:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a06
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a06
.L_lambda_simple_params_end_0a06:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a06
	jmp .L_lambda_simple_end_0a06
.L_lambda_simple_code_0a06:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b44
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b44:
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
.L_lambda_simple_env_loop_0a07:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0a07
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a07
.L_lambda_simple_env_end_0a07:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a07:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0a07
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a07
.L_lambda_simple_params_end_0a07:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a07
	jmp .L_lambda_simple_end_0a07
.L_lambda_simple_code_0a07:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0b45
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b45:
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
	je .L_if_else_06dd
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
	.L_tc_recycle_frame_loop_0c80:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c80
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c80
	.L_tc_recycle_frame_done_0c80:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0793
.L_if_else_06dd:
	mov rax, L_constants + 1
.L_if_end_0793:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0a07:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a08:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0a08
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a08
.L_lambda_simple_env_end_0a08:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a08:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0a08
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a08
.L_lambda_simple_params_end_0a08:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a08
	jmp .L_lambda_simple_end_0a08
.L_lambda_simple_code_0a08:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b46
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b46:
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
	.L_tc_recycle_frame_loop_0c81:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c81
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c81
	.L_tc_recycle_frame_done_0c81:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a08:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a06:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a09:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a09
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a09
.L_lambda_simple_env_end_0a09:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a09:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a09
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a09
.L_lambda_simple_params_end_0a09:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a09
	jmp .L_lambda_simple_end_0a09
.L_lambda_simple_code_0a09:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b47
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b47:
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
.L_lambda_simple_env_loop_0a0a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0a0a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a0a
.L_lambda_simple_env_end_0a0a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a0a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0a0a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a0a
.L_lambda_simple_params_end_0a0a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a0a
	jmp .L_lambda_simple_end_0a0a
.L_lambda_simple_code_0a0a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0b48
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b48:
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
	je .L_if_else_06de
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
	.L_tc_recycle_frame_loop_0c82:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c82
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c82
	.L_tc_recycle_frame_done_0c82:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0794
.L_if_else_06de:
	mov rax, L_constants + 1
.L_if_end_0794:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0a0a:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a0b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0a0b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a0b
.L_lambda_simple_env_end_0a0b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a0b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0a0b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a0b
.L_lambda_simple_params_end_0a0b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a0b
	jmp .L_lambda_simple_end_0a0b
.L_lambda_simple_code_0a0b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b49
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b49:
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
	.L_tc_recycle_frame_loop_0c83:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c83
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c83
	.L_tc_recycle_frame_done_0c83:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a0b:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a09:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a0c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a0c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a0c
.L_lambda_simple_env_end_0a0c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a0c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a0c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a0c
.L_lambda_simple_params_end_0a0c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a0c
	jmp .L_lambda_simple_end_0a0c
.L_lambda_simple_code_0a0c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b4a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b4a:
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
	.L_tc_recycle_frame_loop_0c84:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c84
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c84
	.L_tc_recycle_frame_done_0c84:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a0c:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a0d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a0d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a0d
.L_lambda_simple_env_end_0a0d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a0d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a0d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a0d
.L_lambda_simple_params_end_0a0d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a0d
	jmp .L_lambda_simple_end_0a0d
.L_lambda_simple_code_0a0d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b4b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b4b:
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
	.L_tc_recycle_frame_loop_0c85:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c85
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c85
	.L_tc_recycle_frame_done_0c85:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a0d:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a0e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a0e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a0e
.L_lambda_simple_env_end_0a0e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a0e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a0e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a0e
.L_lambda_simple_params_end_0a0e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a0e
	jmp .L_lambda_simple_end_0a0e
.L_lambda_simple_code_0a0e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b4c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b4c:
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
	.L_tc_recycle_frame_loop_0c86:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c86
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c86
	.L_tc_recycle_frame_done_0c86:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a0e:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a0f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a0f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a0f
.L_lambda_simple_env_end_0a0f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a0f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a0f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a0f
.L_lambda_simple_params_end_0a0f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a0f
	jmp .L_lambda_simple_end_0a0f
.L_lambda_simple_code_0a0f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b4d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b4d:
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
	mov rax, qword [free_var_151]	; free var zero?
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
	.L_tc_recycle_frame_loop_0c87:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c87
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c87
	.L_tc_recycle_frame_done_0c87:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a0f:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a10:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a10
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a10
.L_lambda_simple_env_end_0a10:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a10:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a10
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a10
.L_lambda_simple_params_end_0a10:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a10
	jmp .L_lambda_simple_end_0a10
.L_lambda_simple_code_0a10:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b4e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b4e:
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
	.L_tc_recycle_frame_loop_0c88:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c88
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c88
	.L_tc_recycle_frame_done_0c88:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a10:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a11:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a11
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a11
.L_lambda_simple_env_end_0a11:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a11:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a11
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a11
.L_lambda_simple_params_end_0a11:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a11
	jmp .L_lambda_simple_end_0a11
.L_lambda_simple_code_0a11:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b4f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b4f:
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
	je .L_if_else_06df
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
	.L_tc_recycle_frame_loop_0c89:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c89
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c89
	.L_tc_recycle_frame_done_0c89:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0795
.L_if_else_06df:
	mov rax, PARAM(0)	; param x
.L_if_end_0795:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a11:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a12:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a12
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a12
.L_lambda_simple_env_end_0a12:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a12:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a12
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a12
.L_lambda_simple_params_end_0a12:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a12
	jmp .L_lambda_simple_end_0a12
.L_lambda_simple_code_0a12:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b50
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b50:
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
	je .L_if_else_06e0
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
	jmp .L_if_end_0796
.L_if_else_06e0:
	mov rax, L_constants + 2
.L_if_end_0796:
	cmp rax, sob_boolean_false
	je .L_if_else_06ec
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
	je .L_if_else_06e1
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
	.L_tc_recycle_frame_loop_0c8a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c8a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c8a
	.L_tc_recycle_frame_done_0c8a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_0797
.L_if_else_06e1:
	mov rax, L_constants + 2
.L_if_end_0797:
	jmp .L_if_end_07a2
.L_if_else_06ec:
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
	je .L_if_else_06e3
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
	je .L_if_else_06e2
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
	jmp .L_if_end_0798
.L_if_else_06e2:
	mov rax, L_constants + 2
.L_if_end_0798:
	jmp .L_if_end_0799
.L_if_else_06e3:
	mov rax, L_constants + 2
.L_if_end_0799:
	cmp rax, sob_boolean_false
	je .L_if_else_06eb
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
	.L_tc_recycle_frame_loop_0c8b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c8b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c8b
	.L_tc_recycle_frame_done_0c8b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_07a1
.L_if_else_06eb:
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
	je .L_if_else_06e5
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
	je .L_if_else_06e4
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
	jmp .L_if_end_079a
.L_if_else_06e4:
	mov rax, L_constants + 2
.L_if_end_079a:
	jmp .L_if_end_079b
.L_if_else_06e5:
	mov rax, L_constants + 2
.L_if_end_079b:
	cmp rax, sob_boolean_false
	je .L_if_else_06ea
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
	.L_tc_recycle_frame_loop_0c8c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c8c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c8c
	.L_tc_recycle_frame_done_0c8c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_07a0
.L_if_else_06ea:
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
	je .L_if_else_06e6
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
	jmp .L_if_end_079c
.L_if_else_06e6:
	mov rax, L_constants + 2
.L_if_end_079c:
	cmp rax, sob_boolean_false
	je .L_if_else_06e9
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
	.L_tc_recycle_frame_loop_0c8d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c8d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c8d
	.L_tc_recycle_frame_done_0c8d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_079f
.L_if_else_06e9:
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
	je .L_if_else_06e7
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
	jmp .L_if_end_079d
.L_if_else_06e7:
	mov rax, L_constants + 2
.L_if_end_079d:
	cmp rax, sob_boolean_false
	je .L_if_else_06e8
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
	.L_tc_recycle_frame_loop_0c8e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c8e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c8e
	.L_tc_recycle_frame_done_0c8e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_079e
.L_if_else_06e8:
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
	.L_tc_recycle_frame_loop_0c8f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c8f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c8f
	.L_tc_recycle_frame_done_0c8f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_079e:
.L_if_end_079f:
.L_if_end_07a0:
.L_if_end_07a1:
.L_if_end_07a2:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0a12:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a13:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a13
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a13
.L_lambda_simple_env_end_0a13:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a13:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a13
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a13
.L_lambda_simple_params_end_0a13:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a13
	jmp .L_lambda_simple_end_0a13
.L_lambda_simple_code_0a13:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b51
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b51:
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
	je .L_if_else_06ee
	mov rax, L_constants + 2
	jmp .L_if_end_07a4
.L_if_else_06ee:
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
	je .L_if_else_06ed
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
	.L_tc_recycle_frame_loop_0c90:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c90
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c90
	.L_tc_recycle_frame_done_0c90:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_07a3
.L_if_else_06ed:
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
	.L_tc_recycle_frame_loop_0c91:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c91
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c91
	.L_tc_recycle_frame_done_0c91:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_07a3:
.L_if_end_07a4:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0a13:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a14:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a14
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a14
.L_lambda_simple_env_end_0a14:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a14:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a14
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a14
.L_lambda_simple_params_end_0a14:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a14
	jmp .L_lambda_simple_end_0a14
.L_lambda_simple_code_0a14:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b52
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b52:
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
.L_lambda_simple_env_loop_0a15:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0a15
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a15
.L_lambda_simple_env_end_0a15:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a15:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0a15
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a15
.L_lambda_simple_params_end_0a15:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a15
	jmp .L_lambda_simple_end_0a15
.L_lambda_simple_code_0a15:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0b53
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b53:
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
	je .L_if_else_06ef
	mov rax, PARAM(0)	; param target
	jmp .L_if_end_07a5
.L_if_else_06ef:
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
.L_lambda_simple_env_loop_0a16:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0a16
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a16
.L_lambda_simple_env_end_0a16:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a16:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_0a16
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a16
.L_lambda_simple_params_end_0a16:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a16
	jmp .L_lambda_simple_end_0a16
.L_lambda_simple_code_0a16:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b54
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b54:
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
	.L_tc_recycle_frame_loop_0c93:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c93
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c93
	.L_tc_recycle_frame_done_0c93:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a16:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c92:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c92
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c92
	.L_tc_recycle_frame_done_0c92:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_07a5:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0a15:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a17:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0a17
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a17
.L_lambda_simple_env_end_0a17:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a17:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0a17
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a17
.L_lambda_simple_params_end_0a17:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a17
	jmp .L_lambda_simple_end_0a17
.L_lambda_simple_code_0a17:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_0b55
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b55:
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
	je .L_if_else_06f0
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
	.L_tc_recycle_frame_loop_0c94:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c94
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c94
	.L_tc_recycle_frame_done_0c94:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_07a6
.L_if_else_06f0:
	mov rax, PARAM(1)	; param i
.L_if_end_07a6:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_0a17:	; new closure is in rax
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
.L_lambda_opt_env_loop_013f:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_013f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_013f
.L_lambda_opt_env_end_013f:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_03bb:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_027d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_03bb
.L_lambda_opt_params_end_027d:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_013f
	jmp .L_lambda_opt_end_027d
.L_lambda_opt_code_013f:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	jge .L_lambda_simple_arity_check_ok_0b56
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b56:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 0
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_03bd
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_03bc: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_03bc
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_027e
	.L_lambda_opt_params_loop_03bd:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_03bc: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_03bc
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_03bd:
	cmp rdx, 0
	je .L_lambda_opt_params_end_027e
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_03bd
	.L_lambda_opt_params_end_027e:
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
	.L_lambda_opt_end_027e:
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
	.L_tc_recycle_frame_loop_0c95:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c95
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c95
	.L_tc_recycle_frame_done_0c95:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_027d:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0a14:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a18:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a18
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a18
.L_lambda_simple_env_end_0a18:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a18:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a18
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a18
.L_lambda_simple_params_end_0a18:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a18
	jmp .L_lambda_simple_end_0a18
.L_lambda_simple_code_0a18:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b57
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b57:
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
.L_lambda_simple_env_loop_0a19:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0a19
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a19
.L_lambda_simple_env_end_0a19:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a19:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0a19
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a19
.L_lambda_simple_params_end_0a19:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a19
	jmp .L_lambda_simple_end_0a19
.L_lambda_simple_code_0a19:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0b58
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b58:
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
	je .L_if_else_06f1
	mov rax, PARAM(0)	; param target
	jmp .L_if_end_07a7
.L_if_else_06f1:
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
.L_lambda_simple_env_loop_0a1a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0a1a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a1a
.L_lambda_simple_env_end_0a1a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a1a:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_0a1a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a1a
.L_lambda_simple_params_end_0a1a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a1a
	jmp .L_lambda_simple_end_0a1a
.L_lambda_simple_code_0a1a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b59
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b59:
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
	.L_tc_recycle_frame_loop_0c97:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c97
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c97
	.L_tc_recycle_frame_done_0c97:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a1a:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c96:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c96
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c96
	.L_tc_recycle_frame_done_0c96:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_07a7:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0a19:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a1b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0a1b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a1b
.L_lambda_simple_env_end_0a1b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a1b:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0a1b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a1b
.L_lambda_simple_params_end_0a1b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a1b
	jmp .L_lambda_simple_end_0a1b
.L_lambda_simple_code_0a1b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_0b5a
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b5a:
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
	je .L_if_else_06f2
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
	.L_tc_recycle_frame_loop_0c98:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c98
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c98
	.L_tc_recycle_frame_done_0c98:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_07a8
.L_if_else_06f2:
	mov rax, PARAM(1)	; param i
.L_if_end_07a8:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_0a1b:	; new closure is in rax
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
.L_lambda_opt_env_loop_0140:	; ext_env[i + 1] <-- env[i] copy all the array
	cmp rsi, 1
	je .L_lambda_opt_env_end_0140
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0140
.L_lambda_opt_env_end_0140:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_03be:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_027f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_03be
.L_lambda_opt_params_end_027f:
	mov qword [rax], rbx 	; ext_env[0] <-- The new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0140
	jmp .L_lambda_opt_end_027f
.L_lambda_opt_code_0140:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	jge .L_lambda_simple_arity_check_ok_0b5b
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b5b:
	mov r8, qword [rsp + 8 * 2]
	sub r8, 0
	mov rbx,r8
	cmp r8, 0
	jne .L_lambda_opt_params_loop_03c0
	mov rdx, qword [rsp + 8 * 2]
	add rdx , 3
	sub rsp , 8
	mov rcx, rsp
.L_lambda_opt_stack_adjusted_03bf: ;pushing down the stack of the current function
	mov rbx, qword [rcx + 8 * 1]
	mov qword[rcx] , rbx
	add rcx , 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_03bf
	inc qword [rsp + 8 * 2]
	mov qword [rcx], sob_nil 
	jmp .L_lambda_opt_end_0280
	.L_lambda_opt_params_loop_03c0:
	mov rdx, qword [rsp + 8*2]
	lea rcx, [rsp + 16 + 8*rdx]
	mov rdx, r8
	mov r9, sob_nil
	.L_lambda_opt_params_loop_03bf: ;loop for copying the opt into list
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
	jne .L_lambda_opt_params_loop_03bf
	mov rdx, qword [rsp + 8 * 2]
	mov rax, rsp
	lea rbx, [rsp + 8*(rdx + 2)]
	mov rcx, r8
	dec rcx
	add rdx, 3
	sub rdx,rcx
	shl rcx, 3
	.L_lambda_opt_stack_adjusted_03c0:
	cmp rdx, 0
	je .L_lambda_opt_params_end_0280
	mov rax, rbx
	sub rax, rcx
	mov rsi, qword [rax]
	mov [rbx], rsi
	sub rbx, 8
	dec rdx
	cmp rdx, 0
	jne .L_lambda_opt_stack_adjusted_03c0
	.L_lambda_opt_params_end_0280:
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
	.L_lambda_opt_end_0280:
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
	.L_tc_recycle_frame_loop_0c99:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c99
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c99
	.L_tc_recycle_frame_done_0c99:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	LEAVE
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_027f:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0a18:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a1c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a1c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a1c
.L_lambda_simple_env_end_0a1c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a1c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a1c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a1c
.L_lambda_simple_params_end_0a1c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a1c
	jmp .L_lambda_simple_end_0a1c
.L_lambda_simple_code_0a1c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b5c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b5c:
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
	.L_tc_recycle_frame_loop_0c9a:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c9a
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c9a
	.L_tc_recycle_frame_done_0c9a:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a1c:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a1d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a1d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a1d
.L_lambda_simple_env_end_0a1d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a1d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a1d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a1d
.L_lambda_simple_params_end_0a1d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a1d
	jmp .L_lambda_simple_end_0a1d
.L_lambda_simple_code_0a1d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b5d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b5d:
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
	.L_tc_recycle_frame_loop_0c9b:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c9b
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c9b
	.L_tc_recycle_frame_done_0c9b:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a1d:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a1e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a1e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a1e
.L_lambda_simple_env_end_0a1e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a1e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a1e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a1e
.L_lambda_simple_params_end_0a1e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a1e
	jmp .L_lambda_simple_end_0a1e
.L_lambda_simple_code_0a1e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b5e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b5e:
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
.L_lambda_simple_env_loop_0a1f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0a1f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a1f
.L_lambda_simple_env_end_0a1f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a1f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0a1f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a1f
.L_lambda_simple_params_end_0a1f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a1f
	jmp .L_lambda_simple_end_0a1f
.L_lambda_simple_code_0a1f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0b5f
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b5f:
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
	je .L_if_else_06f3
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
.L_lambda_simple_env_loop_0a20:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0a20
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a20
.L_lambda_simple_env_end_0a20:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a20:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_0a20
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a20
.L_lambda_simple_params_end_0a20:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a20
	jmp .L_lambda_simple_end_0a20
.L_lambda_simple_code_0a20:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b60
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b60:
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
	.L_tc_recycle_frame_loop_0c9d:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c9d
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c9d
	.L_tc_recycle_frame_done_0c9d:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a20:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c9c:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c9c
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c9c
	.L_tc_recycle_frame_done_0c9c:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_07a9
.L_if_else_06f3:
	mov rax, PARAM(0)	; param str
.L_if_end_07a9:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0a1f:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a21:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0a21
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a21
.L_lambda_simple_env_end_0a21:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a21:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0a21
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a21
.L_lambda_simple_params_end_0a21:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a21
	jmp .L_lambda_simple_end_0a21
.L_lambda_simple_code_0a21:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b61
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b61:
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
.L_lambda_simple_env_loop_0a22:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0a22
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a22
.L_lambda_simple_env_end_0a22:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a22:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0a22
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a22
.L_lambda_simple_params_end_0a22:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a22
	jmp .L_lambda_simple_end_0a22
.L_lambda_simple_code_0a22:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b62
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b62:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_151]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_06f4
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	jmp .L_if_end_07aa
.L_if_else_06f4:
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
	.L_tc_recycle_frame_loop_0c9f:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c9f
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c9f
	.L_tc_recycle_frame_done_0c9f:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_07aa:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a22:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0c9e:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0c9e
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0c9e
	.L_tc_recycle_frame_done_0c9e:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a21:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a1e:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a23:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a23
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a23
.L_lambda_simple_env_end_0a23:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a23:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a23
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a23
.L_lambda_simple_params_end_0a23:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a23
	jmp .L_lambda_simple_end_0a23
.L_lambda_simple_code_0a23:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b63
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b63:
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
.L_lambda_simple_env_loop_0a24:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0a24
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a24
.L_lambda_simple_env_end_0a24:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a24:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0a24
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a24
.L_lambda_simple_params_end_0a24:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a24
	jmp .L_lambda_simple_end_0a24
.L_lambda_simple_code_0a24:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0b64
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b64:
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
	je .L_if_else_06f5
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
.L_lambda_simple_env_loop_0a25:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0a25
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a25
.L_lambda_simple_env_end_0a25:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a25:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_0a25
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a25
.L_lambda_simple_params_end_0a25:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a25
	jmp .L_lambda_simple_end_0a25
.L_lambda_simple_code_0a25:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b65
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b65:
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
	.L_tc_recycle_frame_loop_0ca1:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0ca1
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0ca1
	.L_tc_recycle_frame_done_0ca1:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a25:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0ca0:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0ca0
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0ca0
	.L_tc_recycle_frame_done_0ca0:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_07ab
.L_if_else_06f5:
	mov rax, PARAM(0)	; param vec
.L_if_end_07ab:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0a24:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a26:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0a26
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a26
.L_lambda_simple_env_end_0a26:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a26:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0a26
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a26
.L_lambda_simple_params_end_0a26:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a26
	jmp .L_lambda_simple_end_0a26
.L_lambda_simple_code_0a26:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b66
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b66:
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
.L_lambda_simple_env_loop_0a27:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0a27
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a27
.L_lambda_simple_env_end_0a27:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a27:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0a27
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a27
.L_lambda_simple_params_end_0a27:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a27
	jmp .L_lambda_simple_end_0a27
.L_lambda_simple_code_0a27:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b67
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b67:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_151]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_06f6
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	jmp .L_if_end_07ac
.L_if_else_06f6:
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
	.L_tc_recycle_frame_loop_0ca3:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0ca3
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0ca3
	.L_tc_recycle_frame_done_0ca3:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_07ac:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a27:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0ca2:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0ca2
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0ca2
	.L_tc_recycle_frame_done_0ca2:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a26:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a23:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a28:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a28
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a28
.L_lambda_simple_env_end_0a28:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a28:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a28
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a28
.L_lambda_simple_params_end_0a28:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a28
	jmp .L_lambda_simple_end_0a28
.L_lambda_simple_code_0a28:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b68
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b68:
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
.L_lambda_simple_env_loop_0a29:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0a29
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a29
.L_lambda_simple_env_end_0a29:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a29:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0a29
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a29
.L_lambda_simple_params_end_0a29:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a29
	jmp .L_lambda_simple_end_0a29
.L_lambda_simple_code_0a29:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b69
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b69:
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
.L_lambda_simple_env_loop_0a2a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0a2a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a2a
.L_lambda_simple_env_end_0a2a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a2a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0a2a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a2a
.L_lambda_simple_params_end_0a2a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a2a
	jmp .L_lambda_simple_end_0a2a
.L_lambda_simple_code_0a2a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b6a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b6a:
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
	je .L_if_else_06f7
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
	.L_tc_recycle_frame_loop_0ca5:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0ca5
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0ca5
	.L_tc_recycle_frame_done_0ca5:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_07ad
.L_if_else_06f7:
	mov rax, L_constants + 1
.L_if_end_07ad:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a2a:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_0ca6:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0ca6
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0ca6
	.L_tc_recycle_frame_done_0ca6:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a29:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0ca4:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0ca4
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0ca4
	.L_tc_recycle_frame_done_0ca4:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0a28:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a2b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a2b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a2b
.L_lambda_simple_env_end_0a2b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a2b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a2b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a2b
.L_lambda_simple_params_end_0a2b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a2b
	jmp .L_lambda_simple_end_0a2b
.L_lambda_simple_code_0a2b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b6b
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b6b:
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
.L_lambda_simple_env_loop_0a2c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0a2c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a2c
.L_lambda_simple_env_end_0a2c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a2c:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0a2c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a2c
.L_lambda_simple_params_end_0a2c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a2c
	jmp .L_lambda_simple_end_0a2c
.L_lambda_simple_code_0a2c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b6c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b6c:
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
.L_lambda_simple_env_loop_0a2d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0a2d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a2d
.L_lambda_simple_env_end_0a2d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a2d:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0a2d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a2d
.L_lambda_simple_params_end_0a2d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a2d
	jmp .L_lambda_simple_end_0a2d
.L_lambda_simple_code_0a2d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b6d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b6d:
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
.L_lambda_simple_env_loop_0a2e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0a2e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a2e
.L_lambda_simple_env_end_0a2e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a2e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0a2e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a2e
.L_lambda_simple_params_end_0a2e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a2e
	jmp .L_lambda_simple_end_0a2e
.L_lambda_simple_code_0a2e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b6e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b6e:
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
	je .L_if_else_06f8
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
	.L_tc_recycle_frame_loop_0ca9:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0ca9
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0ca9
	.L_tc_recycle_frame_done_0ca9:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_07ae
.L_if_else_06f8:
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var str
.L_if_end_07ae:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a2e:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_0caa:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0caa
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0caa
	.L_tc_recycle_frame_done_0caa:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a2d:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0ca8:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0ca8
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0ca8
	.L_tc_recycle_frame_done_0ca8:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a2c:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0ca7:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0ca7
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0ca7
	.L_tc_recycle_frame_done_0ca7:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0a2b:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a2f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a2f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a2f
.L_lambda_simple_env_end_0a2f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a2f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a2f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a2f
.L_lambda_simple_params_end_0a2f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a2f
	jmp .L_lambda_simple_end_0a2f
.L_lambda_simple_code_0a2f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b6f
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b6f:
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
.L_lambda_simple_env_loop_0a30:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0a30
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a30
.L_lambda_simple_env_end_0a30:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a30:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0a30
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a30
.L_lambda_simple_params_end_0a30:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a30
	jmp .L_lambda_simple_end_0a30
.L_lambda_simple_code_0a30:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b70
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b70:
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
.L_lambda_simple_env_loop_0a31:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0a31
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a31
.L_lambda_simple_env_end_0a31:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a31:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0a31
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a31
.L_lambda_simple_params_end_0a31:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a31
	jmp .L_lambda_simple_end_0a31
.L_lambda_simple_code_0a31:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b71
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b71:
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
.L_lambda_simple_env_loop_0a32:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0a32
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a32
.L_lambda_simple_env_end_0a32:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a32:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0a32
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a32
.L_lambda_simple_params_end_0a32:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a32
	jmp .L_lambda_simple_end_0a32
.L_lambda_simple_code_0a32:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b72
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b72:
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
	je .L_if_else_06f9
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
	.L_tc_recycle_frame_loop_0cad:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0cad
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0cad
	.L_tc_recycle_frame_done_0cad:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_07af
.L_if_else_06f9:
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var vec
.L_if_end_07af:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a32:	; new closure is in rax
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
	.L_tc_recycle_frame_loop_0cae:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0cae
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0cae
	.L_tc_recycle_frame_done_0cae:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a31:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0cac:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0cac
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0cac
	.L_tc_recycle_frame_done_0cac:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a30:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0cab:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0cab
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0cab
	.L_tc_recycle_frame_done_0cab:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0a2f:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a33:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a33
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a33
.L_lambda_simple_env_end_0a33:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a33:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a33
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a33
.L_lambda_simple_params_end_0a33:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a33
	jmp .L_lambda_simple_end_0a33
.L_lambda_simple_code_0a33:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0b73
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b73:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_151]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_06fc
	mov rax, L_constants + 3485
	jmp .L_if_end_07b2
.L_if_else_06fc:
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
	je .L_if_else_06fb
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
	.L_tc_recycle_frame_loop_0caf:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0caf
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0caf
	.L_tc_recycle_frame_done_0caf:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	jmp .L_if_end_07b1
.L_if_else_06fb:
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
	je .L_if_else_06fa
	mov rax, L_constants + 3485
	jmp .L_if_end_07b0
.L_if_else_06fa:
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
	.L_tc_recycle_frame_loop_0cb0:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0cb0
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0cb0
	.L_tc_recycle_frame_done_0cb0:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
.L_if_end_07b0:
.L_if_end_07b1:
.L_if_end_07b2:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0a33:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a34:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a34
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a34
.L_lambda_simple_env_end_0a34:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a34:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a34
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a34
.L_lambda_simple_params_end_0a34:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a34
	jmp .L_lambda_simple_end_0a34
.L_lambda_simple_code_0a34:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0b74
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b74:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 3510
	push rax
	push 1	; arg count
	mov rax, qword [free_var_150]	; free var write-char
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
	.L_tc_recycle_frame_loop_0cb1:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0cb1
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0cb1
	.L_tc_recycle_frame_done_0cb1:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0a34:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a35:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a35
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a35
.L_lambda_simple_env_end_0a35:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a35:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a35
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a35
.L_lambda_simple_params_end_0a35:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a35
	jmp .L_lambda_simple_end_0a35
.L_lambda_simple_code_0a35:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0b75
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b75:
	enter 0, 0
	mov rax, L_constants + 0
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0a35:	; new closure is in rax
	mov qword [free_var_149], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 2
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
.L_lambda_simple_env_loop_0a36:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a36
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a36
.L_lambda_simple_env_end_0a36:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a36:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a36
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a36
.L_lambda_simple_params_end_0a36:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a36
	jmp .L_lambda_simple_end_0a36
.L_lambda_simple_code_0a36:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b76
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b76:
	enter 0, 0
	; preparing a tail-call
	push 0	; arg count
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
.L_lambda_simple_env_loop_0a37:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0a37
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a37
.L_lambda_simple_env_end_0a37:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a37:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0a37
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a37
.L_lambda_simple_params_end_0a37:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a37
	jmp .L_lambda_simple_end_0a37
.L_lambda_simple_code_0a37:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0b77
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b77:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0a37:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0cb2:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0cb2
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0cb2
	.L_tc_recycle_frame_done_0cb2:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a36:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 3
	push rax
	mov rax, L_constants + 2
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
.L_lambda_simple_env_loop_0a38:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a38
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a38
.L_lambda_simple_env_end_0a38:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a38:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a38
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a38
.L_lambda_simple_params_end_0a38:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a38
	jmp .L_lambda_simple_end_0a38
.L_lambda_simple_code_0a38:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b78
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b78:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2
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
.L_lambda_simple_env_loop_0a39:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0a39
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a39
.L_lambda_simple_env_end_0a39:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a39:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0a39
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a39
.L_lambda_simple_params_end_0a39:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a39
	jmp .L_lambda_simple_end_0a39
.L_lambda_simple_code_0a39:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b79
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b79:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2
	push rax
	mov rax, L_constants + 2
	push rax
	mov rax, L_constants + 2
	push rax
	push 3	; arg count
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
.L_lambda_simple_env_loop_0a3a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0a3a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a3a
.L_lambda_simple_env_end_0a3a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a3a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0a3a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a3a
.L_lambda_simple_params_end_0a3a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a3a
	jmp .L_lambda_simple_end_0a3a
.L_lambda_simple_code_0a3a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0b7a
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b7a:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2
	push rax
	mov rax, L_constants + 2
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0a3b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0a3b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a3b
.L_lambda_simple_env_end_0a3b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a3b:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_0a3b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a3b
.L_lambda_simple_params_end_0a3b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a3b
	jmp .L_lambda_simple_end_0a3b
.L_lambda_simple_code_0a3b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b7b
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b7b:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 1]	; bound var y
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0a3b:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0cb5:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0cb5
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0cb5
	.L_tc_recycle_frame_done_0cb5:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0a3a:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0cb4:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0cb4
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0cb4
	.L_tc_recycle_frame_done_0cb4:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a39:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0cb3:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0cb3
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0cb3
	.L_tc_recycle_frame_done_0cb3:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0a38:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a3c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a3c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a3c
.L_lambda_simple_env_end_0a3c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a3c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a3c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a3c
.L_lambda_simple_params_end_0a3c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a3c
	jmp .L_lambda_simple_end_0a3c
.L_lambda_simple_code_0a3c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b7c
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b7c:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0a3c:	; new closure is in rax
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_0a3d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a3d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a3d
.L_lambda_simple_env_end_0a3d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a3d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a3d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a3d
.L_lambda_simple_params_end_0a3d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a3d
	jmp .L_lambda_simple_end_0a3d
.L_lambda_simple_code_0a3d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b7d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b7d:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2
	push rax
	mov rax, L_constants + 3
	push rax
	push 2	; arg count
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
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0cb6:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0cb6
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0cb6
	.L_tc_recycle_frame_done_0cb6:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a3d:	; new closure is in rax
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_0a3e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a3e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a3e
.L_lambda_simple_env_end_0a3e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a3e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a3e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a3e
.L_lambda_simple_params_end_0a3e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a3e
	jmp .L_lambda_simple_end_0a3e
.L_lambda_simple_code_0a3e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b7e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b7e:
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
.L_lambda_simple_env_loop_0a3f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0a3f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a3f
.L_lambda_simple_env_end_0a3f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a3f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0a3f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a3f
.L_lambda_simple_params_end_0a3f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a3f
	jmp .L_lambda_simple_end_0a3f
.L_lambda_simple_code_0a3f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b7f
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b7f:
	enter 0, 0
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
.L_lambda_simple_env_loop_0a40:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0a40
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a40
.L_lambda_simple_env_end_0a40:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a40:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0a40
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a40
.L_lambda_simple_params_end_0a40:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a40
	jmp .L_lambda_simple_end_0a40
.L_lambda_simple_code_0a40:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b80
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b80:
	enter 0, 0
	; preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var y
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param p
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0cb8:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0cb8
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0cb8
	.L_tc_recycle_frame_done_0cb8:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a40:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0a3f:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param p
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0cb7:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0cb7
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0cb7
	.L_tc_recycle_frame_done_0cb7:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a3e:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a41:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a41
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a41
.L_lambda_simple_env_end_0a41:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a41:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a41
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a41
.L_lambda_simple_params_end_0a41:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a41
	jmp .L_lambda_simple_end_0a41
.L_lambda_simple_code_0a41:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b81
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b81:
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
.L_lambda_simple_env_loop_0a42:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0a42
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a42
.L_lambda_simple_env_end_0a42:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a42:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0a42
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a42
.L_lambda_simple_params_end_0a42:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a42
	jmp .L_lambda_simple_end_0a42
.L_lambda_simple_code_0a42:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b82
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b82:
	enter 0, 0
	mov rax, PARAM(0)	; param y
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a42:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a41:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a43:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a43
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a43
.L_lambda_simple_env_end_0a43:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a43:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a43
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a43
.L_lambda_simple_params_end_0a43:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a43
	jmp .L_lambda_simple_end_0a43
.L_lambda_simple_code_0a43:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b83
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b83:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0a43:	; new closure is in rax
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_0a44:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a44
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a44
.L_lambda_simple_env_end_0a44:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a44:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a44
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a44
.L_lambda_simple_params_end_0a44:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a44
	jmp .L_lambda_simple_end_0a44
.L_lambda_simple_code_0a44:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b84
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b84:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2
	push rax
	mov rax, L_constants + 3
	push rax
	push 2	; arg count
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
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0cb9:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0cb9
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0cb9
	.L_tc_recycle_frame_done_0cb9:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a44:	; new closure is in rax
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_0a45:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a45
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a45
.L_lambda_simple_env_end_0a45:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a45:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a45
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a45
.L_lambda_simple_params_end_0a45:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a45
	jmp .L_lambda_simple_end_0a45
.L_lambda_simple_code_0a45:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b85
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b85:
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
.L_lambda_simple_env_loop_0a46:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0a46
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a46
.L_lambda_simple_env_end_0a46:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a46:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0a46
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a46
.L_lambda_simple_params_end_0a46:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a46
	jmp .L_lambda_simple_end_0a46
.L_lambda_simple_code_0a46:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b86
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b86:
	enter 0, 0
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
.L_lambda_simple_env_loop_0a47:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0a47
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a47
.L_lambda_simple_env_end_0a47:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a47:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0a47
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a47
.L_lambda_simple_params_end_0a47:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a47
	jmp .L_lambda_simple_end_0a47
.L_lambda_simple_code_0a47:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b87
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b87:
	enter 0, 0
	; preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var y
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param p
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0cbb:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0cbb
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0cbb
	.L_tc_recycle_frame_done_0cbb:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a47:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0a46:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param p
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0cba:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0cba
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0cba
	.L_tc_recycle_frame_done_0cba:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a45:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a48:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a48
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a48
.L_lambda_simple_env_end_0a48:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a48:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a48
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a48
.L_lambda_simple_params_end_0a48:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a48
	jmp .L_lambda_simple_end_0a48
.L_lambda_simple_code_0a48:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b88
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b88:
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
.L_lambda_simple_env_loop_0a49:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0a49
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a49
.L_lambda_simple_env_end_0a49:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a49:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0a49
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a49
.L_lambda_simple_params_end_0a49:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a49
	jmp .L_lambda_simple_end_0a49
.L_lambda_simple_code_0a49:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b89
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b89:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param y
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0cbc:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0cbc
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0cbc
	.L_tc_recycle_frame_done_0cbc:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a49:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a48:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a4a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a4a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a4a
.L_lambda_simple_env_end_0a4a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a4a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a4a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a4a
.L_lambda_simple_params_end_0a4a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a4a
	jmp .L_lambda_simple_end_0a4a
.L_lambda_simple_code_0a4a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b8a
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b8a:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0a4a:	; new closure is in rax
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_0a4b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a4b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a4b
.L_lambda_simple_env_end_0a4b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a4b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a4b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a4b
.L_lambda_simple_params_end_0a4b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a4b
	jmp .L_lambda_simple_end_0a4b
.L_lambda_simple_code_0a4b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b8b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b8b:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2
	push rax
	mov rax, L_constants + 3
	push rax
	push 2	; arg count
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
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0cbd:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0cbd
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0cbd
	.L_tc_recycle_frame_done_0cbd:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a4b:	; new closure is in rax
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_0a4c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a4c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a4c
.L_lambda_simple_env_end_0a4c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a4c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a4c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a4c
.L_lambda_simple_params_end_0a4c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a4c
	jmp .L_lambda_simple_end_0a4c
.L_lambda_simple_code_0a4c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b8c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b8c:
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
.L_lambda_simple_env_loop_0a4d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0a4d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a4d
.L_lambda_simple_env_end_0a4d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a4d:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0a4d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a4d
.L_lambda_simple_params_end_0a4d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a4d
	jmp .L_lambda_simple_end_0a4d
.L_lambda_simple_code_0a4d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b8d
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b8d:
	enter 0, 0
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
.L_lambda_simple_env_loop_0a4e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0a4e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a4e
.L_lambda_simple_env_end_0a4e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a4e:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0a4e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a4e
.L_lambda_simple_params_end_0a4e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a4e
	jmp .L_lambda_simple_end_0a4e
.L_lambda_simple_code_0a4e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b8e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b8e:
	enter 0, 0
	; preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var y
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param p
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0cbf:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0cbf
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0cbf
	.L_tc_recycle_frame_done_0cbf:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a4e:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0a4d:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param p
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0cbe:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0cbe
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0cbe
	.L_tc_recycle_frame_done_0cbe:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a4c:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a4f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a4f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a4f
.L_lambda_simple_env_end_0a4f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a4f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a4f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a4f
.L_lambda_simple_params_end_0a4f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a4f
	jmp .L_lambda_simple_end_0a4f
.L_lambda_simple_code_0a4f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b8f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b8f:
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
.L_lambda_simple_env_loop_0a50:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0a50
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a50
.L_lambda_simple_env_end_0a50:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a50:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0a50
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a50
.L_lambda_simple_params_end_0a50:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a50
	jmp .L_lambda_simple_end_0a50
.L_lambda_simple_code_0a50:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b90
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b90:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param y
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0cc0:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0cc0
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0cc0
	.L_tc_recycle_frame_done_0cc0:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a50:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a4f:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a51:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a51
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a51
.L_lambda_simple_env_end_0a51:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a51:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a51
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a51
.L_lambda_simple_params_end_0a51:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a51
	jmp .L_lambda_simple_end_0a51
.L_lambda_simple_code_0a51:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b91
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b91:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0a51:	; new closure is in rax
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_0a52:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a52
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a52
.L_lambda_simple_env_end_0a52:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a52:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a52
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a52
.L_lambda_simple_params_end_0a52:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a52
	jmp .L_lambda_simple_end_0a52
.L_lambda_simple_code_0a52:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b92
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b92:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2
	push rax
	mov rax, L_constants + 3
	push rax
	push 2	; arg count
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
	mov rdx, 5
	mov rax, rdx
	dec rax
	shl rax,3
	add rax, rsp
	.L_tc_recycle_frame_loop_0cc1:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0cc1
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0cc1
	.L_tc_recycle_frame_done_0cc1:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a52:	; new closure is in rax
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_0a53:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a53
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a53
.L_lambda_simple_env_end_0a53:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a53:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a53
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a53
.L_lambda_simple_params_end_0a53:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a53
	jmp .L_lambda_simple_end_0a53
.L_lambda_simple_code_0a53:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b93
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b93:
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
.L_lambda_simple_env_loop_0a54:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0a54
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a54
.L_lambda_simple_env_end_0a54:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a54:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0a54
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a54
.L_lambda_simple_params_end_0a54:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a54
	jmp .L_lambda_simple_end_0a54
.L_lambda_simple_code_0a54:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0b94
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b94:
	enter 0, 0
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
.L_lambda_simple_env_loop_0a55:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0a55
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a55
.L_lambda_simple_env_end_0a55:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a55:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0a55
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a55
.L_lambda_simple_params_end_0a55:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a55
	jmp .L_lambda_simple_end_0a55
.L_lambda_simple_code_0a55:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b95
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b95:
	enter 0, 0
	; preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var y
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param p
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0cc3:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0cc3
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0cc3
	.L_tc_recycle_frame_done_0cc3:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a55:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0a54:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param p
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0cc2:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0cc2
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0cc2
	.L_tc_recycle_frame_done_0cc2:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a53:	; new closure is in rax
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_0a56:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a56
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a56
.L_lambda_simple_env_end_0a56:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a56:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a56
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a56
.L_lambda_simple_params_end_0a56:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a56
	jmp .L_lambda_simple_end_0a56
.L_lambda_simple_code_0a56:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b96
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b96:
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
.L_lambda_simple_env_loop_0a57:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0a57
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a57
.L_lambda_simple_env_end_0a57:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a57:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0a57
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a57
.L_lambda_simple_params_end_0a57:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a57
	jmp .L_lambda_simple_end_0a57
.L_lambda_simple_code_0a57:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b97
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b97:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param y
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0cc4:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0cc4
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0cc4
	.L_tc_recycle_frame_done_0cc4:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a57:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a56:	; new closure is in rax
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
.L_lambda_simple_env_loop_0a58:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0a58
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0a58
.L_lambda_simple_env_end_0a58:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0a58:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0a58
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0a58
.L_lambda_simple_params_end_0a58:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0a58
	jmp .L_lambda_simple_end_0a58
.L_lambda_simple_code_0a58:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0b98
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0b98:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param x
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param x
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
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
	.L_tc_recycle_frame_loop_0cc5:
	cmp rcx, rdx
	je .L_tc_recycle_frame_done_0cc5
	mov r9, qword [rax]
	mov qword [rbx],r9
	sub rax,8
	sub rbx,8
	add rcx,1
	jmp .L_tc_recycle_frame_loop_0cc5
	.L_tc_recycle_frame_done_0cc5:
	add rbx,8
	mov rsp,rbx
	jmp SOB_CLOSURE_CODE(r8)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0a58:	; new closure is in rax
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
        cmp qword [rsp + 8 * 2], 2 ;arg count
        jne L_error_arg_count_2
        mov r8, qword [rsp + 8 * 3] ;param 0 (closure)
        assert_closure(r8)
        lea r9, [rsp + 8 * 4] 
        mov r10, qword [r9] ;param 1 (list)
        mov r11, qword [rsp] ;ret_addr
        mov rcx, 0
        mov rbx, r10
.L_length_loop: ;count list length
        cmp rbx, sob_nil
        je .L_length_loop_exit
        assert_pair(rbx)
        inc rcx
        mov rbx, SOB_PAIR_CDR(rbx)
        jmp .L_length_loop
.L_length_loop_exit:
        lea rbx, [8 * rcx - 8 * 2]
        sub rsp, rbx ;fix stack pointer
        mov rdi, rsp
        mov [rdi], r11 ;ret_addr
        add rdi,8
        mov rax, SOB_CLOSURE_ENV(r8)
        mov [rdi], rax ;param 0 env
        add rdi,8
        mov [rdi], rcx ;args_count (list length)
        add rdi,8
.L_loop:
        cmp rcx, 0
        je .L_exit
        mov rax, SOB_PAIR_CAR(r10)
        mov [rdi], rax
        add rdi,8
        mov r10, SOB_PAIR_CDR(r10)
        dec rcx
        jmp .L_loop
.L_exit:
        jmp SOB_CLOSURE_CODE(r8)






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
