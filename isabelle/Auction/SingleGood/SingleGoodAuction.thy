(*
Auction Theory Toolbox (http://formare.github.io/auctions/)

Authors:
* Manfred Kerber <mnfrd.krbr@gmail.com>
* Christoph Lange <math.semantic.web@gmail.com>
* Colin Rowat <c.rowat@bham.ac.uk>
* Makarius Wenzel <wenzel@lri.fr>

Dually licenced under
* Creative Commons Attribution (CC-BY) 3.0
* ISC License (1-clause BSD License)
See LICENSE file for details
(Rationale for this dual licence: http://arxiv.org/abs/1107.3212)
*)

header {* Single good auctions *}

theory SingleGoodAuction
(* TODO CL: consider renaming as per https://github.com/formare/auctions/issues/16 *)
imports Complex_Main Vectors
begin

subsection {* Preliminaries *}

text{* convenience type synonyms for most of the basic concepts we are dealing with *}

type_synonym participant = index

type_synonym valuations = "real vector"
type_synonym bids = "real vector"
type_synonym allocation = "real vector"
type_synonym payments = "real vector"


text{* Initially we'd like to formalise any single good auction as a relation of bids and outcome.
  Proving the well-definedness of an auction is then a separate step in the auction design process.
  It involves:
  \begin{enumerate}
  \item checking that the allocation and payments vectors actually meet our expectation of an allocation or payment,
    as defined by the @{term allocation_def} predicate below, and auction-specific payment predicates
  \item checking that the relation actually is a function, i.e. that it is
    \begin{enumerate}
    \item left-total (@{term sga_left_total}): ``for any admissible bids \dots''
    \item right-unique (@{term sga_right_unique}): ``\dots there is a unique outcome.''
    \end{enumerate}
  \end{enumerate}
*}
type_synonym single_good_auction = "((participant set \<times> bids) \<times> (allocation \<times> payments)) set"

subsection {* Valuation *}

definition valuations :: "participant set \<Rightarrow> valuations \<Rightarrow> bool"
  where "valuations N v \<longleftrightarrow> positive N v"

subsection {* Strategy (bids) *}

definition bids :: "participant set \<Rightarrow> bids \<Rightarrow> bool"
  where "bids N b \<longleftrightarrow> non_negative N b"

lemma valuation_is_bid: "valuations N v \<Longrightarrow> bids N v"
  by (simp only: valuations_def positive_def bids_def non_negative_def)

subsection {* Admissible input *}

type_synonym input_admissibility = "participant set \<Rightarrow> bids \<Rightarrow> bool"

text {* Admissible input (i.e.\ admissible bids, given the participants).  As we represent
  @{typ bids} as functions, which are always total in Isabelle/HOL, we can't simply test, e.g., whether
  their domain is @{term N} for the given participants @{term N}.  Therefore
  we test whether the function returns a value within some set. *}
(* CL: Once we realise general/special auctions using locales, we need an admissible_input axiom. *)
definition admissible_input :: "participant set \<Rightarrow> bids \<Rightarrow> bool"
where "admissible_input N b \<longleftrightarrow> bids N b"

subsection {* Allocation *}

(* CL: changed for case checker: From now on, we merely assume that an allocation is a vector 
       of reals that sum up to 1, i.e. this allows for a divisible good,
       and we no longer assume that it is a function of the bids.
       This will make it easier for us to ``overlook'' cases in the definitions of concrete auctions ;-)
   CL@CR: I see that in your paper formalisation you had already defined the allocation as 
          a vector of {0,1} with exactly one 1.  *)
text{* We employ the general definition of an allocation for a divisible single good.
  This is to allow for more possibilities of an auction to be not well-defined.
  Also, it is no longer the allocation that we model as a function of the bid, but instead we model
  the \emph{auction} as a relation of bids to a @{typ "allocation \<times> payments"} outcome. *}
(* text_raw{*\snip{allocation_def}{1}{2}{%*} *)
definition allocation :: "participant set \<Rightarrow> allocation \<Rightarrow> bool"
  where "allocation N x \<longleftrightarrow> non_negative N x \<and> (\<Sum> i \<in> N . x i) = 1"
(* text_raw{*}%endsnip*} *)

subsection {* Payoff *}

definition payoff :: "real \<Rightarrow> real \<Rightarrow> real \<Rightarrow> real"
  where "payoff v x p = v * x - p"

text {* A general single good auction in predicate form.
  To give the auction designer flexibility (including the possibility to introduce mistakes),
  we only constrain the left hand side of the relation, as to cover admissible inputs.
  This definition makes sure that whenever we speak of a single good auction, there is an
  admissible input on the left hand side.  In other words, this predicate returns false for relations having left
  hand side entries that are known not to be admissible inputs.
  For this and other reasons (including Isabelle's difficulties to handle complex set comprehensions)
  it is more convenient to treat the auction as a predicate over all of
  its arguments, instead of a left-hand-side/right-hand-side relation.*}
definition sga_pred :: "participant set \<Rightarrow> bids \<Rightarrow> allocation \<Rightarrow> payments \<Rightarrow> bool"
  where
    "sga_pred N b x p \<longleftrightarrow> admissible_input N b"

text {* We construct the relational form of an auction from the predicate form @{const sga_pred}: given a 
  predicate that defines an auction by telling us for all possible arguments whether they 
  form an @{term "(input, outcome)"} pair according to the auction's definition, we construct a predicate
  that tells us whether all @{term "(input, outcome)"} pairs in a given relation satisfy that predicate,
  i.e.\ whether the given relation is an auction of the desired type. *}
definition rel_sat_sga_pred ::
  "(participant set \<Rightarrow> bids \<Rightarrow> allocation \<Rightarrow> payments \<Rightarrow> bool) \<Rightarrow> single_good_auction \<Rightarrow> bool"
  where "rel_sat_sga_pred pred A \<longleftrightarrow> (\<forall> ((N, b), (x, p)) \<in> A . pred N b x p)"

text {* A variant of @{const rel_sat_sga_pred}: We construct a predicate that tells us whether the
  given relation comprises \emph{all} @{term "(input, outcome)"} pairs that satisfy the given auction predicate, 
  i.e.\ whether the given relation comprises all possible auctions of the desired type.  *}
definition rel_all_sga_pred ::
  "(participant set \<Rightarrow> bids \<Rightarrow> allocation \<Rightarrow> payments \<Rightarrow> bool) \<Rightarrow> single_good_auction \<Rightarrow> bool"
  where "rel_all_sga_pred pred A \<longleftrightarrow> (\<forall> N b x p . ((N, b), (x, p)) \<in> A \<longleftrightarrow> pred N b x p)"

text {* relational form of a single good auction *}
definition single_good_auction :: "single_good_auction \<Rightarrow> bool"
  where "single_good_auction = rel_sat_sga_pred sga_pred"

end
