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

type direction = Path.direction =
  | Vec of Point.t
  | Curl of float
  | NoDir 

type joint = Path.joint =
  | JLine
  | JCurve
  | JCurveNoInflex
  | JTension of float * float
  | JControls of Point.t * Point.t

type knot = Path.knot

type t = Path.t
(** build a knot from a pair of floats *)
val knot :
    ?l:Path.direction -> ?r:Path.direction -> 
      ?scale:(float -> Num.t) -> float * float -> Path.knot
(** build a knot from a point *)
val knotp :
    ?l:Path.direction -> ?r:Path.direction -> Point.t -> Path.knot

(** build a path from a list of floatpairs *)
val path : 
    ?style:Path.joint -> ?cycle:Path.joint -> ?scale:(float -> Num.t) -> 
      (float * float) list -> Path.t

(** build a path from a knot list *)
val pathk :
    ?style:Path.joint -> ?cycle:Path.joint -> Path.knot list -> Path.t

(** build a path from a point list *)
val pathp :
    ?style:Path.joint -> ?cycle:Path.joint -> Point.t list -> Path.t

(** build a path from [n] knots and [n-1] joints *)
val jointpathk : Path.knot list -> Path.joint list -> Path.t
(** build a path from [n] points and [n-1] joints, with default directions *)
val jointpathp : Point.t list -> Path.joint list -> Path.t

(** build a path from [n] float_pairs and [n-1] joints, with default 
* directions *)
val jointpath : 
    ?scale:(float -> Num.t) -> (float * float) list -> 
      Path.joint list -> Path.t

(** the same functions as in [Path] but with labels *)
val cycle : ?dir:Path.direction -> ?style:Path.joint -> Path.t -> Path.t
val concat : ?style:Path.joint -> Path.t -> Path.knot -> Path.t
val start : knot -> t
val append : ?style:Path.joint -> t -> t -> t
val subpath : float -> float -> t -> t
val fullcircle : t
val halfcircle : t
val quartercircle: t
val unitsquare: t

val transform : Transform.t -> t -> t

val bpath : Box.t -> t

val point : float -> t -> Point.t

val cut_after : t -> t -> t
val cut_before: t -> t -> t
val build_cycle : t list -> t

