(*
Auction Theory Toolbox (http://formare.github.io/auctions/)

Authors:
* Manfred Kerber <mnfrd.krbr@gmail.com>
* Christoph Lange <math.semantic.web@gmail.com>
* Colin Rowat <c.rowat@bham.ac.uk>
* Marco B. Caminati <marco.caminati@gmail.com>

Dually licenced under
* Creative Commons Attribution (CC-BY) 3.0
* ISC License (1-clause BSD License)
See LICENSE file for details
(Rationale for this dual licence: http://arxiv.org/abs/1107.3212)
*)

header {* combinatorial Vickrey auction *}

theory CombinatorialVickreyAuction
imports
  CombinatorialAuction
  CombinatorialAuctionTieBreaker
  Maximum

begin

section {* value-maximising allocation (for winner determination) *}

text {* the set of value-maximising allocations (according to the bids submitted), i.e.\ the ``arg max''
  of @{const value_rel} on the set of all possible allocations *}
definition winning_allocations_rel :: "goods \<Rightarrow> participant set \<Rightarrow> bids \<Rightarrow> allocation_rel set"
where "winning_allocations_rel G N b = arg_max' (value_rel b) (possible_allocations_rel G N)"

(* CL: probably not needed, neither for close-to-paper nor for computable version
definition winning_allocations_fun :: "goods \<Rightarrow> participant set \<Rightarrow> bids \<Rightarrow> allocation_fun set"
where "winning_allocations_fun G N b = 
{ (Y,potential_buyer) . value_fun b (Y,potential_buyer) = max_value G N b }"
*)

text {* the unique winning allocation that remains from @{const winning_allocations_rel} after
  tie-breaking (assuming relational allocations) *}
fun winning_allocation_rel :: "goods \<Rightarrow> participant set \<Rightarrow> tie_breaker_rel \<Rightarrow> bids \<Rightarrow> allocation_rel"
where "winning_allocation_rel G N t b = t (winning_allocations_rel G N b)"

(* CL: probably not needed, neither for close-to-paper nor for computable version
definition winning_allocation_fun :: "goods \<Rightarrow> participant set \<Rightarrow> tie_breaker_fun \<Rightarrow> bids \<Rightarrow> allocation_fun"
where "winning_allocation_fun G N t b = t (winning_allocations_fun G N b)"
*)

text {* algorithmic version of @{const winning_allocations_rel} *}
fun winning_allocations_alg_CL :: "goods \<Rightarrow> participant set \<Rightarrow> bids \<Rightarrow> allocation_rel list"
where "winning_allocations_alg_CL G N b = (arg_max_alg_list
    (possible_allocations_alg G N)
    (value_rel b))"

text {* alternative algorithmic version of @{const winning_allocations_rel} *}
fun winning_allocations_alg_MC :: "goods \<Rightarrow> participant set \<Rightarrow> bids \<Rightarrow> allocation_rel list"
where "winning_allocations_alg_MC G N b = (let all = possible_allocations_alg G N in
  map (nth all) (max_positions (map (value_rel b) all)))"

text {* algorithmic version of @{const winning_allocation_rel} *}
fun winning_allocation_alg_CL :: "goods \<Rightarrow> participant set \<Rightarrow> tie_breaker_alg \<Rightarrow> bids \<Rightarrow> allocation_rel"
where "winning_allocation_alg_CL G N t b = t (winning_allocations_alg_CL G N b)"

text {* alternative algorithmic version of @{const winning_allocation_rel} *}
fun winning_allocation_alg_MC :: "goods \<Rightarrow> participant set \<Rightarrow> tie_breaker_alg \<Rightarrow> bids \<Rightarrow> allocation_rel"
where "winning_allocation_alg_MC G N t b = t (winning_allocations_alg_MC G N b)"

text {* payments *}

