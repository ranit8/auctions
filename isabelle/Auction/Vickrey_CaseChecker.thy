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

header {* Vickrey's Theorem: second price auctions are
  efficient, and truthful bidding is a weakly dominant strategy --
  copy to experiment with ``case checking'' *}

theory Vickrey_CaseChecker
imports Complex_Main
begin

section {* Single good auctions *}

subsection {* Preliminaries *}

type_synonym participant = nat
type_synonym participants = "nat set"

type_synonym 'a vector = "participant \<Rightarrow> 'a"

definition non_negative_real_vector :: "participants \<Rightarrow> real vector \<Rightarrow> bool"
  where "non_negative_real_vector N v \<longleftrightarrow> (\<forall>i \<in> N. v i \<ge> 0)"

definition positive_real_vector :: "participants \<Rightarrow> real vector \<Rightarrow> bool"
  where "positive_real_vector N v \<longleftrightarrow> (\<forall>i \<in> N. v i > 0)"

text{* convenience type synonyms for most of the basic concepts we are dealing with *}
type_synonym valuations = "real vector"
type_synonym bids = "real vector"
type_synonym allocation = "real vector"
type_synonym payments = "real vector"

(* TODO CL: link to "function" theorems from this text *)
text{* Initially we'd like to formalise any single good auction as a relation of bids and outcome.
  Proving the well-definedness of an auction is then a separate step in the auction design process.
  It involves:
  \begin{enumerate}
  \item checking that the allocation and payments vectors actually meet our expectation of an allocation or payment,
    as defined by the @{term allocation_def} and @{term vickrey_payment} predicates below
  \item checking that the relation actually is a function, i.e. that it is
    \begin{enumerate}
    \item left-total: ``for any admissible bids \dots''
    \item right-unique: ``\dots there is a unique outcome.''
    \end{enumerate}
  \end{enumerate}
*}
type_synonym single_good_auction = "((participants \<times> bids) \<times> (allocation \<times> payments)) set"

subsection {* Valuation *}

definition valuations :: "participants \<Rightarrow> valuations \<Rightarrow> bool"
  where "valuations N v \<longleftrightarrow> positive_real_vector N v"

subsection {* Strategy (bids) *}

definition bids :: "participants \<Rightarrow> bids \<Rightarrow> bool"
  where "bids N b \<longleftrightarrow> non_negative_real_vector N b"

lemma valuation_is_bid: "valuations N v \<Longrightarrow> bids N v"
  by (auto simp add: valuations_def positive_real_vector_def bids_def non_negative_real_vector_def)

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
  the \emph{auction} as a relation of bids to a @{text "(allocation \<times> payments)"} outcome. *}
(* text_raw{*\snip{allocation_def}{1}{2}{%*} *)
definition allocation :: "participants \<Rightarrow> allocation \<Rightarrow> bool"
  where "allocation N x \<longleftrightarrow> (\<Sum> i \<in> N . x i) = 1"
(* text_raw{*}%endsnip*} *)

subsection {* Payment *}

text{* Same as with the @{text allocation} we now model this as a plain vector. *}
definition vickrey_payment :: "participants \<Rightarrow> payments \<Rightarrow> bool"
  where "vickrey_payment N p \<longleftrightarrow> (\<forall>i \<in> N . p i \<ge> 0)"

subsection {* Payoff *}

definition payoff :: "real \<Rightarrow> real \<Rightarrow> real \<Rightarrow> real"
  where "payoff v x p = v * x - p"

text{* To give the auction designer flexibility (including the possibility to introduce mistakes),
  we only constrain the left hand side of the relation, as to cover admissible @{text bids}.
  This definition makes sure that whenever we speak of a single good auction, there is a bid vector
  on the left hand side.  In other words, this predicate returns false for relations having left
  hand side entries that are known not to be bid vectors.
  For this and other purposes it is more convenient to treat the auction as a predicate over all of
  its arguments, instead of a left-hand-side/right-hand-side relation.*}
definition sga_pred :: "participants \<Rightarrow> bids \<Rightarrow> allocation \<Rightarrow> payments \<Rightarrow> bool"
  where
    "sga_pred N b x p \<longleftrightarrow> bids N b"

text{* We construct the relational version of an auction from the predicate version: given a 
  predicate that defines an auction by telling us for all possible arguments whether they 
  form an (input, outcome) pair according to the auction's definition, we construct a predicate
  that tells us whether all (input, outcome) pairs in a given relation satisfy that predicate,
  i.e. whether the given relation is an auction of the desired type. *}
definition rel_sat_sga_pred ::
  "(participants \<Rightarrow> bids \<Rightarrow> allocation \<Rightarrow> payments \<Rightarrow> bool) \<Rightarrow> single_good_auction \<Rightarrow> bool"
  where "rel_sat_sga_pred pred A \<longleftrightarrow> (\<forall> ((N, b), (x, p)) \<in> A . pred N b x p)"

text{* A variant of @{text rel_sat_sga_pred}: We construct a predicate that tells us whether the
  given relation comprises all (input, outcome) pairs that satisfy the given auction predicate, 
  i.e. whether the given relation comprises all possible auctions of the desired type.  *}
definition rel_all_sga_pred ::
  "(participants \<Rightarrow> bids \<Rightarrow> allocation \<Rightarrow> payments \<Rightarrow> bool) \<Rightarrow> single_good_auction \<Rightarrow> bool"
  where "rel_all_sga_pred pred A \<longleftrightarrow> (\<forall> N b x p . ((N, b), (x, p)) \<in> A \<longleftrightarrow> pred N b x p)"

