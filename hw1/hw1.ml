(* hw1.ml
 * Handling infix expressions with percents:
 *
 *   x + y %
 *   x - y %
 *   x * y %
 *
 * Programmer: Mayer Goldberg, 2024
 *)

#use "pc.ml";;

type binop = Add | Sub | Mul | Div | Mod | Pow | AddPer | SubPer | PerOf;;

type expr =
  | Num of int
  | Var of string
  | BinOp of binop * expr * expr
  | Deref of expr * expr
  | Call of expr * expr list;;

type args_or_index = Args of expr list | Index of expr;;

module type INFIX_PARSER = sig
  val nt_expr : expr PC.parser
end;; (* module type INFIX_PARSER *)

module InfixParser : INFIX_PARSER = struct
open PC;;

let maybeify  nt none_value = 
  pack (maybe nt) (function | None -> none_value | Some x -> x);;


(*int related*)
let nt_optional_is_positive =
  let nt1 = pack (char '-') (fun _ -> false) in
  let nt2 = pack (char '+') (fun _ -> true) in
  let nt1 = maybeify (disj nt1 nt2) true in 
  nt1;;

let int_of_digit_char = 
  let delta = int_of_char '0' in 
  fun ch -> int_of_char ch - delta;;
  

let nt_digit_0_9 = 
  pack (range '0' '9') (int_of_digit_char)


let nt_optional_is_not_divided =
  let nt1 = pack (char '/') (fun _ -> false) in
  let nt1 = maybeify nt1 true in
  nt1;;
  

let nt_int = 
  let nt1 = pack (plus nt_digit_0_9)
  (fun digits -> List.fold_left (fun number digit -> 10 * number + digit) 0 digits) in
  let nt1 = caten nt_optional_is_positive nt1 in
  let nt1 = pack nt1 (fun (is_positive, n) -> if is_positive then n else (-n)) in
  let nt1 = pack nt1 (fun n -> Num n) in
    nt1;;


let nt_whitespace = const (fun ch -> ch <= ' ');;


let make_nt_spaced_out nt = 
  let nt1 = star nt_whitespace in
  let nt1 = pack (caten nt1 (caten nt nt1)) (fun (_, (e, _)) -> e) in
  nt1;;

let make_nt_paren ch_left ch_right nt =
      let nt1 = make_nt_spaced_out (char ch_left) in
      let nt2 = make_nt_spaced_out (char ch_right) in
      let nt1 = caten nt1 (caten nt nt2) in
      let nt1 = pack nt1 (fun (_, (e, _)) -> e) in 
      nt1;;


(*whitespace*)



(*parenthesis*)
let make_nt_paren ch_left ch_right nt=
  let nt1 = make_nt_spaced_out (char ch_left) in
  let nt2 = make_nt_spaced_out (char ch_right) in
  let nt1 = caten nt1 (caten nt nt2) in
  let nt1 = pack nt1 (fun (_, (e, _)) -> e) in
  nt1;;

(*vars*)
let nt_var = 
  let nt1 = range_ci 'a' 'z' in
  let nt2 = range '0' '9' in
  let nt3 = const (fun ch -> ch = '$' || ch = '_') in
  let nt4 = (disj (disj nt1 nt2) nt3) in
  let nt2 = caten nt1 (star nt4) in
  let nt1 = pack (diff nt2 (not_followed_by (word "mod") nt4)) (fun (ch1, chs) -> string_of_list (ch1 :: chs)) in
  let nt1 = pack nt1 (fun name -> Var name) in
  nt1;;

let nt_mod = word "mod"

 
let rec nt_expr str = nt_expr_0 str
and nt_expr_0 str =
  let nt1 = pack (char '+') (fun _ -> Add) in
  let nt2 = pack (char '-') (fun _ -> Sub) in
  let nt1 = disj nt1 nt2 in
  let nt1 = star (caten nt1 nt_expr_1) in
  let nt1 = pack (caten nt_expr_1 nt1) (fun (expr1, binop_expr1) -> List.fold_left (fun expr1 (binop, expr1') -> BinOp (binop, expr1, expr1')) expr1 binop_expr1) in
  let nt1 = make_nt_spaced_out nt1 in
  nt1 str
  and nt_expr_1 str =
    let nt1 = pack (char '*') (fun _ -> Mul) in
    let nt2 = pack (char '/') (fun _ -> Div) in
    let nt3 = pack nt_mod (fun _ -> Mod) in
    let nt1 = disj nt1 (disj nt2 nt3) in
    let nt1 = star (caten nt1 nt_expr_3) in
    let nt1 = pack (caten nt_expr_3 nt1) (fun (expr3, binop_expr3) -> List.fold_left (fun expr3 (binop, expr3') -> BinOp (binop, expr3, expr3')) expr3 binop_expr3) in
    let nt1 = make_nt_spaced_out nt1 in
    nt1 str

