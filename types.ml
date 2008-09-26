(**************************************************************************)
(*                                                                        *)
(*  Copyright (C) Johannes Kanig, Stephane Lescuyer                       *)
(*  and Jean-Christophe Filliatre                                         *)
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

type color = 
  | RGB of float * float * float
  | CMYK of float * float * float * float

  | Gray of float

type name = string

type corner = N | S | W | E | NE | NW | SW | SE
type piccorner = UL | UR | LL | LR


type position =
  | Pcenter
  | Pleft
  | Pright
  | Ptop
  | Pbot
  | Pupleft
  | Pupright
  | Plowleft
  | Plowright

open Hashcons

type num_node = 
  | F of float
  | NXPart of point
  | NYPart of point
  | NAdd of num * num
  | NSub of num * num
  | NMult of num * num
  | NDiv of num * num
  | NMax of num * num
  | NMin of num * num
  | NGMean of num * num
  | NLength of path

and num = num_node hash_consed

and point_node = 
  | PTPair of num * num
  | PTPicCorner of picture * piccorner
  | PTPointOf of float * path
  | PTDirectionOf of float * path
  | PTAdd of point * point
  | PTSub of point * point
  | PTMult of num * point
  | PTRotated of float * point
  | PTTransformed of point * transform list

and point = point_node hash_consed

and on_off_node = 
  | On of num 
  | Off of num

and on_off = on_off_node hash_consed 

and direction_node = 
  | Vec of point
  | Curl of float
  | NoDir 

and direction = direction_node hash_consed

and joint_node = 
  | JLine
  | JCurve
  | JCurveNoInflex
  | JTension of float * float
  | JControls of point * point

and joint = joint_node hash_consed

and knot_node = 
    { knot_in : direction ; knot_p : point ; knot_out : direction }

and knot = knot_node hash_consed

and path_node =
  | PAConcat of knot * joint * path
  | PACycle of direction * joint * path
  | PAFullCircle
  | PAHalfCircle
  | PAQuarterCircle
  | PAUnitSquare
  | PATransformed of path * transform list
  | PAKnot of knot
  | PAAppend of path * joint * path
  | PACutAfter of path * path
  | PACutBefore of path * path
  | PABuildCycle of path list
  | PASub of float * float * path
  | PABBox of picture

and path = path_node hash_consed

and transform_node =
  | TRRotated of float
  | TRScaled of num
  | TRShifted of point
  | TRSlanted of num
  | TRXscaled of num
  | TRYscaled of num
  | TRZscaled of point
  | TRReflect of point * point
  | TRRotateAround of point * float

and transform = transform_node hash_consed

and picture_node = 
  | PITex of string
  | PIMake of command
  | PITransform of transform list * picture
  | PIClip of picture * path

and picture = picture_node hash_consed

and dash_node =
  | DEvenly
  | DWithdots
  | DScaled of float * dash
  | DShifted of point * dash
  | DPattern of on_off list

and dash = dash_node hash_consed

and pen_node = 
  | PenCircle
  | PenSquare
  | PenFromPath of path
  | PenTransformed of pen * transform list

and pen = pen_node hash_consed


and command_node =
  | CDraw of path * color option * pen option * dash option
  | CDrawArrow of path * color option * pen option * dash option
  | CDrawPic of picture
  | CFill of path * color option
  | CLabel of picture * position * point
  | CDotLabel of picture * position * point
  | CSeq of command list

and command = command_node hash_consed

let hash_float = Hashtbl.hash

let hash_piccorner = Hashtbl.hash

let hash_string = Hashtbl.hash

let combine n acc = acc * 65599 + n

let combine2 n acc1 acc2 = combine n (combine acc1 acc2)

let combine3 n acc1 acc2 acc3 = combine n (combine acc1 (combine acc2 acc3))

let combine4 n acc1 acc2 acc3 acc4 = combine n (combine3 acc1 acc2 acc3 acc4)


