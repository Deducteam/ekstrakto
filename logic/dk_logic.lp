require open logic.cc
require open logic.dk_bool

// Impredicative prop

constant symbol prop : uT
constant symbol Prop : TYPE
rule eT prop ↪ Prop
symbol ebP : eT bool → Prop

constant symbol imp : Prop → Prop → Prop
constant symbol forall_type : (uT → Prop) → Prop
constant symbol forall : Π (A : uT), (eT A → Prop) → Prop

symbol eeP : Prop → uT
definition eP : Prop → TYPE
   ≔ λ (f : Prop), eT (eeP f)
rule
    eeP (imp $f1 $f2)
      ↪
    Arrow (eeP $f1) (eeP $f2)

rule
    eeP (forall $A $f)
      ↪
    Pi $A (λ (x : eT $A), eeP ($f x))

rule
    eeP (forall_type $f)
      ↪
    PiT (λ (x : uT), eeP ($f x))

definition True : Prop ≔ forall prop (λ (P : Prop), imp P P)
definition False : Prop ≔ forall prop (λ (P : Prop),  P)
definition not (f : Prop) : Prop ≔ imp f False
definition {|and|} (A : Prop) (B : Prop) : Prop ≔
  forall prop (λ (P : Prop), imp (imp A (imp B P)) P)
definition or  (A : Prop) (B : Prop) : Prop ≔
  forall prop (λ (P : Prop), imp (imp A P) (imp (imp B P) P))
definition eqv (A : Prop) (B : Prop) : Prop ≔
  {|and|} (imp A B) (imp B A)

definition exists (A : uT) (f : eT A → Prop) : Prop ≔
  forall prop (λ (P : Prop), imp (forall A (λ (x : eT A), imp (f x) P)) P)
definition forallc (A : uT) (f : eT A → Prop) : Prop ≔
  not (not (forall A (λ (x : eT A), not (not (f x)))))
definition existsc (A : uT) (f : eT A → Prop) : Prop ≔
  not (not (exists A (λ (x : eT A),not (not (f x)))))

definition exists_type (f : uT → Prop) : Prop
≔ forall prop (λ (z : Prop),
                (imp (forall_type (λ (a : uT),
                                   imp (f a) z))
                     z))


definition TrueT : TYPE ≔ eP True
definition FalseT : TYPE ≔ eP False
constant symbol I : TrueT
constant symbol False_elim : Π (A : uT), FalseT → eT A

symbol Istrue : Bool → TYPE
rule Istrue $b ↪ eP (ebP $b)

definition and_intro  (f1 : Prop)
              (f2 : Prop)
              (H1 : eP f1)
              (H2 : eP f2)
              : eP ({|and|} f1 f2)
    ≔ λ
        (f3 : Prop)
        (H3 : (eP f1 → eP f2 → eP f3)),
       H3 H1 H2

definition and_elim1 (f1 : Prop)
              (f2 : Prop)
              (H3 : eP ({|and|} f1 f2))
              : eP f1
    ≔ H3 f1 (λ (H1 : eP f1)  (H2 : eP f2), H1)

definition and_elim2 (f1 : Prop)
              (f2 : Prop)
              (H3 : eP ({|and|} f1 f2))
              : eP f2
    ≔ H3 f2 (λ (H1 : eP f1) (H2 : eP f2), H2)

definition or_intro1 (f1 : Prop)
              (f2 : Prop)
              (H1 : eP f1)
              : eP (or f1 f2)
    ≔ λ (f3 : Prop)
       (H13 : (eP f1 → eP f3))
       (H23 : (eP f2 → eP f3)),
       H13 H1

definition or_intro2  (f1 : Prop)
              (f2 : Prop)
              (H2 : eP f2)
              : eP (or f1 f2)
    ≔ λ (f3 : Prop),
       λ (H13 : (eP f1 → eP f3)),
       λ (H23 : (eP f2 → eP f3)),
       H23 H2

definition or_elim (f1 : Prop)
            (f2 : Prop)
            (f3 : Prop)
            (H3 : eP (or f1 f2))
            (H13 : eP (imp f1 f3))
            (H23 : eP (imp f2 f3))
            : eP f3
    ≔ H3 f3 H13 H23

definition eqv_intro ≔ λ (f1 : Prop)
                 (f2 : Prop),
                 and_intro (imp f1 f2) (imp f2 f1)
definition eqv_elim1 ≔ λ (f1 : Prop)
                 (f2 : Prop),
                 and_elim1 (imp f1 f2) (imp f2 f1)
definition eqv_elim2 ≔ λ (f1 : Prop)
                 (f2 : Prop),
                 and_elim2 (imp f1 f2) (imp f2 f1)

rule ebP true ↪ True
rule ebP false ↪ False

// equality
definition equal : Π (A : uT) (x : eT A) (y : eT A), Prop
      ≔ λ (A : uT) (x : eT A) (y : eT A),
                                     forall (Arrow A prop)
                                            (λ (H : (eT A → Prop)),
                                             imp (H x) (H y))

definition equalc (A : uT) (x : eT A) (y : eT A) : Prop ≔
  not (not (equal A x y))

definition refl : Π (A : uT) (x : eT A), eP (equal A x x)
     ≔ λ (A : uT) (x : eT A)
                     (H : (eT A → Prop))
                     (px : eP (H x)), px

definition equal_ind : Π (A : uT)
            (H : (eT A → Prop))
            (x : eT A)
            (y : eT A)
            , eP (equal A x y) →
            eP (H x) →
            eP (H y)
          ≔
            λ (A : uT)
            (P : (eT A → Prop))
            (x : eT A)
            (y : eT A)
            (eq: eP (equal A x y)),
            eq P

definition equal_sym : Π (A : uT)
            (x : eT A)
            (y : eT A),
            eP (equal A x y) →
            eP (equal A y x)
          ≔
            λ (A : uT)
            (x : eT A)
            (y : eT A)
            (eq : eP (equal A x y)),
            equal_ind
              A
              (λ (z : eT A), equal A z x)
              x
                y
                eq
                (refl A x)

definition equal_congr : Π
  (A : uT)
  (B : uT)
  (f : (eT A → eT B))
  (x : eT A)
  (y : eT A),
  eP (equal A x y) →
  eP (equal B (f x) (f y))
  ≔ λ
    (A : uT)
    (B : uT)
    (f : (eT A → eT B))
    (x : eT A)
    (y : eT A)
    (H : eP (equal A x y)),
    equal_ind A (λ (z : eT A), equal B (f x) (f z)) x y H (refl B (f x))