text {* the maximum sum of bids of all bidders except bidder @{text n}'s bid, computed over all possible allocations of all goods,
  i.e. the value reportedly generated by value maximization problem when solved without n's bids *}
fun \<alpha> :: "goods \<Rightarrow> participant set \<Rightarrow> bids \<Rightarrow> participant \<Rightarrow> price"
where "\<alpha> G N b n = Max ((value_rel b) ` (possible_allocations_rel G (N - {n})))"

text {* algorithmic version of @{text \<alpha>} *}
fun \<alpha>_alg :: "goods \<Rightarrow> participant set \<Rightarrow> bids \<Rightarrow> participant \<Rightarrow> price"
where "\<alpha>_alg G N b n = maximum_alg_list (possible_allocations_alg G (N - {n})) (value_rel b)"

(* CL: probably not needed, neither for close-to-paper nor for computable version
definition winners'_goods_fun :: "goods \<Rightarrow> participant set \<Rightarrow> tie_breaker_fun \<Rightarrow> bids \<Rightarrow> participant option \<Rightarrow> goods" 
where "winners'_goods_fun G N t b = inv (snd (winning_allocation_fun G N t b))"
*)

(* CL: probably not needed, neither for close-to-paper nor for computable version
definition remaining_value_fun :: "goods \<Rightarrow> participant set \<Rightarrow> tie_breaker_fun \<Rightarrow> bids \<Rightarrow> participant \<Rightarrow> price"
where "remaining_value_fun G N t b n =
  (\<Sum> m \<in> N - {n} . b m (winners'_goods_fun G N t b (Some m)))"
*)

text {* the sum of bids of all bidders except bidder @{text n} on those goods that they actually get,
  according to the winning allocation *}
fun remaining_value_rel :: "goods \<Rightarrow> participant set \<Rightarrow> tie_breaker_rel \<Rightarrow> bids \<Rightarrow> participant \<Rightarrow> price"
where "remaining_value_rel G N t b n =
  (\<Sum> m \<in> N - {n} . b m (eval_rel_or ((winning_allocation_rel G N t b)\<inverse>) m {}))"

text {* algorithmic version of @{text remaining_value_rel} *}
fun remaining_value_alg :: "goods \<Rightarrow> participant set \<Rightarrow> tie_breaker_alg \<Rightarrow> bids \<Rightarrow> participant \<Rightarrow> price"
where "remaining_value_alg G N t b n =
  (\<Sum> m \<in> N - {n} . b m (eval_rel_or
    (* When a participant doesn't gain any goods, there is no participant \<times> goods pair in this relation,
       but we interpret this case as if 'the empty set' had been allocated to the participant. *)
    ( 
      (* the winning allocation after tie-breaking: a goods \<times> participant relation, which we have to invert *)
      (winning_allocation_alg_CL G N t b)\<inverse>)
    m (* evaluate the relation for participant m *)
    {} (* return the empty set if nothing is in relation with m *)
  ))"

(* CL: probably not needed, neither for close-to-paper nor for computable version
definition payments_fun :: "goods \<Rightarrow> participant set \<Rightarrow> tie_breaker_fun \<Rightarrow> bids \<Rightarrow> participant \<Rightarrow> price"
where "payments_fun G N t = \<alpha> G N - remaining_value_fun G N t"
*)

text {* the payments per bidder *}
fun payments_rel :: "goods \<Rightarrow> participant set \<Rightarrow> tie_breaker_rel \<Rightarrow> bids \<Rightarrow> participant \<Rightarrow> price"
where "payments_rel G N t = \<alpha> G N - remaining_value_rel G N t"

text {* algorithmic version of @{text payments_rel} *}
fun payments_alg :: "goods \<Rightarrow> participant set \<Rightarrow> tie_breaker_alg \<Rightarrow> bids \<Rightarrow> participant \<Rightarrow> price"
where "payments_alg G N t = \<alpha>_alg G N - remaining_value_alg G N t"

text {* alternative algorithmic version of @{text payments_rel}, working around an Isabelle2013 bug *}

section {* the Combinatorial Vickrey Auction in relational form *}

(* TODO CL: revise the following as per https://github.com/formare/auctions/issues/35 *)

(* TODO CL: we may need nVCG-specific notions of "valid input" *)

text {* combinatorial Vickrey auction in predicate form, where the outcome is obtained from input according to the definitions above. *}
definition nVCG_pred :: "tie_breaker_rel \<Rightarrow> goods \<Rightarrow> participant set \<Rightarrow> bids \<Rightarrow> allocation_rel \<Rightarrow> payments \<Rightarrow> bool"
where "nVCG_pred t G N b x p \<longleftrightarrow>
  x = winning_allocation_rel G N t b \<and>
  p = payments_rel G N t b"

text {* Checks whether a combinatorial auction in relational form, given some tie-breaker,
  satisfies @{const nVCG_pred}, i.e.\ is a combinatorial Vickrey auction.
  For such a relational form we need to show that, given an arbitrary but fixed tie-breaker,
  for each valid input, there is a unique, well-defined outcome. *}
definition nVCG_auction :: "tie_breaker_rel \<Rightarrow> combinatorial_auction_rel \<Rightarrow> bool"
where "nVCG_auction t = rel_sat_pred (nVCG_pred t)"

text {* The combinatorial Vickrey auction in relational form *}
definition nVCG_auctions :: "tie_breaker_rel \<Rightarrow> combinatorial_auction_rel"
where "nVCG_auctions t = rel_all (nVCG_pred t)"

end