let num = function 
  | F f -> combine 1 (hash_float f)
  | NXPart p -> combine 2 p.hkey
  | NYPart p -> combine 3 p.hkey
  | NAdd(n,m) -> combine2 4 n.hkey m.hkey
  | NSub(n,m) -> combine2 5 n.hkey m.hkey
  | NMult(n,m) -> combine2 6 n.hkey m.hkey
  | NDiv(n,m) -> combine2 7 n.hkey m.hkey
  | NMax(n,m) -> combine2 8 n.hkey m.hkey
  | NMin(n,m) -> combine2 9 n.hkey m.hkey
  | NGMean(n,m) -> combine2 10 n.hkey m.hkey
  | NLength p -> combine 11 p.hkey

let point = function
  | PTPair(n,m) -> combine2 12 n.hkey m.hkey
  | PTPicCorner(p,pc) -> combine2 13 p.hkey (hash_piccorner pc)
  | PTPointOf(f,p) -> combine2 14 (hash_float f) p.hkey
  | PTDirectionOf(f,p) -> combine2 15 (hash_float f) p.hkey
  | PTAdd(p,q) -> combine2 16 p.hkey q.hkey
  | PTSub(p,q) -> combine2 17 p.hkey q.hkey
  | PTMult(n,q) -> combine2 18 n.hkey q.hkey
  | PTRotated(f,p) -> combine2 19 (hash_float f) p.hkey
  | PTTransformed(p,l) ->
      List.fold_left (fun acc t -> combine2 21 acc t.hkey)
	(combine 20 p.hkey) l

let on_off = function 
  | On n -> combine 65 n.hkey
  | Off n -> combine 66 n.hkey

let direction = function
  | Vec p -> combine 61 p.hkey
  | Curl f -> combine 62 (hash_float f)
  | NoDir -> 63

let joint = function
  | JLine -> 67
  | JCurve -> 68
  | JCurveNoInflex -> 69
  | JTension(f1,f2) -> combine2 70 (hash_float f1) (hash_float f2) 
  | JControls(p1,p2) -> combine2 71 p1.hkey p2.hkey

let knot k = 
  combine3 64 k.knot_in.hkey k.knot_p.hkey k.knot_out.hkey


let path = function
  | PAConcat(k,j,p) -> 
      combine3 22 k.hkey j.hkey p.hkey
  | PACycle(d,j,p) ->
      combine3 23 d.hkey j.hkey p.hkey
  | PAFullCircle -> 24
  | PAHalfCircle -> 25
  | PAQuarterCircle -> 26
  | PAUnitSquare -> 27
  | PATransformed(p,l) ->
      List.fold_left (fun acc t -> combine2 28 acc t.hkey)
	(combine 29 p.hkey) l
  | PAKnot k -> combine 30 k.hkey
  | PAAppend(p1,j,p2) -> combine3 31 p1.hkey j.hkey p2.hkey
  | PACutAfter(p,q) -> combine2 32 p.hkey q.hkey
  | PACutBefore(p,q) -> combine2 33 p.hkey q.hkey
  | PABuildCycle l ->
      List.fold_left (fun acc p -> combine2 35 acc p.hkey) 34 l
  | PASub(f1,f2,p) ->
      combine3 36 (hash_float f1) (hash_float f2) p.hkey
  | PABBox p -> combine 37 p.hkey

let transform = function
  | TRRotated f -> combine 52 (hash_float f)
  | TRScaled n -> combine 53 n.hkey
  | TRShifted p -> combine 57 p.hkey
  | TRSlanted n -> combine 54 n.hkey
  | TRXscaled n -> combine 55 n.hkey
  | TRYscaled n -> combine 56 n.hkey
  | TRZscaled p -> combine 58 p.hkey
  | TRReflect(p,q) -> combine2 59 p.hkey q.hkey
  | TRRotateAround(p,q) -> combine2 60 p.hkey (hash_float q)

