(*
$Id$

Auction Theory Toolbox

Authors:
* Manfred Kerber <m.kerber@cs.bham.ac.uk>
* Christoph Lange <c.lange@cs.bham.ac.uk>
* Colin Rowat <c.rowat@bham.ac.uk>

Dually licenced under
* Creative Commons Attribution (CC-BY) 3.0
* ISC License (1-clause BSD License)
See LICENSE file for details
(Rationale for this dual licence: http://arxiv.org/abs/1107.3212)
*)

theory SingleGoodAuction
imports Vectors

begin

section{* Preliminaries *}

text{* some types defined for our convenience *}
type_synonym participant = "nat"  (* ordinal number *)
type_synonym participants = "nat" (* cardinal number *)

text{* TODO CL: discuss whether it's intuitive to name some types as in the following lines.
However, being of one such type does not yet imply well-formedness; e.g. we could have an x::allocation, which, for some given n and b does not satisfy "allocation n b x". *}
type_synonym allocation = "real_vector \<Rightarrow> participants \<Rightarrow> bool"
type_synonym payments = "real_vector \<Rightarrow> participants \<Rightarrow> real" (* a payment vector is a function of a real_vector of bids *)

section{* Strategy (bids) *}
text{*
Strategy and strategy profile (the vector of the strategies of all participants) are not fully defined below. We ignore the distribu-
tion and density function, as they do not play a role in the proof of the theorem.
So, for now, we do not model the random mapping from a participant's valuation to its bid, but simply consider its bid as a non-
negative number that doesn't depend on anything.
*}
definition bids ::
  "participants \<Rightarrow> real_vector \<Rightarrow> bool" where
  "bids n b \<equiv> non_negative_real_vector n b"

subsection{* Deviation from a bid *}

text{* A deviation from a bid is still a well-formed bid. *}
lemma deviated_bid_well_formed :
  fixes n::participants and bid::real_vector and alternative_vec::real_vector and i::participant
  assumes bids_original: "bids n bid" and bids_alternative: "bids n alternative_vec"
  shows "bids n (deviation_vec n bid alternative_vec i)"
proof -
  let ?dev = "deviation_vec n bid alternative_vec i"
  {
    fix k::participant
    assume k_range: "k \<in> {1..n}"
    have "?dev k \<ge> 0"
    proof (cases "?dev k = bid k")
      case True
      with k_range bids_original
        show ?thesis
        unfolding deviation_def
        by (simp only: bids_def non_negative_real_vector_def)
    next
      case False
      then have "?dev k = alternative_vec k" by (auto simp add: deviation_vec_def deviation_def)
           (* "then" \<equiv> "from this", where "this" is the most recently established fact;
             note that in line with https://lists.cam.ac.uk/pipermail/cl-isabelle-users/2012-October/msg00057.html
             and for easier general comprehensibility
             we are not using the abbreviations "hence" \<equiv> "then have" and "thus" \<equiv> "then show" here. *)
        with k_range bids_alternative show ?thesis unfolding deviation_def by (simp add: bids_def non_negative_real_vector_def)
    qed
  }
  then show "bids n ?dev" unfolding bids_def non_negative_real_vector_def by simp
qed

text{* A single-good auction is a mechanism specified by a function that maps a strategy profile to an outcome. *}

section{* Allocation *}

text{* A predicate that is satisfied for exactly one member of a set *}
(* We could also have using a member_of_S predicate as the first argument, but a set is more convenient. *)
definition true_for_exactly_one_member :: "'s set \<Rightarrow> ('s \<Rightarrow> bool) \<Rightarrow> bool"
  where "true_for_exactly_one_member S pred \<equiv>
         \<exists>k . k \<in> S \<and> pred k \<and> (\<forall>j . j \<in> S \<and> j \<noteq> k \<longrightarrow> \<not>pred j)"

lemma true_for_exactly_one_member_sat :
  shows "true_for_exactly_one_member { True } (\<lambda> b::bool . b)"
  unfolding true_for_exactly_one_member_def by blast

lemma true_for_exactly_one_member_unique :
  fixes S::"'s set" and pred::"'s \<Rightarrow> bool" and satisfier::'s and j::'s
  assumes "true_for_exactly_one_member S pred"
    and "satisfier \<in> S"
    and "pred satisfier"
    and "j \<in> S"
    and "pred j"
  shows "j = satisfier"
  using assms true_for_exactly_one_member_def by metis

text{* A function x, which takes a vector of n bids, is an allocation if it returns True for one bidder and False for the others. *}
(* TODO CL: discuss whether we should use different names for "definition allocation" and "type_synonym allocation", as they denote two different things *)
(* TODO CL: record in our notes that the order of arguments of a function matters.
   Note that I, CL, reordered the arguments on 2012-08-24.
   When using the function x in a curried way, we can speak of (x b) as a vector of booleans, in a very straightforward way;
   with a different order of arguments we'd have to use (\<lambda> index::nat . x index b).
*)
definition allocation :: "participants \<Rightarrow> real_vector \<Rightarrow> allocation \<Rightarrow> bool" where 
  "allocation n b x \<equiv> bids n b \<and> 
   true_for_exactly_one_member {1..n} (x b)"

text{* An allocation function uniquely determines the winner. *}
lemma allocation_unique :
  fixes n::participants and x::allocation and b::real_vector and winner::participant and other::participant
  assumes "allocation n b x"
    and "winner \<in> {1..n}"
    and "x b winner"
    and "other \<in> {1..n}"
    and "x b other"
  shows "other = winner"
  using assms allocation_def true_for_exactly_one_member_unique by metis

section{* Payment *}

text{* Each participant pays some amount. *}
definition vickrey_payment ::
  "participants \<Rightarrow> real_vector \<Rightarrow> payments \<Rightarrow> bool" where
  "vickrey_payment n b p \<equiv> bids n b \<and> (\<forall>i:: participant. i \<in> {1..n} \<longrightarrow> p b i \<ge> 0)"

section{* Outcome *}

text{* The outcome of an auction is specified an allocation ${0, 1}^n$ and a vector of payments $R^n$
 made by each participant; we don't introduce a dedicated definition for this. *}

section{* Valuation *}

text{* Each participant has a positive valuation of the good. *}
definition valuation ::
  "participants \<Rightarrow> real_vector \<Rightarrow> bool" where
  "valuation n v \<equiv> positive_real_vector n v"

text{* Any well-formed valuation vector is a well-formed bid vector *}
lemma valuation_is_bid :
  fixes n::participants and v::real_vector
  assumes "valuation n v"
  shows "bids n v"
  using assms
  unfolding valuation_def positive_real_vector_def
  unfolding bids_def non_negative_real_vector_def
  by (simp add: order_less_imp_le)
  (* If we had been searching the library for an applicable theorem, we could have used
     find_theorems (200) "_ > _ \<Longrightarrow> _ \<ge> _" where 200 is some upper search bound,
     and would have found less_imp_le and others *)

section{* Payoff *}

(* TODO CL: Maybe define payoff as a vector altogether, and just use one definition. *)
text{* The payoff of the winner ($x_i=1$), determined by a utility function u, is the difference between its valuation and the actual
payment. For the losers, it is the negative payment. *}
(* TODO CL: ask whether there is a built-in function that converts bool to {0,1} *)
definition payoff ::
  "real \<Rightarrow> bool \<Rightarrow> real \<Rightarrow> real" where
  "payoff Valuation Allocation Payment \<equiv> Valuation * (if Allocation then 1 else 0) - Payment"

text{* For convenience in the subsequent formalisation, we also define the payoff as a vector, component-wise. *}
definition payoff_vector ::
  "real_vector \<Rightarrow> bool_vector \<Rightarrow> real_vector \<Rightarrow> participant \<Rightarrow> real" where
  "payoff_vector v concrete_x concrete_p i \<equiv> payoff (v i) (concrete_x i) (concrete_p i)"

(* unused theorems (which might nevertheless be useful for the toolbox):
   * move cursor over the word "unused_thms" for jEdit to display the list
   * This has to be at the end of the file to make sure that the whole theory has been processed. *)
unused_thms

end
