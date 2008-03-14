open Mlpost
open Command

let a = Point.p (Num.bp 0., Num.bp 0.)
let pen = Pen.transform [Transform.scaled ~scale:Num.bp 4.] Pen.circle
let fig = [
  draw (SimplePath.pathp [a]) ~pen;
  label ~pos:Ptop (Picture.tex "Au dessus") a;
  label ~pos:Pbot (Picture.tex "En dessous") a;
  label ~pos:Pright (Picture.tex "\\`A droite") a;
  label ~pos:Pleft (Picture.tex "\\`A gauche") a;
]