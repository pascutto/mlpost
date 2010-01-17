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

open Point_lib
open Spline_lib

let draw_spline cr p = 
  List.iter (fun (e,_) -> 
    List.iter (fun s -> 
      Cairo.move_to cr s.sa.x s.sa.y ;
      Cairo.curve_to cr s.sb.x s.sb.y s.sc.x s.sc.y s.sd.x s.sd.y) e) p;
  Cairo.stroke cr

module Cairo_device = Dev_save.Dev_load(Dvicairo.Cairo_device)

let draw_tex cr tex = 
  Cairo.save cr;
  Cairo.transform cr tex.Gentex.trans;
  Cairo_device.replay false tex.Gentex.tex 
  {Dvicairo.pic = cr;new_page = (fun () -> assert false);
   x_origin = 0.; y_origin = 0.};
  Cairo.restore cr
  (*;Format.printf "Gentex : %a@." print tex*)

module MetaPath =
struct
  type pen = Matrix.t

  let draw_path cr = function
    | Path p ->
       List.iter (function 
                    | {start = true} as s -> 
                        Cairo.move_to cr s.sa.x s.sa.y ;
                        Cairo.curve_to cr 
                          s.sb.x s.sb.y 
                          s.sc.x s.sc.y 
                          s.sd.x s.sd.y
                    | s -> 
                        Cairo.curve_to cr 
                          s.sb.x s.sb.y 
                          s.sc.x s.sc.y 
                          s.sd.x s.sd.y) p.pl;
        if p.cycle then Cairo.close_path cr
    | Spline_lib.Point _ -> failwith "Metapost fail in that case what should I do???"

  let stroke cr pen = function
    | Path _ as path -> 
        (*Format.printf "stroke : %a@." S.print path;*)
        draw_path cr path;
        Cairo.save cr;
        (*Matrix.set*) Cairo.transform cr pen;
        Cairo.stroke cr;
        Cairo.restore cr;
    | Point p ->
        (*Format.printf "stroke : %a@." S.print path;*)
        Cairo.save cr;
        Cairo.transform cr (Matrix.translation p);
        Cairo.transform cr pen;
        draw_path cr (Metapath_lib.Approx.fullcircle 1.);
        Cairo.fill cr;
        Cairo.restore cr

  let fill cr path = draw_path cr path; Cairo.fill cr
end

module Picture =
struct
  open Types

  exception Not_implemented of string
  let not_implemented s = raise (Not_implemented s)

  let rec color cr = function
    | OPAQUE (RGB (r,g,b)) -> Cairo.set_source_rgb cr r g b
    | OPAQUE (CMYK _) -> not_implemented "cmyk"
    | OPAQUE (Gray g) -> color cr (OPAQUE (RGB (g,g,g)))
    | TRANSPARENT (a,RGB (r,g,b)) -> Cairo.set_source_rgba cr r g b a
    | TRANSPARENT (a,CMYK _) -> not_implemented "cmyk"
    | TRANSPARENT (a,(Gray g)) -> color cr (TRANSPARENT (a,RGB (g,g,g)))

  let color_option cr = function
    | None -> ()
    | Some c -> color cr c

  let dash cr = function
    | None | Some (_,[]) -> ();
    | Some (f,l) -> Cairo.set_dash cr (Array.of_list l) f

  let inversey cr height = 
    Cairo.translate cr ~tx:0. ~ty:height;
    Cairo.scale cr ~sx:1. ~sy:(-.1.)

  open Picture_lib

  let rec draw_aux cr = function
    | Empty -> ()
    | Transform (m,t) -> 
        Cairo.save cr;
        Cairo.transform cr m;
        (*Format.printf "Transform : %a@." Matrix.print m;*)
        draw_aux cr t;
        Cairo.restore cr
    | OnTop l -> List.iter (draw_aux cr) l
    | Tex t -> 
        Cairo.save cr;
        let ({y=min},{y=max}) = Gentex.bounding_box t in
        inversey cr (max+.min);
        draw_tex cr t;
        Cairo.restore cr
    | Stroke_path(path,c,pen,d) ->
        Cairo.save cr;
        color_option cr c;
        dash cr d;
        MetaPath.stroke cr pen path;
        Cairo.restore cr
    | Fill_path (path,c)-> 
        Cairo.save cr;
        color_option cr c;
        MetaPath.fill cr path;
        Cairo.restore cr
    | Clip (com,p) -> 
        Cairo.save cr;
        MetaPath.draw_path cr p;
        Cairo.clip cr;
        draw_aux cr com;
        Cairo.restore cr
    | ExternalImage (filename,height,width) -> 
        Cairo.save cr;
        inversey cr height;
        let img = Cairo_png.image_surface_create_from_file filename in
        let iwidth = float_of_int (Cairo.image_surface_get_width img) in
        let iheight = float_of_int (Cairo.image_surface_get_height img) in
        Cairo.scale cr (width/.iwidth) (height/.iheight);
        Cairo.set_source_surface cr img 0. 0.;
        Cairo.paint cr;
        Cairo.restore cr

  let draw cr width height p =
    Cairo.save cr;
    inversey cr height;
    Cairo.set_line_width cr default_line_size;
    (* Only elliptical pens use the stroke command *)
    Cairo.set_line_cap cr Cairo.LINE_CAP_ROUND;
    Cairo.set_line_join cr Cairo.LINE_JOIN_ROUND;
    draw_aux cr p.fcl;
    (*Spline_lib.Epure.draw cr p.fb;*)
    Cairo.restore cr

  let where cr t (x,y) = not_implemented "where"
  let move t id p = not_implemented "move"

end
