open Expr
open Printf

(* insert a require command for each step in the global proof *)
let rec print_requires oc proof_tree m_name =
  List.iter
    (fun (name, e) ->
      fprintf oc "require %s.lemmas.%s as %s;\n" m_name name name)
    proof_tree
let forbidden_idents = ["abort";"admit";"admitted";"apply";"as";"assert";"assertnot";
                        "associative";"assume";"begin";"builtin";"commutative";"compute";
                        "constant";"debug";"end";"fail";"flag";"focus";"have";"generalize";
                        "in";"induction";"inductive";"infix";"injective";"left";"let";
                        "notation";"off";"on";"opaque";"open";"prefix";"print";"private";
                        "proofterm";"protected";"prover";"prover_timeout";"quantifier";
                        "refine";"reflexivity";"require";"rewrite";"right";"rule";"sequential";
                        "simplify";"solve";"symbol";"symmetry";"type";"TYPE";"unif_rule";
                        "verbose";"why3";"with"; "_"]
let escape_name s =
  let id_regex = Str.regexp "^[a-zA-Z_][a-zA-Z0-9_]*$" in
  if Str.string_match id_regex s 0 
    && List.for_all ((<>) s) forbidden_idents 
    then s else "{|" ^ s ^ "|}"

(* add {|VAR|} pattern for each variable to avoid unicode characters
   and check if it belongs to signature or not *)
let print_var v signame =
  let escaped_v = escape_name v in
  escaped_v
  (* if signame = "" then escaped_v else signame ^ "." ^ escaped_v *)

(* print the formula (type) in lambdapi format *)
let rec print_dk_type oc (ex, signame) =
    let out s = fprintf oc s in
    match ex with
    | Efalse -> out "⊥"
    | Etrue -> out "⊤"
    | Evar (x, _) -> out "%s" x
    | Eapp (Evar (e, _), [], _) -> out "%s" (print_var e signame)
    | Eapp (Evar("=",_),e1::e2::[],_)->
      out "%a = %a" print_dk_type (e1, signame) print_dk_type (e2, signame)
    | Eapp (Evar (e, _), l, _) ->
      out "(%s %a)" (print_var e signame) print_dk_type_vars (l, signame)
    | Eor (e1, e2, _) ->
      out "(%a) ∨ (%a)" print_dk_type (e1, signame)
        print_dk_type (e2, signame)
    | Eand (e1, e2, _) ->
      out "(%a) ∧ (%a)" print_dk_type (e1, signame)
        print_dk_type (e2, signame)
    | Eall (v, e, _) ->
      out "∀ (λ %a, %a)"
        print_dk_type (v, "") print_dk_type (e, signame)
    | Eex (v, e, _) ->
      out "∃ (λ %a, (%a))" print_dk_type (v, "")
        print_dk_type (e, signame)
    | Enot (e, _) ->
      out "¬ (%a)" print_dk_type (e, signame)
    | Eimply(a, b, _) ->
      out "(%a) ⇒ (%a)" print_dk_type (a, signame)
        print_dk_type (b, signame)
    | Eequiv(a, b, _) ->
      out "(%a) ⇔ (%a)" print_dk_type (a, signame)
        print_dk_type (b, signame)
    | _ -> out "[%a]" print_dk_type (ex, signame); failwith "Formula not accepted"