text{* Now for the relational version of the single good auction: *}
definition single_good_auction :: "single_good_auction \<Rightarrow> bool"
  where "single_good_auction A = rel_sat_sga_pred sga_pred A"

text{* In the general case, by ``well-defined outcome'' we mean that the good gets properly 
  allocated w.r.t. the definition of an @{text allocation}.  We are not constraining the payments
  at this point. *}
definition sga_well_defined_outcome_pred :: "participants \<Rightarrow> bids \<Rightarrow> allocation \<Rightarrow> payments \<Rightarrow> bool"
  where
    "sga_well_defined_outcome_pred N b x p \<longleftrightarrow> allocation N x"

definition sga_well_defined_outcome :: "single_good_auction \<Rightarrow> bool"
  where
    "sga_well_defined_outcome A \<longleftrightarrow>
      (\<forall> ((N::participants, b::bids), (x::allocation, p::payments)) \<in> A .
        sga_well_defined_outcome_pred N b x p)"

type_synonym input_admissibility = "participants \<Rightarrow> bids \<Rightarrow> bool"

text{* Left-totality of an auction defined as a relation: for each admissible bid vector
  there exists some outcome (not necessarily unique). *}
definition sga_left_total :: "single_good_auction \<Rightarrow> input_admissibility \<Rightarrow> bool"
  where "sga_left_total A admissible \<longleftrightarrow>
    (\<forall> (N :: participants) (b :: bids) . admissible N b \<longrightarrow>
      (\<exists> (x :: allocation) (p :: payments) . ((N, b), (x, p)) \<in> A))"

type_synonym outcome_equivalence = "participants \<Rightarrow> bids \<Rightarrow> allocation \<Rightarrow> payments \<Rightarrow> allocation \<Rightarrow> payments \<Rightarrow> bool"

text{* Right-uniqueness of an auction defined as a relation: for each admissible bid vector,
  if there is an outcome, it is unique. *}
(* TODO CL: same as for allowing an admissibility predicate (instead of considering _all_ 
   possible inputs), allow for speaking of "uniqueness modulo <something>".

   CL@CR,@PC: In the second price auction what could this <something> be,
   if defined as weakly as possible, and in a practically useful way,
   i.e. without making the mistake of restating the auction's definition once more?
   How about "if the good gets allocated to i and i' both must have made the same bid?"
   and "if the payments of p and p' are non-zero, both must have made the same bid?"

   OK, we see that the equivalence of outcomes will in practice be defined dependently on the input. *)
definition sga_right_unique :: "single_good_auction \<Rightarrow> input_admissibility \<Rightarrow> outcome_equivalence \<Rightarrow> bool"
  where "sga_right_unique A admissible equivalent \<longleftrightarrow>
    (\<forall> (N :: participants) (b :: bids) . admissible N b \<longrightarrow>
      (\<forall> (x :: allocation) (x' :: allocation) (p :: payments) (p' :: payments) .
        ((N, b), (x, p)) \<in> A \<and> ((N, b), (x', p')) \<in> A \<longrightarrow> equivalent N b x p x' p'))"

definition sga_function :: "single_good_auction \<Rightarrow> input_admissibility \<Rightarrow> outcome_equivalence \<Rightarrow> bool"
  where "sga_function A admissible equivalent \<longleftrightarrow>
    sga_left_total A admissible \<and> sga_right_unique A admissible equivalent"

