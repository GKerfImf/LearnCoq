Require Export List Omega.
Import ListNotations.


Lemma TODO:
  False.
Proof. Admitted.

(*** Util. *)

(* This tactic feeds the precondition of an implication in order to derive the conclusion
   (taken from http://comments.gmane.org/gmane.science.mathematics.logic.coq.club/7013).

   Usage: feed H.

   H: P -> Q  ==becomes==>  H: P
                            ____
                            Q

   After completing this proof, Q becomes a hypothesis in the context. *)
Ltac feed H :=
  match type of H with
  | ?foo -> _ =>
    let FOO := fresh in
    assert foo as FOO; [|specialize (H FOO); clear FOO]
  end.

(* Generalization of feed for multiple hypotheses.
   feed_n is useful for accessing conclusions of long implications.

   Usage: feed_n 3 H.
     H: P1 -> P2 -> P3 -> Q.

   We'll be asked to prove P1, P2 and P3, so that Q can be inferred. *)
Ltac feed_n n H := match constr:(n) with
  | O => idtac
  | (S ?m) => feed H ; [| feed_n m H]
  end.


Definition dec X := {X} + {~X}.
Notation "'eq_dec' X" := (forall x y: X, dec (x = y)) (at level 70).

Notation "x 'el' A" := (In x A) (at level 70).
Notation "x 'nel' A" := (~ In x A) (at level 70).

Existing Class dec.
Definition decision (X : Prop) (D : dec X) : dec X := D.
Arguments decision X {D}.

Tactic Notation "decide" constr(p) := 
  destruct (decision p).
Tactic Notation "decide" constr(p) "as" simple_intropattern(i) := 
  destruct (decision p) as i.

Lemma size_recursion (X: Type) (σ: X -> nat) (p: X -> Type):
  (forall x, (forall y, σ y < σ x -> p y) -> p x) -> 
  forall x, p x.
Proof.
  intros D x. apply D.
  cut (forall n y, σ y < n -> p y).
  now eauto.
  clear x. intros n.
  induction n; intros y E.
  - exfalso. omega. 
  - apply D. intros x F. apply IHn. omega.
Defined.

Instance nat_eq_dec: 
  eq_dec nat.
Proof.
  intros x y. hnf. decide equality.
Defined.

Definition equi {X: Type} (A B: list X) : Prop :=
  incl A B /\ incl B A.

Hint Unfold equi.

Lemma inclusion_app {T: Type} (xs1 xs2 xs: list T): 
  incl (xs1 ++ xs2) xs ->
  incl xs1 xs /\ incl xs2 xs.
Proof.
  intros; split.
  - intros x IN.
      specialize (H x).
      assert (EL: x el xs1 ++ xs2).
      { apply in_or_app; left; assumption. }
      eauto.
  - intros x IN.
      specialize (H x).
      assert (EL: x el xs1 ++ xs2).
      { apply in_or_app; right; assumption. }
      eauto.
Defined.

Instance list_in_dec {T: Type} (x: T) (xs: list T): 
  eq_dec T -> dec (x el xs).
Proof.
  intros D; apply in_dec; exact D.
Defined.

Instance inclusion_dec {T: Type} (xs1 xs2: list T):
  eq_dec T -> dec (incl xs1 xs2).
Proof.
  intros D.
  induction xs1.
  { left.
    intros x IN; inversion IN. }
  { destruct IHxs1 as [INCL|NINCL].
    decide (a el xs2) as [IN|NIN].
    { left; intros x IN'.
      destruct IN'.
      - subst x; assumption.
      - specialize (INCL x); auto. } 
    { right.
      intros CONTR.
      apply NIN, CONTR.
      left; reflexivity.
    }
    { right.
      intros CONTR; apply NINCL; clear NINCL.
      intros x IN.
      apply CONTR.
      right; assumption.
    }
  }
Defined.

Lemma singl_in {X: Type} (x y: X):
  x el [y] -> x = y.
Proof.
  intros.
  inversion_clear H; [subst; reflexivity | inversion_clear  H0].
Qed.

(*** TODO *)
(*** Predicates on lists with equivalence *)

Fixpoint mem_e {X: Type} (R: X -> X -> Prop) (x: X) (xs: list X): Prop :=
  match xs with
  | [] => False
  | h::tl => (R x h) \/ (mem_e R x tl)
  end.

(* Definition incl_e {X: Type} (R: X -> X -> Prop) (xs1 xs2: list X) :=
  forall x, mem_e R x xs1 -> mem_e R x xs2.

Definition equiv_e {X: Type} (R: X -> X -> Prop) (xs1 xs2: list X) :=
  incl_e R xs1 xs2 /\ incl_e R xs2 xs1.  *)

  
Lemma mem_app:
  forall {X: Type} (R: X -> X -> Prop) (x: X) (xs1 xs2: list X),
  mem_e R x (xs1 ++ xs2) ->
  {mem_e R x xs1} + {mem_e R x xs2}. 
Proof.
Admitted.

Lemma mem_app_equiv:
  forall {X: Type} (R: X -> X -> Prop) (x: X) (xs1 xs2: list X),
  mem_e R x (xs1 ++ xs2) <-> (mem_e R x xs1) \/ (mem_e R x xs2). 
Proof.
Admitted.


Lemma mem_map_iff:
  forall {X: Type} (R: X -> X -> Prop) (f: X -> X) (l: list X) (y: X),
    mem_e R y (map f l) <-> (exists x: X, R (f x) y /\ mem_e R x l).
Proof.
Admitted.

Fixpoint dupfree_e {X: Type} (equiv: X -> X -> Prop) (xs: list X): Prop :=
  match xs with
  | [] => True
  | h::tl => (~ mem_e equiv h tl) /\ (dupfree_e equiv tl)
  end.


(*** Assignments. *)

(* TODO: comment *)
Inductive variable := V: nat -> variable.

(* TODO: comment *)
Instance eq_var_dec (v1 v2: variable): 
  dec (v1 = v2).
Proof.
  destruct v1 as [n], v2 as [m].
  decide (n = m).
  - left; rewrite e; reflexivity.
  - right; intros C; apply n0; inversion C; reflexivity.
Defined. 

(* *)
Definition variables := list variable.

(* TODO: comment *)
(* Basically, here we have a choice (?) 
   We can introduce a strong type for assignments, in this case equality will be easy to decide, 
   Or we can have weak structure here, but then we'll get a lot of "different" assignments, 
   which has to be equivalent. 
   
   I decided to use some relatively weak structure. 

   My plan is to introduce a notion of "equivalence" and use it everywhere instead of equality. 

*)
(* List be cause I want the whole thing to be computable *)
Definition assignment := list (variable * bool).
Definition assignments := list assignment.

(* TODO: comment *)
Fixpoint vars_in (α: assignment): variables :=
  map fst α.

(* TODO: comment *)
Reserved Notation "v / α ↦ b" (at level 10).

Inductive mapsto: variable -> assignment -> bool -> Prop := 
| maps_hd: forall var α_tl b,
    var/((var, b) :: α_tl) ↦ b
| maps_tl: forall var var' c α b,
    var <> var' -> (var/α ↦ b) -> (var/((var',c)::α) ↦ b)
