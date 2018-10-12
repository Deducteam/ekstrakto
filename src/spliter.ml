open Printf;;
open Namespace;;
open Expr;;
open Phrase;;


let report_error lexbuf msg =
  let p = Lexing.lexeme_start_p lexbuf in
  Lextstp.Error.errpos p msg;
  exit 3;
;;

let make_lexbuf stdin_opt f =
  let (name, chan, close) =
    match f with
    | "-" when stdin_opt -> ("", stdin, ignore)
    | _ -> (f, open_in f, close_in)
  in
  let lexbuf = Lexing.from_channel chan in
  lexbuf.Lexing.lex_curr_p <- {
     Lexing.pos_fname = name;
     Lexing.pos_lnum = 1;
     Lexing.pos_bol = 0;
     Lexing.pos_cnum = 0;
  };
  (lexbuf, fun () -> close chan)
;;

let parse_file f =
  try
    let (lexbuf, closer) = make_lexbuf true f in
    try
      let tpphrases = Parsetstp.file Lextstp.token lexbuf in
      closer ();
      tpphrases
    with
    | Parsing.Parse_error -> report_error lexbuf "syntax error."
    | Lextstp.Error.Lex_error msg -> report_error lexbuf msg
  with Sys_error (msg) -> Lextstp.Error.err msg; exit 4
;;

(* let x = Hashtbl.find name_formula_tbl "c_0_0";; *)

(* get only lines that contains inferences *)
let rec get_inferences tstp_lines =
  match tstp_lines with
   [] -> []
  |Formula_annot(_, _, _, Some (Inference(_, _, _)|Name _|List _)) as f::l' -> f::(get_inferences l')
  |_::l' -> get_inferences l';;

(* get the premises of an inference rule *)
let rec get_premises annotation =
  match annotation with
   Name name -> [name]
  |Inference(_, _, l) -> get_premises_list l
  |List l -> get_premises_list l
  |_ -> []
  and get_premises_list annotation_list =
    match annotation_list with
    |[] -> []
    |a::l' -> (get_premises a) @ (get_premises_list l')
    ;;

(* get sequent [premises] |- name *)
let rec get_sequent tstp_lines =
  match tstp_lines with
  |[] -> []
  |Formula_annot (name, _, _, Some inf)::l' -> (name, get_premises inf) :: (get_sequent l')
  |_::l' -> get_sequent l';;

let rec print_hypothesis oc (name, l) =
  
  match l with
  |[] -> Printf.fprintf oc "%a" Expr.print_expr (Hashtbl.find name_formula_tbl name)
  |x::l' -> Printf.fprintf oc "(%a) => (%a)"  Expr.print_expr (Hashtbl.find name_formula_tbl x) print_hypothesis (name, l');;

(* print the goal to prove in TPTP format *)
let print_goal oc (name, l) = Printf.fprintf oc "fof(%s, conjecture, (%a))." name print_hypothesis (name, l);;

(* generate single TPTP file *)
let generate_tptp (name, lines) =
  Printf.printf "Process problem %s%!" name;
  let goal_name = (Filename.remove_extension (Filename.basename name)) in
  let oc = open_out name in  
    Printf.fprintf oc "%a\n" print_goal (goal_name, lines);     
    close_out oc;
  Printf.printf "\t \027[32m OK \027[0m\n%!";;           

let rec generate_files tstp_fname premises = 
  match premises with
  |[] -> ()
  |(name, l)::l' -> 
    generate_tptp (((Sys.getcwd ())^ "/" ^ tstp_fname ^ "/lemmas/" ^ name ^ ".p"), l);
    generate_files tstp_fname l';;
let insert_symbols ht = 
  Hashtbl.iter (fun x y -> Signature.get_symbols true y) ht;;

(* get only the name of each inference (intermediate lemma) *)
let get_lemmas l = List.map (fun e -> fst e) l;; 

let rec last_goal l = match l with
   []       -> failwith "Goal to prove is not provided"
  |(g, axs)::[] -> g
  |_::l'    -> last_goal l';;

let rec get_axioms inferences lemmas =
  match inferences with
   [] -> []
  |(name, prems)::l' -> (check_axiom prems lemmas) @ (get_axioms l' lemmas)
  and
  check_axiom l lemmas = 
    match l with
    |[] -> []
    |x::l' -> if List.exists (fun e -> x = e) lemmas then 
                  check_axiom l' lemmas
              else
                  x::(check_axiom l' lemmas);;


let _ =
  match Sys.argv with
  | [|_ ; fname|] ->
      
      let res : Phrase.tpphrase list = parse_file fname in
      let inferences = get_inferences res in
      let premises = get_sequent inferences in
      (* let axioms = get_axioms premises (get_lemmas premises) in *)
      (* let l_goal = last_goal premises in *)
      (* let () = List.iter (fun m -> Printf.printf "%s" m) (get_axioms premises (get_lemmas premises)) in *)
      let name = (Filename.remove_extension (Filename.basename fname)) in 
      if Sys.command ("mkdir -p " ^ (Sys.getcwd ()) ^ "/" ^ name ^ "/lemmas") = 0 
      then () 
      else Printf.printf "Error while creating %s/lemmas folder " name;
      Printf.printf "\t ==== Generating %i TPTP Problems from %s ==== \n%!" (List.length premises) fname;
      generate_files name premises;
      Printf.printf "\n%!";
     (* Printing all formulas in name_formula_tbl *)
     (* Hashtbl.iter (fun x y -> Printf.printf "%s : %s\n%!" x (Expr.expr_to_string y)) Phrase.name_formula_tbl *)
      insert_symbols Phrase.name_formula_tbl;
      Signature.generate_signature_file name Signature.symbols_table;
      (*Printf.printf "Debug 1\n%!";
      Proof.generate_dk name axioms name premises l_goal;*)
      Signature.generate_makefile name;
  | _             ->
      Printf.eprintf "Usage: %s file.p\n%!" Sys.argv.(0);
      exit 1
