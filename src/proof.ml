open Expr;;
let print_var v signame = if signame = "" then v else signame ^ "." ^ v;;
let rec print_dk_type ex signame = 
    match ex with
     Efalse             -> "zen.False"
    |Etrue              -> "zen.True"
    |Evar (x, _)        -> x
    |Eapp (Evar (e, _), [], _)    -> print_var e signame
    |Eapp (Evar (e, _), l, _)     -> (print_var e signame) ^ " " ^ (print_dk_type_vars l signame)
    |Eapp (Evar ("=", _), e1::e2::[], _)     -> "zen.equal (zen.iota) " ^ (print_dk_type_vars l signame)
    |Eor (e1, e2, _)    ->  "zen.or \n(" ^ (print_dk_type e1 signame) ^ ")\n(" ^ (print_dk_type e2 signame) ^ ")"
    |Eall (v, e, _)     -> "zen.forall (zen.iota)\n( " ^ (print_dk_type v "") ^ " => " ^ (print_dk_type e signame) ^ ")" 
    |Eex (v, e, _)      -> "zen.exists (" ^ (print_dk_type v "") ^ ")\n(" ^ (print_dk_type e signame) ^ ")" 
    |Enot (e, _) -> "zen.not (" ^ (print_dk_type e signame) ^ ")"
    |Eimply(a, b, _) -> "zen.imp \n(" ^ (print_dk_type a signame) ^ ")\n(" ^ (print_dk_type b signame) ^ ")"
    |Eequiv(a, b, _) -> "zen.eqv \n(" ^ (print_dk_type a signame) ^ ")\n(" ^ (print_dk_type b signame) ^ ")"
    |_ -> failwith "Formula not accepted"

    and print_dk_type_vars l signame = 
        match l with
         []             -> ""
        |x::l'          -> (print_dk_type x signame) ^ " " ^ (print_dk_type_vars l' signame)
;;




let rec generate_abs oc axioms = 
    match axioms with
     []             -> ()
    |ax::l'         -> Printf.fprintf oc "ax_%s => %a" ax generate_abs l'
;;
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

let rec generate_dk name l signame proof_tree goal = 
    let name_file = ( (Sys.getcwd ())^ "/" ^ name ^ "/proof_" ^ name ^ ".dk") in 
    let oc = open_out name_file in
        Printf.printf "\t ==== Generating the proof file ====\n%!";
        Printf.fprintf oc "def proof_%s : \n(" name;
        generate_dk_list oc l signame;
        Printf.fprintf oc ")\n\n:=\n";
        Printf.fprintf oc "%a" generate_abs l;
        Printf.fprintf oc "\n";
        Printf.fprintf oc "%a." make_one_proof (goal, proof_tree);
        close_out oc;
        Printf.printf "%s \027[32m OK \027[0m\n\n%!" name_file
and
generate_dk_list oc l signame =
    match l with
     []                 -> ()
    |x::[]              -> Printf.fprintf oc "zen.proof (%s) \n\n->\n\nzen.seq" (print_dk_type (Hashtbl.find Phrase.name_formula_tbl x) signame)
    |x::l'              -> Printf.fprintf oc "zen.proof (%s) \n\n->\n\n" (print_dk_type (Hashtbl.find Phrase.name_formula_tbl x) signame); generate_dk_list oc l' signame
;; 