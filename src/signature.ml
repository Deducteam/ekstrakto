open Expr;;
let symbols_table = Hashtbl.create 100;;

(* get all the symbols used in the TSTP file *)
let rec get_symbols b e =  
  match e with
  |Eapp (Evar("=", _), l, _)  -> List.iter (get_symbols false) l
  |Eapp (Evar(x, _), l, _)  -> Hashtbl.replace symbols_table x (List.length l, b); List.iter (get_symbols false) l
  |Eor (e1, e2, _)          -> get_symbols true e1; get_symbols true e2
  |Eall (_, e', _)          -> get_symbols true e' 
  |Eex (_, e', _)           -> get_symbols true e'  
  |Enot (e', _)             -> get_symbols true e'
  |Eimply(a, b, _)          -> get_symbols true a; get_symbols true b
  |Eequiv(a, b, _)          -> get_symbols true a; get_symbols true b
  |_ -> ()
  ;;

(* print the type of a term correspanding to its arity *)
let rec generate_iota oc p =
    match p with
    |0          -> () 
    |x          -> Printf.fprintf oc "zen.term (zen.iota) ⇒ %a" generate_iota (x - 1);;

(* print the type of a term or a proposition in lambdapi *)
let get_type oc (b, n) = 
    match (b, n) with 
     (0, true)           -> Printf.fprintf oc "zen.prop"
    |(0, false)          -> Printf.fprintf oc "zen.term (zen.iota)"
    |(n, false)          -> Printf.fprintf oc "%a zen.term (zen.iota)" generate_iota n
    |(n, true)           -> Printf.fprintf oc "%a zen.prop" generate_iota n;;

(* let print_symbols ht = 
    Hashtbl.iter (fun x n -> Printf.printf "def %s : %s.\n%!" x (get_type (fst n) (snd n))) ht;; *)

(* Generating signature file *)
let generate_signature_file name ht =
    let name_dk = name ^ ".lp" in  
    let name = ((Sys.getcwd ()) ^ "/" ^ name ^ "/" ^ name_dk) in 
    let oc = open_out name in
        Printf.printf "\t ==== Generating signature file ====\n";
        Printf.fprintf oc "require logic.zen as zen\n";
        Hashtbl.iter (fun x n -> Printf.fprintf oc "symbol {|%s|} : %a\n" x get_type (fst n, snd n)) ht;
        close_out oc;
        Printf.printf "%s \027[32m OK \027[0m\n\n%!" name;;

(* generate a makefile to automate the proof generating and proof checking of all files *)
let generate_makefile name = 
    let name_file = ((Sys.getcwd ()) ^ "/" ^ name ^ "/Makefile" ) in
    let oc = open_out  name_file in
        Printf.printf "\t ==== Generating the Makefile ==== \n";
        Printf.fprintf oc "DIR?=/usr/local/lib/\n";
        Printf.fprintf oc "TIMELIMIT?=10s\n";
        Printf.fprintf oc "TPTP=$(wildcard lemmas/*.p)\n";
        Printf.fprintf oc "DKS=$(TPTP:.p=.lp)\n";
        Printf.fprintf oc "DKO=$(DKS:.lp=.lpo)\n";
        (* Printf.fprintf oc "all: proof_%s.dko $(DKS)\n" name; *)
        Printf.fprintf oc "all: %s.lpo $(DKO) $(DKS)\n" name;
        Printf.fprintf oc "lemmas_lpo: %s.lpo $(DKO) $(DKS)\n" name;
        Printf.fprintf oc "proof: proof_%s.lpo \n" name;
        Printf.fprintf oc "\n";

        Printf.fprintf oc "lemmas/%%.lp : lemmas/%%.p\n";
        Printf.fprintf oc "\tzenon_modulo -itptp -max-time $(TIMELIMIT) -odkterm -sig %s $< > $@\n" name;
        Printf.fprintf oc "\n";

        Printf.fprintf oc "lemmas/%%.lpo : lemmas/%%.lp %s.lpo\n" name;
        Printf.fprintf oc "\tlambdapi --gen-obj $< \n";
        Printf.fprintf oc "\n";

        Printf.fprintf oc "%s.lpo: %s.lp\n" name name;
        Printf.fprintf oc "\tlambdapi --gen-obj $< \n";
        Printf.fprintf oc "\n";

        Printf.fprintf oc "proof_%s.lpo : proof_%s.lp %s.lpo $(DKO)\n" name name name;
        Printf.fprintf oc "\tlambdapi --gen-obj $< \n";
        Printf.fprintf oc "\n"; 

        Printf.printf "%s\t \027[32m OK \027[0m\n\n%!" name_file;
        close_out oc;;