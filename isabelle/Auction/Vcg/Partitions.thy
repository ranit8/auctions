(*
Auction Theory Toolbox (http://formare.github.io/auctions/)

Authors:
* Christoph Lange <math.semantic.web@gmail.com>
* Marco B. Caminati http://caminati.co.nr

Dually licenced under
* Creative Commons Attribution (CC-BY) 3.0
* ISC License (1-clause BSD License)
See LICENSE file for details
(Rationale for this dual licence: http://arxiv.org/abs/1107.3212)
*)

header {* Partitions of sets *}

theory Partitions
imports
  Main
  SetUtils

begin

text {*
We define the set of all partitions of a set (@{term all_partitions}) in textbook style, as well as
a function @{term all_partitions_list} to algorithmically compute this set (then represented as a
list).  This function is suitable for code generation.  We prove their equivalence to ensure that
the generated code correctly implements the original textbook-style definition.  For further 
background on the overall approach, see Caminati, Kerber, Lange, Rowat:
\href{http://arxiv.org/abs/1308.1779}{Proving soundness of combinatorial Vickrey auctions and
generating verified executable code}, 2013.
*}

text {* @{term P} is a partition of some set. *}
definition is_partition where
"is_partition P = (\<forall> X\<in>P . \<forall> Y\<in> P . (X \<inter> Y \<noteq> {} \<longleftrightarrow> X = Y))"
(* alternative, less concise formalisation:
"is_partition P = (\<forall> ec1 \<in> P . ec1 \<noteq> {} \<and> (\<forall> ec2 \<in> P - {ec1}. ec1 \<inter> ec2 = {}))"
*)

text {* A subset of a partition is also a partition (but, note: only of a subset of the original set) *}
lemma subset_is_partition:
  assumes subset: "P \<subseteq> Q"
      and partition: "is_partition Q"
  shows "is_partition P"
(* CL: The following takes 387 ms with Isabelle2013-1-RC1:
   by (metis is_partition_def partition set_rev_mp subset) *)
proof -
  {
    fix X Y assume "X \<in> P \<and> Y \<in> P"
    then have "X \<in> Q \<and> Y \<in> Q" using subset by fast
    then have "X \<inter> Y \<noteq> {} \<longleftrightarrow> X = Y" using partition unfolding is_partition_def by force
  }
  then show ?thesis unfolding is_partition_def by force
qed

(* This is not used at the moment, but it is interesting, as the proof
   was very hard to find for Sledgehammer. *)
text {* The set that results from removing one element from an equivalence class of a partition
  is not otherwise a member of the partition. *}
lemma remove_from_eq_class_preserves_disjoint:
  fixes elem::'a
    and X::"'a set"
    and P::"'a set set"
  assumes partition: "is_partition P"
      and eq_class: "X \<in> P"
      and elem: "elem \<in> X"
  shows "X - {elem} \<notin> P"
 using assms
 Int_Diff is_partition_def 
by (metis Diff_disjoint Diff_eq_empty_iff Int_absorb2 insert_Diff_if insert_not_empty)

text {* Inserting into a partition @{term P} a set @{term X}, which is disjoint with the set 
  partitioned by @{term P}, yields another partition. *}
lemma partition_extension1:
  fixes P::"'a set set"
    and X::"'a set"
  assumes partition: "is_partition P"
      and disjoint: "X \<inter> \<Union> P = {}" 
      and non_empty: "X \<noteq> {}"
  shows "is_partition (insert X P)"
proof -
  {
    fix Y::"'a set" and Z::"'a set"
    assume Y_Z_in_ext_P: "Y \<in> insert X P \<and> Z \<in> insert X P"
    have "Y \<inter> Z \<noteq> {} \<longleftrightarrow> Y = Z"
    proof
      assume "Y \<inter> Z \<noteq> {}"
      then show "Y = Z"
        using Y_Z_in_ext_P partition disjoint
        unfolding is_partition_def
        by fast
    next
      assume "Y = Z"
      then show "Y \<inter> Z \<noteq> {}"
        using Y_Z_in_ext_P partition non_empty
        unfolding is_partition_def
        by auto
    qed
  }
  then show ?thesis unfolding is_partition_def by force
qed

text {* An equivalence class of a partition has no intersection with any of the other 
  equivalence classes. *}
lemma disj_eq_classes:
  fixes P::"'a set set"
    and X::"'a set"
  assumes "is_partition P"
      and "X \<in> P"
  shows "X \<inter> \<Union> (P - {X}) = {}" 
proof -
  {
    fix x::'a
    assume x_in_two_eq_classes: "x \<in> X \<inter> \<Union> (P - {X})"
    then obtain Y where other_eq_class: "Y \<in> P - {X} \<and> x \<in> Y" by blast
    have "x \<in> X \<inter> Y \<and> Y \<in> P"
      using x_in_two_eq_classes other_eq_class by force
    then have "X = Y" using assms is_partition_def by fast
    then have "x \<in> {}" using other_eq_class by fast
  }
  then show ?thesis by blast
qed

text {* In a partition there is no empty equivalence class. *}
lemma no_empty_eq_class:
  assumes "is_partition p"
  shows "{} \<notin> p"
(* CL: The following takes 36 ms with Isabelle2013-1-RC1:
   by (metis Int_iff all_not_in_conv assms is_partition_def) *)
  using assms is_partition_def by fast

text {* @{term P} is a partition of the set @{term A}. *}
definition is_partition_of (infix "partitions" 75)
where "is_partition_of P A = (\<Union> P = A \<and> is_partition P)"

text {* No partition of a non-empty set is empty. *}
lemma non_empty_imp_non_empty_partition:
  assumes "A \<noteq> {}"
      and "is_partition_of P A"
  shows "P \<noteq> {}"
using assms
unfolding is_partition_of_def
by fast

text {* Every element of a partitioned set ends up in an equivalence class. *}
lemma elem_in_eq_class:
  assumes in_set: "x \<in> A"
      and part: "is_partition_of P A"
  obtains X where "x \<in> X" and "X \<in> P"
using part in_set
unfolding is_partition_of_def is_partition_def 
by (auto simp add: UnionE)

text {* Every element of the difference of a set @{term A} and another set @{term B} ends up in 
  an equivalence class of a partition of @{term A}, but this equivalence class will never be
  @{term "{B}"}. *}
lemma diff_elem_in_eq_class:
  assumes x: "x \<in> A - B"
      and part: "is_partition_of P A"
  shows "\<exists> S \<in> P - { B } . x \<in> S"
(* Sledgehammer in Isabelle2013-1-RC1 can't do this within the default time limit. *)
proof -
  from part x obtain X where "x \<in> X" and "X \<in> P"
    by (metis Diff_iff elem_in_eq_class)
  with x have "X \<noteq> B" by fast
  with `x \<in> X` `X \<in> P` show ?thesis by blast
qed

text {* Every element of a partitioned set ends up in exactly one equivalence class. *}
lemma elem_in_uniq_eq_class:
  assumes in_set: "x \<in> A"
      and part: "is_partition_of P A"
  shows "\<exists>! X \<in> P . x \<in> X"
proof -
  from assms obtain X where *: "X \<in> P \<and> x \<in> X"
    by (rule elem_in_eq_class) blast
  moreover {
    fix Y assume "Y \<in> P \<and> x \<in> Y"
    then have "Y = X"
      using part in_set *
      unfolding is_partition_of_def is_partition_def
      by (metis disjoint_iff_not_equal)
  }
  ultimately show ?thesis by (rule ex1I)
qed

text {* A non-empty set is a partition of itself. *}
lemma set_partitions_itself:
  assumes "A \<noteq> {}"
  shows "is_partition_of {A} A" unfolding is_partition_of_def is_partition_def
(* CL: the following takes 48 ms on my machine with Isabelle2013:
   by (metis Sup_empty Sup_insert assms inf_idem singletonE sup_bot_right) *)
proof
  show "\<Union> {A} = A" by simp
  {
    fix X Y
    assume "X \<in> {A}"
    then have "X = A" by (rule singletonD)
    assume "Y \<in> {A}"
    then have "Y = A" by (rule singletonD)
    from `X = A` `Y = A` have "X \<inter> Y \<noteq> {} \<longleftrightarrow> X = Y" using assms by simp
  }
  then show "\<forall> X \<in> {A} . \<forall> Y \<in> {A} . X \<inter> Y \<noteq> {} \<longleftrightarrow> X = Y" by force
qed

text {* The empty set is a partition of the empty set. *}
lemma emptyset_part_emptyset1:
  shows "is_partition_of {} {}" 
  unfolding is_partition_of_def is_partition_def by fast

text {* Any partition of the empty set is empty. *}
lemma emptyset_part_emptyset2:
  assumes "is_partition_of P {}"
  shows "P = {}"
  using assms is_partition_def is_partition_of_def by fast

text {* classical set-theoretical definition of ``all partitions of a set @{term A}'' *}
definition all_partitions where 
"all_partitions A = {P . is_partition_of P A}"

text {* The set of all partitions of the empty set only contains the empty set.
  We need this to prove the base case of @{term all_partitions_paper_equiv_alg}. *}
lemma emptyset_part_emptyset3:
  shows "all_partitions {} = {{}}"
  unfolding all_partitions_def
  using emptyset_part_emptyset1 emptyset_part_emptyset2
  by fast

text {* inserts an element into a specified set inside the given set of sets *}
definition insert_into_member :: "'a \<Rightarrow> 'a set set \<Rightarrow> 'a set \<Rightarrow> 'a set set"
where "insert_into_member new_el Sets S = insert (S \<union> {new_el}) (Sets - {S})"

text {* Using @{const insert_into_member} to insert a fresh element, which is not a member of the
  set @{term S} being partitioned, into an equivalence class of a partition yields another
  partition (of -- we don't prove this here -- the set @{term "S \<union> {new_el}"}). *}
lemma partition_extension2:
  fixes new_el::'a
    and P::"'a set set"
    and X::"'a set"
  assumes partition: "is_partition P"
      and eq_class: "X \<in> P"
      and new: "new_el \<notin> \<Union> P"
shows "is_partition (insert_into_member new_el P X)"
proof -
  let ?Y = "insert new_el X"
  have rest_is_partition: "is_partition (P - {X})"
    using partition subset_is_partition by blast
  have *: "X \<inter> \<Union> (P - {X}) = {}"
   using partition eq_class by (rule disj_eq_classes)
  from * have non_empty: "?Y \<noteq> {}" by blast
  from * have disjoint: "?Y \<inter> \<Union> (P - {X}) = {}" using new by force
  have "is_partition (insert ?Y (P - {X}))"
    using rest_is_partition disjoint non_empty by (rule partition_extension1)
  then show ?thesis unfolding insert_into_member_def by simp
qed

text {* inserts an element into a specified set inside the given list of sets --
   the list variant of @{const insert_into_member}

   The rationale for this variant and for everything that depends on it is:
   While it is possible to computationally enumerate ``all partitions of a set'' as an
   @{typ "'a set set set"}, we need a list representation to apply further computational
   functions to partitions.  Because of the way we construct partitions (using functions
   such as @{term all_coarser_partitions_with} below) it is not sufficient to simply use 
   @{typ "'a set set list"}, but we need @{typ "'a set list list"}.  This is because it is hard 
   to impossible to convert a set to a list, whereas it is easy to convert a @{type list} to a @{type set}.
*}
definition insert_into_member_list
:: "'a \<Rightarrow> 'a set list \<Rightarrow> 'a set \<Rightarrow> 'a set list"
where "insert_into_member_list new_el Sets S = (S \<union> {new_el}) # (remove1 S Sets)"

text {* @{const insert_into_member_list} and @{const insert_into_member} are equivalent
  (as in returning the same set). *}
lemma insert_into_member_list_alt:
  fixes new_el::'a
    and Sets::"'a set list"
    and S::"'a set"
  assumes "distinct Sets"
  shows "set (insert_into_member_list new_el Sets S) = insert_into_member new_el (set Sets) S"
unfolding insert_into_member_list_def insert_into_member_def
using assms
by simp

text {* an alternative characterisation of the set partitioned by a partition obtained by 
  inserting an element into an equivalence class of a given partition (if @{term P}
  \emph{is} a partition) *}
lemma insert_into_member_partition1:
  fixes elem::'a
    and P::"'a set set"
    and eq_class::"'a set"
  (* no need to assume "eq_class \<in> P" *)
  shows "\<Union> insert_into_member elem P eq_class = \<Union> insert (eq_class \<union> {elem}) (P - {eq_class})"
(* CL: The following takes 12 ms in Isabelle2013-1-RC1:
   by (metis insert_into_member_def) *)
    unfolding insert_into_member_def
    by fast

(* TODO CL: document for the general case of a non-partition argument as per https://github.com/formare/auctions/issues/20 *)
text {* Assuming that @{term P} is a partition of a set @{term S}, and @{term "new_el \<notin> S"}, this function yields
  all possible partitions of @{term "S \<union> {new_el}"} that are coarser than @{term P}
  (i.e.\ not splitting equivalence classes that already exist in @{term P}).  These comprise one partition 
  with an equivalence class @{term "{new_el}"} and all other equivalence classes unchanged,
  as well as all partitions obtained by inserting @{term new_el} into one equivalence class of @{term P} at a time. *}
definition coarser_partitions_with ::"'a \<Rightarrow> 'a set set \<Rightarrow> 'a set set set"
where "coarser_partitions_with new_el P = 
  insert
  (* Let P be a partition of a set Set,
     and suppose new_el \<notin> Set, i.e. {new_el} \<notin> P,
     then the following constructs a partition of 'Set \<union> {new_el}' obtained by
     inserting a new equivalence class {new_el} and leaving all previous equivalence classes unchanged. *)
  (insert {new_el} P)
  (* Let P be a partition of a set Set,
     and suppose new_el \<notin> Set,
     then the following constructs
     the set of those partitions of 'Set \<union> {new_el}' obtained by
     inserting new_el into one equivalence class of P at a time. *)
  ((insert_into_member new_el P) ` P)"

(* TODO CL: document for the general case of a non-partition argument as per https://github.com/formare/auctions/issues/20 *)
text {* the list variant of @{const coarser_partitions_with} *}
definition coarser_partitions_with_list ::"'a \<Rightarrow> 'a set list \<Rightarrow> 'a set list list"
where "coarser_partitions_with_list new_el P = 
  (* Let P be a partition of a set Set,
     and suppose new_el \<notin> Set, i.e. {new_el} \<notin> set P,
     then the following constructs a partition of 'Set \<union> {new_el}' obtained by
     inserting a new equivalence class {new_el} and leaving all previous equivalence classes unchanged. *)
  ({new_el} # P)
  #
  (* Let P be a partition of a set Set,
     and suppose new_el \<notin> Set,
     then the following constructs
     the set of those partitions of 'Set \<union> {new_el}' obtained by
     inserting new_el into one equivalence class of P at a time. *)
  (map ((insert_into_member_list new_el P)) P)"

text {* @{const coarser_partitions_with_list} and @{const coarser_partitions_with} are equivalent. *}
lemma coarser_partitions_with_list_alt:
  assumes "distinct P"
  shows "set (map set (coarser_partitions_with_list new_el P)) = coarser_partitions_with new_el (set P)"
proof -
  have "set (map set (coarser_partitions_with_list new_el P)) = set (map set (({new_el} # P) # (map ((insert_into_member_list new_el P)) P)))"
    unfolding coarser_partitions_with_list_def ..
  also have "\<dots> = insert (insert {new_el} (set P)) ((set \<circ> (insert_into_member_list new_el P)) ` set P)"
    by simp
  also have "\<dots> = insert (insert {new_el} (set P)) ((insert_into_member new_el (set P)) ` set P)"
    using assms insert_into_member_list_alt by (metis comp_apply)
  finally show ?thesis unfolding coarser_partitions_with_def .
qed

text {* Any member of the set of coarser partitions of a given partition, obtained by inserting 
  a given fresh element into each of its equivalence classes, actually is a partition. *}
lemma partition_extension3:
  fixes elem::'a
    and P::"'a set set"
    and Q::"'a set set"
  assumes P_partition: "is_partition P"
      and new_elem: "elem \<notin> \<Union> P"
      and Q_coarser: "Q \<in> coarser_partitions_with elem P"
  shows "is_partition Q"
proof -
  let ?q = "insert {elem} P"
  have Q_coarser_unfolded: "Q \<in> insert ?q (insert_into_member elem P ` P)" 
    using Q_coarser 
    unfolding coarser_partitions_with_def
    by fast
  show ?thesis
  proof (cases "Q = ?q")
    case True
    then show ?thesis
      using P_partition new_elem partition_extension1
      by fastforce
  next
    case False
    then have "Q \<in> (insert_into_member elem P) ` P" using Q_coarser_unfolded by fastforce
    then show ?thesis using partition_extension2 P_partition new_elem by fast
  qed
qed

text {* Let @{term P} be a partition of a set @{term S}, and @{term elem} an element (which may or may not be
  in @{term S} already).  Then, any member of @{term "coarser_partitions_with elem P"} is a set of sets
  whose union is @{term "S \<union> {elem}"}, i.e.\ it satisfies a necessary criterion for being a partition of @{term "S \<union> {elem}"}.
*}
lemma coarser_partitions_covers:
  fixes elem::'a
    and P::"'a set set"
    and Q::"'a set set"
  assumes "Q \<in> coarser_partitions_with elem P"
  shows "\<Union> Q = insert elem (\<Union> P)"
proof -
  let ?S = "\<Union> P"
  have Q_cases: "Q \<in> (insert_into_member elem P) ` P \<or> Q = insert {elem} P"
    using assms unfolding coarser_partitions_with_def by fast
  {
    fix eq_class assume eq_class_in_P: "eq_class \<in> P"
    have "\<Union> insert (eq_class \<union> {elem}) (P - {eq_class}) = ?S \<union> (eq_class \<union> {elem})"
      using insert_into_member_partition1
      by (metis Sup_insert Un_commute Un_empty_right Un_insert_right insert_Diff_single)
    with eq_class_in_P have "\<Union> insert (eq_class \<union> {elem}) (P - {eq_class}) = ?S \<union> {elem}" by blast
    then have "\<Union> insert_into_member elem P eq_class = ?S \<union> {elem}"
      using insert_into_member_partition1
      by (rule subst)
  }
  then show ?thesis using Q_cases by blast
qed

text {* Removes the element @{term elem} from every set in @{term P}, and removes from @{term P} any
  remaining empty sets.  This function is intended to be applied to partitions, i.e. @{term elem}
  occurs in at most one set.  @{term "partition_without e"} reverses @{term "coarser_partitions_with e"}.
@{const coarser_partitions_with} is one-to-many, while this is one-to-one, so we can think of a tree relation,
where coarser partitions of a set @{term "S \<union> {elem}"} are child nodes of one partition of @{term S}. *}
definition partition_without :: "'a \<Rightarrow> 'a set set \<Rightarrow> 'a set set"
where "partition_without elem P = (\<lambda>X . X - {elem}) ` P - {{}}"
(* Set comprehension notation { x - {elem} | x . x \<in> P } would look nicer but is harder to do proofs about *)

(* We don't need to define partition_without_list. *)

text {* alternative characterisation of the set partitioned by the partition obtained 
  by removing an element from a given partition using @{const partition_without} *}
lemma partition_without_covers:
  fixes elem::'a
    and P::"'a set set"
  shows "\<Union> partition_without elem P = \<Union> P - {elem}"
proof -
  have "\<Union> partition_without elem P = \<Union> ((\<lambda>x . x - {elem}) ` P - {{}})"
    unfolding partition_without_def by fast
  also have "\<dots> = \<Union> P - {elem}" by blast
  finally show ?thesis .
qed

text {* Any equivalence class of the partition obtained by removing an element @{term elem} from an
  original partition @{term P} using @{const partition_without} equals some equivalence
  class of @{term P}, reduced by @{term elem}. *}
lemma super_eq_class:
  assumes "X \<in> partition_without elem P"
  obtains Z where "Z \<in> P" and "X = Z - {elem}"
proof -
  from assms have "X \<in> (\<lambda>X . X - {elem}) ` P - {{}}" unfolding partition_without_def .
  then obtain Z where Z_in_P: "Z \<in> P" and Z_sup: "X = Z - {elem}"
    by (metis (lifting) Diff_iff image_iff)
  then show ?thesis ..
qed

text {* The set of sets obtained by removing an element from a partition actually is another
  partition. *}
lemma partition_without_is_partition:
  fixes elem::'a
    and P::"'a set set"
  assumes "is_partition P"
  shows "is_partition (partition_without elem P)" (is "is_partition ?Q")
proof -   
  have "\<forall> X1 \<in> ?Q. \<forall> X2 \<in> ?Q. X1 \<inter> X2 \<noteq> {} \<longleftrightarrow> X1 = X2"
  proof 
    fix X1 assume X1_in_Q: "X1 \<in> ?Q"
    then obtain Z1 where Z1_in_P: "Z1 \<in> P" and Z1_sup: "X1 = Z1 - {elem}"
      by (rule super_eq_class)
    have X1_non_empty: "X1 \<noteq> {}" using X1_in_Q partition_without_def by fast
    show "\<forall> X2 \<in> ?Q. X1 \<inter> X2 \<noteq> {} \<longleftrightarrow> X1 = X2" 
    proof
      fix X2 assume "X2 \<in> ?Q"
      then obtain Z2 where Z2_in_P: "Z2 \<in> P" and Z2_sup: "X2 = Z2 - {elem}"
        by (rule super_eq_class)
      have "X1 \<inter> X2 \<noteq> {} \<longrightarrow> X1 = X2"
      proof
        assume "X1 \<inter> X2 \<noteq> {}"
        then have "Z1 \<inter> Z2 \<noteq> {}" using Z1_sup Z2_sup by fast
        then have "Z1 = Z2" using Z1_in_P Z2_in_P assms unfolding is_partition_def by fast
        then show "X1 = X2" using Z1_sup Z2_sup by fast
      qed
      moreover have "X1 = X2 \<longrightarrow> X1 \<inter> X2 \<noteq> {}" using X1_non_empty by auto
      ultimately show "(X1 \<inter> X2 \<noteq> {}) \<longleftrightarrow> X1 = X2" by blast
    qed
  qed
  then show ?thesis unfolding is_partition_def .
qed

text {* @{term "coarser_partitions_with elem"} is the ``inverse'' of 
  @{term "partition_without elem"}. *}
lemma coarser_partitions_inv_without:
  fixes elem::'a
    and P::"'a set set"
  assumes partition: "is_partition P"
      and elem: "elem \<in> \<Union> P" 
  shows "P \<in> coarser_partitions_with elem (partition_without elem P)"
    (is "P \<in> coarser_partitions_with elem ?Q")
proof -
  let ?remove_elem = "\<lambda>X . X - {elem}" (* function that removes elem out of a set *)
  obtain Y (* the equivalence class of elem *)
    where elem_eq_class: "elem \<in> Y" and elem_eq_class': "Y \<in> P" using elem ..
  let ?elem_neq_classes = "P - {Y}" (* those equivalence classes in which elem is not *)
  have P_wrt_elem: "P = ?elem_neq_classes \<union> {Y}" using elem_eq_class' by blast
  let ?elem_eq = "Y - {elem}" (* other elements equivalent to elem *)
  have Y_elem_eq: "?remove_elem ` {Y} = {?elem_eq}" by fast
  (* those equivalence classes, in which elem is not, form a partition *)
  have elem_neq_classes_part: "is_partition ?elem_neq_classes"
    using subset_is_partition partition
    by blast
  have elem_eq_wrt_P: "?elem_eq \<in> ?remove_elem ` P" using elem_eq_class' by blast
  
  { (* consider an equivalence class W, in which elem is not *)
    fix W assume W_eq_class: "W \<in> ?elem_neq_classes"
    then have "elem \<notin> W"
      using elem_eq_class elem_eq_class' partition is_partition_def
      by fast
    then have "?remove_elem W = W" by simp
  }
  then have elem_neq_classes_id: "?remove_elem ` ?elem_neq_classes = ?elem_neq_classes" by fastforce

  have Q_unfolded: "?Q = ?remove_elem ` P - {{}}"
    unfolding partition_without_def
    using image_Collect_mem
    by blast
  also have "\<dots> = ?remove_elem ` (?elem_neq_classes \<union> {Y}) - {{}}" using P_wrt_elem by presburger
  also have "\<dots> = ?elem_neq_classes \<union> {?elem_eq} - {{}}"
    using Y_elem_eq elem_neq_classes_id image_Un by metis
  finally have Q_wrt_elem: "?Q = ?elem_neq_classes \<union> {?elem_eq} - {{}}" .

  have "?elem_eq = {} \<or> ?elem_eq \<notin> P"
    using elem_eq_class elem_eq_class' partition Diff_Int_distrib2 Diff_iff empty_Diff insert_iff
unfolding is_partition_def by metis
  then have "?elem_eq \<notin> P"
    using partition no_empty_eq_class
    by metis
  then have elem_neq_classes: "?elem_neq_classes - {?elem_eq} = ?elem_neq_classes" by fastforce

  show ?thesis
  proof cases
    assume "?elem_eq \<notin> ?Q" (* the equivalence class of elem is not a member of ?Q = partition_without elem P *)
    then have "?elem_eq \<in> {{}}"
      using elem_eq_wrt_P Q_unfolded
      by (metis DiffI)
    then have Y_singleton: "Y = {elem}" using elem_eq_class by fast
    then have "?Q = ?elem_neq_classes - {{}}"
      using Q_wrt_elem
      by force
    then have "?Q = ?elem_neq_classes"
      using no_empty_eq_class elem_neq_classes_part
      by blast
    then have "insert {elem} ?Q = P"
      using Y_singleton elem_eq_class'
      by fast
    then show ?thesis unfolding coarser_partitions_with_def by auto
  next
    assume True: "\<not> ?elem_eq \<notin> ?Q"
    hence Y': "?elem_neq_classes \<union> {?elem_eq} - {{}} = ?elem_neq_classes \<union> {?elem_eq}"
      using no_empty_eq_class partition partition_without_is_partition
      by force
    have "insert_into_member elem ({?elem_eq} \<union> ?elem_neq_classes) ?elem_eq = insert (?elem_eq \<union> {elem}) (({?elem_eq} \<union> ?elem_neq_classes) - {?elem_eq})"
      unfolding insert_into_member_def ..
    also have "\<dots> = ({} \<union> ?elem_neq_classes) \<union> {?elem_eq \<union> {elem}}" using elem_neq_classes by force
    also have "\<dots> = ?elem_neq_classes \<union> {Y}" using elem_eq_class by blast
    finally have "insert_into_member elem ({?elem_eq} \<union> ?elem_neq_classes) ?elem_eq = ?elem_neq_classes \<union> {Y}" .
    then have "?elem_neq_classes \<union> {Y} = insert_into_member elem ?Q ?elem_eq"
      using Q_wrt_elem Y' partition_without_def
      by force
    then have "{Y} \<union> ?elem_neq_classes \<in> insert_into_member elem ?Q ` ?Q" using True by blast
    then have "{Y} \<union> ?elem_neq_classes \<in> coarser_partitions_with elem ?Q" unfolding coarser_partitions_with_def by simp
    then show ?thesis using P_wrt_elem by simp
  qed
qed

text {* Given a set @{term Ps} of partitions, this is intended to compute the set of all coarser
  partitions (given an extension element) of all partitions in @{term Ps}. *}
definition all_coarser_partitions_with :: " 'a \<Rightarrow> 'a set set set \<Rightarrow> 'a set set set"
where "all_coarser_partitions_with elem Ps = \<Union> (coarser_partitions_with elem ` Ps)"

text {* the list variant of @{const all_coarser_partitions_with} *}
definition all_coarser_partitions_with_list :: " 'a \<Rightarrow> 'a set list list \<Rightarrow> 'a set list list"
where "all_coarser_partitions_with_list elem Ps = concat (map (coarser_partitions_with_list elem) Ps)"

text {* @{const all_coarser_partitions_with_list} and @{const all_coarser_partitions_with} are equivalent. *}
lemma all_coarser_partitions_with_list_alt:
  fixes elem::'a
    and Ps::"'a set list list"
  assumes distinct: "\<forall> P \<in> set Ps . distinct P"
  shows "set (map set (all_coarser_partitions_with_list elem Ps)) = all_coarser_partitions_with elem (set (map set Ps))"
    (is "?list_expr = ?set_expr")
proof -
  have "?list_expr = set (map set (concat (map (coarser_partitions_with_list elem) Ps)))"
    unfolding all_coarser_partitions_with_list_def ..
  also have "\<dots> = set ` (\<Union> x \<in> (coarser_partitions_with_list elem) ` (set Ps) . set x)" by simp
    (* This and other intermediate results may not be easy to understand.  I obtained them by 
       conflating multiple “by <simple_method>” steps into one. *)
  also have "\<dots> = set ` (\<Union> x \<in> { coarser_partitions_with_list elem P | P . P \<in> set Ps } . set x)"
    by (simp add: image_Collect_mem)
  also have "\<dots> = \<Union> { set (map set (coarser_partitions_with_list elem P)) | P . P \<in> set Ps }" by auto
  also have "\<dots> = \<Union> { coarser_partitions_with elem (set P) | P . P \<in> set Ps }"
    using distinct coarser_partitions_with_list_alt by fast
  also have "\<dots> = \<Union> (coarser_partitions_with elem ` (set ` (set Ps)))" by (simp add: image_Collect_mem)
  also have "\<dots> = \<Union> (coarser_partitions_with elem ` (set (map set Ps)))" by simp
  also have "\<dots> = ?set_expr" unfolding all_coarser_partitions_with_def ..
  finally show ?thesis .
qed

text {* all partitions of a set (given as list) *}
fun all_partitions_set :: "'a list \<Rightarrow> 'a set set set"
where 
"all_partitions_set [] = {{}}" |
"all_partitions_set (e # X) = all_coarser_partitions_with e (all_partitions_set X)"

text {* all partitions of a set (given as list) *}
fun all_partitions_list :: "'a list \<Rightarrow> 'a set list list"
where 
"all_partitions_list [] = [[]]" |
"all_partitions_list (e # X) = all_coarser_partitions_with_list e (all_partitions_list X)"

text {* A list of partitions coarser than a given partition in list representation (constructed
  with @{const coarser_partitions_with} is distinct under certain conditions. *}
lemma coarser_partitions_with_list_distinct:
  fixes ps
  assumes ps_coarser: "ps \<in> set (coarser_partitions_with_list x Q)"
      and distinct: "distinct Q"
      and partition: "is_partition (set Q)"
      and new: "{x} \<notin> set Q"
  shows "distinct ps"
proof -
  have "set (coarser_partitions_with_list x Q) = insert ({x} # Q) (set (map (insert_into_member_list x Q) Q))"
    unfolding coarser_partitions_with_list_def by simp
  with ps_coarser have "ps \<in> insert ({x} # Q) (set (map ((insert_into_member_list x Q)) Q))" by blast
  then show ?thesis
  proof
    assume "ps = {x} # Q"
    with distinct and new show ?thesis by simp
  next
    assume "ps \<in> set (map (insert_into_member_list x Q) Q)"
    then obtain X where X_in_Q: "X \<in> set Q" and ps_insert: "ps = insert_into_member_list x Q X" by auto
    from ps_insert have "ps = (X \<union> {x}) # (remove1 X Q)" unfolding insert_into_member_list_def .
    also have "\<dots> = (X \<union> {x}) # (removeAll X Q)" using distinct by (metis distinct_remove1_removeAll)
    finally have ps_list: "ps = (X \<union> {x}) # (removeAll X Q)" .
    
    have distinct_tl: "X \<union> {x} \<notin> set (removeAll X Q)"
    proof
      from partition have partition': "\<forall>x\<in>set Q. \<forall>y\<in>set Q. (x \<inter> y \<noteq> {}) = (x = y)" unfolding is_partition_def .
      assume "X \<union> {x} \<in> set (removeAll X Q)"
      with X_in_Q partition show False by (metis partition' inf_sup_absorb member_remove no_empty_eq_class remove_code(1))
    qed
    with ps_list distinct show ?thesis by (metis (full_types) distinct.simps(2) distinct_removeAll)
  qed
qed

text {* The paper-like definition @{const all_partitions} and the algorithmic definition
  @{const all_partitions_list} are equivalent. *}
lemma all_partitions_paper_equiv_alg':
  fixes xs::"'a list"
  shows "distinct xs \<Longrightarrow> ((set (map set (all_partitions_list xs)) = all_partitions (set xs)) \<and> (\<forall> ps \<in> set (all_partitions_list xs) . distinct ps))"
proof (induct xs)
  case Nil
  have "set (map set (all_partitions_list [])) = all_partitions (set [])"
    unfolding List.set_simps(1) emptyset_part_emptyset3 by simp
    (* Sledgehammer no longer seems to find this, maybe after we have added the "distinct" part to the theorem statement. *)
  moreover have "\<forall> ps \<in> set (all_partitions_list []) . distinct ps" by fastforce
  ultimately show ?case ..
next
  case (Cons x xs)
  from Cons.prems Cons.hyps
    have hyp_equiv: "set (map set (all_partitions_list xs)) = all_partitions (set xs)" by simp
  from Cons.prems Cons.hyps
    have hyp_distinct: "\<forall> ps \<in> set (all_partitions_list xs) . distinct ps" by simp

  have distinct_xs: "distinct xs" using Cons.prems by simp
  have x_notin_xs: "x \<notin> set xs" using Cons.prems by simp
  
  have "set (map set (all_partitions_list (x # xs))) = all_partitions (set (x # xs))"
  proof (rule equalitySubsetI) (* -- {* case set \<rightarrow> list *} *)
    fix P::"'a set set" (* a partition *)
    let ?P_without_x = "partition_without x P"
    have P_partitions_exc_x: "\<Union> ?P_without_x = \<Union> P - {x}" using partition_without_covers .

    assume "P \<in> all_partitions (set (x # xs))"
    then have is_partition_of: "is_partition_of P (set (x # xs))" unfolding all_partitions_def ..
    then have is_partition: "is_partition P" unfolding is_partition_of_def by simp
    from is_partition_of have P_covers: "\<Union> P = set (x # xs)" unfolding is_partition_of_def by simp

    have "is_partition_of ?P_without_x (set xs)"
      unfolding is_partition_of_def
      using is_partition partition_without_is_partition partition_without_covers P_covers x_notin_xs
      by (metis Diff_insert_absorb List.set_simps(2))
    with hyp_equiv have p_list: "?P_without_x \<in> set (map set (all_partitions_list xs))"
      unfolding all_partitions_def by fast
    have "P \<in> coarser_partitions_with x ?P_without_x"
      using coarser_partitions_inv_without is_partition P_covers
      by (metis List.set_simps(2) insertI1)
    then have "P \<in> \<Union> (coarser_partitions_with x ` set (map set (all_partitions_list xs)))"
      using p_list by blast
    then have "P \<in> all_coarser_partitions_with x (set (map set (all_partitions_list xs)))"
      unfolding all_coarser_partitions_with_def by fast
    then show "P \<in> set (map set (all_partitions_list (x # xs)))"
      using all_coarser_partitions_with_list_alt hyp_distinct
      by (metis all_partitions_list.simps(2))
  next (* -- {* case list \<rightarrow> set *} *)
    fix P::"'a set set" (* a partition *)
    assume P: "P \<in> set (map set (all_partitions_list (x # xs)))"

    have "set (map set (all_partitions_list (x # xs))) = set (map set (all_coarser_partitions_with_list x (all_partitions_list xs)))"
      by simp
    also have "\<dots> = all_coarser_partitions_with x (set (map set (all_partitions_list xs)))"
      using distinct_xs hyp_distinct all_coarser_partitions_with_list_alt by fast
    also have "\<dots> = all_coarser_partitions_with x (all_partitions (set xs))"
      using distinct_xs hyp_equiv by auto
    finally have P_set: "set (map set (all_partitions_list (x # xs))) = all_coarser_partitions_with x (all_partitions (set xs))" .

    with P have "P \<in> all_coarser_partitions_with x (all_partitions (set xs))" by fast
    then have "P \<in> \<Union> (coarser_partitions_with x ` (all_partitions (set xs)))"
      unfolding all_coarser_partitions_with_def .
    then obtain Y
      where P_in_Y: "P \<in> Y"
        and Y_coarser: "Y \<in> coarser_partitions_with x ` (all_partitions (set xs))" ..
    from Y_coarser obtain Q
      where Q_part_xs: "Q \<in> all_partitions (set xs)"
        and Y_coarser': "Y = coarser_partitions_with x Q" ..
    from P_in_Y Y_coarser' have P_wrt_Q: "P \<in> coarser_partitions_with x Q" by fast
    then have "Q \<in> all_partitions (set xs)" using Q_part_xs by simp
    then have "is_partition_of Q (set xs)" unfolding all_partitions_def ..
    then have "is_partition Q" and Q_covers: "\<Union> Q = set xs"
      unfolding is_partition_of_def by simp_all
    then have P_partition: "is_partition P"
      using partition_extension3 P_wrt_Q x_notin_xs by fast
    have "\<Union> P = set xs \<union> {x}"
      using Q_covers P_in_Y Y_coarser' coarser_partitions_covers by fast
    then have "\<Union> P = set (x # xs)"
      using x_notin_xs P_wrt_Q Q_covers
      by (metis List.set_simps(2) insert_is_Un sup_commute)
    then have "is_partition_of P (set (x # xs))"
      using P_partition unfolding is_partition_of_def by blast
    then show "P \<in> all_partitions (set (x # xs))" unfolding all_partitions_def ..
  qed
  moreover have "\<forall> ps \<in> set (all_partitions_list (x # xs)) . distinct ps"
  proof
    fix ps::"'a set list" assume ps_part: "ps \<in> set (all_partitions_list (x # xs))"

    have "set (all_partitions_list (x # xs)) = set (all_coarser_partitions_with_list x (all_partitions_list xs))"
      by simp
    also have "\<dots> = set (concat (map (coarser_partitions_with_list x) (all_partitions_list xs)))"
      unfolding all_coarser_partitions_with_list_def ..
    also have "\<dots> = \<Union> ((set \<circ> (coarser_partitions_with_list x)) ` (set (all_partitions_list xs)))"
      by simp
    finally have all_parts_unfolded: "set (all_partitions_list (x # xs)) = \<Union> ((set \<circ> (coarser_partitions_with_list x)) ` (set (all_partitions_list xs)))" .
    (* \<dots> = \<Union> { set (coarser_partitions_with_list x ps) | ps . ps \<in> set (all_partitions_list xs) }
       (more readable, but less useful in proofs) *)

    with ps_part obtain qs
      where qs: "qs \<in> set (all_partitions_list xs)"
        and ps_coarser: "ps \<in> set (coarser_partitions_with_list x qs)"
      using UnionE comp_def imageE by auto

    from qs have "set qs \<in> set (map set (all_partitions_list (xs)))" by simp
    with distinct_xs hyp_equiv have qs_hyp: "set qs \<in> all_partitions (set xs)" by fast
    then have qs_part: "is_partition (set qs)"
      using all_partitions_def is_partition_of_def
      by (metis mem_Collect_eq)
    then have distinct_qs: "distinct qs"
      using qs distinct_xs hyp_distinct by fast
    
    from Cons.prems have "x \<notin> set xs" by simp
    then have new: "{x} \<notin> set qs"
      using qs_hyp
      unfolding all_partitions_def is_partition_of_def
      by (metis (lifting, mono_tags) UnionI insertI1 mem_Collect_eq)

    from ps_coarser distinct_qs qs_part new
      show "distinct ps" by (rule coarser_partitions_with_list_distinct)
  qed
  ultimately show ?case ..
qed

text {* The paper-like definition @{const all_partitions} and the algorithmic definition
  @{const all_partitions_list} are equivalent.  This is a frontend theorem derived from
  @{thm all_partitions_paper_equiv_alg'}; it does not make the auxiliary statement about partitions
  being distinct lists. *}
theorem all_partitions_paper_equiv_alg:
  fixes xs::"'a list"
  shows "distinct xs \<Longrightarrow> set (map set (all_partitions_list xs)) = all_partitions (set xs)"
  using all_partitions_paper_equiv_alg' by blast

text {* The function that we will be using in practice to compute all partitions of a set,
  a set-oriented frontend to @{const all_partitions_list} *}
definition all_partitions_alg :: "'a\<Colon>linorder set \<Rightarrow> 'a set list list"
where "all_partitions_alg X = all_partitions_list (sorted_list_of_set X)"

(* TODO CL: maybe delete as per https://github.com/formare/auctions/issues/21 *)
corollary mm90[code_unfold]: 
  fixes X
  assumes "finite X"
  shows "all_partitions X = set (map set (all_partitions_alg X))"
    unfolding all_partitions_alg_def
  using assms by (metis all_partitions_paper_equiv_alg' sorted_list_of_set)
(* all_partitions internally works with a list representing a set
   (this allows us to use the recursive function all_partitions_list).
   For a general list we can only guarantee compliance once we establish distinctness. *)

(* TODO CL: choose a better name, and document *)
lemma remove_singleton_eq_class_from_part:
  assumes singleton_eq_class: "{X} \<subseteq> P"
      and part: "is_partition P"
  shows "(P - {X}) \<inter> {Y \<union> X} = {}"
    using assms unfolding is_partition_def
    by (metis Diff_disjoint Diff_iff Int_absorb2 Int_insert_right_if0 Un_upper2 empty_Diff insert_subset subset_refl)

text {* If new elements are added to a set, for any partition @{term P} of the original set,
  we can obtain a partition @{term Q} of the enlarged set by adding the new elements as a new equivalence class,
  and each equivalence class in @{term P} is a subset of one equivalence class in @{term Q}. *}
lemma exists_partition_of_strictly_larger_set:
  assumes part: "P partitions A"
      and new: "B \<inter> A = {}"
      and non_empty: "B \<noteq> {}"
  shows "(P \<union> {B}) partitions (A \<union> B) \<and> (\<forall> X \<in> P . \<exists> Y \<in> P \<union> {B} . X \<subseteq> Y)"
proof
  show "(P \<union> {B}) partitions (A \<union> B)"
    unfolding is_partition_of_def is_partition_def
  proof
    from part have "\<Union> P = A" unfolding is_partition_of_def ..

    show "\<Union> (P \<union> {B}) = A \<union> B"
    proof -
      from part have "\<Union> P = A" unfolding is_partition_of_def ..
      then show ?thesis by auto
    qed
    show "\<forall> X \<in> P \<union> {B} . \<forall> Y \<in> P \<union> {B} . (X \<inter> Y \<noteq> {} \<longleftrightarrow> X = Y)"
    proof
      fix X assume X_class: "X \<in> P \<union> {B}"
      show "\<forall> Y \<in> P \<union> {B} . (X \<inter> Y \<noteq> {} \<longleftrightarrow> X = Y)" using assms Un_insert_right X_class 
      is_partition_def is_partition_of_def partition_extension1 sup_bot.right_neutral by (metis(no_types))
    qed
  qed
  show "\<forall> X \<in> P . \<exists> Y \<in> P \<union> {B} . X \<subseteq> Y"
  proof
    fix X assume "X \<in> P"
    then have "X \<in> P \<union> {B}" by (rule UnI1)
    then show "\<exists> Y \<in> P \<union> {B} . X \<subseteq> Y" by blast
  qed
qed

text {* If zero or more new elements are added to a set,
  one can obtain for any partition @{term P} of the original set
  a partition @{term Q} of the enlarged set such that each equivalence class in @{term P} is a 
  subset of one equivalence class in @{term Q}. *}
(* TODO CL: choose a more appropriate name *)
lemma exists_partition_of_larger_set:
  assumes part: "P partitions A"
      and new: "B \<inter> A = {}"
  shows "\<exists> Q . Q partitions (A \<union> B) \<and> (\<forall> X \<in> P . \<exists> Y \<in> Q . X \<subseteq> Y)"
proof cases
  assume "B = {}"
  with part have "P partitions (A \<union> B) \<and> (\<forall> X \<in> P . \<exists> Y \<in> P . X \<subseteq> Y)" unfolding is_partition_of_def by auto
  then show ?thesis by fast
next
  assume non_empty: "B \<noteq> {}"
  with part new have "(P \<union> {B}) partitions (A \<union> B) \<and> (\<forall> X \<in> P . \<exists> Y \<in> P \<union> {B} . X \<subseteq> Y)"
    by (rule exists_partition_of_strictly_larger_set)
  then show ?thesis by blast
qed

end
