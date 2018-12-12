open Expr;;

let rec print_requires oc proof_tree = 
    List.iter (fun (name, e) -> Printf.fprintf oc "require lemmas.%s as %s\n" name name) proof_tree;;

let print_var v signame = let v = "{|" ^ v ^ "|}" in if signame = "" then v else signame ^ "." ^ v;;
let rec print_dk_type oc (ex, signame) =
    let out s = Printf.fprintf oc s in 
    match ex with
     Efalse                         -> out "zen.False"
    |Etrue                          -> out "zen.True"
    |Evar (x, _)                    -> out "%s" x
    |Eapp (Evar (e, _), [], _)      -> out "%s" (print_var e signame)
    |Eapp (Evar("=",_),e1::e2::[],_)-> out "zen.equal (zen.iota) %a" print_dk_type_vars ([e1; e2], signame)
    |Eapp (Evar (e, _), l, _)       -> out "(%s %a)" (print_var e signame) print_dk_type_vars (l, signame)
    |Eor (e1, e2, _)                -> out "zen.or (%a) (%a)" print_dk_type (e1, signame) print_dk_type (e2, signame)
    |Eall (v, e, _)                 -> out "zen.forall (zen.iota) (λ (%a : (zen.term zen.iota)), %a)" print_dk_type (v, "") print_dk_type (e, signame) 
    |Eex (v, e, _)                  -> out "zen.exists (%a) (%a)" print_dk_type (v, "") print_dk_type (e, signame) 
    |Enot (e, _)                    -> out "zen.not (%a)" print_dk_type (e, signame)
    |Eimply(a, b, _)                -> out "zen.imp (%a) (%a)" print_dk_type (a, signame) print_dk_type (b, signame)
    |Eequiv(a, b, _)                -> out "zen.eqv (%a) (%a)" print_dk_type (a, signame) print_dk_type (b, signame)
    |_                              -> failwith "Formula not accepted"

    and print_dk_type_vars oc (l, signame) =
        match l with
         []             -> ()
        |x::l'          -> Printf.fprintf oc "%a %a" print_dk_type (x, signame) print_dk_type_vars (l', signame)
;;

let rec print_axioms oc (axioms, signame) = 
    match axioms with
    |[]                 -> ()
    |x::l'              -> Printf.fprintf oc "(ax_%s : zen.Proof (%a))\n %a" x print_dk_type ((Hashtbl.find Phrase.name_formula_tbl x), signame) print_axioms (l', signame);; 

let is_axiom ax proof_tree =
    if List.exists (fun e -> fst e = ax) proof_tree then false else true;;
let rec make_one_proof oc (goal, proof_tree) = 
    if is_axiom goal proof_tree then Printf.fprintf oc "ax_%s" goal else
    (Printf.fprintf oc "%s.delta \n" goal; make_proofs oc ((get_axioms goal proof_tree), proof_tree))
and
    make_proofs oc (axioms, proof_tree) =
        match axioms with
         []                 -> ()
        |ax::l'             -> Printf.fprintf oc "(%a)\n%a" make_one_proof (ax, proof_tree) make_proofs (l', proof_tree)
and get_axioms goal proof_tree = 
    match proof_tree with
     []         -> []
    |(g, la)::l'-> if g = goal then la else get_axioms goal l'
;;
let print_arg oc (s, proof_tree) = if is_axiom s proof_tree 
                                   then Printf.fprintf oc "ax_%s" s 
                                   else Printf.fprintf oc "lemmas_%s" s;;  
let rec print_args oc (args, proof_tree) =
    match args with
    |[]                 -> ()
    |x::l'              -> Printf.fprintf oc "%a %a" print_arg (x, proof_tree) print_args (l', proof_tree);;
let rec print_lemmas oc (proof_tree, fixed_tree) =
    match proof_tree with
    |[]         -> ()
    |(g, la)::[]-> Printf.fprintf oc "let lemmas_%s = %s.delta %a in\nlemmas_%s" g g print_args (la, fixed_tree) g
    |(g, la)::l'-> Printf.fprintf oc "let lemmas_%s = %s.delta %a in\n%a" g g print_args (la, fixed_tree) print_lemmas (l', fixed_tree);;
let rec generate_dk name l signame proof_tree goal = 
    let name_file = ( (Sys.getcwd ())^ "/" ^ name ^ "/proof_" ^ name ^ ".lp") in 
    let oc = open_out name_file in
        Printf.printf "\t ==== Generating the proof file ====\n%!";
        Printf.fprintf oc "require %s\n" name;
        print_requires oc proof_tree;
        Printf.fprintf oc "\n";
        Printf.fprintf oc "require logic.zen as zen\n\n";
        Printf.fprintf oc "definition proof_%s \n %a : zen.seq \n" name print_axioms (l, signame);
        (*generate_dk_list oc l signame;*)
        Printf.fprintf oc "\n ≔ \n";
        (* Printf.fprintf oc "%a" generate_abs l; *)
        Printf.fprintf oc "\n";
        print_lemmas oc (proof_tree, proof_tree);
        (* Printf.fprintf oc "%a." make_one_proof (goal, proof_tree); *)
        
        close_out oc;
        Printf.printf "%s \027[32m OK \027[0m\n\n%!" name_file
and
generate_dk_list oc l signame =
    match l with
     []                 -> ()
    |x::[]              -> Printf.fprintf oc "zen.proof (%a) \n\n->\n\nzen.seq" print_dk_type ((Hashtbl.find Phrase.name_formula_tbl x), signame)
    |x::l'              -> Printf.fprintf oc "zen.proof (%a) \n\n->\n\n" print_dk_type ((Hashtbl.find Phrase.name_formula_tbl x), signame); generate_dk_list oc l' signame
;; 