subsection {* Maximum *}
text{* This subsection uses Isabelle's set maximum functions, wrapping them for our use. *}

definition maximum_defined :: "participants \<Rightarrow> bool"
  where "maximum_defined N \<longleftrightarrow> card N > 0"

lemma maximum_except_defined:
  fixes N i
  assumes "i \<in> N" "card N > 1"
  shows "maximum_defined (N - {i})"
  using assms maximum_defined_def
  by (smt card.remove card_infinite)

definition maximum :: "participants \<Rightarrow> real vector \<Rightarrow> real"
  where "maximum N y = Max (y ` N)"

lemma maximum_equal:
  fixes N :: participants and y :: "real vector" and z :: "real vector"
  assumes "\<forall>i \<in> N. y i = z i"
  shows "maximum N y = maximum N z"
proof -
  have "y ` N = z ` N" by (rule image_cong) (auto simp add: assms)
  then show ?thesis unfolding maximum_def by simp
qed

lemma maximum_is_greater_or_equal:
  fixes N :: participants and y :: "real vector" and i :: participant
  assumes "maximum_defined N"
    and "i \<in> N"
  shows "maximum N y \<ge> y i"
  using assms unfolding maximum_defined_def maximum_def by (simp add: card_gt_0_iff)

lemma maximum_is_component:
  fixes N :: participants and y :: "real vector"
  assumes defined: "maximum_defined N"
  shows "\<exists>i \<in> N. maximum N y = y i"
proof -
  let ?A = "y ` N"
  from defined have "finite ?A" and "?A \<noteq> {}"
    unfolding maximum_defined_def by (simp_all add: card_gt_0_iff)
  then have "Max ?A \<in> ?A" by (rule Max_in)
  then obtain i where "i \<in> N" and "Max ?A = y i" by blast
  with maximum_def show ?thesis by auto
qed

lemma maximum_sufficient:
  fixes N :: participants and y :: "real vector" and m :: real
  assumes defined: "maximum_defined N"
    and greater_or_equal: "\<forall>i \<in> N. m \<ge> y i"
    and is_component: "\<exists>i \<in> N. m = y i"
  shows "maximum N y = m"
  unfolding maximum_def
proof -
  let ?A = "y ` N"
  show "Max ?A = m"
  proof (rule Max_eqI)
    from defined show "finite ?A"
      unfolding maximum_defined_def by (simp add: card_gt_0_iff)
    show "m \<in> ?A" using is_component by blast
    fix a assume "a \<in> ?A"
    then show "a \<le> m" using greater_or_equal by blast
  qed
qed

definition arg_max_set :: "participants \<Rightarrow> real vector \<Rightarrow> participants"
  where "arg_max_set N b = {i. i \<in> N \<and> maximum N b = b i}"

lemma maximum_except_is_greater_or_equal:
  fixes N :: participants and y :: "real vector" and j :: participant and i :: participant
  assumes defined: "maximum_defined N"
    and i: "i \<in> N \<and> i \<noteq> j"
  shows "maximum (N - {j}) y \<ge> y i"
proof -
  let ?M = "N - {j}"
  let ?A = "y ` ?M"
  from i have *: "i \<in> ?M" by simp
  with defined have "finite ?A" and "?A \<noteq> {}"
    unfolding maximum_defined_def by (auto simp add: card_gt_0_iff)
  with * have "Max ?A \<ge> y i" by (auto simp add: Max_ge_iff)
  then show ?thesis unfolding maximum_def .
qed

lemma maximum_remaining_maximum:
  fixes N :: participants and y :: "real vector" and j :: participant
  assumes defined': "maximum_defined (N - {j})"
    and j_max: "y j = maximum N y"
  shows "y j \<ge> maximum (N - {j}) y"
proof -
  have "y ` (N - {j}) \<subseteq> y ` N" by blast
  with defined' have "maximum (N - {j}) y \<le> maximum N y"
    unfolding maximum_def maximum_defined_def by (simp add: card_gt_0_iff Max_mono)
  also note j_max [symmetric]
  finally show ?thesis .
qed

lemma remaining_maximum_invariant:
  fixes N :: participants and y :: "real vector" and i :: participant and a :: real
  shows "maximum (N - {i}) (y(i := a)) = maximum (N - {i}) y"
proof -
  let ?M = "N - {i}"
  have "y ` ?M = (y(i := a)) ` ?M" by auto
  then show ?thesis unfolding maximum_def by simp
qed

subsection {* Second price single good auctions and some of their properties *}

definition second_price_auction_winner ::
    "participants \<Rightarrow> bids \<Rightarrow> allocation \<Rightarrow> payments \<Rightarrow> participant \<Rightarrow> bool"
  where
    "second_price_auction_winner N b x p i \<longleftrightarrow>
      i \<in> N \<and> i \<in> arg_max_set N b \<and> x i = 1 \<and> p i = maximum (N - {i}) b"

definition second_price_auction_loser ::
    "participants \<Rightarrow> allocation \<Rightarrow> payments \<Rightarrow> participant \<Rightarrow> bool"
  where "second_price_auction_loser N x p i \<longleftrightarrow> i \<in> N \<and>
     x i = 0 \<and>
     p i = 0"

definition spa_pred :: "participants \<Rightarrow> bids \<Rightarrow> allocation \<Rightarrow> payments \<Rightarrow> bool"
  where
    "spa_pred N b x p \<longleftrightarrow>
      bids N b \<and>
      (\<exists>i \<in> N. second_price_auction_winner N b x p i \<and>
        (\<forall>j \<in> N . j \<noteq> i \<longrightarrow> second_price_auction_loser N x p j))"

definition second_price_auction :: "single_good_auction \<Rightarrow> bool"
  where "second_price_auction A = rel_sat_sga_pred spa_pred A"

text{* definition of a second price auction, projected to the allocation *}
lemma spa_allocation :
  fixes N :: participants and b :: bids
    and x :: allocation and p :: payments
  assumes "spa_pred N b x p"
  shows "\<exists> i \<in> N . x i = 1 \<and> (\<forall> j \<in> N . j \<noteq> i \<longrightarrow> x j = 0)"
  using assms
  unfolding spa_pred_def second_price_auction_def second_price_auction_winner_def second_price_auction_loser_def
  by metis

text{* Our second price auction (@{text spa_pred}) is well-defined in that its outcome is an allocation. *}
lemma spa_allocates :
  fixes N :: participants and b :: bids
    and x :: allocation and p :: payments
  assumes spa: "spa_pred N b x p"
      and finite: "finite N"
  shows "allocation N x"
proof -
  from spa obtain i where i_def: "i \<in> N \<and> x i = 1" using spa_allocation by blast
  (* the losers' allocations are all 0 *)
  with spa have "\<forall>j \<in> N - {i} . x j = 0" using spa_allocation by (metis member_remove remove_def)
  then have "(\<Sum> k \<in> N . x k) = 1" using finite i_def by (metis comm_monoid_add_class.add.right_neutral setsum.F_neutral' setsum.remove)
  then show ?thesis unfolding allocation_def by simp
qed

lemma spa_well_defined_sga :
  fixes N :: participants and b :: bids
    and x :: allocation and p :: payments
  assumes spa: "spa_pred N b x p"
      and finite: "finite N"
  shows "sga_well_defined_outcome_pred N b x p"
  using assms spa_allocates unfolding allocation_def sga_well_defined_outcome_pred_def by simp

text{* definition of a second price auction, projected to the payments *}
lemma spa_payments :
  fixes N :: participants and b :: bids
    and x :: allocation and p :: payments
  assumes "spa_pred N b x p"
  shows "\<exists> i \<in> N . p i = maximum (N - {i}) b \<and> (\<forall> j \<in> N . j \<noteq> i \<longrightarrow> p j = 0)"
  using assms
  unfolding spa_pred_def second_price_auction_def second_price_auction_winner_def second_price_auction_loser_def
  by metis

(* TODO CL: In the general auction case it may make sense to check that the payments (including the seller's payment)
   sum up to 0.
*)
text{* Our second price auction (@{text spa_pred}) is well-defined in that its outcome specifies non-negative payments for everyone. *}
lemma spa_vickrey_payment :
  fixes N :: participants and b :: bids
    and x :: allocation and p :: payments
  assumes spa: "spa_pred N b x p"
      and card_N: "card N > 1"
  shows "vickrey_payment N p"
proof -
  from card_N have maximum_defined: "maximum_defined N" unfolding maximum_defined_def by auto
  from spa obtain i where i_range: "i \<in> N"
    and i_pay: "p i = maximum (N - {i}) b"
    and losers_pay: "\<forall> j \<in> N . j \<noteq> i \<longrightarrow> p j = 0"
    using spa_payments by blast
  (* Note that if "card N = 1" were allowed, there would be no such k.  This seems fine for now,
     but in the next step it becomes apparent what we need "card N = 1" and thus this k_def for:
     for obtaining the fact `greater`, which talks about the second-highest bid and assumes 
     that it is defined. *)
  from card_N and i_range obtain k where k_def: "k \<in> N \<and> k \<noteq> i" 
    by (metis all_not_in_conv card.insert card_empty ex_least_nat_le finite.emptyI insertCI le0 monoid_add_class.add.right_neutral nonempty_iff not_less)
  from k_def and maximum_defined have greater: "maximum (N - {i}) b \<ge> b k" using maximum_except_is_greater_or_equal by blast
  also have "\<dots> \<ge> 0" using spa spa_pred_def second_price_auction_def bids_def non_negative_real_vector_def by (smt greater k_def)
  with i_pay and calculation have "p i \<ge> 0" by simp
  with i_range and losers_pay have "\<forall> k \<in> N . p k \<ge> 0" by auto
  with vickrey_payment_def show ?thesis by blast
qed

definition spa_admissible_input :: "participants \<Rightarrow> bids \<Rightarrow> bool"
  where "spa_admissible_input N b \<longleftrightarrow> card N > 1 \<and> bids N b"

(* TODO CL: This lemma also works when admissibility is defined as "card N > 0" because
   when we compute the second-highest bid for the payments vector, card N = 0 will 
   boil down to the question of whether Max {} exists.  Isabelle says that it exists; to see this try

lemma max_exists : "\<exists>x . x = Max {}" by blast

  This is an inherent trait of Isabelle's HOL implementation: all functions are total in principle, 
  just sometimes underspecified, so that you don't know _what_ "Max {}" is.  To see this try

value "Max {}"

  vs.

value "Max {1::nat, 2}"

  Isabelle supports partial functions.  One can either use explicit undefinedness (using the Option datatype with the None and Some constructors),
  but that would affect and thus bloat large parts of our formalisation.

  In "isabelle doc functions" section 7 there is also something that looks like a more sophisticated support for 
  partial functions.

  For now, spa_is_left_total doesn't catch the case "card N = 1", but spa_vickrey_payment, which is
  part of our checks whether the outcome is well-defined, doesn't work for "case N = 1".  For precise
  details, see the comment in spa_vickrey_payment.

  So, @CR, this is really a good justification for why we need spa_vickrey_payment.  Indeed the whole
  battery of case checks now covers: "for each admissible input there is (that's left-totality) a 
  unique (that's right-uniqueness), well-defined (that's spa_vickrey_payment and spa_allocates) outcome."
*)
text{* Our relational definition of second price auction is left-total. *}
lemma spa_is_left_total :
  fixes A :: single_good_auction
  (* A is the set of all second price auctions.
     Assuming "second_price_auction A" would merely mean that all elements of A are second price auctions,
     which is not enough here. *)
  assumes spa: "rel_all_sga_pred spa_pred A"
  shows "sga_left_total A spa_admissible_input"
proof -
  {
    fix N :: participants and b :: bids
    assume admissible: "spa_admissible_input N b"
    (* Note that Isabelle says that "Max {}" exists (but of course can't specify it).
       However we are working with our own wrapped maximum definition anyway. *)
    then obtain winner::participant where winner_def: "winner \<in> N \<and> winner \<in> arg_max_set N b"
      using spa_admissible_input_def arg_max_set_def maximum_def maximum_def maximum_is_component maximum_defined_def
      by (smt mem_Collect_eq)
    (* Now that we know the winner exists, let's construct a suitable allocation and payments. *)
    def x \<equiv> "\<lambda> i::participant . if i = winner then 1::real else 0"
    def p \<equiv> "\<lambda> i::participant . if i = winner then maximum (N - {i}) b else 0"
    from x_def and p_def and winner_def and admissible
      have "spa_pred N b x p"
      using spa_admissible_input_def second_price_auction_winner_def second_price_auction_loser_def spa_pred_def
      by auto
    with spa have "\<exists> (x :: allocation) (p :: payments) . ((N, b), (x, p)) \<in> A"
      using spa_pred_def rel_all_sga_pred_def by auto
  }
  then show ?thesis unfolding sga_left_total_def by blast
qed

text{* We consider two outcomes of a second price auction equivalent if 
\begin{enumerate}
\item the bids of the participants to which the good is allocated are equal
\item the bids of the participants with positive payments are equal
\end{enumerate}
This should be as weak as possible, as not to accidentally restate the full definition of a second price auction.
 *}
definition spa_equivalent_outcome :: "participants \<Rightarrow> bids \<Rightarrow> allocation \<Rightarrow> payments \<Rightarrow> allocation \<Rightarrow> payments \<Rightarrow> bool"
  where "spa_equivalent_outcome N b x p x' p' \<longleftrightarrow> 
    b ` { i \<in> N . x i = 1 } = b ` { i \<in> N . x' i = 1 } \<and>
    b ` { i \<in> N . p i > 0 } = b ` { i \<in> N . p' i > 0 }"
(* This definition is more general in that it allow for divisible goods. *)

text{* Under certain conditions we can show that 
  the bids of the participants with positive payments are equal
  (one direction of the equality) *}
lemma positive_payment_bids_eq_suff :
  fixes N :: participants
    and winner :: participant
    and b :: bids
    and p :: payments
    and p' :: payments
  assumes admissible: "spa_admissible_input N b"
      and range: "winner \<in> N \<and> winner \<in> arg_max_set N b"
      and pay: "p winner = maximum (N - {winner}) b \<and> (\<forall>j \<in> N . j \<noteq> winner \<longrightarrow> p j = 0)"
      and range': "winner' \<in> N \<and> winner' \<in> arg_max_set N b"
      and pay': "p' winner' = maximum (N - {winner'}) b \<and> (\<forall>j \<in> N . j \<noteq> winner' \<longrightarrow> p' j = 0)"
  shows "b ` { i \<in> N . p i > 0 } \<subseteq> b ` { i \<in> N . p' i > 0 }"
proof (intro subsetI)
  from admissible have bids: "bids N b" and ge2: "card N > 1"
    using spa_admissible_input_def by auto
  fix bid assume premise: "bid \<in> b ` { i \<in> N . p i > 0 }"
  with range pay range' have bw': "bid = b winner'" using arg_max_set_def by auto
  from premise pay have p_positive: "p winner > 0" by auto
  with ge2 range pay have bwpos: "b winner > 0"
    using arg_max_set_def maximum_except_defined maximum_remaining_maximum by (smt mem_Collect_eq)
  from ge2 range' have md: "maximum_defined (N - {winner'})" using maximum_except_defined by blast
  have "maximum (N - {winner'}) b > 0"
  proof (rule ccontr)
    assume assm: "\<not> maximum (N - {winner'}) b > 0"
    {
      fix i assume i_range: "i \<in> (N - {winner'})"
      with bids have bipos: "b i \<ge> 0" unfolding bids_def non_negative_real_vector_def by blast
      from md have "maximum (N - {winner'}) b \<ge> b i" using i_range maximum_is_greater_or_equal by simp
      then have "maximum (N - {winner'}) b = 0" using assm bipos by simp
    }
    with assm range range' pay pay' have foow': "maximum (N - {winner'}) b = 0"
      using maximum_is_component md by metis
    show False
    proof cases
      assume "winner' = winner"
      then show False using p_positive pay foow' by auto
    next
      assume "winner' \<noteq> winner"
      with range have "winner \<in> N - {winner'}" by fast
      then have x: "maximum (N - {winner'}) b \<ge> b winner" using range maximum_is_greater_or_equal md by blast
      with foow' have bwzn: "b winner \<le> 0" by auto
      from range have "maximum N b = b winner" using arg_max_set_def by auto
      with md x maximum_remaining_maximum bwpos bwzn show False by auto
    qed
  qed
  then show "bid \<in> b ` { i \<in> N . p' i > 0 }" using range' pay' bw' by auto
qed

text{* Our relational definition of second price auction is right-unique. *}
lemma spa_is_right_unique :
  fixes A :: single_good_auction
  (* A is the set of all second price auctions.
     Assuming "second_price_auction A" would merely mean that all elements of A are second price auctions,
     which is not enough here. *)
  assumes spa: "rel_all_sga_pred spa_pred A"
  shows "sga_right_unique A spa_admissible_input spa_equivalent_outcome"
proof -
  {
    fix N :: participants and b :: bids
    assume admissible: "spa_admissible_input N b"
    fix x :: allocation and x' :: allocation and p :: payments and p' :: payments

    assume "((N, b), (x, p)) \<in> A"
    with spa have "spa_pred N b x p" unfolding rel_all_sga_pred_def by blast
    then obtain winner::participant
      where range: "winner \<in> N \<and> winner \<in> arg_max_set N b"
        and alloc: "x winner = 1 \<and> (\<forall> j \<in> N . j \<noteq> winner \<longrightarrow> x j = 0)"
        and pay: "p winner = maximum (N - {winner}) b \<and> (\<forall>j \<in> N . j \<noteq> winner \<longrightarrow> p j = 0)"
      unfolding rel_all_sga_pred_def spa_pred_def second_price_auction_def second_price_auction_winner_def second_price_auction_loser_def
      by blast

    assume "((N, b), (x', p')) \<in> A"
    with spa have "spa_pred N b x' p'" unfolding rel_all_sga_pred_def by blast
    then obtain winner'::participant
      where range': "winner' \<in> N \<and> winner' \<in> arg_max_set N b"
        and alloc': "x' winner' = 1 \<and> (\<forall> j \<in> N . j \<noteq> winner' \<longrightarrow> x' j = 0)"
        and pay': "p' winner' = maximum (N - {winner'}) b \<and> (\<forall>j \<in> N . j \<noteq> winner' \<longrightarrow> p' j = 0)"
      unfolding spa_pred_def second_price_auction_def second_price_auction_winner_def second_price_auction_loser_def
      by blast
    have "b ` { i \<in> N . x i = 1 } = b ` { i \<in> N . x' i = 1 }"
    proof (intro equalityI) (* CL: any way to collapse these two cases into one? *)
      from range alloc range' alloc' show "b ` { i \<in> N . x i = 1 } \<subseteq> b ` { i \<in> N . x' i = 1 }"
        using arg_max_set_def by auto
    next
      from range' alloc' range alloc show "b ` { i \<in> N . x' i = 1 } \<subseteq> b ` { i \<in> N . x i = 1 }"
        using arg_max_set_def by auto
    qed
    moreover have "b ` { i \<in> N . p i > 0 } = b ` { i \<in> N . p' i > 0 }"
    proof (intro equalityI)
      from admissible range pay range' pay' show "b ` { i \<in> N . p i > 0 } \<subseteq> b ` { i \<in> N . p' i > 0 }"
        using positive_payment_bids_eq_suff by simp
    next
      from admissible range' pay' range pay show "b ` { i \<in> N . p' i > 0 } \<subseteq> b ` { i \<in> N . p i > 0 }"
        using positive_payment_bids_eq_suff by simp
    qed
    ultimately have "spa_equivalent_outcome N b x p x' p'" unfolding spa_equivalent_outcome_def by blast
  }
  then show ?thesis unfolding sga_right_unique_def by blast