where "v / α ↦ b" := (mapsto v α b).

Lemma todo2:
  forall (α: assignment) (v: variable) (b1 b2: bool),
  v / α ↦ b1 ->
  v / α ↦ b2 ->
  b1 = b2.
Proof.
  intros ? ? ? ? M1 M2.
  induction α.
  { inversion M1. }
  { destruct a.
    admit. }
Admitted.

Lemma mapsto_dec:
  forall (α: assignment) (v: variable),
    v el (vars_in α) ->
    {v / α ↦ true} + {v / α ↦ false}. 
Proof.
  induction α; intros v1 ?. 
  { inversion_clear H. }
  { destruct a as [v2 b].
    decide (v1 = v2); [subst | ].
    { destruct b; [left|right]; constructor. } 
    { specialize (IHα v1).
      feed IHα.
      inversion_clear H; [exfalso; eauto | destruct α; eauto]. 
      destruct IHα as [IH1|IH2]; [left|right]; constructor; auto.
    } 
  }
Defined.


Lemma m1: (V 1) el (vars_in ([(V 0, true); (V 1, false); (V 2, false)])).
Proof.
  right; left; reflexivity. 
Defined.

(* Compute (proj1_sig (mapstob (V 1) [(V 0, true); (V 1, true); (V 2, false)] m1)). *)

(* TODO: fix *)
Definition assignment_on_variables (vs: list variable) (α: assignment) :=
  equi vs (vars_in α).

(*   forall v, v el vs -> exists b, v / α ↦ b. *)


(* TODO: comment *)
(* Lemma assignments_on_vars_dec:
  forall vs α, dec (assignment_on_variables vs α).
Proof.
  induction vs; intros.
  - destruct α; [left | right]. 
    + intros x IN; inversion IN. 
    + intros C.
      destruct p.
      admit.
  - admit. 
Admitted. *)

(* TODO: fix *)
(* TODO: comment *)
Definition equiv_assignments (vs: variables) (α1 α2: assignment) :=
  forall v, v el vs -> exists b, v / α1 ↦ b /\ v / α2 ↦ b.

(* TODO: comment *)
(* Lemma assignments_equiv_dec:
  forall vs α1 α2, dec (equiv_assignments vs α1 α2).
Proof.
Admitted. *)

(* There is a problem that is related to the fact that 
   two assignments can be equivalent, but not equal. 
   But we still need to consider a list of assignments and so on.
   So, I intrtoduce a new predicate for IN. 
 *)

(* *)
Definition mem_a (vs: variables) (α: assignment) (αs: assignments): Prop :=
  mem_e (equiv_assignments vs) α αs.

(* *)
Definition dupfree_a (vs: variables) (αs: assignments): Prop :=
  dupfree_e (equiv_assignments vs) αs.


(* Definition incl_a (vs: variables) (αs1 αs2: assignments): Prop :=
  incl_e (equiv_assignments vs) αs1 αs2.

Definition equiv_a (vs: variables) (αs1 αs2: assignments): Prop :=
  equiv_e (equiv_assignments vs) αs1 αs2. *)
  

(* Section Example1.
  Let x1 := V 0.
  Let x2 := V 1.
  Let x3 := V 2.
  Compute (all_assignments_on [x1; x2; x3]).
  Goal assignment_on_variables [x1; x2; x3] [(x1, false); (x2, true); (x3, false)].
  Proof.
    intros.
    split; intros.
    { destruct H as [EQ1| [EQ2 | [EQ3 | C]]]; subst.
      - exists false; constructor.
      - exists true. constructor. intros C; inversion C. constructor.
      - exists false. constructor. intros C; inversion C. constructor. admit. constructor.
      - inversion C.
    }
    { destruct H as [b H].
      inversion_clear H. admit. 
      inversion_clear H1. admit.
      inversion_clear H2. admit.
      inversion_clear H3.
    }
  Admitted.
  Goal equiv_assignments [x1; x2; x3] 
       [(x1, false); (x2, true); (x3, false)]
       [(x1, false); (x3, false); (x2, true)]. 
  Proof. Admitted.
  Goal equiv_assignments [x1; x3] 
       [(x1, false); (x2, true); (x3, false)]
       [(x1, false); (x2, false); (x3, false)].
  Proof. Admitted.  
End Example1. *)


(*** Formulas *)

(* TODO: comment *)
Inductive formula :=
| F: formula
| T: formula
| Var: variable -> formula
| Neg: formula -> formula
| Conj: formula -> formula -> formula
| Disj: formula -> formula -> formula.
  
(* Supplementary notation for formulas. *)
Notation "[| x |]" := (Var x) (at level 0).
Notation "¬ x" := (Neg x) (at level 40). 
Notation "x '∧' y" := (Conj x y) (at level 40, left associativity).
Notation "x '∨' y" := (Disj x y) (at level 41, left associativity).

