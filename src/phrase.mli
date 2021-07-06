val name_formula_tbl : (string, Expr.expr) Hashtbl.t

type infoitem =
  | Cte of string
  | Fun of string * infoitem list

type tpannot =
  | File of string
  | Inference of string * infoitem list * tpannot list
  | Introduced of string
  | Name of string
  | List of tpannot list
  | Other of string

type tpphrase =
  | Include of string * string list option
  | Formula of string * string * Expr.expr * string option
  | Formula_annot of string * string * Expr.expr * tpannot option
  | Annotation of string