let picture = function
  | PITex s -> combine 38 (hash_string s)
  | PIMake c -> combine 39 c.hkey
  | PITransform(l,p) ->
      List.fold_left (fun acc t -> combine2 40 acc t.hkey)
	(combine 41 p.hkey) l
  | PIClip(p,q) -> combine2 42 p.hkey q.hkey

let dash = function
  | DEvenly -> 72
  | DWithdots -> 73
  | DScaled(f,d) -> combine2 74 (hash_float f) d.hkey
  | DShifted(p,d) -> combine2 75 p.hkey d.hkey
  | DPattern l -> 
      List.fold_left (fun acc o -> combine2 76 acc o.hkey) 77 l

let pen = function
  | PenCircle -> 78
  | PenSquare -> 79
  | PenFromPath p -> combine 80 p.hkey
  | PenTransformed(p,l) ->
      List.fold_left (fun acc t -> combine2 81 acc t.hkey)
	(combine 82 p.hkey) l

let hash_opt f = function
  | None -> 83
  | Some o -> combine 84 (f o)

let hash_key x = x.hkey

let hash_color = Hashtbl.hash

let hash_position = Hashtbl.hash

let command = function
  | CDraw(pa,c,p,d) ->
      combine4 43 pa.hkey (hash_opt hash_color c) (hash_opt hash_color p) (hash_opt hash_key d)
  | CDrawArrow(pa,c,p,d) ->
      combine4 44 pa.hkey (hash_opt hash_color c) (hash_opt hash_color p) (hash_opt hash_key d)
  | CDrawPic p -> combine 45 p.hkey
  | CFill(p,c) -> combine2 46 p.hkey (hash_color c)
  | CLabel(pic,pos,poi) -> combine3 47 pic.hkey (hash_position pos) poi.hkey
  | CDotLabel(pic,pos,poi) -> 
      combine3 48 pic.hkey (hash_position pos) poi.hkey
  | CSeq l ->
      List.fold_left (fun acc t -> combine2 50 acc t.hkey) 51 l

(** equality *)

(* equality of floats with correct handling of nan *)
let eq_float (f1:float) (f2:float) =
  Pervasives.compare f1 f2 == 0

(* we enforce to use physical equality only on hash-consed data 
   of the same type *)
let eq_hashcons (x:'a hash_consed) (y:'a hash_consed) =
  x == y

let rec eq_hashcons_list (x:'a hash_consed list) (y:'a hash_consed list) =
  match x,y with
    | [], [] -> true
    | h1::t1,h2::t2 -> h1 == h2 && eq_hashcons_list t1 t2
    | _ -> false

let eq_opt f o1 o2 =
  match o1,o2 with
    | None,None -> true
    | Some x1, Some x2 -> f x1 x2
    | _ -> false

let eq_color c1 c2 = Pervasives.compare c1 c2 = 0

let eq_pen_node p1 p2 =
  match p1, p2 with
    | PenCircle, PenCircle 
    | PenSquare, PenSquare -> true
    | PenFromPath p1, PenFromPath p2 ->
	eq_hashcons p1 p2
    | PenTransformed(p1,l1), PenTransformed(p2,l2) ->
	eq_hashcons p1 p2 && eq_hashcons_list l1 l2
    | _ -> false

let eq_dash_node d1 d2 =
  match d1, d2 with
  | DEvenly, DEvenly 
  | DWithdots, DWithdots -> true
  | DScaled(f1,d1), DScaled(f2,d2) ->
      eq_float f1 f2 && eq_hashcons d1 d2
  | DShifted(p1,d1), DShifted(p2,d2) ->
      eq_hashcons p1 p2 && eq_hashcons d1 d2
  | DPattern l1, DPattern l2 ->
      eq_hashcons_list l1 l2
  | _ -> false

let eq_on_off o1 o2 =
  match o1,o2 with
    | Off n1, Off n2
    | On n1, On n2 -> eq_hashcons n1 n2
    | _ -> false

let eq_position (p1:position) (p2:position) = 
  p1 == p2 (* correct because this type contains only constants *)

