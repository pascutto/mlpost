(**************************************************************************)
(*                                                                        *)
(*  Copyright (C) Johannes Kanig, Stephane Lescuyer                       *)
(*  Jean-Christophe Filliatre, Romain Bardou and Francois Bobot           *)
(*                                                                        *)
(*  This software is free software; you can redistribute it and/or        *)
(*  modify it under the terms of the GNU Library General Public           *)
(*  License version 2.1, with the special exception on linking            *)
(*  described in file LICENSE.                                            *)
(*                                                                        *)
(*  This software is distributed in the hope that it will be useful,      *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of        *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                  *)
(*                                                                        *)
(**************************************************************************)

open Format

let print i fmt c =
  (* resetting is actually not needed; variables other than
     x,y are not local to figures *)
(*   Compile.reset (); *)
  let () = Duplicate.commandpic c in
  let c = Compile.commandpic_cmd c in
  fprintf fmt "@[beginfig(%d)@\n  @[%a@] endfig;@]@." i MPprint.command c

let print_prelude ?(eps=false) s fmt () =
  fprintf fmt "input mp-tool ; %% some initializations and auxiliary macros
input mp-spec ; %% macros that support special features

%%redefinition
def doexternalfigure (expr filename) text transformation =
  begingroup ; save p, t ; picture p ; transform t ;
  p := nullpicture ; t := identity transformation ;
  flush_special(10, 9,
    dddecimal (xxpart t, yxpart t, xypart t) & \" \" &
    dddecimal (yypart t,  xpart t,  ypart t) & \" \" & filename) ;
  addto p contour unitsquare transformed t ;
  setbounds p to unitsquare transformed t ;
  _color_counter_ := _color_counter_ + 1 ;
  draw p withcolor (_special_signal_/_special_div_,\
_color_counter_/_special_div_,_special_counter_/_special_div_) ;
  endgroup ;
enddef ;

vardef reset_extra_specials =
  enddef ;

@\n";
  if eps then
    fprintf fmt "prologues := 2;@\n"
  else
    (fprintf fmt "prologues := 0;@\n";
     fprintf fmt "mpprocset := 0;@\n");
 fprintf fmt "verbatimtex@\n";
 fprintf fmt "%%&latex@\n";
 fprintf fmt "%s" s;
 fprintf fmt "\\begin{document}@\n";
 fprintf fmt "etex@\n"
   (* fprintf fmt "input boxes;@\n" *)

let defaultprelude = "\\documentclass{article}\n\\usepackage[T1]{fontenc}\n"

(** take a list of figures [l] and write the code to the formatter in argument
 *)

let generate_mp_fmt l ?(prelude=defaultprelude) ?eps fmt =
  print_prelude ?eps prelude fmt ();
  List.iter (fun (i,_,f) -> print i fmt f) l;
  fprintf fmt "end@."

let generate_mp fn ?prelude ?eps l =
  File.LowLevel.write_to_formatted fn (generate_mp_fmt l ?prelude ?eps)

let generate_mp_file fn ?prelude ?eps l =
  File.write_to_formatted fn (generate_mp_fmt l ?prelude ?eps)

(* batch processing *)

let figuren = ref 0
let figures = Queue.create ()

let filename_prefix = ref ""
let set_filename_prefix = (:=) filename_prefix

let emit s f =
  incr figuren;
  Queue.add (!figuren, !filename_prefix^s, f) figures

let read_prelude_from_tex_file = Metapost_tool.read_prelude_from_tex_file

let dump_tex ?prelude f =
  let c = open_out (f ^ ".tex") in
  let fmt = formatter_of_out_channel c in
  begin match prelude with
    | None ->
	fprintf fmt "\\documentclass[a4paper]{article}";
	fprintf fmt "\\usepackage{graphicx}"
    | Some s ->
	fprintf fmt "%s@\n" s
  end;
  fprintf fmt "\\begin{document}@\n";
  fprintf fmt "\\begin{center}@\n";
  Queue.iter
    (fun (_,s,_) ->
       fprintf fmt "\\hrulefill\\verb!%s!\\hrulefill\\\\[1em]@\n" s;
       fprintf fmt "\\includegraphics{%s.mps}\\\\@\n" s;
       fprintf fmt "\\hrulefill\\\\@\n@\n\\medskip@\n";)
    figures;
  fprintf fmt "\\end{center}@\n";
  fprintf fmt "\\end{document}@.";
  close_out c

let call_latex ?inv ?outv ?verbose f =
  let cmd = Misc.sprintf "latex -interaction=nonstopmode %s" f in
  Misc.call_cmd ?inv ?outv ?verbose cmd

let call_mpost ?inv ?outv ?verbose f =
  let cmd =
    Misc.sprintf "mpost -interaction=nonstopmode %s" (File.to_string f) in
  Misc.call_cmd ?inv ?outv ?verbose cmd

let print_latex_error () =
  if Sys.file_exists "mpxerr.tex" then begin
    Printf.printf
      "############################################################\n";
    Printf.printf
      "LaTeX has found an error in your file. Here is its output:\n";
    ignore (call_latex ~outv:true "mpxerr.tex")
  end else
    Printf.printf "There was an error during execution of metapost. Aborting. \
      Execute with option -v to see the error.\n"

let generate_aux rename f ?prelude ?eps ?(verbose=false)
    ?(clean=true) figl =
  if figl <> [] then
    let do_ _ _ =
      (* a chdir has been done to tmpdir *)
      generate_mp_file f ?prelude ?eps figl;
      let s = call_mpost ~verbose f in
      if s <> 0 then print_latex_error ();
      s in
    if Metapost_tool.tempdir ~clean "mlpost" "mpost" do_ rename <> 0
    then exit 2

let generate ?prelude ?(pdf=false) ?eps ?(verbose=false) ?clean bn figl =
  let fn = File.from_string bn in
  let base = File.clear_dir fn in
  let mpfile = File.set_ext fn "mp" in
  let suf = if pdf then "mps" else "1" in
  let rename =
    List.fold_left
      (fun acc (i,s,_) ->
         let from = File.set_ext base (string_of_int i) in
         let to_ = File.set_ext (File.from_string s) suf in
         File.Map.add from to_ acc) File.Map.empty figl in
  generate_aux rename mpfile ?prelude ?eps ~verbose ?clean figl

let dump ?prelude ?pdf ?eps ?verbose ?clean bn =
  let figl = Queue.fold (fun l (i,s,f) -> (i,s,f) :: l) [] figures in
  generate ?prelude ?pdf ?eps ?verbose ?clean bn figl



let dump_mp ?prelude bn =
  let figl = Queue.fold (fun l s -> s :: l) [] figures in
  let f = bn ^ ".mp" in
  generate_mp f ?prelude figl


(** with mptopdf *)
let dump_png ?prelude ?(verbose=false) ?(clean=true) bn =
  dump_mp ?prelude bn;
  let s =
    Misc.call_cmd ~verbose
      (sprintf "mptopdf %s.mp" bn) in
  if s <> 0 then print_latex_error ();
  if clean then
    ignore (Misc.call_cmd ~verbose
      (Printf.sprintf
        "rm -f mpxerr.log mpxerr.tex mpxerr.aux mpxerr.dvi %s.mp %s.mpx %s.log"
        bn bn bn));
  if s <> 0 then exit 1;
  Queue.iter
    (fun (i,s,_) ->
       let s =
         Misc.call_cmd ~verbose
           (sprintf "convert -density 600x600 \"%s-%i.pdf\" \"%s.png\"" bn i s)
       in
       if clean then
         ignore (Misc.call_cmd ~verbose
                   (Printf.sprintf
                      "rm -f %s-%i.pdf" bn i));
       if s <> 0 then (
         ignore (Misc.call_cmd ~verbose
                   (Printf.sprintf
                      "rm -f %s-*.pdf" bn));exit 1)
    ) figures

let slideshow l k =
  let l = List.map Picture.make l in
  let l' = Command.seq (List.map
                  (fun p -> Command.draw
                              ~color:Color.white
                              (Picture.bbox p)) l)
  in
  let x = ref (k-1) in
    List.map (fun p ->
                  incr x;
                  !x, Command.seq [l'; Command.draw_pic p]) l


let emit_slideshow s l =
  let l = slideshow l 0 in
  List.iter (fun (i,fig) -> emit (s^(string_of_int i)) fig) l


let emited () = Queue.fold (fun l (i,n,f) -> (i,n,f) :: l) [] figures

let dumpable () =
  Queue.iter (fun (_,s,_) -> Printf.printf "%s\n" s) figures

let depend myname =
  Queue.iter (fun (_,s,_) -> Printf.printf "%s.fmlpost " s) figures;
  Printf.printf " : %s.cmlpost\n" myname



