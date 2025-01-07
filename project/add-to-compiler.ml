exception X_not_yet_implemented of string;;

(* *)

let file_to_string input_file =
  let in_channel = open_in input_file in
  let rec run () =
    try 
      let ch = input_char in_channel in ch :: (run ())
    with End_of_file ->
      ( close_in in_channel;
	[] )
  in string_of_list (run ());;

let string_to_file output_file out_string =
  let out_channel = open_out output_file in
  ( output_string out_channel out_string;
    close_out out_channel );;

let remove_duplicates =
  let rec run singles = function
    | [] -> singles
    | sexpr :: sexprs when List.mem sexpr singles -> run singles sexprs
    | sexpr :: sexprs -> run (singles @ [sexpr]) sexprs
  in fun sexprs -> run [] sexprs;;

module type CODE_GENERATION =
  sig
    val compile_scheme_string : string -> string -> unit
    val compile_scheme_file : string -> string -> unit
    val compile_and_run_scheme_string : string -> string -> unit
  end;;

module Code_Generation (* : CODE_GENERATION *) = struct
  let word_size = 8;;
  let label_start_of_constants_table = "L_constants";;
  let comment_length = 20;;

  let global_bindings_table =
    [ (* 1-10 *)
      ("null?", "L_code_ptr_is_null");
      ("pair?", "L_code_ptr_is_pair");
      ("void?", "L_code_ptr_is_void");
      ("char?", "L_code_ptr_is_char");
      ("string?", "L_code_ptr_is_string");
      ("interned-symbol?", "L_code_ptr_is_symbol");
      ("vector?", "L_code_ptr_is_vector");
      ("procedure?", "L_code_ptr_is_closure");
      ("real?", "L_code_ptr_is_real");
      ("fraction?", "L_code_ptr_is_fraction");
      (* 11-20 *)
      ("boolean?", "L_code_ptr_is_boolean");
      ("number?", "L_code_ptr_is_number");
      ("collection?", "L_code_ptr_is_collection");
      ("cons", "L_code_ptr_cons");
      ("display-sexpr", "L_code_ptr_display_sexpr");
      ("write-char", "L_code_ptr_write_char");
      ("car", "L_code_ptr_car");
      ("cdr", "L_code_ptr_cdr");
      ("string-length", "L_code_ptr_string_length");
      ("vector-length", "L_code_ptr_vector_length");
      (* 21-30*)
      ("real->integer", "L_code_ptr_real_to_integer");
      ("exit", "L_code_ptr_exit");
      ("integer->real", "L_code_ptr_integer_to_real");
      ("fraction->real", "L_code_ptr_fraction_to_real");
      ("char->integer", "L_code_ptr_char_to_integer");
      ("integer->char", "L_code_ptr_integer_to_char");
      ("trng", "L_code_ptr_trng");
      ("zero?", "L_code_ptr_is_zero");
      ("integer?", "L_code_ptr_is_integer");
      ("__bin-apply", "L_code_ptr_bin_apply");
      (* 31-40*)
      ("__bin-add-rr", "L_code_ptr_raw_bin_add_rr");
      ("__bin-sub-rr", "L_code_ptr_raw_bin_sub_rr");
      ("__bin-mul-rr", "L_code_ptr_raw_bin_mul_rr");
      ("__bin-div-rr", "L_code_ptr_raw_bin_div_rr");
      ("__bin-add-qq", "L_code_ptr_raw_bin_add_qq");
      ("__bin-sub-qq", "L_code_ptr_raw_bin_sub_qq");
      ("__bin-mul-qq", "L_code_ptr_raw_bin_mul_qq");
      ("__bin-div-qq", "L_code_ptr_raw_bin_div_qq");
      ("__bin-add-zz", "L_code_ptr_raw_bin_add_zz");
      ("__bin-sub-zz", "L_code_ptr_raw_bin_sub_zz");
      (* 41-50 *)      
      ("__bin-mul-zz", "L_code_ptr_raw_bin_mul_zz");
      ("__bin-div-zz", "L_code_ptr_raw_bin_div_zz");
      ("error", "L_code_ptr_error");
      ("__bin-less-than-rr", "L_code_ptr_raw_less_than_rr");
      ("__bin-less-than-qq", "L_code_ptr_raw_less_than_qq");
      ("__bin-less-than-zz", "L_code_ptr_raw_less_than_zz");
      ("__bin-equal-rr", "L_code_ptr_raw_equal_rr");
      ("__bin-equal-qq", "L_code_ptr_raw_equal_qq");
      ("__bin-equal-zz", "L_code_ptr_raw_equal_zz");
      ("quotient", "L_code_ptr_quotient");
      (* 51-60 *)
      ("remainder", "L_code_ptr_remainder");
      ("set-car!", "L_code_ptr_set_car");
      ("set-cdr!", "L_code_ptr_set_cdr");
      ("string-ref", "L_code_ptr_string_ref");
      ("vector-ref", "L_code_ptr_vector_ref");
      ("vector-set!", "L_code_ptr_vector_set");
      ("string-set!", "L_code_ptr_string_set");
      ("make-vector", "L_code_ptr_make_vector");
      ("make-string", "L_code_ptr_make_string");
      ("numerator", "L_code_ptr_numerator");
      (* 61-70 *)
      ("denominator", "L_code_ptr_denominator");
      ("eq?", "L_code_ptr_is_eq");
      ("__integer-to-fraction", "L_code_ptr_integer_to_fraction");
      ("logand", "L_code_ptr_logand");
      ("logor", "L_code_ptr_logor");
      ("logxor", "L_code_ptr_logxor");
      ("lognot", "L_code_ptr_lognot");
      ("ash", "L_code_ptr_ash");
      ("symbol?", "L_code_ptr_is_symbol");
      ("uninterned-symbol?", "L_code_ptr_is_uninterned_symbol");
      (* 71-80 *)
      ("gensym?", "L_code_ptr_is_uninterned_symbol");
      ("interned-symbol?", "L_code_ptr_is_interned_symbol");
      ("gensym", "L_code_ptr_gensym");
      ("frame", "L_code_ptr_frame");
      ("break", "L_code_ptr_break");
      ("boolean-false?", "L_code_ptr_is_boolean_false");
      ("boolean-true?", "L_code_ptr_is_boolean_true");
      ("primitive?", "L_code_ptr_is_primitive");
      ("length", "L_code_ptr_length");
      ("make-list", "L_code_ptr_make_list");
      ("return", "L_code_ptr_return");
    ];;  

  let collect_constants =
    let rec run = function
      | _ -> raise (X_not_yet_implemented "final project")
    and runs exprs' =
      List.fold_left (fun consts expr' -> consts @ (run expr')) [] exprs'
    in
    fun exprs' ->
    (List.map
       (fun (scm_name, _) -> ScmString scm_name)
       global_bindings_table)
    @ (runs exprs');;

  let add_sub_constants =
    let rec run sexpr = match sexpr with
      | ScmVoid | ScmNil | ScmBoolean _ -> []
      | ScmChar _ | ScmString _ | ScmNumber _ -> [sexpr]
      | ScmSymbol sym -> [ScmString sym; ScmSymbol sym]
      | ScmPair (car, cdr) -> (run car) @ (run cdr) @ [sexpr]
      | ScmVector sexprs -> (runs sexprs) @ [sexpr]
    and runs sexprs =
      List.fold_left (fun full sexpr -> full @ (run sexpr)) [] sexprs
    in fun exprs' ->
       [ScmVoid; ScmNil; ScmBoolean false; ScmBoolean true; ScmChar '\000']
       @ (runs exprs');;

  type initialized_data =
    | RTTI of string
    | Byte of int
    | ASCII of string
    | Quad of int
    | QuadFloat of float
    | ConstPtr of int;;

  let search_constant_address =
    let rec run sexpr = function
      | [] -> assert false
      | (sexpr', loc, _repr) :: sexprs when sexpr = sexpr' -> loc
      | _ :: sexprs -> run sexpr sexprs
    in run;;

  let const_repr sexpr loc table = match sexpr with
    | ScmVoid -> ([RTTI "T_void"], 1)
    | ScmNil -> ([RTTI "T_nil"], 1)
    | ScmBoolean false ->
       ([RTTI "T_boolean_false"], 1)
    | ScmBoolean true ->
       ([RTTI "T_boolean_true"], 1)
    | ScmChar ch ->
       ([RTTI "T_char"; Byte (int_of_char ch)], 2)
    | ScmString str ->
       raise (X_not_yet_implemented "final project")
    | ScmSymbol sym ->
       let addr = search_constant_address (ScmString sym) table in
       ([RTTI "T_interned_symbol"; ConstPtr addr], 1 + word_size)
    | ScmNumber (ScmInteger n) ->
       ([RTTI "T_integer"; Quad n], 1 + word_size)
    | ScmNumber (ScmFraction (numerator, denominator)) ->
       raise (X_not_yet_implemented "final project")
    | ScmNumber (ScmReal x) ->
       ([RTTI "T_real"; QuadFloat x], 1 + word_size)
    | ScmVector s ->
       raise (X_not_yet_implemented "final project")
    | ScmPair (car, cdr) ->
       raise (X_not_yet_implemented "final project");;

  let make_constants_table =
    let rec run table loc = function
      | [] -> table
      | sexpr :: sexprs ->
         let (repr, len) = const_repr sexpr loc table in
         run (table @ [(sexpr, loc, repr)]) (loc + len) sexprs
    in
    fun exprs' ->
    run [] 0
      (remove_duplicates
         (add_sub_constants
            (remove_duplicates
               (collect_constants exprs'))));;    

  let asm_comment_of_sexpr sexpr =
    let str = string_of_sexpr sexpr in
    let str =
      if (String.length str) <= comment_length
      then str
      else (String.sub str 0 comment_length) ^ "..." in
    "; " ^ str;;

  let asm_of_representation sexpr =
    let str = asm_comment_of_sexpr sexpr in
    let run = function
      | [RTTI str] -> Printf.sprintf "\tdb %s" str
      | [RTTI "T_char"; Byte byte] ->
         Printf.sprintf "\tdb T_char, 0x%02X\t%s" byte str
      | [RTTI "T_string"; Quad length; ASCII const_str] ->
         Printf.sprintf "\tdb T_string\t%s\n\tdq %d%s"
           str length
           (let s = list_of_string const_str in
            let s = List.map
                      (fun ch -> Printf.sprintf "0x%02X" (int_of_char ch))
                      s in
            let s = split_to_sublists 8 s in
            let s = List.map (fun si -> "\n\tdb " ^ (String.concat ", " si)) s in
            String.concat "" s)
      | [RTTI "T_interned_symbol"; ConstPtr addr] ->
         Printf.sprintf "\tdb T_interned_symbol\t%s\n\tdq %s + %d"
           str label_start_of_constants_table addr
      | [RTTI "T_integer"; Quad n] ->
         Printf.sprintf "\tdb T_integer\t%s\n\tdq %d" str n
      | [RTTI "T_fraction"; Quad numerator; Quad denominator] ->
         Printf.sprintf "\tdb T_fraction\t%s\n\tdq %d, %d"
           str
           numerator denominator
      | [RTTI "T_real"; QuadFloat x] ->
         Printf.sprintf "\tdb T_real\t%s\n\tdq %f" str x
      | (RTTI "T_vector") :: (Quad length) :: addrs ->
         Printf.sprintf "\tdb T_vector\t%s\n\tdq %d%s"
           str length
           (let s = List.map
                      (function
                       | ConstPtr ptr ->
                          Printf.sprintf "%s + %d"
                            label_start_of_constants_table ptr
                       | _ -> assert false)
                      addrs in
            let s = split_to_sublists 3 s in
            let s = List.map (fun si -> "\n\tdq " ^ (String.concat ", " si)) s in
            String.concat "" s)
      | [RTTI "T_pair"; ConstPtr car; ConstPtr cdr] ->
         Printf.sprintf "\tdb T_pair\t%s\n\tdq %s + %d, %s + %d"
           str
           label_start_of_constants_table car
           label_start_of_constants_table cdr
      | _ -> assert false
    in run;;

  let asm_of_constants_table =
    let rec run = function
      | [] -> ""
      | (sexpr, loc, repr) :: rest ->
         (Printf.sprintf "\t; %s + %d:\n" label_start_of_constants_table loc)
         ^ (asm_of_representation sexpr repr) ^ "\n" ^ (run rest)
    in
    fun table ->
    Printf.sprintf "%s:\n%s"
      label_start_of_constants_table (run table);;

  let collect_free_vars =
    let rec run = function
      | _ -> raise (X_not_yet_implemented "final project")
    and runs exprs' =
      List.fold_left
        (fun vars expr' -> vars @ (run expr'))
        []
        exprs'
    in fun exprs' -> remove_duplicates (runs exprs');;

  let make_free_vars_table =
    let rec run index = function
      | [] -> []
      | v :: vars ->
         let x86_label = Printf.sprintf "free_var_%d" index in
         (v, x86_label) :: (run (index + 1) vars)
    in fun exprs' ->
       run 0 (List.sort String.compare (collect_free_vars exprs'));;

  let search_free_var_table =
    let rec run v = function
      | [] -> assert false
      | (v', x86_label) :: _ when v = v' -> x86_label
      | _ :: table -> run v table
    in run;;

  let asm_of_global_bindings global_bindings_table free_var_table =
    String.concat "\n"
      (List.map
         (fun (scheme_name, asm_code_ptr) ->
           let free_var_label =
             search_free_var_table scheme_name free_var_table in
           (Printf.sprintf "\t; building closure for %s\n" scheme_name)
           ^ (Printf.sprintf "\tmov rdi, %s\n" free_var_label)
           ^ (Printf.sprintf "\tmov rsi, %s\n" asm_code_ptr)
           ^ "\tcall bind_primitive\n")
         (List.filter
            (fun (scheme_name, _asm_code_ptr) ->
              match (List.assoc_opt scheme_name free_var_table) with
              | None -> false
              | Some _ -> true)
            global_bindings_table));;
  
  let asm_of_free_vars_table fvars_table consts_table=
    let tmp = 
      List.map
        (fun (scm_var, asm_label) ->
          let addr =
            search_constant_address (ScmString scm_var) consts_table in
          (Printf.sprintf "%s:\t; location of %s\n" 
             asm_label scm_var)
          ^ "\tdq .undefined_object\n"
          ^ ".undefined_object:\n"
          ^ "\tdb T_undefined\n"
          ^ (Printf.sprintf "\tdq L_constants + %d\n"
               addr))
        fvars_table in
    String.concat "\n" tmp;;

  let make_make_label prefix =
    let index = ref 0 in
    fun () ->
    (index := !index + 1;
     Printf.sprintf "%s_%04x" prefix !index);;

  let make_if_else = make_make_label ".L_if_else";;
  let make_if_end = make_make_label ".L_if_end";;
  let make_or_end = make_make_label ".L_or_end";;
  let make_lambda_simple_loop_env =
    make_make_label ".L_lambda_simple_env_loop";;
  let make_lambda_simple_loop_env_end =
    make_make_label ".L_lambda_simple_env_end";;
  let make_lambda_simple_loop_params =
    make_make_label ".L_lambda_simple_params_loop";;
  let make_lambda_simple_loop_params_end =
    make_make_label ".L_lambda_simple_params_end";;
  let make_lambda_simple_code = make_make_label ".L_lambda_simple_code";;
  let make_lambda_simple_end = make_make_label ".L_lambda_simple_end";;
  let make_lambda_simple_arity_ok =
    make_make_label ".L_lambda_simple_arity_check_ok";;

  let make_lambda_opt_loop_env =
    make_make_label ".L_lambda_opt_env_loop";;
  let make_lambda_opt_loop_env_end =
    make_make_label ".L_lambda_opt_env_end";;
  let make_lambda_opt_loop_params =
    make_make_label ".L_lambda_opt_params_loop";;
  let make_lambda_opt_loop_params_end =
    make_make_label ".L_lambda_opt_params_end";;
  let make_lambda_opt_code = make_make_label ".L_lambda_opt_code";;
  let make_lambda_opt_end = make_make_label ".L_lambda_opt_end";;
  let make_lambda_opt_arity_exact =
    make_make_label ".L_lambda_opt_arity_check_exact";;
  let make_lambda_opt_arity_more =
    make_make_label ".L_lambda_opt_arity_check_more";;
  let make_lambda_opt_stack_ok =
    make_make_label ".L_lambda_opt_stack_adjusted";;
  let make_lambda_opt_loop =
    make_make_label ".L_lambda_opt_stack_shrink_loop";;
  let make_lambda_opt_loop_exit =
    make_make_label ".L_lambda_opt_stack_shrink_loop_exit";;
  let make_tc_applic_recycle_frame_loop =
    make_make_label ".L_tc_recycle_frame_loop";;
  let make_tc_applic_recycle_frame_done =
    make_make_label ".L_tc_recycle_frame_done";;

  let code_gen exprs' =
    let consts = make_constants_table exprs' in
    let free_vars = make_free_vars_table exprs' in
    let rec run params env = function
      | ScmConst' sexpr ->
         let addr = search_constant_address sexpr consts in
         Printf.sprintf "\tmov rax, L_constants + %d\n" addr
      | ScmVarGet' (Var' (v, Free)) ->
         let label = search_free_var_table v free_vars in
         (Printf.sprintf
            "\tmov rax, qword [%s]\t; free var %s\n"
            label v)
         ^ "\tcmp byte [rax], T_undefined\n"
         ^ "\tje L_error_fvar_undefined\n"
      | ScmVarGet' (Var' (v, Param minor)) ->
         Printf.sprintf "\tmov rax, PARAM(%d)\t; param %s\n"
           minor v
      | ScmVarGet' (Var' (v, Bound (major, minor))) ->
         "\tmov rax, ENV\n"
         ^ (Printf.sprintf "\tmov rax, qword [rax + 8 * %d]\n" major)
         ^ (Printf.sprintf
              "\tmov rax, qword [rax + 8 * %d]\t; bound var %s\n" minor v)
      | ScmIf' (test, dit, dif) ->
         let test_code = run params env test
         and dit_code = run params env dit
         and dif_code = run params env dif
         and label_else = make_if_else ()
         and label_end = make_if_end () in
         test_code
         ^ "\tcmp rax, sob_boolean_false\n"
         ^ (Printf.sprintf "\tje %s\n" label_else)
         ^ dit_code
         ^ (Printf.sprintf "\tjmp %s\n" label_end)
         ^ (Printf.sprintf "%s:\n" label_else)
         ^ dif_code
         ^ (Printf.sprintf "%s:\n" label_end)
      | ScmSeq' exprs' ->
         String.concat "\n"
           (List.map (run params env) exprs')
      | ScmOr' exprs' ->
         raise (X_not_yet_implemented "final project")
      | ScmVarSet' (Var' (v, Free), expr') ->
         raise (X_not_yet_implemented "final project")
      | ScmVarSet' (Var' (v, Param minor), ScmBox' _) ->
         raise (X_not_yet_implemented "final project")
      | ScmVarSet' (Var' (v, Param minor), expr') ->
         raise (X_not_yet_implemented "final project")
      | ScmVarSet' (Var' (v, Bound (major, minor)), expr') ->
         raise (X_not_yet_implemented "final project")
      | ScmVarDef' (Var' (v, Free), expr') ->
         let label = search_free_var_table v free_vars in
         (run params env expr')
         ^ (Printf.sprintf "\tmov qword [%s], rax\n" label)
         ^ "\tmov rax, sob_void\n"
      | ScmVarDef' (Var' (v, Param minor), expr') ->
         raise (X_not_yet_implemented "Support local definitions (param)")
      | ScmVarDef' (Var' (v, Bound (major, minor)), expr') ->
         raise (X_not_yet_implemented "Support local definitions (bound)")
      | ScmBox' _ -> assert false
      | ScmBoxGet' var' ->
         (run params env (ScmVarGet' var'))
         ^ "\tmov rax, qword [rax]\n"
      | ScmBoxSet' (var', expr') ->
         raise (X_not_yet_implemented "final project")
      | ScmLambda' (params', Simple, body) ->
         let label_loop_env = make_lambda_simple_loop_env ()
         and label_loop_env_end = make_lambda_simple_loop_env_end ()
         and label_loop_params = make_lambda_simple_loop_params ()
         and label_loop_params_end = make_lambda_simple_loop_params_end ()
         and label_code = make_lambda_simple_code ()
         and label_arity_ok = make_lambda_simple_arity_ok ()
         and label_end = make_lambda_simple_end ()
         in
         "\tmov rdi, (1 + 8 + 8)\t; sob closure\n"
         ^ "\tcall malloc\n"
         ^ "\tpush rax\n"
         ^ (Printf.sprintf "\tmov rdi, 8 * %d\t; new rib\n" params)
         ^ "\tcall malloc\n"
         ^ "\tpush rax\n"
         ^ (Printf.sprintf "\tmov rdi, 8 * %d\t; extended env\n" (env + 1))
         ^ "\tcall malloc\n"
         ^ "\tmov rdi, ENV\n"
         ^ "\tmov rsi, 0\n"
         ^ "\tmov rdx, 1\n"
         ^ (Printf.sprintf "%s:\t; ext_env[i + 1] <-- env[i]\n"
              label_loop_env)
         ^ (Printf.sprintf "\tcmp rsi, %d\n" env)
         ^ (Printf.sprintf "\tje %s\n" label_loop_env_end)
         ^ "\tmov rcx, qword [rdi + 8 * rsi]\n"
         ^ "\tmov qword [rax + 8 * rdx], rcx\n"
         ^ "\tinc rsi\n"
         ^ "\tinc rdx\n"
         ^ (Printf.sprintf "\tjmp %s\n" label_loop_env)
         ^ (Printf.sprintf "%s:\n" label_loop_env_end)
         ^ "\tpop rbx\n"
         ^ "\tmov rsi, 0\n"
         ^ (Printf.sprintf "%s:\t; copy params\n" label_loop_params)
         ^ (Printf.sprintf "\tcmp rsi, %d\n" params)
         ^ (Printf.sprintf "\tje %s\n" label_loop_params_end)
         ^ "\tmov rdx, qword [rbp + 8 * rsi + 8 * 4]\n"
         ^ "\tmov qword [rbx + 8 * rsi], rdx\n"
         ^ "\tinc rsi\n"
         ^ (Printf.sprintf "\tjmp %s\n" label_loop_params)
         ^ (Printf.sprintf "%s:\n" label_loop_params_end)
         ^ "\tmov qword [rax], rbx\t; ext_env[0] <-- new_rib \n"
         ^ "\tmov rbx, rax\n"
         ^ "\tpop rax\n"
         ^ "\tmov byte [rax], T_closure\n"
         ^ "\tmov SOB_CLOSURE_ENV(rax), rbx\n"
         ^ (Printf.sprintf "\tmov SOB_CLOSURE_CODE(rax), %s\n" label_code)
         ^ (Printf.sprintf "\tjmp %s\n" label_end)
         ^ (Printf.sprintf "%s:\t; lambda-simple body\n" label_code)
         ^ (Printf.sprintf "\tcmp qword [rsp + 8 * 2], %d\n"
              (List.length params'))
         ^ (Printf.sprintf "\tje %s\n" label_arity_ok)
         ^ "\tpush qword [rsp + 8 * 2]\n"
         ^ (Printf.sprintf "\tpush %d\n" (List.length params'))
         ^ "\tjmp L_error_incorrect_arity_simple\n"
         ^ (Printf.sprintf "%s:\n" label_arity_ok)
         ^ "\tenter 0, 0\n"
         ^ (run (List.length params') (env + 1) body)
         ^ "\tleave\n"
         ^ (Printf.sprintf "\tret AND_KILL_FRAME(%d)\n" (List.length params'))
         ^ (Printf.sprintf "%s:\t; new closure is in rax\n" label_end)
      | ScmLambda' (params', Opt opt, body) ->
         let label_loop_env = make_lambda_opt_loop_env ()
         and label_loop_env_end = make_lambda_opt_loop_env_end ()
         and label_loop_params = make_lambda_opt_loop_params ()
         and label_loop_params_end = make_lambda_opt_loop_params_end ()
         and label_code = make_lambda_opt_code ()
         and label_arity_exact = make_lambda_opt_arity_exact ()
         and label_arity_more = make_lambda_opt_arity_more ()
         and label_stack_ok = make_lambda_opt_stack_ok ()
         and label_end = make_lambda_opt_end ()
         and label_loop = make_lambda_opt_loop ()
         and label_loop_exit = make_lambda_opt_loop_exit ()
         in
         raise (X_not_yet_implemented "final project")
      | ScmApplic' (proc, args, Non_Tail_Call) -> 
         let args_code =
           String.concat ""
             (List.map
                (fun arg ->
                  let arg_code = run params env arg in
                  arg_code
                  ^ "\tpush rax\n")
                (List.rev args)) in
         let proc_code = run params env proc in
         "\t; preparing a non-tail-call\n"
         ^ args_code
         ^ (Printf.sprintf "\tpush %d\t; arg count\n" (List.length args))
         ^ proc_code
         ^ "\tcmp byte [rax], T_closure\n"
         ^ "\tjne L_error_non_closure\n"
         ^ "\tpush SOB_CLOSURE_ENV(rax)\n"
         ^ "\tcall SOB_CLOSURE_CODE(rax)\n"
      | ScmApplic' (proc, args, Tail_Call) -> 
         raise (X_not_yet_implemented "final project")
    and runs params env exprs' =
      List.map (fun expr' -> run params env expr') exprs' in
    let codes = runs 0 0 exprs' in
    let code =
      String.concat "\n\tmov rdi, rax\n\tcall print_sexpr_if_not_void\n"
        codes in
    let code =
      (file_to_string "prologue-1.asm")
      ^ (asm_of_constants_table consts)
      ^ (asm_of_free_vars_table free_vars consts)
      ^ (file_to_string "prologue-2.asm")
      ^ (asm_of_global_bindings global_bindings_table free_vars)
      ^ "\n"
      ^ code
      ^ "Lend:\n"
      ^ "\tmov rdi, rax\n"
      ^ "\tcall print_sexpr_if_not_void\n"
      ^ (file_to_string "epilogue.asm") in
    code;;

  let compile_scheme_string file_out user =
    let init = file_to_string "init.scm" in
    let source_code = init ^ "\n" ^ user in
    let sexprs = (PC.star Reader.nt_sexpr source_code 0).found in
    let exprs = List.map Tag_Parser.tag_parse sexprs in
    let exprs' = List.map Semantic_Analysis.semantics exprs in
    let asm_code = code_gen exprs' in
    (string_to_file file_out asm_code;
     Printf.printf "!!! Compilation finished. Time to assemble!\n");;  

  let compile_scheme_file file_in file_out =
    compile_scheme_string file_out (file_to_string file_in);;

  let compile_and_run_scheme_string file_out_base user =
    let init = file_to_string "init.scm" in
    let source_code = init ^ "\n" ^ user in
    let sexprs = (PC.star Reader.nt_sexpr source_code 0).found in
    let exprs = List.map Tag_Parser.tag_parse sexprs in
    let exprs' = List.map Semantic_Analysis.semantics exprs in
    let asm_code = code_gen exprs' in
    ( string_to_file (Printf.sprintf "%s.asm" file_out_base) asm_code;
      match (Sys.command
               (Printf.sprintf
                  "make -f testing/makefile %s" file_out_base)) with
      | 0 -> let _ = Sys.command (Printf.sprintf "./%s" file_out_base) in ()
      | n -> (Printf.printf "!!! Failed with code %d\n" n; ()));;

end;; (* end of Code_Generation struct *)

(* end-of-input *)

let test = Code_Generation.compile_and_run_scheme_string "testing/goo";;