Definition xor (ϕl ϕr: formula) := ((ϕl ∧ ¬ ϕr) ∨ (¬ ϕl ∧ ϕr)). 
Notation "x '⊕' y" := (xor x y) (at level 41, left associativity).

Definition impl (ϕl ϕr: formula) := ¬ϕl ∧ ϕr. 
Notation "x '⇒' y" := (impl x y) (at level 41, left associativity).


(* TODO: def *)
(* TODO: comment *)
Reserved Notation "'ℇ' '(' ϕ ')' α ≡ b" (at level 10).

Inductive formula_eval: formula -> assignment -> bool -> Prop :=

| ev_true: forall (α: assignment), formula_eval T α true
| ev_false: forall (α: assignment), formula_eval F α false
                                   
| ev_var: forall (v: variable) (α: assignment) (b: bool),
    (v/α ↦ b) -> (formula_eval [|v|] α b)
                  
| ev_neg: forall (ϕn: formula) (α: assignment) (b: bool),
    formula_eval ϕn α (negb b) -> formula_eval (¬ ϕn) α b
                          
| ev_conj_t: forall (ϕl ϕr: formula) (α: assignment),
    formula_eval ϕl α true -> formula_eval ϕr α true -> formula_eval (ϕl ∧ ϕr) α true
| ev_conj_fl: forall (ϕl ϕr: formula) (α: assignment),
    formula_eval ϕl α false -> formula_eval (ϕl ∧ ϕr) α false
| ev_conj_fr: forall (ϕl ϕr: formula) (α: assignment),
    formula_eval ϕr α false -> formula_eval (ϕl ∧ ϕr) α false
                           
| ev_disj_f: forall (ϕl ϕr: formula) (α: assignment),
    formula_eval ϕl α false -> formula_eval ϕr α false -> formula_eval (ϕl ∨ ϕr) α false                   
| ev_disj_tl: forall (ϕl ϕr: formula) (α: assignment),
    formula_eval ϕl α true -> formula_eval (ϕl ∨ ϕr) α true
| ev_disj_tr: forall (ϕl ϕr: formula) (α: assignment),
    formula_eval ϕr α true -> formula_eval (ϕl ∨ ϕr) α true
where "'ℇ' '(' ϕ ')' α ≡ b" := (formula_eval ϕ α b). 

Hint Constructors formula_eval.

(* *)
Definition sat_assignment (ϕ: formula) (α: assignment) :=
  formula_eval ϕ α true.

Definition unsat_assignment (ϕ: formula) (α: assignment) :=
  formula_eval ϕ α false.


(* Variables are important.
   
   Maybe it's a bad deifintion, but consider a formula 
         x1 ∨ x2 ∨ T.
   How many sat as. are there? 
   My answer would be  "On which variables?" 
    That is, assignments [x1 ↦ F] [x1 ↦ T, x3 ↦ T] 
    are both sat. ass. even though the first one 
    doesn't set variable x2, and the second sets 
    a variable x3.

 *)

(* Definition number_of_sat_assignments (vs: variables) (ϕ: formula) (n: nat) :=
  forall (αs: assignments),
    list_of_sat_assignments vs ϕ αs ->
    length αs = n. *)



(* TODO: *)
Fixpoint leaves (ϕ: formula): variables :=
  match ϕ with
  | T => [] | F => []
  | Var v => [v]
  | ¬ ϕ => leaves ϕ
  | ϕ1 ∧ ϕ2 => leaves ϕ1 ++ leaves ϕ2
  | ϕ1 ∨ ϕ2 => leaves ϕ1 ++ leaves ϕ2
  end.

(* => [V 0; V 1; V 0; V 1] *)
Compute (leaves ([|V 0|] ⊕ [|V 1|])). 

(* Definition of the size of a formula. *)
Definition formula_size (ϕ: formula): nat :=
  length (leaves ϕ).

(* => 4 *)
Compute (formula_size ([|V 0|] ⊕ [|V 1|])).

Definition sets_all_variables (ϕ: formula) (α: assignment) := 
  incl (leaves ϕ) (vars_in α).



(* TODO: del vs? *)
Definition list_of_sat_assignments (vs: variables) (ϕ: formula) (αs: assignments) :=
  dupfree_a vs αs /\
  (forall α, α el αs -> sat_assignment ϕ α) /\
  (forall α, sat_assignment ϕ α -> mem_a vs α αs) /\
  (forall α, α el αs -> equi vs (vars_in α)). 


(* TODO: fix leaves to vars *)
Definition number_of_sat_assignments (ϕ: formula) (n: nat) :=
  exists (αs: assignments),
    list_of_sat_assignments (leaves ϕ) ϕ αs /\
    length αs = n.

Notation "'#sat' ϕ '≃' n" := (number_of_sat_assignments ϕ n) (at level 10).







Reserved Notation "ϕ [ x ↦ ψ ]" (at level 10).

Fixpoint substitute (ϕ: formula) (v: variable) (ψ: formula): formula :=
  match ϕ with
  | T => T
  | F => F
  | [| v0 |] => if decision (v = v0) then ψ else Var v0
  | ¬ ϕn => ¬ ϕn[v ↦ ψ]
  | ϕl ∧ ϕr => ϕl[v ↦ ψ] ∧ ϕr[v ↦ ψ]
  | ϕl ∨ ϕr => ϕl[v ↦ ψ] ∨ ϕr[v ↦ ψ]
  end
where "ϕ [ x ↦ f ]" := (substitute ϕ x f).


Definition get_var (ϕ: formula) (NE: formula_size ϕ > 0):
  {v: variable | v el (leaves ϕ)}.
Proof.
  unfold formula_size in NE.
  destruct (leaves ϕ).
  { simpl in NE; omega. }
  { exists v; left; reflexivity. }
Defined.