(* print an application term of the form [f t1 ... tn] *)
and print_dk_type_vars oc (l, signame) =
    match l with
    | [] -> ()
    | x::l' ->
       fprintf oc "%a %a" print_dk_type (x, signame)
         print_dk_type_vars (l', signame)

(* print all axioms used in the global proof (as a parameters) *)
let rec print_axioms oc (axioms, signame) =
    match axioms with
    | [] -> ()
    | x::l' ->
        fprintf oc "symbol %s_ax : ϵ (%a);\n%a" x
         print_dk_type ((Hashtbl.find Phrase.name_formula_tbl x), signame)
         print_axioms (l', signame)

(* check if a formula is an axiom or an inference *)
let is_axiom ax proof_tree =
    if List.exists (fun e -> fst e = ax) proof_tree then false else true

(* get the term that represents the proof of a step or an axiom
let rec make_one_proof oc (goal, proof_tree) =
    if is_axiom goal proof_tree then fprintf oc "ax_%s" goal else
    (fprintf oc "%s.delta \n" goal;
    make_proofs oc ((get_axioms goal proof_tree), proof_tree))

and make_proofs oc (axioms, proof_tree) =
        match axioms with
        | [] -> ()
        | ax::l' ->
          fprintf oc "(%a)\n%a" make_one_proof (ax, proof_tree)
            make_proofs (l', proof_tree)

and get_axioms goal proof_tree =
    match proof_tree with
    | [] -> []
    |(g, la)::l'-> if g = goal then la else get_axioms goal l'*)

(* print one arg inside the proof (axiom or a lemma) *)
let print_arg oc (s, proof_tree) =
  if is_axiom s proof_tree then fprintf oc "%s_ax" s
  else fprintf oc "lemmas_%s" s

(* print all args inside the proof *)
let rec print_args oc (args, proof_tree) =
    match args with
    | [] -> ()
    | x::l' ->
       fprintf oc "%a %a" print_arg (x, proof_tree)
         print_args (l', proof_tree)

let rec get_lemmas proof_tree = 
  match proof_tree with
  |[] -> []
  |(x, _)::l' -> x::(get_lemmas l')


let rec order_lemmas_aux proof_tree accu goal =
  if List.mem_assoc goal accu then accu
  else
    try
      let ps = List.assoc goal proof_tree in
      (goal,ps)::List.fold_left (order_lemmas_aux proof_tree)
                   accu ps
    with Not_found -> accu

let order_lemmas proof_tree goal =
  List.rev @@ order_lemmas_aux proof_tree [] goal

(* print how lemmas were constructed as the TSTP file shows *)
let rec print_lemmas oc (proof_tree, fixed_tree) =
    match proof_tree with
    | [] -> ()
    | [g, la] ->
       fprintf oc
         "opaque symbol lemmas_%s ≔ %s.delta %a;\n"
         g g print_args (la, fixed_tree) 
    | (g, la)::l'->
       fprintf oc
         "opaque symbol lemmas_%s ≔ %s.delta %a;\n%a"
         g g print_args (la, fixed_tree) print_lemmas (l', fixed_tree)

(* generate a global proof file that contains all the requirements and
   the proof term *)
let rec generate_dk name l signame proof_tree goal =
    let name_file = ( (Sys.getcwd ())^ "/" ^ name ^ "/proof_" ^ name ^ ".lp") in
    let oc = open_out name_file in
        printf "\t ==== Generating the proof file ====\n%!";
        fprintf oc "require open logic.fol logic.ll logic.nd logic.nd_eps logic.nd_eps_full logic.nd_eps_aux logic.ll_nd;\n";
        fprintf oc "require open %s.%s;\n" name name;
        print_requires oc proof_tree name;
        fprintf oc "\n";
        fprintf oc "require open logic.zen;\n\n";
        fprintf oc "%a" print_axioms (l, signame);
        print_lemmas oc (proof_tree, proof_tree);
        fprintf oc "symbol proof_%s : ϵ ⊥ ≔ lemmas_%s;" name goal;
        (*generate_dk_list oc l signame;*)
        (* fprintf oc "%a" generate_abs l; *)
        (* fprintf oc "%a." make_one_proof (goal, proof_tree); *)
        close_out oc;
        printf "%s \027[32m OK \027[0m\n\n%!" name_file

(* generate package file *)
let generate_pkg name =
    let name_file = ( (Sys.getcwd ())^ "/" ^ name ^ "/lambdapi.pkg") in
    let oc = open_out name_file in
        printf "\t ==== Generating the package file ====\n%!";
        fprintf oc "package_name = %s\n" name;
        fprintf oc "root_path = %s\n" name;
        close_out oc;
        printf "%s \027[32m OK \027[0m\n\n%!" name_file

(* print builtins *)
let print_builtins oc name = 
  fprintf oc "set builtin \"A\" ≔ axiom_A\n";
  fprintf oc "set builtin \"B\" ≔ proof_%s\n" name;
  fprintf oc "set builtin \"iota\" ≔ iota_b\n";
  fprintf oc "set builtin \"proof\" ≔ ϵ\n";
  fprintf oc "set builtin  \"forall\" ≔ ∀\n";
  fprintf oc "set builtin \"imp\" ≔ imp\n"
(* and generate_dk_list oc l signame =
    match l with
    | [] -> ()
    | [x] ->
      fprintf oc "zen.proof (%a) \n\n->\n\nzen.seq"
      print_dk_type ((Hashtbl.find Phrase.name_formula_tbl x), signame)
    | x::l' ->
      fprintf oc "zen.proof (%a) \n\n->\n\n"
      print_dk_type ((Hashtbl.find Phrase.name_formula_tbl x), signame);
      generate_dk_list oc l' signame *)
