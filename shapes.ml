(**************************************************************************)
(*                                                                        *)
(*  Copyright (C) Johannes Kanig, Stephane Lescuyer                       *)
(*  and Jean-Christophe Filliatre                                         *)
(*                                                                        *)
(*  This software is free software; you can redistribute it and/or        *)
(*  modify it under the terms of the GNU Library General Public           *)
(*  License version 2, with the special exception on linking              *)
(*  described in file LICENSE.                                            *)
(*                                                                        *)
(*  This software is distributed in the hope that it will be useful,      *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of        *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                  *)
(*                                                                        *)
(**************************************************************************)

open Command
open Helpers
open Point
open Path

let pi = 4. *. (atan 1.)
let kappa = 4. *. (sqrt 2. -. 1.) /. 3.
let mkappa = 1. -. kappa

(** Rectangles *)

let rounded_rect ?fill ?(stroke=Color.black) ?(thickness=0.5) 
    width height rx ry =
  let path = 
    let hw,hh = width/.2.,height/.2. in
    let rx = max 0. (if rx > hw then hw else rx) in
    let ry = max 0. (if ry > hh then hh else ry) in
(*     let ul, ur, br, bl =  *)
(*       pt (-.hw, hh), pt (hw, hh),  *)
(*       pt (hw, -.hh), pt (-.hw, -.hh) in *)
    let ul1, ul2 = 
      pt (-.hw, hh-.mkappa*.ry), pt (-.hw+.mkappa*.rx, hh) in
    let ur1, ur2 = 
      pt (hw-.mkappa*.rx, hh), pt (hw, hh-.mkappa*.ry) in
    let br1, br2 = 
      pt (hw, -.hh+.mkappa*.ry), pt (hw-.mkappa*.rx, -.hh) in
    let bl1, bl2 = 
      pt (-.hw+.mkappa*.rx, -.hh), pt (-.hw, -.hh+.mkappa*.ry) in
    let knots = 
      [(NoDir, pt (-.hw+.rx, hh), Vec right);
       (NoDir, pt (hw-.rx, hh), Vec right);
       (NoDir, pt (hw, hh-.ry), Vec down); 
       (NoDir, pt (hw, -.hh+.ry), Vec down);
       (NoDir, pt (hw-.rx, -.hh), Vec left); 
       (NoDir, pt (-.hw+.rx, -.hh), Vec left);
       (NoDir, pt (-.hw, -.hh+.ry), Vec up);
       (NoDir, pt (-.hw, hh-.ry), Vec up)] in
    let joints = 
      [JLine; JControls(ur1,ur2);
       JLine; JControls(br1,br2); 
       JLine; JControls(bl1,bl2); JLine] in
      cycle ~dir:(Vec right) ~style:(JControls(ul1,ul2))
	(jointpathk knots joints) in
  let fillcmd =
    match fill with
      | None -> Command.nop
      | Some color -> Command.fill ~color path in
  let pen = Pen.square ~tr:([Transform.scaled thickness]) () in
  let strokecmd = Command.draw ~color:stroke ~pen path in
    Picture.make (Command.seq [fillcmd; strokecmd])

let rectangle ?fill ?(stroke=Color.black) ?(thickness=0.5) width height =
  match fill with 
    | None -> rounded_rect ~stroke ~thickness width height 0. 0.
    | Some fill -> 
	rounded_rect ~fill ~stroke ~thickness width height 0. 0.

(** Ellipses and Arcs *)

let full_ellipse_path rx ry =
  let m theta = pt (rx *. cos theta, ry *. sin theta) in
  let knots = 
    [(NoDir, m 0., Vec up); (NoDir, m (pi /. 2.), Vec left);
     (NoDir, m pi, Vec down); (NoDir, m (-. pi /. 2.), Vec right)] in
  let r1, r2 = pt (rx, -.ry*.kappa), pt (rx, ry*.kappa) in
  let t1, t2 = pt (rx*.kappa , ry), pt (-.rx*.kappa, ry) in
  let l1, l2 = pt (-.rx, ry*.kappa), pt (-.rx, -.ry*.kappa) in
  let b1, b2 = pt (-.rx*.kappa , -.ry), pt (rx*.kappa, -.ry) in
  let joints =
    [JControls(r2,t1); JControls(t2,l1); JControls(l2,b1)] in
    cycle ~dir:(Vec up) 
      ~style:(JControls(b2,r1)) (jointpathk knots joints)
      
let arc_ellipse ?fill ?(stroke=Color.black) ?(thickness=0.5) ?(close=false)
    rx ry theta1 theta2 =
  let curvabs theta =  (2. *. theta) /. pi in
  let path = 
    subpath (curvabs theta1) (curvabs theta2) (full_ellipse_path rx ry) in
  let path =
    if close || (match fill with Some _ -> true | _ -> false) then
      cycle ~style:JLine (concat ~style:JLine path (NoDir,origin,NoDir))
    else path
  in
  let fillcmd =
    match fill with
      | None -> Command.nop
      | Some color -> Command.fill ~color path in
  let pen = Pen.square ~tr:([Transform.scaled thickness]) () in
  let strokecmd = Command.draw ~color:stroke ~pen path in
    Picture.make (Command.seq [fillcmd; strokecmd])

let ellipse ?fill ?(stroke=Color.black) ?(thickness=0.5) rx ry =
  let path = full_ellipse_path rx ry in
  let fillcmd =
    match fill with
      | None -> Command.nop
      | Some color -> Command.fill ~color path in
  let pen = Pen.square ~tr:([Transform.scaled thickness]) () in
  let strokecmd = Command.draw ~color:stroke ~pen path in
    Picture.make (Command.seq [fillcmd; strokecmd])