Definition equivalent (ϕ1 ϕ2: formula) :=
  forall (α: assignment) (b: bool), ℇ (ϕ1) α ≡ b <-> ℇ (ϕ2) α ≡ b.

Lemma formula_equivalence_is_transitive:
  forall (ϕ1 ϕ2 ϕ3: formula),
    equivalent ϕ1 ϕ2 ->
    equivalent ϕ2 ϕ3 ->
    equivalent ϕ1 ϕ3.
Proof.
Admitted.



(*** Alg 1: *)
(** Just make the list of all assignments, and then filter *)
(** This algorithm is quite boring. *)


Definition list_of_all_assignments (vs: variables) (αs: assignments) :=
  dupfree_a vs αs /\
  (forall α,
      assignment_on_variables vs α ->
      mem_a vs α αs).



Fixpoint all_assignments_on (vs: variables): assignments :=
  match vs with
  |  [] => [[]]
  | v::vs => map (fun α => (v,false)::α) (all_assignments_on vs)
              ++ map (fun α => (v,true)::α) (all_assignments_on vs)
  end.

(* TODO: name *)
Lemma correctness_all_assignments:
  forall (vs: variables), list_of_all_assignments vs (all_assignments_on vs).
Proof.
  intros; split.
  { induction vs.
    - split; [intros C; inversion C | apply I].
    - simpl. admit.  
  }
  { intros. 
    admit. } 
Admitted.

Lemma size_of_list_of_all_assignments:
  forall (vs: variables),
    length (all_assignments_on vs) = Nat.pow 2 (length vs).
Proof.
  induction vs.
  { simpl; reflexivity. }
  { simpl. admit. } 
Admitted.



 (* vs: variables *)
Definition sat_kek (ϕ: formula) (α: assignment) (SET: sets_all_variables ϕ α): {b: bool | formula_eval ϕ α b}.
  induction ϕ.
  - exists false. constructor.
  - exists true. constructor.
  - feed (SET v).
    { left; reflexivity. }
    destruct (mapsto_dec α v SET) as [M|M]; [exists true| exists false]; constructor; assumption.
  - destruct IHϕ as [b EV].
    simpl in SET; assumption.
    exists (negb b); constructor; rewrite Bool.negb_involutive; assumption.
  - apply inclusion_app in SET; destruct SET.
    destruct IHϕ1 as [b1 EV1]; destruct IHϕ2 as [b2 EV2]; try auto.
    exists (andb b1 b2).
    destruct b1, b2; simpl in *; try(constructor; auto; fail). 
  - simpl in SET; apply inclusion_app in SET; destruct SET.
    destruct IHϕ1 as [b1 EV1]; destruct IHϕ2 as [b2 EV2]; try auto.
    exists (orb b1 b2).
    destruct b1, b2; simpl in *; try(constructor; auto; fail).
Defined.

(* Check *)
(* Trivial, but important implication of the previous algorithm/evaluator. *)
Lemma todo7:
  forall (ϕ: formula) (α: assignment),
    sets_all_variables ϕ α -> 
    {ℇ (ϕ) α ≡ true} + {ℇ (ϕ) α ≡ false}.
Proof.
  intros.
  assert (EV:= sat_kek ϕ α H).
  destruct EV as [b EV]; destruct b.
  - left; assumption.
  - right; assumption.
Qed.

(* TODO: del *)
(* (* Trivial, but important implication of the previous algorithm/evaluator. *)
Lemma todo8:
  forall (ϕ: formula) (α: assignment),
    {ℇ (ϕ) α ≡ true} + {ℇ (ϕ) α ≡ false}.
Proof.
Admitted. *)


Definition sat_kek_kek (ϕ: formula) (α: assignment): option {b: bool | formula_eval ϕ α b}.
Proof.
  decide (incl (leaves ϕ) (vars_in α)) as [IN | NIN].
  { apply Some.
    apply sat_kek.
    assumption. }
  { apply None. }
Defined.
  
(* TODO: comment *)
Compute ((sat_kek_kek ([|V 0|] ∧ T) [(V 0, false)])).

(* *)
Definition algorithm1 (vs: variables) (ϕ: formula): nat :=
  length (
      filter (fun α => match sat_kek_kek ϕ α with
                    | None => false
                    | Some (exist _ a _) => a
                    end)
             (all_assignments_on vs)).


Definition algorithm1' (vs: variables) (ϕ: formula): {n: nat | #sat ϕ ≃ n }.
  exists (algorithm1 vs ϕ).
  exists (filter (fun α => match sat_kek_kek ϕ α with
                    | None => false
                    | Some (exist _ a _) => a
                    end)
            (all_assignments_on vs)).
  admit. 
Admitted.



  

(*** Alg 2: *)
(** With transformation ϕ = (ϕ[x ↦ T] ∧ x) ∨ (ϕ[x ↦ F] ∧ ¬x). *)

Lemma todo9:
  forall (ϕ: formula), formula_size (¬ ϕ) = formula_size ϕ.
Proof.
Admitted.

Lemma todo10:
  forall (ϕl ϕr: formula), formula_size (ϕl ∧ ϕr) = formula_size ϕl + formula_size ϕr.
Proof.
Admitted.

Lemma todo11:
  forall (ϕl ϕr: formula), formula_size (ϕl ∨ ϕr) = formula_size ϕl + formula_size ϕr.
Proof.
Admitted.


Lemma todo3:
  forall (ϕ: formula) (x: variable),
    x el leaves ϕ -> 
    formula_size (ϕ[x ↦ T]) < formula_size ϕ.
Proof.
  induction ϕ; intros ? L.
  { easy. }
  { easy. }
  { apply singl_in in L; subst.
    simpl; decide (v = v); [compute; omega | easy]. }
  { simpl; rewrite todo9, todo9; eauto. }
  { simpl; rewrite todo10, todo10.
    admit.  }
  { admit. }
    
Admitted.

Lemma todo5:
  forall (ϕ: formula) (x: variable),
    x el leaves ϕ -> 
    formula_size (ϕ[x ↦ F]) < formula_size ϕ.