let eq_piccorner (p1:piccorner) (p2:piccorner) =
  p1 == p2 (* correct because this type contains only constants *)


let eq_num_node n1 n2 =
  match n1,n2 with
    | F f1, F f2 -> eq_float f1 f2
    | NXPart p1, NXPart p2 
    | NYPart p1, NYPart p2 -> eq_hashcons p1 p2
    | NAdd(n11,n12),NAdd(n21,n22) 
    | NSub(n11,n12),NSub(n21,n22) 
    | NMult(n11,n12),NMult(n21,n22) 
    | NDiv(n11,n12),NDiv(n21,n22) 
    | NMax(n11,n12),NMax(n21,n22) 
    | NMin(n11,n12),NMin(n21,n22) 
    | NGMean(n11,n12),NGMean(n21,n22) 
	-> eq_hashcons n11 n21 && eq_hashcons n12 n22
    | NLength p1, NLength p2 -> eq_hashcons p1 p2
    | _ -> false

let eq_point_node p1 p2 =
  match p1,p2 with
    | PTPair(n11,n12),PTPair(n21,n22) -> 
	eq_hashcons n11 n21 && eq_hashcons n12 n22 
    | PTPicCorner(pic1,corn1), PTPicCorner(pic2,corn2) ->
	eq_hashcons pic1 pic2 && eq_piccorner corn1 corn2
    | PTPointOf(f1,p1), PTPointOf(f2,p2)
    | PTDirectionOf(f1,p1), PTDirectionOf(f2,p2)
	-> eq_float f1 f2 && eq_hashcons p1 p2 
    | PTAdd(p11,p12),PTAdd(p21,p22)
    | PTSub(p11,p12),PTSub(p21,p22)
	-> eq_hashcons p11 p21 && eq_hashcons p12 p22
    | PTMult(n1,p1),PTMult(n2,p2) ->
	eq_hashcons n1 n2 && eq_hashcons p1 p2
    | PTRotated(f1,p1),PTRotated(f2,p2) ->
	eq_float f1 f2 && eq_hashcons p1 p2
    | PTTransformed(p1,l1), PTTransformed(p2,l2) ->
	eq_hashcons p1 p2 && eq_hashcons_list l1 l2
    | _ -> false


let eq_path_node p1 p2 =
  match p1,p2 with
    | PAConcat(k1,j1,p1),PAConcat(k2,j2,p2) ->
	eq_hashcons k1 k2 && eq_hashcons j1 j2 && eq_hashcons p1 p2
    | PACycle(d1,j1,p1),PACycle(d2,j2,p2) ->	
	eq_hashcons d1 d2 && eq_hashcons j1 j2 && eq_hashcons p1 p2
    | PAFullCircle, PAFullCircle 
    | PAHalfCircle, PAHalfCircle
    | PAQuarterCircle, PAQuarterCircle
    | PAUnitSquare, PAUnitSquare 
	-> true
    | PATransformed(p1,l1),PATransformed(p2,l2) ->
	eq_hashcons p1 p2 && eq_hashcons_list l1 l2
    | PAKnot(k1), PAKnot(k2) -> eq_hashcons k1 k2
    | PAAppend(p11,j1,p12),PAAppend(p21,j2,p22) ->
	eq_hashcons p11 p21 && eq_hashcons j1 j2 && eq_hashcons p12 p22
    | PACutAfter(p11,p12),PACutAfter(p21,p22)
    | PACutBefore(p11,p12),PACutBefore(p21,p22) 
	-> eq_hashcons p11 p21 && eq_hashcons p12 p22
    | PABuildCycle(l1),PABuildCycle(l2) ->
	eq_hashcons_list l1 l2
    | PASub(f11,f12,p1), PASub(f21,f22,p2) ->
	eq_float f11 f21 && eq_float f12 f22 && eq_hashcons p1 p2
    | PABBox(p1), PABBox(p2) ->
	eq_hashcons p1 p2
    | _ -> false


