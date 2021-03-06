(*
Auction Theory Toolbox (http://formare.github.io/auctions/)

Authors:
* Marco B. Caminati http://caminati.co.nr
* Christoph Lange <math.semantic.web@gmail.com>

Dually licenced under
* Creative Commons Attribution (CC-BY) 3.0
* ISC License (1-clause BSD License)
See LICENSE file for details
(Rationale for this dual licence: http://arxiv.org/abs/1107.3212)
*)

header {* Additional material that we would have expected in Set.thy *}

theory SetUtils
imports
  Main

begin

section {* Equality *}

text {* An inference rule that combines @{thm equalityI} and @{thm subsetI} to a single step *}
lemma equalitySubsetI: "(\<And>x . x \<in> A \<Longrightarrow> x \<in> B) \<Longrightarrow> (\<And>x . x \<in> B \<Longrightarrow> x \<in> A) \<Longrightarrow> A = B" by blast

section {* Trivial sets *}

text {* A trivial set (i.e. singleton or empty), as in Mizar *}
definition trivial where "trivial x = (x \<subseteq> {the_elem x})"

text {* The empty set is trivial. *}
lemma trivial_empty: "trivial {}" unfolding trivial_def by (rule empty_subsetI)

text {* A singleton set is trivial. *}
lemma trivial_singleton: "trivial {x}" unfolding trivial_def by simp

text {* If there are no two different elements in a set, it is trivial. *}
lemma no_distinct_imp_trivial:
  assumes "\<forall> x y . x \<in> X \<and> y \<in> X \<longrightarrow> x = y"
  shows "trivial X"
(* CL: The following takes 81 ms in Isabelle2013-1-RC1:
   by (metis assms ex_in_conv insertI1 subsetI subset_singletonD trivial_def trivial_singleton) *)
unfolding trivial_def
proof 
  fix x::'a
  assume x_in_X: "x \<in> X"
  with assms have uniq: "\<forall> y \<in> X . x = y" by force
  have "X = {x}"
  proof (rule equalitySubsetI)
    fix x'::'a
    assume "x' \<in> X"
    with uniq show "x' \<in> {x}" by simp
  next
    fix x'::'a
    assume "x' \<in> {x}"
    with x_in_X show "x' \<in> X" by simp
  qed
  then show "x \<in> {the_elem X}" by simp
qed

text {* If a trivial set has a singleton subset, the latter is unique. *}
lemma singleton_sub_trivial_uniq:
  fixes x X
  assumes "{x} \<subseteq> X"
      and "trivial X"
  shows "x = the_elem X"
(* CL: The following takes 16 ms in Isabelle2013-1-RC1:
   by (metis assms(1) assms(2) insert_not_empty insert_subset subset_empty subset_insert trivial_def trivial_imp_no_distinct) *)
using assms unfolding trivial_def by fast

text {* Any subset of a trivial set is trivial. *}
lemma trivial_subset: fixes X Y assumes "trivial Y" assumes "X \<subseteq> Y" 
shows "trivial X"
(* CL: The following takes 36 ms in Isabelle2013-1-RC1:
   by (metis assms(1) assms(2) equals0D no_distinct_imp_trivial subsetI subset_antisym subset_singletonD trivial_cases) *)
using assms unfolding trivial_def by (metis (full_types) subset_empty subset_insertI2 subset_singletonD)

text {* There are no two different elements in a trivial set. *}
lemma trivial_imp_no_distinct:
  assumes triv: "trivial X"
      and x: "x \<in> X"
      and y: "y \<in> X"
  shows "x = y"
(* CL: The following takes 17 ms in Isabelle2013-1-RC1: *)
using assms by (metis empty_subsetI insert_subset singleton_sub_trivial_uniq) 

section {* The image of a set under a function *}

(* TODO CL: review whether we are always using the simplest possible set comprehension notation (compare List.set_concat) *)
text {* an equivalent notation for the image of a set, using set comprehension *}
lemma image_Collect_mem: "{ f x | x . x \<in> S } = f ` S" by auto

section {* Big Union *}

text {* An element is in the union of a family of sets if it is in one of the family's member sets. *}
lemma Union_member: "(\<exists> S \<in> F . x \<in> S) \<longleftrightarrow> x \<in> \<Union> F" by blast

section {* Miscellaneous *}

lemma ll69: assumes "trivial t" "t \<inter> X \<noteq> {}" shows "t \<subseteq> X" using trivial_def assms in_mono by fast

lemma lm54: assumes "trivial X" shows "finite X" 
using assms by (metis finite.simps subset_singletonD trivial_def)
(* finite.simps trivial_cases by metis *)

lemma lm001a: assumes "trivial (A \<times> B)" shows "(finite (A\<times>B) & card A * (card B) \<le> 1)" 
using trivial_def assms One_nat_def card_cartesian_product card_empty card_insert_disjoint
empty_iff finite.emptyI le0 lm54 order_refl subset_singletonD by (metis(no_types))

lemma ll97: assumes "finite X" shows "trivial X=(card X \<le> 1)" (is "?LH=?RH") 
using assms One_nat_def card_empty card_insert_if card_mono card_seteq empty_iff empty_subsetI 
finite.cases finite.emptyI finite_insert insert_mono trivial_def trivial_singleton
by (metis(no_types))

lemma ll10: shows "trivial {x}" by (metis order_refl the_elem_eq trivial_def)

lemma ll11: assumes "trivial X" "{x} \<subseteq> X" shows "{x}=X" 
using singleton_sub_trivial_uniq assms by (metis subset_antisym trivial_def)

lemma ll26: assumes "\<not> trivial X" "trivial T" shows "X-T \<noteq> {}"
using assms by (metis Diff_iff empty_iff subsetI trivial_subset)

lemma lm001b: assumes "(finite (A\<times>B) & card A * (card B) \<le> 1)" shows "trivial (A \<times> B)" 
unfolding trivial_def using trivial_def assms by (metis card_cartesian_product ll97)

lemma lm001: "trivial (A \<times> B)=(finite (A\<times>B) & card A * (card B) \<le> 1)" using lm001a lm001b by blast

lemma lm01: "trivial X = (\<forall>x1 \<in> X. \<forall>x2 \<in> X. x1=x2)" unfolding trivial_def using trivial_def 
by (metis no_distinct_imp_trivial trivial_imp_no_distinct)

lemma lm009a: assumes "(Pow X \<subseteq> {{},X})" shows "trivial X" unfolding lm01 using assms by auto

lemma lm009b: assumes "trivial X" shows "(Pow X \<subseteq> {{},X})" using assms lm01 by fast

lemma lm009: "trivial X = (Pow X \<subseteq> {{},X})" using lm009a lm009b by metis

lemma lm007: "trivial X = (X={} \<or> X={the_elem X})" 
by (metis subset_singletonD trivial_def trivial_empty trivial_singleton)

lemma ll40: assumes "trivial X" "trivial Y" shows "trivial (X \<times> Y)"
using assms lm001 One_nat_def Sigma_empty1 Sigma_empty2 card_empty card_insert_if finite_SigmaI 
lm54 nat_1_eq_mult_iff order_refl subset_singletonD trivial_def trivial_empty
by (metis (full_types))

lemma lm002: "({x} \<times> UNIV) \<inter> P = {x} \<times> (P `` {x})" by fast

lemma lm00: "(x,y) \<in> P = (y \<in> P``{x})" by simp

lemma lm010: assumes "inj_on f A" "inj_on f B" shows "inj_on f (A \<union> B) = (f`(A-B) \<inter> (f`(B-A))={})"
using assms inj_on_Un by (metis)

lemma lm010b: assumes "inj_on f A" "inj_on f B" "f`A \<inter> (f`B)={}" shows "inj_on f (A \<union> B)" 
using assms lm010 by fast

lemma lm008: "(Pow X = {X}) = (X={})" by auto

end