Proof.

Admitted.


Lemma todo4:
  forall (ϕ: formula),
    formula_size ϕ > 0 -> 
    exists x,
      x el leaves ϕ /\
      formula_size (ϕ[x ↦ T]) < formula_size ϕ.
Proof.

Admitted.

Lemma kek1:
  forall (ϕ: formula) (α: assignment) (b: bool),
  forall (x: variable),
    x / α ↦ true -> 
    formula_eval ϕ α b <-> formula_eval (ϕ[x ↦ T]) α b.
Proof.
  induction ϕ; intros ? ? ? MAP; split; intros EV.
  all: try assumption.
  all: simpl in *.
  { decide (x = v); [subst | ].
    inversion_clear EV.
    assert (EQ := todo2 _ _ _ _ MAP H); subst.
    all: auto. }
  { decide (x = v); [subst | ].
    admit (* Ok *).
    auto. }
  { inversion_clear EV.
    constructor. 
    apply IHϕ; assumption. }
  { inversion_clear EV.
    constructor.
    apply IHϕ with x; assumption. }
  { inversion_clear EV.
    - constructor; [apply IHϕ1| apply IHϕ2]; assumption.
    - constructor; apply IHϕ1; assumption. 
    - apply ev_conj_fr; apply IHϕ2; assumption. }
  { inversion_clear EV. 
    - constructor; [eapply IHϕ1 | eapply IHϕ2]; eauto.
    - admit.
    - admit. } 
  { inversion_clear EV.
    - constructor; [apply IHϕ1| apply IHϕ2]; assumption.
    - constructor; apply IHϕ1; assumption. 
    - apply ev_disj_tr; apply IHϕ2; assumption. } 
  { admit. }
Admitted.

Lemma kek2 (ϕ: formula) (α: assignment) (b: bool):
  forall (x: variable),
    x / α ↦ false -> 
    formula_eval ϕ α b <-> formula_eval (ϕ[x ↦ F]) α b.
