open Mlpost
open Num
open Command
open Point
open Path
open Helpers

let cmp x y = SimplePoint.cmp (x, y)

let fig = 
  let a = Box.circle (cmp 0. 0.) (Picture.tex "$\\sqrt2$") in
  let b = Box.rect (cmp 2. 0.) (Picture.tex "$\\pi$") in
  let pen = Pen.transform [Transform.scaled 3.] Pen.default in
  [ draw_box a;
    draw_box ~fill:Color.purple b;
    draw
      ~color:Color.red
      (Path.transform [Transform.shifted (cmp 1. 1.)] (Path.bpath a));
    draw_label_arrow ~color:Color.orange ~pen 
      ~pos:Pupright (Picture.tex "foo") (Box.west a) (Box.south_east b);
    box_simple_arrow ~color:Color.blue a b;
  ]
