(* Extended arrows. *)

let normalize p =
  Point.scale (Num.divn (Num.bp 1.) (Point.length p)) p

let neg = Point.scale (Num.bp (-1.))

let direction_on_path f p =
  Path.directionn (Num.multf f (Path.length p)) p

let point_on_path f p =
  Path.pointn (Num.multf f (Path.length p)) p

let subpath_01 f t p =
  let l = Path.length p in
  let f = Num.multf f l in
  let t = Num.multf t l in
  Path.subpathn f t p

(* Atoms *)

type line = {
  dashed: Types.dash option;
  color: Types.color option;
  pen: Types.pen option;
  from_point: float;
  to_point: float;
  dist: Num.t;
}

type head = Point.t -> Point.t -> Command.t * Path.t

type belt = {
  clip: bool;
  rev: bool;
  point: float;
  head: head;
}

type kind = {
  lines: line list;
  belts: belt list;
}

let empty = {
  lines = [];
  belts = [];
}

let add_line ?dashed ?color ?pen ?(from_point = 0.) ?(to_point = 1.)
    ?(dist = Num.bp 0.) kind =
  { kind with lines = {
      dashed = dashed;
      color = color;
      pen = pen;
      from_point = from_point;
      to_point = to_point;
      dist = dist;
    } :: kind.lines }

let head_classic_points ?(angle = 60.) ?(size = Num.bp 4.) p dir =
  let dir = Point.scale size dir in
  let dir_a = neg (Point.rotate (angle /. 2.) dir) in
  let dir_b = neg (Point.rotate (-. angle /. 2.) dir) in
  let a = Point.add p dir_a in
  let b = Point.add p dir_b in
  a, b

let head_classic ?color ?pen ?dashed ?angle ?size p dir =
  let a, b = head_classic_points ?angle ?size p dir in
  let path = Path.pathp ~style: Path.jLine [a; p; b] in
  Command.draw ?color ?pen ?dashed path, path

let head_triangle ?color ?pen ?dashed ?angle ?size p dir =
  let a, b = head_classic_points ?angle ?size p dir in
  let path = Path.pathp ~style: Path.jLine ~cycle: Path.jLine [a; p; b] in
  let clipping_path = Path.pathp ~style: Path.jLine [a; b] in
  Command.draw ?color ?pen ?dashed path, clipping_path

let head_triangle_full ?color ?angle ?size p dir =
  let a, b = head_classic_points ?angle ?size p dir in
  let path = Path.pathp ~style: Path.jLine ~cycle: Path.jLine [a; p; b] in
  let clipping_path = Path.pathp ~style: Path.jLine [a; b] in
  Command.fill ?color path, clipping_path

let add_belt ?(clip = false) ?(rev = false) ?(point = 0.5)
    ?(head = fun x -> head_classic x) kind =
  { kind with belts = {
      clip = clip;
      rev = rev;
      point = point;
      head = head;
    } :: kind.belts }

let add_head ?head kind = add_belt ~clip: true ~point: 1. ?head kind

let add_foot ?head kind = add_belt ~clip: true ~rev: true ~point: 0. ?head kind

(* Compute the path of a line along an arrow path.
   Return the line (unchanged) and the computed path. *)
let make_arrow_line path line =
  (* TODO: use line.dist *)
  let path =
    if line.from_point <> 0. || line.to_point <> 1. then
      subpath_01 line.from_point line.to_point path
    else path
  in
  line, path

(* Compute the command and the clipping path of a belt along an arrow path.
   Return the belt (unchanged), the command and the clipping path. *)
let make_arrow_belt path belt =
  let p = point_on_path belt.point path in
  let d = normalize (direction_on_path belt.point path) in
  let d = if belt.rev then neg d else d in
  let command, clipping_path = belt.head p d in
  belt, command, clipping_path

(* Clip a line with a belt clipping path if needed. *)
let clip_line_with_belt (line, line_path) (belt, _, clipping_path) =
  let cut =
    if belt.clip then
      (if belt.rev then Path.cut_before else Path.cut_after) clipping_path
    else fun x -> x
  in
  line, cut line_path

(* Compute the command to draw a line. *)
let draw_line (line, line_path) =
  Command.draw ?color: line.color ?pen: line.pen ?dashed: line.dashed line_path

let classic = add_head (add_line empty)

let draw ?(kind = classic) ?tex ?pos path =
  let lines, belts = kind.lines, kind.belts in
  let lines = List.map (make_arrow_line path) lines in
  let belts = List.map (make_arrow_belt path) belts in
  let lines =
    List.map (fun line -> List.fold_left clip_line_with_belt line belts) lines in
  let lines = List.map draw_line lines in
  let belts = List.map (fun (_, x, _) -> x) belts in
  let labels = match tex with
    | None -> []
    | Some tex -> [Command.label ?pos (Picture.tex tex) (point_on_path 0.5 path)]
  in
  Command.seq (lines @ belts @ labels)

(* Instances *)

let triangle = add_head ~head: head_triangle (add_line empty)

let triangle_full = add_head ~head: head_triangle_full (add_line empty)

let draw2 ?kind ?tex ?pos ?outd ?ind a b =
  let r, l = outd, ind in
  draw ?kind ?tex ?pos (Path.pathk [Path.knotp ?r a; Path.knotp ?l b])
