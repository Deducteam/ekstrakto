open Expr
open Printf

let symbols_table = Hashtbl.create 100

(* get all the symbols used in the TSTP file *)
let rec get_symbols b e =
  match e with
  | Eapp (Evar("=", _), l, _) -> List.iter (get_symbols false) l
  | Eapp (Evar(x, _), l, _) ->
     Hashtbl.replace symbols_table x (List.length l, b);
     List.iter (get_symbols false) l
  | Eor (e1, e2, _) -> get_symbols true e1; get_symbols true e2
  | Eand (e1, e2, _) -> get_symbols true e1; get_symbols true e2
  | Eall (_, e', _) -> get_symbols true e'
  | Eex (_, e', _) -> get_symbols true e'
  | Enot (e', _) -> get_symbols true e'
  | Eimply(a, b, _) -> get_symbols true a; get_symbols true b
  | Eequiv(a, b, _) -> get_symbols true a; get_symbols true b
  | _ -> ()

(* print the type of a term correspanding to its arity *)
let rec generate_iota oc p =
    match p with
    | 0 -> ()
    | x -> fprintf oc "κ → %a" generate_iota (x - 1)

(* print the type of a term or a proposition in lambdapi *)
let get_type oc (b, n) =
    match (b, n) with
    | (0, true) -> fprintf oc "Prop"
    | (0, false) -> fprintf oc "κ"
    | (n, false) -> fprintf oc "%a κ" generate_iota n
    | (n, true) -> fprintf oc "%a Prop" generate_iota n

(* let print_symbols ht =
    Hashtbl.iter
      (fun x n -> printf "def %s : %s.\n%!" x (get_type (fst n) (snd n))) ht *)

(* Generating signature file *)
let generate_signature_file name ht avatar_definitions =
  let name_dk = name ^ ".lp" in
  let name = Sys.getcwd() ^ "/" ^ name ^ "/" ^ name_dk in
  let oc = open_out name in
  fprintf oc "require open logic.fol logic.ll logic.nd logic.nd_eps logic.nd_eps_full logic.nd_eps_aux logic.ll_nd;\n";
  fprintf oc "require open logic.zen;\n";
  Hashtbl.iter
    (fun x n -> fprintf oc "constant symbol %s : %a;\n" (Proof.escape_name x) get_type n) ht;
  List.iter
    (fun (n, f) -> fprintf oc "symbol %s : Prop ≔ %a;\n" (Proof.escape_name (n ^ "_av_ax")) Proof.print_dk_type (f, "default_signame")) avatar_definitions;
  close_out oc;
  printf "Generating signature file for [%s] \027[32m OK \027[0m\n%!" name

(* generate a makefile to automate the proof generating and proof
   checking of all files *)
let generate_makefile name =
  let fname = Sys.getcwd() ^ "/" ^ name ^ "/Makefile" in
  let oc = open_out fname in
  fprintf oc "DIR?=/usr/local/lib/\n";
  fprintf oc "TIMELIMIT?=10s\n";
  fprintf oc "TPTP=$(wildcard lemmas/*.p)\n";
  fprintf oc "DKS=$(TPTP:.p=.lp)\n";
  fprintf oc "DKO=$(DKS:.lp=.lpo)\n";
  fprintf oc "all: %s.lpo $(DKO) $(DKS)\n" name;
  fprintf oc "lemmas_lpo: %s.lpo $(DKO) $(DKS)\n" name;
  fprintf oc "proof: proof_%s.lpo \n" name;
  fprintf oc "\n";
  fprintf oc "lemmas/%%.lp : lemmas/%%.p\n";
  fprintf oc
    "\tzenon_modulo -itptp -max-time $(TIMELIMIT) -odkterm -sig %s $< > $@\n"
    name;
  fprintf oc "\n";
  fprintf oc "lemmas/%%.lpo : lemmas/%%.lp %s.lpo\n" name;
  fprintf oc "\tlambdapi check $< \n";
  fprintf oc "\n";
  fprintf oc "%s.lpo: %s.lp\n" name name;
  fprintf oc "\tlambdapi check $< \n";
  fprintf oc "\n";
  fprintf oc "proof_%s.lpo : proof_%s.lp %s.lpo $(DKO)\n" name name name;
  fprintf oc "\tlambdapi check $< \n";
  fprintf oc "\n";
  printf "Generating Makefile for [%s]\t \027[32m OK \027[0m\n%!" fname;
  close_out oc