qed

lemma spa_is_sga_pred :
  fixes N :: participants and b :: bids
    and x :: allocation and p :: payments
  assumes "spa_pred N b x p"
  shows "sga_pred N b x p"
  using assms
  unfolding spa_pred_def sga_pred_def by blast

lemma spa_is_sga :
  fixes A :: single_good_auction
  assumes spa: "second_price_auction A"
  shows "single_good_auction A"
proof -
  {
    fix N :: participants and b :: bids and x :: allocation and p :: payments
    assume "((N, b), (x, p)) \<in> A"
    with spa have "spa_pred N b x p" unfolding second_price_auction_def rel_sat_sga_pred_def by blast
    then have "sga_pred N b x p" using spa_is_sga_pred by blast
  }
  then show ?thesis unfolding single_good_auction_def rel_sat_sga_pred_def by blast
qed

lemma spa_allocates_binary :
  fixes N :: participants and b :: bids
    and x :: allocation and p :: payments
    and i :: participant
  assumes "spa_pred N b x p"
      and "i \<in> N"
  shows "x i = 0 \<or> x i = 1"
  using assms
  unfolding spa_pred_def second_price_auction_def second_price_auction_winner_def second_price_auction_loser_def
  by fast

lemma allocated_implies_spa_winner:
  fixes N :: participants and b :: bids
     and x :: allocation and p :: payments
     and winner :: participant
  assumes "spa_pred N b x p"
    and "winner \<in> N"
    and "x winner = 1"
  shows "second_price_auction_winner N b x p winner"
  using assms
  unfolding spa_pred_def second_price_auction_def second_price_auction_winner_def second_price_auction_loser_def
    allocation_def
  by (metis zero_neq_one)
    (* CL: With the generalised allocation_def, this proof needed a bit more complexity,
         as "x winner = 1" implies "x i = 0" for all other participants is rather implicit now. *)

