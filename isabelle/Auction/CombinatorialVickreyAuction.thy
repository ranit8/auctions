(*
$Id: nVCG_CaseChecker.thy 1448 2013-08-08 18:14:23Z langec $

Auction Theory Toolbox

Authors:
* Manfred Kerber <m.kerber@cs.bham.ac.uk>
* Christoph Lange <math.semantic.web@gmail.com>
* Colin Rowat <c.rowat@bham.ac.uk>
* Marco B. Caminati <marco.caminati@gmail.com>

Dually licenced under
* Creative Commons Attribution (CC-BY) 3.0
* ISC License (1-clause BSD License)
See LICENSE file for details
(Rationale for this dual licence: http://arxiv.org/abs/1107.3212)
*)

header {* code generation setup for combinatorial Vickrey auction *}

theory CombinatorialVickreyAuction
imports nVCG_CaseChecker
  "~~/src/HOL/Library/Efficient_Nat"
begin

code_include Scala ""
{*package CombinatorialVickreyAuction
*}
export_code winning_allocations_comp_CL payments_comp_workaround in Scala
(* In SML, OCaml and Scala "file" is a file name; in Haskell it's a directory name ending with / *)
file "code/generated/CombinatorialVickreyAuction.scala"

end