let eq_picture_node p1 p2 =
  match p1,p2 with
    | PITex s1, PITex s2 -> s1==s2 
	(* incomplete but fast.
	   poor chance that same TeX text occurs twice anyway
	*)
    | PIMake c1, PIMake c2 -> eq_hashcons c1 c2
    | PITransform(l1,p1), PITransform(l2,p2) ->
	eq_hashcons p1 p2 && eq_hashcons_list l1 l2
    | PIClip(pi1,pa1), PIClip(pi2,pa2) ->
	eq_hashcons pi1 pi2 && eq_hashcons pa1 pa2
    | _ -> false

let eq_transform_node t1 t2 =
  match t1,t2 with
  | TRRotated f1, TRRotated f2 -> eq_float f1 f2
  | TRScaled n1, TRScaled n2 
  | TRSlanted n1, TRSlanted n2
  | TRXscaled n1, TRXscaled n2
  | TRYscaled n1, TRYscaled n2 -> eq_hashcons n1 n2
  | TRShifted p1, TRShifted p2
  | TRZscaled p1, TRZscaled p2 -> eq_hashcons p1 p2
  | TRReflect(p11,p12), TRReflect(p21,p22) ->
      eq_hashcons p11 p21 && eq_hashcons p12 p22
  | TRRotateAround(p1,f1), TRRotateAround(p2,f2) ->
      eq_hashcons p1 p2 && eq_float f1 f2
  | _ -> false

let eq_knot_node k1 k2 =
  eq_hashcons k1.knot_in k2.knot_in &&
  eq_hashcons k1.knot_p k2.knot_p &&
  eq_hashcons k1.knot_out k2.knot_out

let eq_joint_node j1 j2 =
  match j1,j2 with
  | JLine, JLine
  | JCurve, JCurve
  | JCurveNoInflex, JCurveNoInflex -> true
  | JTension(f11,f12), JTension(f21,f22) ->
      eq_float f11 f21 && eq_float f12 f22
  | JControls(p11,p12), JControls(p21,p22) ->
      eq_hashcons p11 p21 && eq_hashcons p12 p22
  | _ -> false


let eq_direction_node d1 d2 =
  match d1,d2 with
    | Vec p1, Vec p2 -> eq_hashcons p1 p2
    | Curl f1, Curl f2 -> eq_float f1 f2
    | NoDir, NoDir -> true
    | _ -> false 

  
let eq_command_node c1 c2 =
  match c1,c2 with
  | CDraw(p1,c1,pen1,d1), CDraw(p2,c2,pen2,d2) 
  | CDrawArrow(p1,c1,pen1,d1), CDrawArrow(p2,c2,pen2,d2) ->
      eq_hashcons p1 p2 && 
	eq_opt eq_color c1 c2 &&
	eq_opt eq_hashcons pen1 pen2 &&
	eq_opt eq_hashcons d1 d2
  | CDrawPic p1, CDrawPic p2 -> eq_hashcons p1 p2
  | CFill(p1,c1), CFill(p2,c2) ->
      eq_hashcons p1 p2 && eq_opt eq_color c1 c2
  | CLabel(pic1,pos1,poi1), CLabel(pic2,pos2,poi2) 
  | CDotLabel(pic1,pos1,poi1), CDotLabel(pic2,pos2,poi2) ->
      eq_hashcons pic1 pic2 && eq_position pos1 pos2 && eq_hashcons poi1 poi2
  | CSeq l1, CSeq l2 ->
      eq_hashcons_list l1 l2
  | _ -> false


(* smart constructors *)

(* num *)

let unsigned f x = (f x) land 0x3FFFFFFF

module HashNum = 
  Hashcons.Make(struct type t = num_node
		       let equal = eq_num_node
		       let hash = unsigned num end)

let hashnum_table = HashNum.create 257;;

let hashnum = HashNum.hashcons hashnum_table


let mkF f = hashnum (F f) 