lemma not_allocated_implies_spa_loser:
  fixes N :: participants and b :: bids
    and x :: allocation and p :: payments
    and loser :: participant
  assumes spa: "spa_pred N b x p"
    and range: "loser \<in> N"
    and loses: "x loser = 0"
  shows "second_price_auction_loser N x p loser"
proof -
  from loses have "\<not> second_price_auction_winner N b x p loser"
    unfolding second_price_auction_winner_def by simp
  with spa range show ?thesis
      unfolding spa_pred_def second_price_auction_def by fast
qed

lemma only_max_bidder_wins:
  fixes N :: participants and max_bidder :: participant
    and b :: bids and x :: allocation and p :: payments
  assumes defined: "maximum_defined N"
    and spa: "spa_pred N b x p"
    and range: "max_bidder \<in> N"
    and only_max_bidder: "b max_bidder > maximum (N - {max_bidder}) b"
  shows "second_price_auction_winner N b x p max_bidder"
proof -
  from spa have spa_unfolded:
    "bids N b \<and> (\<exists>i. second_price_auction_winner N b x p i \<and>
      (\<forall>j \<in> N. j \<noteq> i \<longrightarrow> second_price_auction_loser N x p j))"
    unfolding spa_pred_def second_price_auction_def by blast
  {
    fix j :: participant
    assume j_not_max: "j \<in> N \<and> j \<noteq> max_bidder"
    have "j \<notin> arg_max_set N b"
    proof
      assume "j \<in> arg_max_set N b"
      then have maximum: "b j = maximum N b" unfolding arg_max_set_def by simp

      from j_not_max range have "b j \<le> maximum (N - {max_bidder}) b"
        using defined maximum_except_is_greater_or_equal by simp
      with only_max_bidder have *: "b j < b max_bidder" by simp

      from defined range maximum have "b j \<ge> b max_bidder"
        by (simp add: maximum_is_greater_or_equal)
      with * show False by simp
    qed
  }
    with spa_unfolded show ?thesis
    by (auto simp add: second_price_auction_winner_def)
