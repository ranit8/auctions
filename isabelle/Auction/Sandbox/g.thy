theory g

imports f "../CombinatorialVickreyAuction"
"~~/src/HOL/Library/Code_Target_Nat"

begin

(* CL@MC: What's the rationale behind this?  Bringing allocation and bids into the 
   same structure, so that it is easier to compute a sum over them?  If so, this 
   will be worth mentioning in the paper, as it is an important design choice
   in formalisation. *)
type_synonym altbids = "(participant \<times> goods) \<Rightarrow> price"
type_synonym allocation_conv = "(participant \<times> goods) set"

abbreviation "altbids (b::bids) == split b"
term "altbids b"
term "(altbids (b::bids))=(x::altbids)"
(* CL: I don't understand the choice of the name "proceeds". *)
abbreviation "proceeds (b::altbids) (allo::allocation_conv) == setsum b allo"

lemma lll23: assumes "finite A" shows "setsum f A = setsum f (A \<inter> B) + setsum f (A - B)" using 
assms by (metis DiffD2 Int_iff Un_Diff_Int Un_commute finite_Un setsum.union_inter_neutral)

lemma shows "(P||(Domain Q)) +* Q = Q" by (metis Int_lower2 ll41 ll56)

lemma lll77: assumes "Range P \<inter> (Range Q)={}" "runiq (P^-1)" "runiq (Q^-1)" shows "runiq ((P \<union> Q)^-1)"
using assms
by (metis Domain_converse converse_Un disj_Un_runiq)

lemma lll77b: assumes "Range P \<inter> (Range Q)={}" "runiq (P^-1)" "runiq (Q^-1)" shows "runiq ((P +* Q)^-1)"
using lll77 assms subrel_runiq by (metis converse_converse converse_subset_swap paste_sub_Un)

lemma assumes "runiq P" shows "P^-1``((Range P)-X) \<inter> ((P^-1)``X) \<subseteq> {}"
using assms ll71 by blast

lemma lll78: assumes "runiq (P^-1)" shows "P``(Domain P -X) \<inter> (P``X) = {}"
using assms ll71 by fast

abbreviation "eval_rel2 R x == \<Union> (R``{x})"
notation eval_rel2 (infix ",,," 75)
(* MC: realized that eval_rel2 could be preferable to eval_rel, because it generalizes the latter 
while evaluating to {} outside of the domain, and to something defined in general when eval_rel is not. 
This is generally a better behaviour from the formal point of view (cmp. lll74)*)

lemma lll82: assumes "x \<in> Domain f" "runiq f" shows "f,,x = f,,,x" using eval_rel_def 
assms by (metis Image_runiq_eq_eval cSup_singleton)

lemma lll79: assumes "\<Union> XX \<subseteq> X" "x \<in> XX" "x \<noteq> {}" shows "x \<inter> X \<noteq> {}" using assms by blast

lemma lll80: assumes "is_partition XX" "YY \<subseteq> XX" shows "is_partition_of (XX - YY) (\<Union> XX - \<Union> YY)"
using is_partition_of_def is_partition_def assms
proof -
  let ?i=is_partition let ?I=is_partition_of let ?xx="XX - YY" let ?X="\<Union> XX" let ?Y="\<Union> YY"
  let ?x="?X - ?Y"
  have "\<forall> y \<in> YY. \<forall> x\<in>?xx. y \<inter> x={}" using assms is_partition_def by (metis Diff_iff set_rev_mp)
  then have "\<Union> ?xx \<subseteq> ?x" using assms by blast
  then have "\<Union> ?xx = ?x" by blast
  moreover have "?i ?xx" using subset_is_partition by (metis Diff_subset assms(1))
  ultimately
  show ?thesis using is_partition_of_def by blast
qed

lemma lll81a: assumes "(a \<in> possible_allocations_rel G N)" shows
"(runiq a & runiq (a^-1) & is_partition_of (Domain a) (G) & Range a \<subseteq> N)" 
using assms possible_allocations_rel_def
proof -
  let ?P=all_partitions let ?I=injections obtain Y where
  0: "a \<in> ?I Y N & Y \<in> ?P G" using assms possible_allocations_rel_def by auto
  show ?thesis using 0 injections_def by (smt all_partitions_def mem_Collect_eq)
qed

lemma lll81b: assumes "(runiq a & runiq (a^-1) & is_partition_of (Domain a) (G) & Range a \<subseteq> N)" 
shows "a \<in> possible_allocations_rel G N"
proof -
  have "a \<in> injections (Domain a) N" using injections_def assms by blast
  moreover have "Domain a \<in> all_partitions G" using assms all_partitions_def by fast
  ultimately show ?thesis using assms possible_allocations_rel_def by auto
qed

lemma lll81: "(a \<in> possible_allocations_rel G N) =
(runiq a & runiq (a^-1) & is_partition_of (Domain a) (G) & Range a \<subseteq> N)"
using lll81a lll81b by blast

lemma lll74: assumes "a^-1 \<in> possible_allocations_rel G N" 
"Y2 \<inter> (G - a,,,x)={}"
"Y2 \<noteq> {}"
shows "(a +< (x,Y2))^-1 \<in> possible_allocations_rel (G-(a,,,x)\<union>Y2) (N \<union> {x})"
proof -
let ?Y1="a,,,x" let ?u=runiq let ?A=possible_allocations_rel let ?aa="a^-1" let ?I=injections
let ?P=all_partitions let ?r=Range let ?a2="a +< (x, Y2)" let ?d=Domain
obtain pG where 
1: "?aa \<in> ?I pG N & pG \<in> ?P G" using assms(1) possible_allocations_rel_def by fastforce
have "?u a" using 1 injections_def
by (smt converse_converse mem_Collect_eq)
then have 
12: "?u (a +< (x,Y2))" using lll73 by metis
have "?r (a -- x)=a``(?d a - {x})" using Outside_def by blast
moreover have 
0: "?u ?aa & ?u a" using assms ll81 by (metis `runiq a` lll81) ultimately
have "?r (a -- x) \<inter> (a``{x}) = {}" using lll78 Outside_def 
by metis 
moreover have 
3: "(a -- x) \<union> {(x, Y2)} = ?a2" using paste_def 
by (metis Domain_empty Domain_insert fst_conv l37 snd_conv)
have 
6: "?r ?a2 = ?r (a -- x) \<union> {Y2}" using 3 by auto
moreover have "?r a = ?r (a -- x) \<union> (a``{x})" using Outside_def
by blast
ultimately moreover have "?r (a -- x) = ?r a - a``{x}" by auto
moreover have "is_partition (?r a) & (\<Union> (?r a))=G" using 1 by (metis Domain_converse assms(1) is_partition_of_def lll81)
ultimately moreover have "a``{x} \<subseteq> ?r a" by (metis Un_upper2)
ultimately have 
5: "is_partition_of (?r (a -- x)) (G - \<Union>(a``{x}))" using lll80 by metis
then have 
4: "\<Union> (?r (a -- x)) = (G - a,,,x)" using is_partition_of_def by (metis set_eq_subset)
then have "Y2 \<notin> (?r (a -- x))" using lll79 assms subsetI by metis
then have "?r {(x, Y2)} \<inter> ?r (a -- x) = {}" using assms by blast
moreover have "?u {(x, Y2)}" by (metis runiq_singleton_rel)
moreover have "(a--x)^-1 \<subseteq> ?aa" using Outside_def
by blast
moreover then  have "?u ((a -- x)^-1)" using 0 Outside_def subrel_runiq by metis
ultimately moreover have "?u (((a -- x) \<union> {(x, Y2)})^-1)" using 0 lll77 by (metis 
IntI Range_insert empty_iff insert_iff runiq_conv_extend_singleton)
ultimately have 
11: "?u (?a2^-1)" using 3 by metis
moreover have "?d a \<subseteq> N" using assms lll81 by simp
moreover have "?d {(x, Y2)}={x}" by simp
ultimately moreover have "?r (?a2^-1) \<subseteq> N \<union> {x}" using paste_Domain
by (smt Domain_insert Range_converse Un_iff fst_conv set_rev_mp subsetI)
ultimately have 
13: "?a2^-1 \<in> injections (?r ?a2) (N \<union> {x})" using injections_def 12
 Domain_converse converse_converse injectionsI by (metis (hide_lams, no_types) equalityE)
have "Y2 \<inter> \<Union> (?r (a -- x)) = {}" using 4 assms by presburger
moreover have "is_partition (?r (a --x ))" using 5 by (metis is_partition_of_def)
ultimately have "is_partition (insert Y2 (?r (a -- x)))" using partition_extension1 assms
by blast
then have "is_partition (?r (a -- x) \<union> {Y2})" by auto
then have "is_partition (?r ?a2)" by (metis "6")
moreover have "\<Union> (?r ?a2) = \<Union> (?r (a -- x)) \<union> Y2"
by (metis "6" Union_Un_distrib cSup_singleton)
moreover have "... = (G - (a,,,x)) \<union> Y2" by (metis "4")
ultimately have "is_partition_of (?r ?a2) ((G - (a,,,x)) \<union> Y2)"
by (metis "6" Un_commute insert_def is_partition_of_def singleton_conv)
then have "?r ?a2 \<in> ?P (G - (a,,,x) \<union> Y2)" using all_partitions_def by (metis mem_Collect_eq)
then have "(?a2^-1) \<in> injections (?r ?a2) (N \<union> {x}) & ?r ?a2 \<in> ?P (G - (a,,,x) \<union> Y2)"
using 13 by fast
then show ?thesis using possible_allocations_rel_def by auto
qed

lemma lll75: assumes "finite a" "(b::altbids) (xx, yy1) \<le> b (xx, yy2)" shows 
"setsum b ((a::allocation_conv) +< (xx,yy1)) \<le> setsum b (a +< (xx,yy2))"
proof -
  let ?z1="(xx, yy1)" let ?z2="(xx, yy2)" let ?a0="a -- xx" let ?a1="a +< ?z1" let ?a2="a +< ?z2"
  have 
  0: "{?z1} || {xx}={?z1} & {?z2}||{xx}={?z2}" using restrict_def by auto
  have "?a1 = (?a1 -- xx) \<union> (?a1 || {xx}) " 
  using paste_def Outside_def outside_union_restrict by metis
  moreover have "finite ?a1" sorry
  ultimately have "setsum b ?a1 = setsum b (?a1||{xx}) + setsum b (?a1 outside {xx})" 
  by (metis finite_Un lll00 lll01 lll06b outside_union_restrict setsum.union_disjoint)
  moreover have 
  1: "?a1 = a +* {?z1} & ?a2 = a +* {?z2}"
  by (metis fst_conv snd_conv)
  then have "?a1||{xx} = (a || {xx}) +* ({?z1} || {xx})" using lll71
  by fastforce
  moreover have "... = {?z1}||{xx}" using ll41 ll56 by (metis "0" Domain_empty Domain_insert Int_lower2)
  ultimately have 
  "setsum b ?a1 = setsum b ({?z1}) + setsum b (?a1 outside {xx})" 
  by (metis "0") then have
  11: "setsum b ?a1 = b ?z1 + setsum b (?a1 outside {xx})"
  by simp
  have "?a1 = (?a1 -- xx) \<union> (?a1 || {xx}) " 
  using paste_def Outside_def outside_union_restrict by metis
  moreover
  have "finite ?a2" sorry
  moreover have "?a2||{xx} = (a || {xx}) +* ({?z2} || {xx})" using lll71
  1 by fastforce
  moreover have "... = {?z2}||{xx}" using ll41 ll56 
  by (metis (hide_lams, no_types) "0" Domain_empty Domain_insert Int_lower2)
  ultimately have "setsum b ?a2 = setsum b ({?z2}) + setsum b (?a2 outside {xx})" 
  using 0 sorry
  then have
  12: "setsum b ?a2 = b ?z2 + setsum b (?a2 outside {xx})"
  by simp
  have "?a1 outside {xx} = (a outside {xx}) +* ({?z1} outside {xx})" 
  using lll72 by (metis "1")
  moreover have "... = (a outside {xx}) +* {}" using 1
  by (metis "0" Diff_insert_absorb empty_iff lll04 restrict_empty)
  ultimately have "?a1 outside {xx} = a outside {xx}"
  by (metis Un_empty_right outside_union_restrict paste_outside_restrict restrict_empty)
  moreover have "... = ?a2 outside {xx}" using lll72 0 1 lll04 
  Un_empty_right outside_union_restrict paste_outside_restrict restrict_empty 
  by (metis Diff_cancel) (*MC: Diff_insert_absorb AND empty_iff not needed now??! *)
  ultimately show ?thesis using 11 12 assms by smt
qed

lemma lll76: 
assumes "a \<in> possible_allocations_rel G N"
shows "Max (proceeds b ` (converse ` (possible_allocations_rel G (N - {n})))) \<ge> 
proceeds b ((a^-1) -- n)"
proof -
  let ?P=possible_allocations_rel let ?aa="a^-1 -- n" let ?d=Domain let ?Yn="a^-1,,,n"
  let ?p=proceeds let ?X="converse ` (?P G (N-{n}))" let ?u=runiq let ?r=Range
  have 
2: "?aa \<noteq> {}& ?u ?aa & ?u a & ?u (a^-1) & ?u (?aa^-1)" sorry then
  obtain i where 
  0: "i \<in> ?d ?aa" by auto
  let ?Y1="?aa,,,i" let ?Y2="?Y1 \<union> ?Yn"
have 
5: "?d ?aa \<subseteq> N - {n}" using assms lll81 by (metis Diff_mono Range_converse converse_converse outside_reduces_domain subset_refl)
then have 
6: "N - {n} \<union> {i} = N -{n}" using 0 by blast
have
3: "is_partition_of (?d a) G" using assms lll81 by blast then
have "is_partition (?r (a^-1))" using  is_partition_of_def by (metis Range_converse)
then have 
4: "is_partition (?r ?aa)" using all_partitions_def is_partition_of_def 
Outside_def subset_is_partition lll81 assms by (metis Range_outside_sub equalityE)
moreover have "?Y1 \<in> (?r ?aa)" using 0 lll82 by (metis "2" eval_runiq_in_Range)
ultimately have "?Y2 \<noteq> {}" using is_partition_def 0 by (metis Un_empty  inf_bot_right)

  have "{i} \<times> ?aa``{i} = {i} \<times> {?Y1}" using 0 Image_runiq_eq_eval 2 by (metis cSup_singleton)
  moreover have "... = {(i, ?Y1)}" by simp
  ultimately have 
  1: "?aa +< (i, ?Y1) = ?aa" using 0 paste_def eval_rel_def ll84 by (metis fst_conv snd_conv)

have "?r ?aa = ?r (a^-1) - {?Yn}" using 2 sorry
moreover have "{?Yn} \<subseteq> ?r (a^-1)" sorry
moreover have "\<Union> (?r (a^-1))=G" sorry
ultimately
have "is_partition_of (?r ?aa) (G - ?Yn)" using lll80 3 2 4 by (metis `is_partition (Range (a\<inverse>))` cSup_singleton)
moreover have "?u ?aa" by (metis "2")
moreover have "?u (?aa^-1)" using 2 by fast
moreover have "?d ?aa \<subseteq> (N -{n})" by (metis Diff_mono Domain_converse assms lll81 outside_reduces_domain subset_refl)
  ultimately have "?aa^-1 \<in> ?P (G-?Yn) (N-{n})" using assms lll81 by (metis Domain_converse converse_converse)
  moreover have "?Y2 \<inter> (G -?Yn - ?Y1)={}" by fast
  ultimately have "(?aa +< (i, ?Y2))^-1 \<in> ?P (G - ?Yn - ?Y1 \<union> ?Y2) (N-{n} \<union> {i})" 
  using lll74 by (metis `(a\<inverse> -- n) ,,, i \<union> a\<inverse> ,,, n \<noteq> {}`)
  then have 
  "(?aa +< (i, ?Y2))^-1 \<in> ?P (G \<union> ?Y2) (N-{n} \<union> {i})" by (smt Un_Diff_cancel Un_commute Un_left_commute)

moreover have "?Yn \<subseteq> G"
by (metis Union_upper `\<Union>Range (a\<inverse>) = G` `{a\<inverse> ,,, n} \<subseteq> Range (a\<inverse>)` insert_subset)
moreover have "\<Union> (?r ?aa) \<subseteq> G"
by (metis Diff_subset Sup_subset_mono `Range (a\<inverse> -- n) = Range (a\<inverse>) - {a\<inverse> ,,, n}` `\<Union>Range (a\<inverse>) = G`)
then moreover have "?Y1 \<subseteq> G" 
by (metis Sup_le_iff `(a\<inverse> -- n) ,,, i \<in> Range (a\<inverse> -- n)`)
ultimately moreover have "?Y2 \<subseteq> G" by simp

  ultimately have 
  "(?aa +< (i, ?Y2))^-1 \<in> ?P G ((N-{n}) \<union> {i})" by (metis Un_absorb2)
  then have 
  "(?aa +< (i, ?Y2))^-1 \<in> ?P G (N-{n})" using 6 by force
  then have "?aa +< (i, ?Y2) \<in> ?X" by (metis converse_converse image_eqI)
  then have "?p b (?aa +< (i, ?Y2)) \<in> (?p b)`?X" by blast
  moreover have "finite (?p b ` ?X)" sorry
  ultimately have "?p b (?aa +< (i, ?Y2)) \<le> Max ((?p b) ` ?X)" using Max_ge by blast
  moreover have "b (i, ?Y1) \<le> b (i, ?Y2)" sorry (* MC: this is monotonicity assumption *)
  moreover have "finite ?aa" sorry
  ultimately moreover have " ?p b (?aa +< (i, ?Y2)) \<ge> ?p b (?aa +< (i, ?Y1))" using lll75
  by blast
  ultimately show ?thesis  using 1 by force
qed

lemma "value_rel (b::bids) a = proceeds (altbids b) (a^-1)" using value_rel_def sorry

end

