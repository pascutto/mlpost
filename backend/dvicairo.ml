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
open Dviinterp
open Mlpost_ft


type multi_page_pic = {pic :Cairo.t;
                       x_origin : float;
                       y_origin : float
                      }

let conversion = 0.3937 *. 72.
let point_of_cm cm = conversion *. cm

let debug = ref false
let specials = ref false
let info = ref false


let fonts_known = Hashtbl.create 30

let find_font font =
  let font_name = font.Fonts.glyphs_tag in
  try Hashtbl.find fonts_known font_name
  with Not_found ->
    if !debug then printf "Cairo : Loading font@.";
    let face = font.Fonts.glyphs_ft in
    let f = Cairo_ft.font_face_create_for_ft_face face 0 in
    Hashtbl.add fonts_known font_name f;f

let clean_up () = ()

let set_source_color pic = function
  | RGB(r,g,b) ->
    if !debug then
      printf "Use color RGB (%f,%f,%f)@." r g b;
    Cairo.set_source_rgb pic r g b
  | Gray(g) ->
    if !debug then
      printf "Use color Gray (%f)@." g;
    Cairo.set_source_rgb pic g g g
  | CMYK _ -> failwith "dvicairo : I don't know how to convert CMYK\
 to RGB and cairo doesn't support it"
  | HSB _ -> failwith "dvicairo : I'm lazy I haven't written this conversion"
  (* http://en.wikipedia.org/wiki/HSL_and_HSV#Conversion_from_HSV_to_RGB
     and in color.ml*)


let fill_rect s dinfo x1 y1 w h =
  let x1 = point_of_cm x1 +. s.x_origin
  and y1 = point_of_cm y1 +. s.y_origin
  and w = point_of_cm w
  and h = point_of_cm h in
  if !debug then
    printf "Draw a rectangle in (%f,%f) with w=%f h=%f@." x1 y1 w h;
  Cairo.save s.pic;
  set_source_color s.pic dinfo.Dviinterp.color;
  Cairo.rectangle s.pic x1 y1 w h;
  Cairo.fill s.pic;
  Cairo.restore s.pic

let draw_type1 s text_type1 =
  let dinfo = text_type1.c_info in
  let font = text_type1.c_font in
  let char = text_type1.c_glyph in
  let x,y = text_type1.c_pos in
  let f = find_font font in
  let char = font.Fonts.glyphs_enc (Int32.to_int char)
  and x = point_of_cm x +. s.x_origin
  and y = point_of_cm y +. s.y_origin
  and ratio = point_of_cm font.Fonts.glyphs_ratio_cm in
  if !debug then begin
    try
      printf "Draw the char %i(%c) in (%f,%f) x%f@."
        char (Char.chr char) x y ratio;
    with _ ->
      printf "Draw the char %i in (%f,%f) x%f@." char x y ratio
  end;
  Cairo.save s.pic;
  set_source_color s.pic dinfo.Dviinterp.color;
  Cairo.set_font_face s.pic f ;
  Cairo.set_font_size s.pic ratio;
    (* slant and extend *)
  (match font.Fonts.slant with
    | Some a when !info ->
      printf "slant of %f not used@." a
    | Some _ | None -> ());
  (match font.Fonts.extend with
    | Some a when !info ->
      printf "extend of %f not used@." a
    | Some _ | None -> ());
  Cairo.show_glyphs s.pic
    [|{Cairo.index = char;
       Cairo.glyph_x = x;
       Cairo.glyph_y = y}|];
  Cairo.stroke s.pic;
  Cairo.restore s.pic

let _specials s info xxx x y =
  if !debug || !specials then
    printf "specials : \"%s\" at (%f,%f)@." xxx x y

let rec draw_string s text =
  draw_commands s (decompose_text text)

and draw_command s = function
  | Fill_rect (info, x, y, w, h) -> fill_rect s info x y w h
  | Draw_text text -> draw_string s text
  | Specials (info,xxx,x,y) -> _specials s info xxx x y
  | Draw_text_type1 text_type1 -> draw_type1 s text_type1

and draw_commands s = List.iter (draw_command s)

let draw = draw_commands