let mkNAdd n1 n2 = hashnum (NAdd(n1,n2))

let mkNSub n1 n2 = hashnum (NSub(n1,n2))

let mkNMult n1 n2 = hashnum (NMult(n1,n2))

let mkNDiv n1 n2 = hashnum (NDiv(n1,n2))

let mkNMax n1 n2 = hashnum (NMax(n1,n2))

let mkNMin n1 n2 = hashnum (NMin(n1,n2))

let mkNGMean n1 n2 = hashnum (NGMean(n1,n2))

let mkNXPart p = hashnum (NXPart p)

let mkNYPart p = hashnum (NYPart p)

let mkNLength p = hashnum (NLength p)

(* point *)


module HashPoint = 
  Hashcons.Make(struct type t = point_node
		       let equal = eq_point_node
		       let hash = unsigned point end)

let hashpoint_table = HashPoint.create 257;;

let hashpoint = HashPoint.hashcons hashpoint_table

let mkPTPair f1 f2 = hashpoint (PTPair(f1,f2))

let mkPTAdd p1 p2 = hashpoint (PTAdd(p1,p2))

let mkPTSub p1 p2 = hashpoint (PTSub(p1,p2))

let mkPTMult x y = hashpoint (PTMult(x,y))

let mkPTRotated x y = hashpoint (PTRotated(x,y))

let mkPTTransformed x y = hashpoint (PTTransformed(x,y))

let mkPTPointOf f p = hashpoint (PTPointOf(f,p))

let mkPTDirectionOf f p = hashpoint (PTDirectionOf(f,p))

let mkPTPicCorner x y = hashpoint (PTPicCorner(x,y))

(* transform *)


module HashTransform = 
  Hashcons.Make(struct type t = transform_node
		       let equal = eq_transform_node
		       let hash = unsigned transform end)

let hashtransform_table = HashTransform.create 257;;

let hashtransform = HashTransform.hashcons hashtransform_table

let mkTRScaled n = hashtransform (TRScaled n)

let mkTRXscaled n = hashtransform (TRXscaled n)

let mkTRYscaled n = hashtransform (TRYscaled n)

let mkTRZscaled pt = hashtransform (TRZscaled pt)

let mkTRRotated f = hashtransform (TRRotated f)

let mkTRShifted pt = hashtransform (TRShifted pt)

let mkTRSlanted n = hashtransform (TRSlanted n)

let mkTRReflect pt1 pt2 = hashtransform (TRReflect(pt1,pt2))

let mkTRRotateAround pt f = hashtransform (TRRotateAround(pt,f))

(* knot *)

module HashKnot = 
  Hashcons.Make(struct type t = knot_node
		       let equal = eq_knot_node
		       let hash = unsigned knot end)

let hashknot_table = HashKnot.create 257;;

let hashknot = HashKnot.hashcons hashknot_table

let mkKnot d1 p d2 = hashknot { knot_in = d1; knot_p = p; knot_out = d2 }

(* path *)

module HashPath = 
  Hashcons.Make(struct type t = path_node
		       let equal = eq_path_node
		       let hash = unsigned path end)

let hashpath_table = HashPath.create 257;;

let hashpath = HashPath.hashcons hashpath_table

let mkPAKnot k = hashpath (PAKnot k)

let mkPAConcat p1 j p2 = hashpath (PAConcat(p1,j,p2))

let mkPACycle p1 j d = hashpath (PACycle (p1,j,d))

let mkPAAppend x y z = hashpath (PAAppend (x,y,z))

let mkPAFullCircle = hashpath (PAFullCircle)

let mkPAHalfCircle = hashpath (PAHalfCircle)

let mkPAQuarterCircle = hashpath (PAQuarterCircle)

let mkPAUnitSquare = hashpath (PAUnitSquare)

let mkPATransformed x y = hashpath (PATransformed (x,y))

let mkPACutAfter x y = hashpath (PACutAfter (x,y))