and nt_expr_3 str =
  let nt1 = pack (char '+') (fun _ -> AddPer) in
  let nt2 = pack (char '-') (fun _ -> SubPer) in
  let nt3 = pack (char '*') (fun _ -> PerOf) in
  let nt1 = disj nt1 (disj nt2 nt3) in
  let percentage = make_nt_spaced_out(char '%') in
  let nt1 = star (pack 
                (caten nt1 (caten nt_expr_4 percentage))
                (fun (a, (b, _)) -> (a, b))) in
  let nt1 = pack (caten nt_expr_4 nt1) (fun (expr4, binop_expr4) -> List.fold_left (fun expr4 (binop, expr4') -> BinOp (binop, expr4, expr4')) expr4 binop_expr4) in
  let nt1 = make_nt_spaced_out nt1 in
  nt1 str


and nt_expr_4 str =
    let nt1 = pack (char '^') (fun _ -> Pow) in
    let nt1 = star (caten nt_expr_5 nt1) in
    let nt1 = pack (caten nt1 nt_expr_5) (fun (binop_expr5, expr5) -> List.fold_right (fun (expr5',binop) expr5 -> BinOp (binop, expr5',expr5)) binop_expr5 expr5) in
    let nt1 = make_nt_spaced_out nt1 in
    nt1 str


and nt_expr_5 str = 
  let nt1 = nt_expr_6 in
  let nt2 = make_separated_by_star (char ',') nt_expr in
  
  let nt2 = make_nt_paren '(' ')' nt2 in
  let nt2 = pack nt2 (fun arg -> Args arg) in

  let nt3 = make_nt_paren '[' ']' nt_expr in
  let nt3 = pack nt3 (fun e -> Index e) in
  let nt2 = star (disj nt2 nt3) in

  let nt1 = caten nt1 nt2 in
  let nt1 = pack nt1 (fun (index, arg) -> List.fold_left(fun index -> function
                                                                       | Args es -> Call (index,es)
                                                                       | Index index' -> Deref (index,index'))
                                                                       index arg) in
  nt1 str



and nt_expr_6 str= 
  let nt1 = disj_list [nt_int ; nt_var ; nt_paren] in
  let nt1 = make_nt_spaced_out nt1 in
  nt1 str

and nt_paren str =
  let nt1 = pack(char '-')(fun _ -> Sub) in
  let nt2 = followed_by nt_expr(make_nt_spaced_out (char ')')) in
  let nt1 = pack (caten nt1 (make_nt_spaced_out nt2)) (fun (_, exp) -> BinOp (Sub, Num 0, exp)) in
  let nt3 = pack (char '/') (fun _ -> Div) in
  let nt3 = pack (caten nt3 (make_nt_spaced_out nt2))
    (fun (_, exp) -> BinOp (Div, Num 1, exp)) in
  let nt = disj nt1 nt3 in
  make_nt_paren '(' ')' (disj nt nt_expr) str;;

(*and nt_expr_5 str =  
  let nt1 = caten (char '[') (caten (nt_expr_6) (char ']')) in
  let nt1 = pack nt1 (fun (_,(expr6,_)) -> (fun expr6' -> Deref expr6 expr6')) in
  let nt1 = star nt1 in
  let nt1 = pack (caten nt_expr_6 nt1) (fun (expr6, binop_expr6) -> List.fold_left (fun expr6 (binop, expr6') -> BinOp (binop, expr6, expr6')) expr6 binop_expr6) in
  let nt1 = make_nt_spaced_out nt1 in
  nt1 str


 and nt_expr_6 str =
  let nt1 =  
   (caten  (const (fun ch -> ch = '/' )) (const (fun ch -> ch = nt_expr_6 )))  in
(*
  let nt1 = caten(caten(pack (char '(') pack (char '/') (fun _ -> Div)))) in
  let nt2 = Num 1 in *)
  let nt1 = pack (caten nt1 nt_expr_7) (fun (binop, expr7) -> BinOp (binop, nt2, expr)7) in
  let nt1 = make_nt_spaced_out nt1 in
  nt1 str*)

(* This is for Numbers*)
(*
and nt_expr_7 str =
  let nt1 = pack nt_int (fun num -> Num num) in
  let nt1 = disj nt1 nt_var in
  let nt1 = disj nt1 nt_paren in
  let nt1 = make_nt_spaced_out nt1 in
  nt1 str

  (* This is for parenthesis*)
and nt_paren str =
  (make_nt_paren '(' ')' nt_expr)  str
;;*)

end;; (* module InfixParser *)

open InfixParser;;