Proof.
  intros ? MAP. 
  split; intros EV. 
  { induction ϕ.
    - assumption.
    - assumption.
    - simpl; decide (x = v).
      + subst.
        inversion_clear EV.
        assert (EQ := todo2 _ _ _ _ MAP H); subst.
        constructor.
      + assumption.
    - simpl.
      constructor.
      admit (* ??? *).
Admitted.


Lemma substitute_equiv':
  forall (ϕ ψ1 ψ2: formula) (v: variable),
    (forall (α: assignment) (b: bool),        ℇ (ψ1) α ≡ b ->        ℇ (ψ2) α ≡ b) -> 
    (forall (α: assignment) (b: bool), ℇ (ϕ[v ↦ ψ1]) α ≡ b -> ℇ (ϕ[v ↦ ψ2]) α ≡ b).
Proof.
  induction ϕ; intros ? ? ? EQ ? ?; simpl in *.
  { intros EV; assumption. }
  { intros EV; assumption. }
  { decide (v0 = v); eauto 2; split; eauto 2. }
  { intros EV.
    constructor.
    inversion_clear EV; rename H into EV.
    apply IHϕ with ψ1; eauto 2. }
  { intros EV.
    inversion_clear EV; try(constructor; eauto 2; fail). }
  { intros EV.
    inversion_clear EV; try(constructor; eauto 2; fail). }
Qed.

Lemma substitute_equiv:
  forall (ϕ ψ1 ψ2: formula) (v: variable),
    equivalent ψ1 ψ2 ->
    equivalent (ϕ[v ↦ ψ1]) (ϕ[v ↦ ψ2]).
Proof.
  intros; split.
  apply substitute_equiv'; apply H.
  apply substitute_equiv'; apply H.
Qed.


Lemma switch:
  forall (ϕ: formula) (x: variable),
    equivalent ϕ ([|x|] ∧ ϕ[x ↦ T] ∨ ¬[|x|] ∧ ϕ[x ↦ F]). 
Proof.
  
Admitted.


Lemma count1:
  forall (ϕ: formula) (x: variable) (n: nat),
    x el (leaves ϕ) ->
    number_of_sat_assignments (ϕ[x ↦ T]) n
    = number_of_sat_assignments ([|x|] ∧ ϕ) n.
Proof.
Admitted.

Lemma count2:
  forall (ϕ: formula) (x: variable) (n: nat),
    x el (leaves ϕ) ->
    number_of_sat_assignments (ϕ[x ↦ T]) n
    = number_of_sat_assignments ([|x|] ∧ ϕ) n.
Proof.
Admitted.



Lemma formula_size_dec:
  forall (ϕ: formula),
    {formula_size ϕ = 0} + {formula_size ϕ > 0}.
Proof.
  intros.
  induction ϕ.
  { left; easy. }
  { left; easy. }
  { right; unfold formula_size; simpl; omega. }
  { destruct IHϕ as [IH|IH]. 
    - left; assumption.
    - right; assumption.
  }
  { destruct IHϕ1 as [IH1|IH1].
    - destruct IHϕ2 as [IH2|IH2].
      + left; unfold formula_size in *; simpl.
        rewrite app_length, IH1, IH2. easy.
      + right; unfold formula_size in *; simpl.
        rewrite app_length, IH1; easy.
    - right; unfold formula_size in *; simpl.
      rewrite app_length; omega.
  }
  { destruct IHϕ1 as [IH1|IH1].
    - destruct IHϕ2 as [IH2|IH2].
      + left; unfold formula_size in *; simpl.
        rewrite app_length, IH1, IH2. easy.
      + right; unfold formula_size in *; simpl.
        rewrite app_length, IH1; easy.
    - right; unfold formula_size in *; simpl.
      rewrite app_length; omega.
  }
Defined.

Lemma zero_size_formula_constant_dec:
  forall (ϕ: formula),
    formula_size ϕ = 0 -> 
    {equivalent ϕ T} + {equivalent ϕ F}.
Proof.
  intros ? SIZE.
  induction ϕ.
  { right; intros ? ?; split; intros EV; assumption. }
  { left; intros ? ?; split; intros EV; assumption. }
  { exfalso; compute in SIZE; easy. }
  { rewrite todo9 in SIZE.
    feed IHϕ; auto.
    destruct IHϕ as [IH|IH].
    - right; intros ? ?; split; intros EV.
      exfalso; apply TODO.
      exfalso; apply TODO.
    - exfalso; apply TODO. 
  }
  { exfalso; apply TODO. }
  { exfalso; apply TODO. }
Defined.  

Lemma count3:
  number_of_sat_assignments T 1.
Proof. 
  intros.
  exists [[]]; repeat split.  
  - intros C; inversion_clear C.
  - intros.
    constructor.
  - intros; simpl; left.
    intros α1 EL; easy.
  - intros. inversion_clear H.
    simpl in H0.
    exfalso; apply TODO. 
    inversion_clear H0.
  - apply singl_in in H; subst.
    simpl; intros v EL; assumption.
Qed.

Lemma count5:
  forall (ϕ: formula),
    equivalent ϕ T -> 
    number_of_sat_assignments ϕ 1.
Proof.
  intros.
Admitted.

Lemma count4: 
  number_of_sat_assignments F 0.
Proof.
  intros.
  exists []; repeat split; intros.
  - inversion_clear H.
  - inversion_clear H.  
  - inversion_clear H.
  - exfalso; assumption.
Qed. 

Lemma count6:
  forall (ϕ: formula),
    equivalent ϕ F -> 
    number_of_sat_assignments ϕ 0.
Proof.
  intros.
Admitted.



Lemma todo13:
  forall ϕ b v x α,
    v nel (leaves ϕ) ->
    ℇ (ϕ) α ≡ b <-> ℇ (ϕ) (v,x)::α ≡ b.
Proof. Admitted.

Lemma todo12:
  forall ϕ v, 
    v nel leaves (ϕ [v ↦ T]).
Proof.
Admitted.

Lemma todo14:
  forall ϕ v, 
    v nel leaves (ϕ [v ↦ F]).
Proof.
Admitted.

(* 
   The main idea of the algorithm is the following: 
       #sat F = 0
       #sat T = 1 
       #sat ϕ = #sat (x ∧ ϕ[x ↦ T] ∨ ¬x ∧ ϕ[x ↦ F]) 
              = #sat (x ∧ ϕ[x ↦ T]) + #sat (¬x ∧ ϕ[x ↦ F])
              = #sat (ϕ[x ↦ T]) + #sat (ϕ[x ↦ F])

*) 
Definition algorithm2:
  forall (ϕ: formula), {n: nat| number_of_sat_assignments ϕ n}.
Proof.
  apply size_recursion with formula_size; intros ϕ IHϕ. 
  destruct (formula_size_dec ϕ) as [Zero|Pos].
  { destruct (zero_size_formula_constant_dec ϕ Zero) as [Tr|Fl].
    - exists 1; apply count5; assumption.
    - exists 0; apply count6; assumption. } 
  { assert (V := get_var _ Pos).
    destruct V as [x IN]; clear Pos.
    assert (SW := switch ϕ x). 
    assert (IH1 := IHϕ (ϕ[x ↦ T])); assert(IH2 := IHϕ (ϕ[x ↦ F])); clear IHϕ.
    specialize (IH1 (todo3 _ _ IN)); specialize (IH2 (todo5 _ _ IN)).
    destruct IH1 as [nl EQ1], IH2 as [nr EQ2].
    exists (nl + nr).
    destruct EQ1 as [αs1 [LAA1 LEN1]], EQ2 as [αs2 [LAA2 LEN2]].
    
    exists (map (fun α => (x, true)::α) αs1 ++ map (fun α => (x,false)::α) αs2). 
    repeat split.
    { exfalso; apply TODO. }
    { intros; apply SW; clear SW.
      destruct (in_app_or _ _ _ H) as [EL|EL]; clear H.
      { apply ev_disj_tl, ev_conj_t.
        { apply in_map_iff in EL.
          destruct EL as [mα [EQ1 MEM1]]; subst α.
          constructor; constructor.
        } 
        { apply in_map_iff in EL.
          destruct EL as [mα [EQ MEM]]; subst α.
          apply todo13.
          apply todo12.
          apply LAA1; assumption.
        }
      }
      { apply ev_disj_tr, ev_conj_t.
        { apply in_map_iff in EL.
          destruct EL as [mα [EQ MEM]]; subst α.
          constructor; constructor; constructor.
        }
        { apply in_map_iff in EL.
          destruct EL as [mα [EQ MEM]]; subst α.
          apply todo13. apply todo14.
          apply LAA2; assumption.
        }
      }
    }      
    { intros; apply SW in H; clear SW.
      inversion_clear H; inversion_clear H0.
      { 
        

        (* assert(HHH: x nel leaves (ϕ [x ↦ T])). admit. *)

        apply LAA1 in H1.
        destruct LAA1 as [_ [_ [_ Hd]]].

        
        inversion_clear H.

        apply mem_app_equiv; left. 
        

           
        clear LEN2 LAA2 αs2.
        apply mem_map_iff.

        exists α; split. 
        { intros v EL.
          decide (v = x).
          { subst v. exists true; split. constructor. assumption. }
          { exfalso; apply TODO. }
        }
        { assert (HH : forall α : assignment, α el αs1 -> x nel (vars_in α)).
          admit.
          clear Hd. 
          
          unfold mem_a in *.
          clear LEN1; induction αs1.
          { eauto. } 
          { destruct H1.
            unfold equiv_assignments in H.
            { clear IHαs1. 
              

            }
            { right.
              apply IHαs1; eauto 2.
              intros. apply HH. right. assumption.
            } 


          assert (DEC: {α = a} + {a el αs1}). admit. 
          destruct DEC as [EQ|EL].
          subst a.
          
          
          specialize (HH a).
          feed HH. left;reflexivity.
          
          left.
          
          
          intros v EL.
          apply H.
          
          
          decide (x = v). subst.
          { admit. }
          { admit. }
          
          
          
          right.
          
          eauto 2.
          
        }
            
      admit. }
    { admit. }
    { admit. }
    (*
      
    {


      {
        { 
        
          {
            
           
       
          }
          { 
            
            exfalso; apply TODO.
          }
        }
      } *)
    


    { rewrite app_length, map_length, map_length.
      rewrite <- LEN1, <- LEN2; reflexivity.
    } 
  } 
Admitted.


Compute (proj1_sig (algorithm2 (F ∨ T))).


  

(*** Alg 3: *)
(** With certificates and DNF *)

Inductive literal :=
| Atom: bool -> literal
| Positive: variable -> literal
| Negative: variable -> literal.

Inductive literal_eval: literal -> assignment -> bool -> Prop :=
| lit_ev_atom: forall (α: assignment) (b: bool), literal_eval (Atom b) α b
| lit_ev_pos: forall (v: variable) (α: assignment) (b: bool),
    (v/α ↦ b) -> literal_eval (Positive v) α b
| lit_ev_neg: forall (v: variable) (α: assignment) (b: bool),
    (v/α ↦ b) -> literal_eval (Negative v) α (negb b).

Definition monomial := list literal.
 
Inductive monomial_eval: monomial -> assignment -> bool -> Prop :=
| mon_ev_true: forall (m: monomial) (α: assignment),
    (forall (l: literal), l el m -> literal_eval l α true) -> 
    monomial_eval m α true
| mon_ev_false: forall (m: monomial) (α: assignment),
    (exists (l: literal), l el m /\ literal_eval l α false) -> 
    monomial_eval m α false.

Definition dnf := list monomial.

Inductive dnf_eval: dnf -> assignment -> bool -> Prop :=
| dnf_ev_true: forall (d: dnf) (α: assignment),
    (exists (m: monomial), m el d /\ monomial_eval m α true) -> 
    dnf_eval d α true
| dnf_ev_false: forall (d: dnf) (α: assignment),
    (forall (m: monomial), m el d -> monomial_eval m α false) -> 
    dnf_eval d α false.

(* TODO: comment *)
Definition dnf_representation (ϕ: formula) (ψ: dnf) :=
 forall (α: assignment) (b: bool),
      (formula_eval ϕ α b) <-> (dnf_eval ψ α b).

(* TODO: comment *)
(* As you can see, *)
Lemma dnf_representation_of_T_exists:
  dnf_representation T [[Atom true]].   
Proof.
  split; intros EV.
  { inversion_clear EV.
    constructor; intros.
    exists [Atom true]; split.
    - left; reflexivity.
    - constructor.
      intros; apply singl_in in H; subst.
      constructor. 
  }
  { inversion_clear EV.
    - constructor.
    - exfalso.
      assert ([Atom true] el [[Atom true]]); [left; reflexivity| ]. 
      specialize (H _ H0); clear H0.
      inversion_clear H. 
      destruct H0 as [t  [IN EV]].
      apply singl_in in IN; subst.
      inversion_clear EV.
    } 
Qed.

(* TODO: fix ψ ~> [[Atom false]]*)
Lemma dnf_representation_of_F_exists:
  exists (ψ: dnf), dnf_representation F ψ.   
Proof.
  exists [[Atom false]]; intros.
  split; intros EV.
  { inversion_clear EV.
    constructor; intros.
    apply singl_in in H; subst.
    constructor.
    exists (Atom false); split.
    - left; reflexivity.
    - constructor. 
  }
  { inversion_clear EV.
    - exfalso.
      destruct H as [m [IN EV]].
      apply singl_in in IN; subst.
      inversion_clear EV.
      assert ((Atom false) el [Atom false]); [left; reflexivity| ].
      specialize (H _ H0); clear H0.
      inversion_clear H.
    - constructor.      
  } 
Qed.

  
Theorem dnf_representation_exists:
  forall (ϕ: formula), exists (ψ: dnf), dnf_representation ϕ ψ.   
Proof.
  apply size_recursion with formula_size.
  intros ϕ IH.

  destruct (formula_size_dec ϕ) as [Z|POS].
  destruct (zero_size_formula_constant_dec _ Z) as [Tr|Fl].
  { exists [[Atom true]].
    assert(EQ:= dnf_representation_of_T_exists). 
    intros; split; intros.
    - apply EQ, Tr; assumption.
    - apply Tr, EQ; assumption. }
  { destruct (dnf_representation_of_F_exists) as [ψ EQ]. 
    exists ψ.
    intros; split; intros.
    - apply EQ, Fl; assumption.
    - apply Fl, EQ; assumption. }
  { assert (V := get_var _ POS).
    destruct V as [x IN].
    assert (EQ := switch ϕ x).
    assert (IH1:= IH (ϕ[x ↦ T])).
    assert (IH2:= IH (ϕ[x ↦ F])).
    clear IH.
    specialize (IH1 (todo3 _ _ IN)).
    specialize (IH2 (todo5 _ _ IN)).
    destruct IH1 as [ψ1 EQ1], IH2 as [ψ2 EQ2].
    exists ((map (fun m => (Positive x)::m) ψ1) ++ (map (fun m => (Negative x)::m) ψ2)). 
    intros; split; intros EV.    
    { apply EQ in EV.
      inversion_clear EV.
      { inversion_clear H; [inversion_clear H0 | inversion_clear H0]. 
        { inversion_clear H. simpl in H0.
          inversion_clear H1.
          inversion_clear H0. admit. }
        { specialize (EQ2 α false).
          apply EQ2 in H.
          inversion_clear H1.
          constructor; intros mon INm.
          destruct (in_app_or _ _ _ INm) as [INl|INr];clear INm.
          constructor.
          exists (Positive x).
          apply in_map_iff in INl.
          destruct INl as [ms [P INl]]; subst mon.
          split. left; easy.
          constructor. assumption.

          apply in_map_iff in INr.
          destruct INr as [y [EE ELL]].
          subst.

          constructor.

          
          inversion_clear H.
          specialize (H1 _ ELL).
          inversion_clear H1.
          destruct H as [l [INc LIT]].
          exists l; split. right.  assumption. assumption. }
        { admit. }
        { apply EQ1 in H1.
          apply EQ2 in H.
          admit. } 
      }      
      { inversion_clear H.
        inversion_clear H0.
        apply EQ1 in H1.
        inversion_clear H1.
        destruct H0 as [mon [EL EV]].
        constructor.
        exists ((Positive x)::mon). split.
        apply in_or_app. left.
        apply in_map_iff. exists mon. split. reflexivity.
        assumption.
        
        constructor.
        

        intros.

        inversion_clear EV.
        destruct H0. subst. constructor. assumption.
        apply H1. assumption.
      }
      { inversion_clear H.
        admit. 
      }         
    }
    { apply EQ.
      inversion_clear EV.
      - destruct H as [mon [EL EV]].
        admit. 
      - admit. 
      
    }
Admitted.      


(* Definition certificate0 (ϕ: formula) (ξ: assignment): Prop := *)

Definition certificate1 (ϕ: formula) (ξ: assignment): Prop :=
  forall α, equiv_assignments nil α ξ -> ℇ (ϕ) α ≡ true. 

Definition monomial_to_certificate (m: monomial): assignment := nil.

Lemma theorem:
  forall (ϕ: formula) (ψ: dnf),
    dnf_representation ϕ ψ ->
    forall (m: monomial),
      m el ψ ->
      certificate1 ϕ (monomial_to_certificate m).
Proof.
  intros ? ? DNF mon IN ? EQU.
  
  

Admitted.

(* TODO: Certificates are disjoint *)


(* Algorithm
   1) Transform ϕ to dnf
   2) Map each monomial into a certificate1
   3) By construction, all these certificates are disjoint
   4) Calculate the number of sat. assignments
*)



(*Lemma l0:
  forall ϕ α,
    incl (vars_in_formula ϕ) (vars_in_assignment α) ->
    {eval ϕ α true} + {eval ϕ α false}.
Proof.
  intros.
  induction ϕ.
  - right; constructor.
  - left; constructor.
  - admit. 
  - apply IHϕ in H; clear IHϕ. admit. 
  - simpl in H. admit. 
  - admit. 
Admitted.

*)



(* Lemma l1:
  forall ϕ1 ϕ2 α, 
  eval (ϕ1 ∨ ϕ2) α true -> eval ϕ1 α true \/ eval ϕ2 α true.
Proof.
  intros.
  inversion_clear H; [left | right]; assumption.
Qed.

Lemma l2:
  forall ϕ1 ϕ2 α, 
  eval (ϕ1 ∧ ϕ2) α true -> (eval ϕ1 α true) /\ (eval ϕ2 α true).
Proof.
  intros.
  inversion_clear H; split; assumption.
Qed.

Lemma l3:
  forall ϕ1 ϕ2 α b, 
  eval (ϕ1 ∧ ϕ2) α b <-> eval (¬ (¬ ϕ1 ∨ ¬ ϕ2)) α b.
Proof.
  intros; split; intros EV.
  { constructor.
    inversion_clear EV. rename H into EV1, H0 into EV2.
    - apply ev_disj_f; constructor; simpl; assumption.
    - apply ev_disj_tl; constructor; simpl; assumption.
    - apply ev_disj_tr; constructor; simpl; assumption.
  }
  { inversion_clear EV. 
    remember (negb b) as s; rewrite Bool.negb_involutive_reverse.
    rewrite <- Heqs; clear Heqs b.
    inversion_clear H. rename H0 into EV1, H1 into EV2. 
    - inversion_clear EV1. inversion_clear EV2.
      constructor; simpl in *; assumption.
    - inversion_clear H0. simpl in *.
      apply ev_conj_fl; assumption.
    - inversion_clear H0. simpl in *.
      apply ev_conj_fr; assumption.
  }       
Qed. 

Lemma l4:
  forall ϕ1 ϕ2 α b, 
  eval (ϕ1 ∨ ϕ2) α b <-> eval (¬ (¬ ϕ1 ∧ ¬ ϕ2)) α b.
Proof.
  intros; split; intros EV.
  { constructor.
    inversion_clear EV. rename H into EV1, H0 into EV2.
    - apply ev_conj_t; constructor; simpl; assumption.
    - apply ev_conj_fl; constructor; simpl; assumption.
    - apply ev_conj_fr; constructor; simpl; assumption.
  }
  { inversion_clear EV. 
    remember (negb b) as s; rewrite Bool.negb_involutive_reverse.
    rewrite <- Heqs; clear Heqs b.
    inversion_clear H. rename H0 into EV1, H1 into EV2. 
    - inversion_clear EV1. inversion_clear EV2.
      constructor; simpl in *; assumption.
    - inversion_clear H0. simpl in *.
      apply ev_disj_tl; assumption.
    - inversion_clear H0. simpl in *.
      apply ev_disj_tr; assumption.
  }       
Qed.

Lemma distributive_property:
  forall ϕ1 ϕ2 ϕ3 α b,
    eval (ϕ1 ∧ (ϕ2 ∨ ϕ3)) α b <-> eval ((ϕ1 ∧ ϕ2) ∨ (ϕ1 ∧ ϕ3)) α b.
Proof.
  intros; split; intros.
  { destruct b.
    apply l2 in H; destruct H as [X YZ].
    apply l1 in YZ; destruct YZ as [Y|Z].
    apply ev_disj_tl; apply ev_conj_t; assumption.
    apply ev_disj_tr; apply ev_conj_t; assumption.
    inversion_clear H. admit. admit .
  } 
  admit. 
Admitted.
*)

(* As you can see, we have quite weak type for assignment. 
   Therefore, we have a lot of assignments that are equivalent
   TODO
 *)