qed

lemma second_price_auction_winner_payoff:
  fixes N :: participants and v :: valuations and x :: allocation
    and b :: bids and p :: payments and winner :: participant
  assumes defined: "maximum_defined N"
    and spa: "spa_pred N b x p"
    and i_range: "i \<in> N"
    and wins: "x i = 1"
  shows "payoff (v i) (x i) (p i) = v i - maximum (N - {i}) b"
proof -
  have "payoff (v i) (x i) (p i) = v i - p i"
    using wins unfolding payoff_def by simp
  also have "\<dots> = v i - maximum (N - {i}) b"
    using defined spa i_range wins
      using allocated_implies_spa_winner
    unfolding second_price_auction_winner_def
    by simp
  finally show ?thesis .
qed

lemma second_price_auction_loser_payoff:
  fixes N :: participants and v :: valuations and x :: allocation
    and b :: bids and p :: payments and loser :: participant
  assumes "spa_pred N b x p"
    and "i \<in> N"
    and "x i = 0"
  shows "payoff (v i) (x i) (p i) = 0"
  using assms not_allocated_implies_spa_loser
  unfolding second_price_auction_loser_def payoff_def by simp

lemma winners_payoff_on_deviation_from_valuation:
  fixes N :: participants and v :: valuations and x :: allocation
    and b :: bids and p :: payments and winner :: participant
  assumes "maximum_defined N"
    and "spa_pred N b x p"
    and "i \<in> N"
    and "x i = 1"
  shows "payoff (v i) (x i) (p i) = v i - maximum (N - {i}) (b(i := v i))"
  using assms second_price_auction_winner_payoff remaining_maximum_invariant
  by simp