let mkPACutBefore x y = hashpath (PACutBefore (x,y))

let mkPABuildCycle l = hashpath (PABuildCycle l)

let mkPASub x y z = hashpath (PASub (x,y,z))

let mkPABBox pic = hashpath (PABBox pic)

(* joint *)

module HashJoint = 
  Hashcons.Make(struct type t = joint_node
		       let equal = eq_joint_node
		       let hash = unsigned joint end)

let hashjoint_table = HashJoint.create 257;;

let hashjoint = HashJoint.hashcons hashjoint_table

let mkJCurve  = hashjoint JCurve

let mkJLine  = hashjoint JLine

let mkJCurveNoInflex  = hashjoint JCurveNoInflex

let mkJTension x y = hashjoint (JTension(x,y))

let mkJControls x y = hashjoint (JControls(x,y))


(* direction *)

module HashDir = 
  Hashcons.Make(struct type t = direction_node
		       let equal = eq_direction_node
		       let hash = unsigned direction end)

let hashdir_table = HashDir.create 257;;

let hashdir = HashDir.hashcons hashdir_table

let mkNoDir  = hashdir NoDir

let mkVec p = hashdir (Vec p)

let mkCurl f = hashdir (Curl f)

(* picture *)

module HashPicture = 
  Hashcons.Make(struct type t = picture_node
		       let equal = eq_picture_node
		       let hash = unsigned picture end)

let hashpicture_table = HashPicture.create 257;;

let hashpicture = HashPicture.hashcons hashpicture_table

let mkPITex s = hashpicture (PITex s)

let mkPIMake com = hashpicture (PIMake com)

let mkPITransform x y = hashpicture (PITransform (x,y))

let mkPIClip p pic = hashpicture (PIClip(p,pic))

(* command *)

module HashCommand = 
  Hashcons.Make(struct type t = command_node
		       let equal = eq_command_node
		       let hash = unsigned command end)

let hashcommand_table = HashCommand.create 257;;

let hashcommand = HashCommand.hashcons hashcommand_table

let mkCDraw x y z t = hashcommand (CDraw(x,y,z,t))

let mkCDrawArrow x y z t = hashcommand (CDrawArrow(x,y,z,t))

let mkCDrawPic pic = hashcommand (CDrawPic pic)

let mkCFill x y = hashcommand (CFill(x,y))

let mkCLabel x y z = hashcommand (CLabel(x,y,z))

let mkCDotLabel x y z = hashcommand (CDotLabel(x,y,z))

let mkCSeq l = hashcommand (CSeq l)

(* dash *)

module HashDash = 
  Hashcons.Make(struct type t = dash_node
		       let equal = eq_dash_node
		       let hash = unsigned dash end)

let hashdash_table = HashDash.create 257;;

let hashdash = HashDash.hashcons hashdash_table

let mkDEvenly = hashdash DEvenly

let mkDWithdots = hashdash DWithdots

let mkDScaled x y = hashdash (DScaled(x,y))

let mkDShifted x y = hashdash (DShifted(x,y))

let mkDPattern l = hashdash (DPattern l)

(* pen *)

module HashPen = 
  Hashcons.Make(struct type t = pen_node
		       let equal = eq_pen_node
		       let hash = unsigned pen end)

let hashpen_table = HashPen.create 257;;

let hashpen = HashPen.hashcons hashpen_table

let mkPenCircle = hashpen PenCircle

let mkPenSquare = hashpen PenSquare

let mkPenFromPath p = hashpen (PenFromPath p)

let mkPenTransformed x y = hashpen (PenTransformed(x,y))

(* on_off *)

module HashOnOff = 
  Hashcons.Make(struct type t = on_off_node
		       let equal = eq_on_off
		       let hash = unsigned on_off end)

let hashon_off_table = HashOnOff.create 257;;

let hashon_off = HashOnOff.hashcons hashon_off_table

let mkOn n = hashon_off (On n)

let mkOff n = hashon_off (Off n)
