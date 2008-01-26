type numtype = BP | PT | CM | MM | IN

val draw : 
    ?style:Path.joint -> ?cycle:bool -> ?scale:numtype -> 
      (float * float) list -> Path.command

val path : 
    ?style:Path.joint -> ?cycle:bool -> ?scale:numtype -> 
      (float * float) list -> Path.t

val jointpath : 
    ?scale:numtype -> (float * float) list -> Path.joint list -> Path.t

val p :
    ?l:Path.direction -> ?r:Path.direction -> 
      ?scale:numtype -> float * float -> Path.knot
