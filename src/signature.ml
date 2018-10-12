open Expr;;
let symbols_table = Hashtbl.create 100;;

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

let rec generate_iota p =
    match p with
    |0          -> ""
    |x          -> "zen.term (zen.iota) -> " ^ (generate_iota (x - 1));;

let get_type b n =
    match (b, n) with
     (0, true)           -> "zen.prop"
    |(0, false)           -> "zen.term (zen.iota)"
    |(n, false)          -> (generate_iota n) ^ " zen.term (zen.iota)"
    |(n, true)           -> (generate_iota n) ^ " zen.prop";;

let print_symbols ht = 
    Hashtbl.iter (fun x n -> Printf.printf "def %s : %s.\n%!" x (get_type (fst n) (snd n))) ht;; 

(* Generating signature file *)
let generate_signature_file name ht =
    let name_dk = name ^ ".dk" in  
    let name = ((Sys.getcwd ()) ^ "/" ^ name ^ "/" ^ name_dk) in 
    let oc = open_out name in
        Printf.printf "\t ==== Generating signature file ====\n";
        Hashtbl.iter (fun x n -> Printf.fprintf oc "def %s : %s.\n" x (get_type (fst n) (snd n))) ht;
        close_out oc;
        Printf.printf "%s \027[32m OK \027[0m\n\n%!" name;;

let generate_makefile name = 
    let name_file = ((Sys.getcwd ()) ^ "/" ^ name ^ "/Makefile" ) in
    let oc = open_out  name_file in
        Printf.printf "\t ==== Generating the Makefile ==== \n";
        Printf.fprintf oc "DIR?=/usr/local/lib/\n";
        Printf.fprintf oc "TIMELIMIT?=10s\n";
        Printf.fprintf oc "TPTP=$(wildcard lemmas/*.p)\n";
        Printf.fprintf oc "DKS=$(TPTP:.p=.dk)\n";
        Printf.fprintf oc "DKO=$(DKS:.dk=.dko)\n";
        (* Printf.fprintf oc "all: proof_%s.dko $(DKS)\n" name; *)
        Printf.fprintf oc "all: %s.dko $(DKO) $(DKS)\n" name;
        Printf.fprintf oc "\n";

        Printf.fprintf oc "lemmas/%%.dk : lemmas/%%.p\n";
        Printf.fprintf oc "\tzenon_modulo -itptp -max-time $(TIMELIMIT) -odkterm -sig %s $< > $@\n" name;
        Printf.fprintf oc "\n";

        Printf.fprintf oc "lemmas/%%.dko : lemmas/%%.dk %s.dko\n" name;
        Printf.fprintf oc "\tdkcheck -nl -I $(DIR) $< -e\n";
        Printf.fprintf oc "\n";

        Printf.fprintf oc "%s.dko: %s.dk\n" name name;
        Printf.fprintf oc "\tdkcheck -nl -I $(DIR) $< -e\n";
        Printf.fprintf oc "\n";

        (* Printf.fprintf oc "proof_%s.dko : proof_%s.dk %s.dko $(DKO)\n" name name name;
        Printf.fprintf oc "\tdkcheck -nl -I $(DIR) -I lemmas $< -e\n";
        Printf.fprintf oc "\n"; *)

        Printf.printf "%s\t \027[32m OK \027[0m\n\n%!" name_file;
        close_out oc;;