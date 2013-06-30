(*
$Id: Partitions.thy 1274 2013-06-27 10:01:36Z langec $

Auction Theory Toolbox

Authors:
* Christoph Lange <math.semantic.web@gmail.com>
* Marco B. Caminati <marco.caminati@gmail.com>

Dually licenced under
* Creative Commons Attribution (CC-BY) 3.0
* ISC License (1-clause BSD License)
See LICENSE file for details
(Rationale for this dual licence: http://arxiv.org/abs/1107.3212)
*)

theory RelationProperties
imports Main
begin

definition left_total_on :: "('a \<times> 'b) set \<Rightarrow> 'a set \<Rightarrow> bool"
where "left_total_on R A \<longleftrightarrow> (\<forall> x \<in> A . \<exists> y . (x, y) \<in> R)"

definition right_unique :: "('a \<times> 'b) set \<Rightarrow> bool"
where "right_unique R \<longleftrightarrow> (\<forall> a \<in> Domain R . card (R `` {a}) \<le> 1)"

definition function_on :: "('a \<times> 'b) set \<Rightarrow> 'a set \<Rightarrow> bool"
where "function_on R A \<longleftrightarrow> left_total_on R A \<and> right_unique R"

definition as_part_fun :: "('a \<times> 'b) set \<Rightarrow> 'a \<rightharpoonup> 'b"
where "as_part_fun R a = (let im = R `` {a} in 
        if im = {} then None
        else Some (THE b . b \<in> im))"

definition as_function :: "('a \<times> 'b) set \<Rightarrow> 'a \<Rightarrow> 'b"
where "as_function R a = (THE b . b \<in> R `` {a})"

definition as_func_comp :: "('a \<times> ('b::linorder)) set \<Rightarrow> 'a \<Rightarrow> 'b"
where "as_func_comp R a = hd (sorted_list_of_set (R `` {a}))"

value "as_func_comp {(1::nat, 2::nat), (2::nat, 4::nat)} 1::nat"

lemma "function_on {(1::nat, 2::nat), (2::nat, 4::nat)} {1::nat}"
unfolding function_on_def left_total_on_def right_unique_def
oops

lemma "(as_function {(1::nat, 2::nat), (2::nat, 4::nat)} 1::nat) = (2::nat)"
unfolding as_function_def
oops

definition injective :: "('a \<times> 'b) set \<Rightarrow> bool"
where "injective R \<longleftrightarrow> (\<forall> a \<in> Domain R . \<forall> b \<in> Domain R . R `` {a} = R `` {b} \<longrightarrow> a = b)"

definition inverse :: "('a \<times> 'b) set \<Rightarrow> ('b \<times> 'a) set"
where "inverse R = { (y, x) . (x, y) \<in> R }"

(* TODO CL: Now that we can "easily" generate all total functions,
   maybe let's revert the "option type" stuff in nVCG.thy (which we introduced to allow for non-totality).
   Or otherwise we might enable this function to generate partial functions.
   This would have to be done by recursing not just to "xs", but to 
   all sublists of "x # xs" of length n - 1.
 *)
fun injective_functions :: "'a list \<Rightarrow> 'b list \<Rightarrow> ('a \<times> 'b) set set"
where "injective_functions [] ys = {{}}"
    | "injective_functions (x # xs) ys = 
       \<Union> (\<lambda> f . (\<lambda> free_in_range . f \<union> {(x, free_in_range)})
                 ` ((set ys) - (Range f)))
          ` (injective_functions xs ys)"

value "injective_functions [False,True] [0::nat, 1, 2]"

fun injective_functions_list :: "'a list \<Rightarrow> 'b::linorder list \<Rightarrow> ('a \<times> 'b) set list"
where "injective_functions_list [] ys = [{}]"
    | "injective_functions_list (x # xs) ys = 
      concat [ map (\<lambda> free_in_range . f \<union> {(x, free_in_range)})
                 (sorted_list_of_set ((set ys) - (Range f))) . f \<leftarrow> injective_functions_list xs ys ]"

value "injective_functions_list [False,True] [0::nat, 1, 2]"

end