section {* Some properties that single good auctions can have *}

subsection {* Efficiency *}

definition efficient :: "participants \<Rightarrow> valuations \<Rightarrow> bids \<Rightarrow> single_good_auction \<Rightarrow> bool"
  where
    "efficient N v b A \<longleftrightarrow>
      valuations N v \<and> bids N b \<and> single_good_auction A \<and>
      (\<forall> x p . ((N, b), (x, p)) \<in> A
        (* TODO CL: Is there a way of not naming p, as we don't need it? *)
        \<longrightarrow>
        (\<forall>i \<in> N. x i = 1 \<longrightarrow> i \<in> arg_max_set N v))"

subsection {* Equilibrium in weakly dominant strategies *}

definition equilibrium_weakly_dominant_strategy ::
  "participants \<Rightarrow> valuations \<Rightarrow> bids \<Rightarrow> single_good_auction \<Rightarrow> bool" where
  "equilibrium_weakly_dominant_strategy N v b A \<longleftrightarrow>
    valuations N v \<and> bids N b \<and> single_good_auction A \<and>
    (\<forall>i \<in> N.
      (\<forall>whatever_bid . bids N whatever_bid \<and> whatever_bid i \<noteq> b i \<longrightarrow>
        (let b' = whatever_bid(i := b i)
         in 
         (\<forall> x p x' p' . ((N, whatever_bid), (x, p)) \<in> A \<and> ((N, b'), (x', p')) \<in> A
          \<longrightarrow>
          payoff (v i) (x' i) (p' i) \<ge> payoff (v i) (x i) (p i)))))"

section {* Vickrey's Theorem *}

subsection {* Part 1: A second-price auction supports an equilibrium in weakly dominant
  strategies if all participants bid their valuation. *}

theorem vickreyA:
  fixes N :: participants and v :: valuations and A :: single_good_auction
  assumes card_N: "card N > 1"
  assumes val: "valuations N v" 
  defines "b \<equiv> v"
  assumes spa: "second_price_auction A"
  shows "equilibrium_weakly_dominant_strategy N v b A"
proof -
  have defined: "maximum_defined N" using card_N
    unfolding maximum_defined_def by (auto simp: card_ge_0_finite)
  then have finite: "finite N" by (metis card_N card_infinite less_nat_zero_code)

  from val have bids: "bids N b"
    unfolding b_def by (rule valuation_is_bid)
  {
    fix i :: participant
    assume i_range: "i \<in> N"

    let ?M = "N - {i}"
    have defined': "maximum_defined ?M"
      using card_N i_range unfolding maximum_defined_def
      by (simp add: card_ge_0_finite card_Diff_singleton)

    fix whatever_bid :: bids
    assume alternative_is_bid: "bids N whatever_bid"
    (* TOOD CL: also assume "whatever_bid i \<noteq> b i"? *)

    let ?b = "whatever_bid(i := b i)"
    
    have is_bid: "bids N ?b"
      using bids alternative_is_bid
      unfolding bids_def non_negative_real_vector_def by simp

    let ?b_max = "maximum N ?b"
    let ?b_max' = "maximum ?M ?b"

    fix x :: allocation and x' :: allocation and p :: payments and p' :: payments
    assume outcome: "((N, whatever_bid), (x, p)) \<in> A"
       and outcome': "((N, ?b), (x', p')) \<in> A"

    from spa outcome have spa_pred: "spa_pred N whatever_bid x p"
      unfolding second_price_auction_def rel_sat_sga_pred_def by blast
    from spa outcome' have spa_pred': "spa_pred N ?b x' p'"
      unfolding second_price_auction_def rel_sat_sga_pred_def by blast

    from spa_pred finite have allocation: "allocation N x" using spa_allocates by blast
    from spa_pred' finite have allocation': "allocation N x'" using spa_allocates by blast
    from spa_pred card_N have pay: "vickrey_payment N p" using spa_vickrey_payment by blast
    from spa_pred' card_N have pay': "vickrey_payment N p'" using spa_vickrey_payment by blast

    have weak_dominance:
      "payoff (v i) (x' i) (p' i) \<ge> payoff (v i) (x i) (p i)"
    proof cases
      assume alloc: "x' i = 1"
      with spa_pred' i_range
      have winner: "second_price_auction_winner N ?b x' p' i"
        by (rule allocated_implies_spa_winner)

      from winner have "?b i = ?b_max"
        unfolding second_price_auction_winner_def arg_max_set_def by simp
      with defined' have "?b i \<ge> ?b_max'"
        by (rule maximum_remaining_maximum)

      from winner have "p' i = ?b_max'"
        unfolding second_price_auction_winner_def
        by simp

      have winner_payoff: "payoff (v i) (x' i) (p' i) = v i - ?b_max'"
        using defined spa_pred' i_range alloc
        by (rule second_price_auction_winner_payoff)

      have non_negative_payoff: "payoff (v i) (x' i) (p' i) \<ge> 0"
      proof -
        from `?b i \<ge> ?b_max'` have "?b i - ?b_max' \<ge> 0" by simp
        with winner_payoff show ?thesis unfolding b_def by simp
      qed

      show ?thesis
      proof cases -- {* case 1a of the short proof *}
        assume "x i = 1"
        with defined spa_pred alternative_is_bid i_range
        have "payoff (v i) (x i) (p i) = v i - ?b_max'"
          using winners_payoff_on_deviation_from_valuation unfolding b_def by simp
        also have "\<dots> = payoff (v i) (x' i) (p' i)" using winner_payoff by simp
        finally show ?thesis by (rule eq_refl)
      next -- {* case 1b of the short proof *}
        assume "x i \<noteq> 1"
        (* CL: TODO I'm sure one can use spa_allocates_binary at the top level of the 
               case distinction, to get rid of having to do this step for each case distinction. *)
        with spa_pred alternative_is_bid i_range have "x i = 0"
          using spa_allocates_binary by blast
        with spa_pred i_range
        have "payoff (v i) (x i) (p i) = 0"
          by (rule second_price_auction_loser_payoff)
        also have "\<dots> \<le> payoff (v i) (x' i) (p' i)" using non_negative_payoff by simp
        finally show ?thesis .
      qed

    next -- {* case 2 of the short proof *}
      assume non_alloc: "x' i \<noteq> 1"
      (* CL: TODO I'm sure one can use spa_allocates_binary at the top level of the 
             case distinction, to get rid of having to do this step for each case distinction. *)
      with spa_pred' i_range have "x' i = 0"
        using spa_allocates_binary by blast
      with spa_pred' i_range
      have loser_payoff: "payoff (v i) (x' i) (p' i) = 0"
        by (rule second_price_auction_loser_payoff)

      have i_bid_at_most_second: "?b i \<le> ?b_max'"
      proof (rule ccontr)
        assume "\<not> ?thesis"
        then have "?b i > ?b_max'" by simp
        with defined spa_pred' i_range
        have "second_price_auction_winner N ?b x' p' i"
          using only_max_bidder_wins by simp
        with non_alloc show False using second_price_auction_winner_def by simp
      qed

      show ?thesis
      proof cases -- {* case 2a of the short proof *}
        assume "x i = 1"
        with defined spa_pred i_range
        have "payoff (v i) (x i) (p i) = ?b i - ?b_max'"
          using winners_payoff_on_deviation_from_valuation unfolding b_def by simp
        also have "\<dots> \<le> 0" using i_bid_at_most_second by simp
        also have "\<dots> = payoff (v i) (x' i) (p' i)" using loser_payoff by simp
        finally show ?thesis .
      next -- {* case 2b of the short proof *}
        assume "x i \<noteq> 1"
        (* CL: TODO I'm sure one can use spa_allocates_binary at the top level of the 
               case distinction, to get rid of having to do this step for each case distinction. *)
        with spa_pred alternative_is_bid i_range have "x i = 0"
          using spa_allocates_binary by blast
        with spa_pred i_range
        have "payoff (v i) (x i) (p i) = 0"
          by (rule second_price_auction_loser_payoff)
        also have "\<dots> = payoff (v i) (x' i) (p' i)" using loser_payoff by simp
        finally show ?thesis by (rule eq_refl)
      qed
    qed
  }
  with spa val bids show ?thesis
    using spa_is_sga
    unfolding equilibrium_weakly_dominant_strategy_def
    by auto
qed


subsection {* Part 2: A second-price auction is efficient if all participants bid their valuation. *}

theorem vickreyB:
  fixes N :: participants and v :: valuations and A :: single_good_auction
  assumes val: "valuations N v"
  assumes spa: "second_price_auction A"
  defines "b \<equiv> v"
  shows "efficient N v b A"
proof -
  from val have bids: "bids N v" by (rule valuation_is_bid)
  {
    fix k :: participant and x :: allocation and p :: payments
    (* TODO CL: We actually don't need p; is there a way to do without? *)
    assume range: "k \<in> N" and outcome: "((N, v), (x, p)) \<in> A" and wins: "x k = 1"
    from outcome spa have "spa_pred N v x p"
      unfolding second_price_auction_def rel_sat_sga_pred_def
      by blast
    with range and wins have "k \<in> arg_max_set N v"
      using allocated_implies_spa_winner
      unfolding second_price_auction_winner_def by blast
  }
  with bids spa show ?thesis
    using val unfolding b_def efficient_def using spa_is_sga by blast
qed

end
