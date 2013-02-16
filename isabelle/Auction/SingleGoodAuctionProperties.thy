(*
$Id$

Auction Theory Toolbox

Authors:
* Manfred Kerber <m.kerber@cs.bham.ac.uk>
* Christoph Lange <math.semantic.web@gmail.com>
* Colin Rowat <c.rowat@bham.ac.uk>
* Makarius Wenzel <wenzel@lri.fr>

Dually licenced under
* Creative Commons Attribution (CC-BY) 3.0
* ISC License (1-clause BSD License)
See LICENSE file for details
(Rationale for this dual licence: http://arxiv.org/abs/1107.3212)
*)

header {* Some properties that single good auctions can have *}

theory SingleGoodAuctionProperties
imports SingleGoodAuction Maximum
begin

subsection {* Efficiency *}

text{* A single good auction (this is the one we are talking about here) is efficient, if the winner is among the participants who have the
highest valuation of the good. *}
definition efficient ::
  "participants \<Rightarrow> real vector \<Rightarrow> real vector \<Rightarrow> allocation \<Rightarrow> bool" where
  "efficient n v b x \<longleftrightarrow> valuation n v \<and> bids n b \<and>
      (\<forall>i::participant \<in> {1..n}. x b i \<longrightarrow> i \<in> arg_max_set n v)"


subsection {* Equilibrium in weakly dominant strategies *}

text{* Given some auction, a strategy profile supports an equilibrium in weakly dominant strategies
  if each participant maximises its payoff by playing its component in that profile,
    whatever the other participants do. *}
definition equilibrium_weakly_dominant_strategy ::
  "participants \<Rightarrow> real vector \<Rightarrow> real vector \<Rightarrow> allocation \<Rightarrow> payments \<Rightarrow> bool" where
  (* TODO CL: note that 'bids n b' is actually redundant, as allocation and vickrey_payment require bids. *)
  "equilibrium_weakly_dominant_strategy n v b x p \<longleftrightarrow>
    valuation n v \<and> bids n b \<and> allocation n b x \<and> vickrey_payment n b p \<and> 
   (\<forall>i::participant \<in> {1..n}.
     (\<forall>whatever_bid::real vector. bids n whatever_bid \<and> whatever_bid i \<noteq> b i \<longrightarrow> (
       let i_sticks_with_bid = deviation_vec n whatever_bid b i (* here, all components are (whatever_bid j), just the i-th component remains (b i) *)
       in payoff_vector v (x i_sticks_with_bid) (p i_sticks_with_bid) i \<ge>
          payoff_vector v (x whatever_bid) (p whatever_bid) i)))"

(* TODO CL: discuss whether we should define _dominant_ in addition to _weakly_ dominant.  If so, can we refactor the definitions in some way that makes this less redundant? *)


(* unused theorems (which might nevertheless be useful for the toolbox):
   * move cursor over the word "unused_thms" for jEdit to display the list
   * This has to be at the end of the file to make sure that the whole theory has been processed. *)
unused_thms %invisible

end
