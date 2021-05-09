open Printf
open Namespace
open Expr
open Phrase

let roles = ref []
(* Print error message [msg] for current position of [lexbuf] and exit. *)
let report_error lexbuf msg =
  let p = Lexing.lexeme_start_p lexbuf in
  Lextstp.Error.errpos p msg;
  exit 3

(* Create a lexing buffer from a filename [fname]. If [stdin_opt] if
   true and the file name is "-" then read from stdin. *)
let make_lexbuf stdin_opt fname =
  let (name, chan, close) =
    match fname with
    | "-" when stdin_opt -> ("", stdin, ignore)
    | _ -> (fname, open_in fname, close_in)
  in
  let open Lexing in
  let lexbuf = from_channel chan in
  lexbuf.lex_curr_p <-
    { pos_fname = name; pos_lnum = 1; pos_bol = 0; pos_cnum = 0 };
  (lexbuf, fun () -> close chan)

(* Parse the TSTP file named [fname] and return its contents. *)
let parse_file fname =
  let (lexbuf, closer) = make_lexbuf true fname in
  try
    let tpphrases = Parsetstp.file Lextstp.token lexbuf in
    closer ();
    tpphrases
  with
  | Parsing.Parse_error -> report_error lexbuf "syntax error."
  | Lextstp.Error.Lex_error msg -> report_error lexbuf msg
  | Sys_error msg -> (Lextstp.Error.err msg; exit 4)

(* get only lines that contains inferences *)
let rec get_inferences tstp_lines =
  match tstp_lines with
  | [] -> []
  | Formula_annot(name, role, _, Some (Inference(_, _, _)|Name _|List _)) as f::l'
    -> roles := (name, role)::!roles; f :: get_inferences l'
  | _::l' -> get_inferences l'

(* get the premises of an inference rule *)
let rec get_premises annotation =
  match annotation with
  | Name name -> [name]
  | Inference(_, _, l) -> get_premises_list l
  | List l -> get_premises_list l
  | _ -> []

and get_premises_list annotation_list =
  match annotation_list with
  | [] -> []
  | a::l' -> get_premises a @ get_premises_list l'

(* get sequent [premises] |- name *)
let rec get_sequent tstp_lines =
  match tstp_lines with
  | [] -> []
  | Formula_annot (name, _, _, Some inf) :: l' ->
     (name, get_premises inf) :: get_sequent l'
  | _ :: l' -> get_sequent l'

let rec print_hypothesis oc (name, l) =
  match l with
  | [] ->
    let role = snd (List.find (fun (x, _) -> x = name) !roles)  in
    if role = "negated_conjecture" then
      fprintf oc "(%a)" Expr.print_expr (Hashtbl.find name_formula_tbl name)
    else  
      fprintf oc "(%a)" Expr.print_expr (Hashtbl.find name_formula_tbl name)
    
  | x::l' ->
     fprintf oc "(%a) => (%a)"  Expr.print_expr
       (Hashtbl.find name_formula_tbl x) print_hypothesis (name, l')

(* print the goal to prove in TPTP format *)
let print_goal oc (name, l) =
  (* let role = snd (List.find (fun (x, _) -> x = name) !roles)  in
  if role = "negated_conjecture" then *)
    fprintf oc "fof(%s, conjecture, (%a))." name print_hypothesis (name, l)
  (*  else
    fprintf oc "fof(%s, conjecture, (%a))." name print_hypothesis (name, l) *)

(* generate single TPTP file *)
let generate_tptp name lines =
  (* printf "Process problem %s%!" name; *)
  let goal_name = Filename.remove_extension (Filename.basename name) in
  let oc = open_out name in
  fprintf oc "%a\n" print_goal (goal_name, lines);
  close_out oc
  (* printf "\t \027[32m OK \027[0m\n%!" *)

(* generate a file for each step of the proof *)
let rec generate_files tstp_fname premises =
  match premises with
  | [] -> ()
  | (name, l)::l' ->
     let fname = Sys.getcwd() ^ "/" ^ tstp_fname ^ "/lemmas/" ^ name ^ ".p" in
     generate_tptp fname l;
     generate_files tstp_fname l'

let insert_symbols ht =
  Hashtbl.iter (fun x y -> Signature.get_symbols true y) ht

(* get only the name of each inference (intermediate lemma) *)
let get_lemmas l = List.map fst l

(* get the goal of a TSTP trace (last line in the file) *)
let rec last_goal l =
  match l with
  | [] -> failwith "Goal to prove is not provided"
  | (g, _)::l' -> if Hashtbl.find name_formula_tbl g = Expr.efalse then g else last_goal l'

(* get all axioms used in each step of the proof *)
let rec get_axioms inferences lemmas =
  match inferences with
  | [] -> []
  | (name, prems)::l' -> check_axiom prems lemmas @ get_axioms l' lemmas

and check_axiom l lemmas =
  match l with
  | [] -> []
  | x::l' ->
     if List.exists ((=) x) lemmas then check_axiom l' lemmas
     else x :: check_axiom l' lemmas
let rec uniq l liste =
  match l with
  |[]     -> []
  |x::l'  -> if List.exists ((=) x) liste then uniq l' liste else x::(uniq l' (x::liste))

let rec construct_premises l lemmas =
  match l with
  |[] -> []
  |x::l' -> (List.find (fun (x1, _) -> x1 = x) lemmas)::(construct_premises l' lemmas)

(* starting point of the program *)
let _ =
  match Sys.argv with
  | [|_ ; fname|] ->
     let res : Phrase.tpphrase list = parse_file fname in
     let inferences = get_inferences res in
     let premises = get_sequent inferences in
     let axioms = get_axioms premises (get_lemmas premises) in
     let l_goal = last_goal premises in
     (* let () = List.iter (fun m -> printf "%s" m)
        (get_axioms premises (get_lemmas premises)) in *)
     let name = Filename.remove_extension (Filename.basename fname) in
     let cwd = Sys.getcwd () in
     let cmd = "mkdir -p " ^ cwd ^ "/" ^ name ^ "/lemmas" in
     if Sys.command cmd != 0 then
       (printf "Error while creating the folder %s/lemmas\n" name; exit 1);
     printf "\t ==== Generating %i TPTP Problems from %s ==== \n%!"
       (List.length premises) fname;
     generate_files name premises;
     printf "\n%!";
     (* Printing all formulas in name_formula_tbl *)
     (* Hashtbl.iter
        (fun x y -> printf "%s : %s\n%!" x (Expr.expr_to_string y))
        Phrase.name_formula_tbl *)
     insert_symbols Phrase.name_formula_tbl;
     Signature.generate_signature_file name Signature.symbols_table;
     let liste = Proof.order_lemmas premises l_goal in
     Proof.generate_dk name axioms name liste l_goal;
     Proof.generate_pkg name;
     let cmd = "mkdir -p " ^ cwd ^ "/" ^ name ^ "/logic" in
     if Sys.command cmd != 0 then
       (printf "Error while creating the folder %s/logic\n" name; exit 1);
     let cmd =
       "cp -r ~/.ekstrakto/logic/*.lp " ^ cwd ^ "/" ^ name ^ "/logic/" in
     if Sys.command cmd = 0 then ();
     Signature.generate_makefile name;
  | _  ->
     eprintf "Usage: %s file.p\n%!" Sys.argv.(0);
     exit 1
