(*  Copyright 2005 INRIA  *)

val token : Lexing.lexbuf -> Parsetstp.token;;

(* Added Error *)
module Error : sig
  exception Lex_error of string
  val errpos : Lexing.position -> string -> unit;;
  val err : string -> unit;;
end