open Mlpost
open Tree

let fig =
  draw (node "1" [node "2" [leaf "4"; leaf "5"]; 
		  node "3" [leaf "6"; leaf "7"]])