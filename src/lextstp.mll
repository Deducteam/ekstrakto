{

open Lexing;;
open Parsetstp;;
open Printf;;

module Error = struct
  open Printf;;

  let warnings_flag = ref true;;
  let got_warning = ref false;;
  let err_file = ref "";;

  let print_header = ref false;;
  let header = ref "";;

  let set_header msg =
    print_header := true;
    header := msg;
  ;;

  let err_oc = ref stderr;;
  let err_inited = ref false;;

  let print kind msg =
    if not !err_inited then begin
      if !err_file <> "" then err_oc := open_out !err_file;
      if !print_header then fprintf !err_oc "%s\n" !header;
      err_inited := true;
    end;
    fprintf !err_oc "%s%s\n" kind msg;
    flush !err_oc;
  ;;

  let warn msg =
    if !warnings_flag then begin
      print "Zenon warning: " msg;
      got_warning := true;
    end;
  ;;

  let err msg = print "Zenon error: " msg;;

  let errpos pos msg =
    let s = sprintf "File \"%s\", line %d, character %d:"
                    pos.Lexing.pos_fname pos.Lexing.pos_lnum
                    (pos.Lexing.pos_cnum - pos.Lexing.pos_bol)
    in
    print "" s;
    print "Zenon error: " msg;
  ;;

  exception Lex_error of string;;
  exception Abort;;
end

let rec count_lf i s accu =
  if i >= String.length s then accu
  else count_lf (i+1) s (if s.[i] = '\n' then accu + 1 else accu)
;;

let adjust_pos lexbuf =
  let lx = Lexing.lexeme lexbuf in
  let rec loop i nl last =
    if i >= String.length lx then (nl, last)
    else if lx.[i] = '\n' then loop (i+1) (nl+1) i
    else loop (i+1) nl last
  in
  let (nl, last) = loop 0 0 0 in
  if nl > 0 then begin
    lexbuf.lex_curr_p <- {
      lexbuf.lex_curr_p with
      pos_bol = Lexing.lexeme_start lexbuf + last + 1;
      pos_lnum = lexbuf.lex_curr_p.pos_lnum + nl;
    }
  end;
;;

}

let space = [' ' '\009' '\012' '\013']
let stringchar = [^ '\000'-'\031' '\'' '\127'-'\255']
let upperid = [ 'A' - 'Z' ]
let lowerid = [ 'a' - 'z' ]
let idchar = [ 'A' - 'Z' 'a' - 'z' '0' - '9' '_' ]
let all_characters = [ '_' ]
  
rule token = parse
  | "#@" ([^ '\010']* as annot)
                     { ANNOT annot }
  | "#" [^ '\010']*
                     { token lexbuf }
  | '\010'           { adjust_pos lexbuf; token lexbuf }
  | "/*" ([^ '*']* | '*'+ [^ '/' '*'])* '*'+ '/' {
     adjust_pos lexbuf;
     token lexbuf
    }
  | space +          { token lexbuf }
  | "("              { OPEN }
  | ")"              { CLOSE }
  | "["              { LBRACKET }
  | "]"              { RBRACKET }
  | ">"              { RANGL }
  | ","              { COMMA }
  | ":"              { COLON }
  | "*"              { STAR }
  | "."              { DOT }
  | "?"              { EX }
  | "!"              { ALL }
  | "~"              { NOT }
  | "|"              { OR }
  | "&"              { AND }
  | "=>"             { IMPLY }
  | "<="             { RIMPLY }
  | "<=>"            { EQUIV }
  | "="              { EQSYM }
  | "!="             { NEQSYM }
  | "<~>"            { XOR }
  | "~|"             { NOR }
  | "~&"             { NAND }
  | "include"        { INCLUDE }
  | "inference"      { INFERENCE }
  | "theory"         { THEORY }
  | "introduced"     { INTRODUCED }
  | "unknown"        { UNKNOWN }
  | "ac"             { AC }
  | "equality"       { EQUALITY }
  | "file"           { FILE }
  | "creator"        { CREATOR }
  | "cnf"            { INPUT_CLAUSE }
  | "fof"            { INPUT_FORMULA }
  | "tff"            { INPUT_TFF_FORMULA }
  | "$o"             { PROP }
  | "$true"          { TRUE }
  | "$false"         { FALSE }
  | "$tType"         { TTYPE }
  | "\'"             { single_quoted (Buffer.create 20) lexbuf }
  | "\""             { double_quoted (Buffer.create 20) lexbuf }
  | upperid idchar * { UIDENT (Lexing.lexeme lexbuf) }
  | '$'? lowerid idchar * { LIDENT (Lexing.lexeme lexbuf) }
  | all_characters * { ANYCHAR (Lexing.lexeme lexbuf) }
      
  | ['+' '-']? ['0' - '9']+
        { INT (Lexing.lexeme lexbuf) }
  | ['+' '-']? ['0' - '9']+ '/' ['0' - '9']+
        { RAT (Lexing.lexeme lexbuf) }
  | ['+' '-']? ['0' - '9']+ '.' ['0' - '9']+ (['E' 'e'] ['+' '-']? ['0' - '9']+)?
        { REAL (Lexing.lexeme lexbuf) }

  | eof              { EOF }
  | _                {
      let msg = sprintf "bad character %C" (Lexing.lexeme_char lexbuf 0) in
      raise (Error.Lex_error msg)
    }

and single_quoted buf = parse
  | '\\' [ '\\' '\'' ] {
      Buffer.add_char buf (Lexing.lexeme_char lexbuf 1);
      single_quoted buf lexbuf
    }
  | [' ' - '&' (* ' *) '(' - '[' (* \ *) ']' - '~' ]+ {
      Buffer.add_string buf (Lexing.lexeme lexbuf);
      single_quoted buf lexbuf
    }
  | '\'' { LIDENT (Buffer.contents buf) }
  | '\\' { raise (Error.Lex_error "bad \\ escape in <single_quoted>") }
  | _ { raise (Error.Lex_error "bad character in <single_quoted>") }

and double_quoted buf = parse
  | '\\' [ '\\' '\"' ] {
      Buffer.add_char buf (Lexing.lexeme_char lexbuf 1);
      double_quoted buf lexbuf
    }
  | [' ' - '!' (* "" *) '#' - '[' (* \ *) ']' - '~' ]+ {
      Buffer.add_string buf (Lexing.lexeme lexbuf);
      double_quoted buf lexbuf
    }
  | '\"' { STRING (Buffer.contents buf) }
  | '\\' { raise (Error.Lex_error "bad \\ escape in <distinct_object>") }
  | _ { raise (Error.Lex_error "bad character in <distinct_object>") }
