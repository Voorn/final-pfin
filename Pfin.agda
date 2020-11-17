{-# OPTIONS --cubical --no-import-sorts #-}

module Pfin where

open import Size
open import Cubical.Core.Everything
open import Cubical.Foundations.Prelude
open import Cubical.Foundations.Everything
open import Cubical.Functions.Logic renaming (⊥ to ⊥ₚ)
open import Cubical.Relation.Everything
open import Cubical.HITs.PropositionalTruncation as PropTrunc renaming (rec to ∥rec∥; map to ∥map∥)
open import Cubical.HITs.SetQuotients renaming ([_] to eqCl; rec to recQ; rec2 to recQ2)
open import Cubical.Data.Sigma
open import Cubical.Data.List
open import Cubical.Data.Sum renaming (map to map⊎; inl to inj₁; inr to inj₂)
open import Cubical.Data.Empty renaming (elim to ⊥-elim; rec to ⊥-rec)
open import Cubical.Relation.Binary
open import Trees

data Pfin (A : Type) : Type where
  ø     : Pfin A
  η     : A → Pfin A
  _∪_   : Pfin A → Pfin A → Pfin A
  com  : ∀ x y → x ∪ y ≡ y ∪ x
  ass : ∀ x y z → x ∪ (y ∪ z) ≡ (x ∪ y) ∪ z
  idem  : ∀ x → x ∪ x ≡ x
  nr  : ∀ x → x ∪ ø ≡ x
  trunc : isSet (Pfin A)

_∈ₛ_ : ∀{A} → A → Pfin A → hProp ℓ-zero
x ∈ₛ ø = ⊥ₚ
x ∈ₛ η y = x ≡ₚ y
x ∈ₛ (s₁ ∪ s₂) = (x ∈ₛ s₁) ⊔ (x ∈ₛ s₂)
x ∈ₛ com s₁ s₂ i =
  ⇔toPath {_} {x ∈ₛ s₁ ⊔ x ∈ₛ s₂} {x ∈ₛ s₂ ⊔ x ∈ₛ s₁}
    (∥map∥ λ { (inj₁ m) → inj₂ m ; (inj₂ m) → inj₁ m})
    (∥map∥ λ { (inj₁ m) → inj₂ m ; (inj₂ m) → inj₁ m})
    i
x ∈ₛ ass s₁ s₂ s₃ i = 
  ⇔toPath {_} {x ∈ₛ s₁ ⊔ x ∈ₛ s₂ ⊔ x ∈ₛ s₃} {(x ∈ₛ s₁ ⊔ x ∈ₛ s₂) ⊔ x ∈ₛ s₃}
    (∥rec∥ propTruncIsProp λ { (inj₁ m) → inl (inl m)
                            ; (inj₂ m) → ∥map∥ (map⊎ inr (λ y → y)) m})
    (∥rec∥ propTruncIsProp λ { (inj₁ m) → ∥map∥ (map⊎ (λ y → y) inl) m
                            ; (inj₂ m) → inr (inr m)})
    i
x ∈ₛ idem s i =
  ⇔toPath {_} {x ∈ₛ s ⊔ x ∈ₛ s} {x ∈ₛ s}
    (∥rec∥ (isProp⟨⟩ (x ∈ₛ s)) (λ { (inj₁ m) → m ; (inj₂ m) → m }))
    inl
    i
x ∈ₛ nr s i = 
  ⇔toPath {_} {x ∈ₛ s ⊔ ⊥ₚ} {x ∈ₛ s}
  (∥rec∥ (isProp⟨⟩ (x ∈ₛ s)) (λ { (inj₁ m) → m ; (inj₂ ()) }))
  inl
  i
x ∈ₛ trunc s₁ s₂ p q i j = isSetHProp (x ∈ₛ s₁) (x ∈ₛ s₂) (cong (x ∈ₛ_) p) (cong (x ∈ₛ_) q) i j

mapPfin : ∀ {A B} → (A → B) → Pfin A → Pfin B
mapPfin f ø = ø
mapPfin f (η x) = η (f x)
mapPfin f (x ∪ y) = (mapPfin f x) ∪ (mapPfin f y)
mapPfin f (com x y i) = com (mapPfin f x) (mapPfin f y) i
mapPfin f (ass p p₁ p₂ i) = ass (mapPfin f p) (mapPfin f p₁) (mapPfin f p₂) i
mapPfin f (idem p i) = idem (mapPfin f p) i
mapPfin f (nr p i) = nr (mapPfin f p) i
mapPfin f (trunc p q x y i j) = trunc _ _ (cong (mapPfin f) x) (cong (mapPfin f) y) i j

module _ {A : Type₀} (P : Pfin A → hProp ℓ-zero) (pø : ⟨ P ø ⟩) (pη : ∀ a → ⟨ P (η a) ⟩)
         (p∪ : ∀ {s₁ s₂} → ⟨ P s₁ ⟩ → ⟨ P s₂ ⟩ → ⟨ P (s₁ ∪ s₂) ⟩) where

  elimPfinProp : ∀ x → ⟨ P x ⟩
  elimPfinProp ø = pø
  elimPfinProp (η x) = pη x
  elimPfinProp (s ∪ s') = p∪ (elimPfinProp s) (elimPfinProp s')
  elimPfinProp (com s s' i) =
    isProp→PathP (λ j → snd (P (com s s' j)))
      (p∪ (elimPfinProp s) (elimPfinProp s')) (p∪ (elimPfinProp s') (elimPfinProp s))  i
  elimPfinProp (ass s s₁ s₂ i) =
    isProp→PathP (λ j → snd (P (ass s s₁ s₂ j)))
      (p∪ (elimPfinProp s) (p∪ (elimPfinProp s₁) (elimPfinProp s₂)))
      (p∪ (p∪ (elimPfinProp s) (elimPfinProp s₁)) (elimPfinProp s₂)) i
  elimPfinProp (idem s i) =
    isProp→PathP (λ j → snd (P (idem s j))) (p∪ (elimPfinProp s) (elimPfinProp s)) (elimPfinProp s) i 
  elimPfinProp (nr s i) =
    isProp→PathP (λ j → snd (P (nr s j))) (p∪ (elimPfinProp s) pø) (elimPfinProp s) i 
  elimPfinProp (trunc s s' p q i j) =
    isOfHLevel→isOfHLevelDep 2 (λ x → isProp→isSet (snd (P x)))
      (elimPfinProp s) (elimPfinProp s') (cong elimPfinProp p) (cong elimPfinProp q)
      (trunc s s' p q) i j

_≤_ : ∀{A} → Pfin A → Pfin A → Type₀
s ≤ t = (s ∪ t) ≡ t

_⊆_ : ∀{A} → Pfin A → Pfin A → Type₀
s ⊆ t = ∀ x → ⟨ x ∈ₛ s ⟩ → ⟨ x ∈ₛ t ⟩

antisym≤ : ∀{A}{s t : Pfin A} → s ≤ t → t ≤ s → s ≡ t
antisym≤ p q = sym q ∙ com _ _ ∙ p

relLiftₛ : ∀{X Y} (R : X → Y → Type₀)
  → Pfin X → Pfin Y → Type₀
relLiftₛ R s₁ s₂ =
  ∀ x → ⟨ x ∈ₛ s₁ ⟩ → ∃[ y ∈ _ ] ⟨ y ∈ₛ s₂ ⟩ × R x y

-- symrelLiftₛ : ∀{X Y} (R : X → Y → Type₀)
--   → Pfin X → Pfin Y → Type₀
-- symrelLiftₛ R s₁ s₂ = 
--   relLiftₛ R s₁ s₂ × relLiftₛ (λ y x → R x y) s₂ s₁

symrelLiftₛ : ∀{X} (R : X → X → Type₀)
  → Pfin X → Pfin X → Type₀
symrelLiftₛ R s₁ s₂ = 
  relLiftₛ R s₁ s₂ × relLiftₛ R s₂ s₁

∪isLub : ∀{A}{s t : Pfin A} (u : Pfin A)
  → s ≤ u → t ≤ u → (s ∪ t) ≤ u
∪isLub {s = s}{t} u ls lt =
  sym (ass _ _ _)
  ∙ cong (s ∪_) lt
  ∙ ls

isProp≤ : ∀{A}{s t : Pfin A} → isProp (s ≤ t)
isProp≤ = trunc _ _

⊂2≤-η : ∀{A}(a : A) (s : Pfin A) → ⟨ a ∈ₛ s ⟩ → η a ≤ s
⊂2≤-η a = elimPfinProp (λ _ → _ , isPropΠ λ x → isProp≤)
  (λ ())
  (λ b → ∥rec∥ isProp≤ λ eq → cong (_∪ η b) (cong η eq) ∙ idem _)
  (λ {s₁}{s₂} p₁ p₂ → ∥rec∥ isProp≤
    λ { (inj₁ m) → ass _ _ _ ∙ cong (_∪ _) (p₁ m)
      ; (inj₂ m) → ass _ _ _ ∙ cong (_∪ s₂) (com _ _) ∙ sym (ass _ _ _) ∙ cong (_ ∪_) (p₂ m)})

⊂2≤ : ∀{A}(s t : Pfin A) → t ⊆ s → t ≤ s
⊂2≤ s = elimPfinProp (λ _ → _ , isPropΠ λ x → isProp≤)
  (λ p → com ø s ∙ nr s)
  (λ a m → ⊂2≤-η a s (m a ∣ refl ∣))
  (λ p₁ p₂ q → ∪isLub s (p₁ (λ x m → q x (inl m))) (p₂ (λ x m → q x (inr m))))


relLiftₛ⊆ : ∀{X}(s t : Pfin X) → relLiftₛ _≡_ s t → s ⊆ t
relLiftₛ⊆ s t p x mx =
  ∥rec∥ (snd (x ∈ₛ t)) (λ { (y , my , eq) → subst (λ z → ⟨ z ∈ₛ t ⟩) (sym eq) my }) (p x mx)

relLiftₛ⊆2 : ∀{X}(s t : Pfin X) → relLiftₛ (λ y x → x ≡ y) t s → t ⊆ s
relLiftₛ⊆2 s t p x mx = 
  ∥rec∥ (snd (x ∈ₛ s)) (λ { (y , my , eq) → subst (λ z → ⟨ z ∈ₛ s ⟩) eq my }) (p x mx)

-- symrelLiftₛEq : ∀{X} (s t : Pfin X) → symrelLiftₛ _≡_ s t → s ≡ t
-- symrelLiftₛEq s t (p₁ , p₂) =
--   antisym≤ (⊂2≤ _ _ (relLiftₛ⊆ s t p₁)) (⊂2≤ _ _ (relLiftₛ⊆2 s t p₂))

symrelLiftₛEq : ∀{X} (s t : Pfin X) → symrelLiftₛ _≡_ s t → s ≡ t
symrelLiftₛEq s t (p₁ , p₂) =
  antisym≤ (⊂2≤ _ _ (relLiftₛ⊆ s t p₁)) (⊂2≤ _ _ (relLiftₛ⊆ t s p₂))

∈ₛmapPfin : ∀{A B} (f : A → B) (a : A) (s : Pfin A)
  → ⟨ a ∈ₛ s ⟩ → ⟨ f a ∈ₛ mapPfin f s ⟩
∈ₛmapPfin f a =
  elimPfinProp (λ x → _ , isPropΠ (λ _ → snd (f a ∈ₛ mapPfin f x)))
    (λ ())
    (λ b → ∥map∥ (cong f))
    λ p₁ p₂ → ∥map∥ (map⊎ p₁ p₂)

pre∈ₛmapPfin : ∀{A B} (f : A → B) (b : B) (s : Pfin A)
  → ⟨ b ∈ₛ mapPfin f s ⟩ → ∃[ a ∈ A ] ⟨ a ∈ₛ s ⟩ × (f a ≡ b)
pre∈ₛmapPfin f b =
  elimPfinProp (λ x → _ , isPropΠ (λ _ → propTruncIsProp))
    (λ ())
    (λ a → ∥map∥ (λ eq → a , ∣ refl ∣ , sym eq))
    λ p₁ p₂ → ∥rec∥ propTruncIsProp (λ { (inj₁ m) → ∥map∥ (λ {(a , m , eq) → a , inl m , eq}) (p₁ m)
                                       ; (inj₂ m) → ∥map∥ (λ {(a , m , eq) → a , inr m , eq}) (p₂ m) })


{-
νPfin 
= Tree / ExtEq
≃ List Tree / relator ExtEq

and 

Pfin (List Tree / relator ExtEq)
≃ List (List Tree / relator ExtEq) / SameEl

so then we define
ζ' : List Tree → List (List Tree / relator ExtEq)
ζ' [] = []
ζ' (t ∷ ts) = eqCl t ∷ ζ' ts

and we check that 
relator ExtEq t₁ t₂ implies SameEl (ζ' t₁) (ζ' t₂)
-}

List→Pfin : ∀{A} → List A → Pfin A
List→Pfin [] = ø
List→Pfin (x ∷ xs) = η x ∪ List→Pfin xs

∈ₛList→Pfin : ∀{A} (xs : List A){a : A}
  → ⟨ a ∈ₛ List→Pfin xs ⟩ → ∥ a ∈ xs ∥
∈ₛList→Pfin (x ∷ xs) = ∥rec∥ propTruncIsProp
  λ { (inj₁ p) → ∥map∥ here p
    ; (inj₂ p) → ∥map∥ there (∈ₛList→Pfin xs p)} 

List→Pfin∈ : ∀{A} (xs : List A){a : A}
  → a ∈ xs → ⟨ a ∈ₛ List→Pfin xs ⟩
List→Pfin∈ (x ∷ xs) (here eq) = inl ∣ eq ∣
List→Pfin∈ (x ∷ xs) (there p) = inr (List→Pfin∈ xs p)

{-
ζ : νPfin → Pfin νPfin
ζ = recQ trunc (λ t → mapPfin eqCl (List→Pfin (force t)))
  (λ t₁ t₂ r → symrelLiftₛEq _ _
    ((λ x mx → ∥rec∥ propTruncIsProp
       (λ { (t , mt , eqt) → ∥rec∥ propTruncIsProp
         (λ mt' → ∥map∥
           (λ { (s , ms , eqs) → eqCl s , ∈ₛmapPfin eqCl s (List→Pfin (force t₂)) (List→Pfin∈ _ ms) , sym eqt ∙ eq/ _ _ eqs})
           (forceExt r .fst t mt'))
         (∈ₛList→Pfin (force t₁) mt)})
       (pre∈ₛmapPfin eqCl x (List→Pfin (force t₁)) mx))
     ,
     (λ x mx → ∥rec∥ propTruncIsProp
       (λ { (t , mt , eqt) → ∥rec∥ propTruncIsProp
         (λ mt' → ∥map∥
           (λ { (s , ms , eqs) → eqCl s , ∈ₛmapPfin eqCl s (List→Pfin (force t₁)) (List→Pfin∈ _ ms) , eq/ _ _ eqs ∙ eqt })
           (forceExt r .snd t mt'))
         (∈ₛList→Pfin (force t₂) mt)
         })
       (pre∈ₛmapPfin eqCl x (List→Pfin (force t₂)) mx))))

_++ₜ_ : Tree → Tree → Tree
force (t ++ₜ s) = (force t) ++ (force s)


ζ-1 : Pfin νPfin → νPfin
ζ-1 ø = eqCl (record { force = [] })
ζ-1 (η x) = x
ζ-1 (s ∪ s') = recQ2 squash/ (λ t t' → eqCl (t ++ₜ t')) {!!} {!!} (ζ-1 s) (ζ-1 s')
ζ-1 (com x x₁ i) = {!!}
ζ-1 (ass x x₁ x₂ i) = {!!}
ζ-1 (idem x i) = {!!}
ζ-1 (nr x i) = {!!}
ζ-1 (trunc x x₁ x₂ y i i₁) = {!!}
-}

SameEl : {X : Type} → List X → List X → Type
SameEl = relator _≡_

Pfin2 : Type → Type
Pfin2 X = List X / SameEl

{- 
IT NEEDS FULL AXIOM OF CHOICE!!!  (And therefore excluded middle in hProp)
It would work if X → Pfin2 X ≃ (X → List X) / (X → SameEl) 
-}
pre-anaₜ : ∀{X} (c : X → Pfin2 X) → List X → Tree
pre-anaₚ : ∀{X} (c : X → Pfin2 X) → Pfin2 X → νPfin
force (pre-anaₜ c []) = []
force (pre-anaₜ c (x ∷ xs)) = {!pre-anaₚ c (c x)!} ∷ {!!}
pre-anaₚ c = recQ squash/ (λ xs → eqCl (pre-anaₜ c xs)) {!!}
-- pre-ana' c ø = ø
-- pre-ana' c (η x) = η (pre-ana c x)
-- pre-ana' c (s ∪ s₁) = pre-ana' c s ∪ pre-ana' c s₁
-- pre-ana' c (com s s₁ i) = com (pre-ana' c s) (pre-ana' c s₁) i
-- pre-ana' c (ass s s₁ s₂ i) = ass (pre-ana' c s)  (pre-ana' c s₁) (pre-ana' c s₂) i
-- pre-ana' c (idem s i) = idem (pre-ana' c s) i
-- pre-ana' c (nr s i) = nr (pre-ana' c s) i
-- pre-ana' c (trunc p q x y i j) = trunc _ _ (cong (pre-ana' c) x) (cong (pre-ana' c) y) i j

record νPfin2 (j : Size) : Type₀ where
  constructor thunk
  coinductive
  field
    force2 : {k : Size< j} → Pfin (νPfin2 k)
open νPfin2 public

record Bisim2 (j : Size) (s₁ s₂ : νPfin2 ∞) : Type where
  coinductive
  field
    forceEq2 : ∀{k : Size< j} → symrelLiftₛ (Bisim2 k) (force2 s₁) (force2 s₂)
open Bisim2

force2-inj : ∀{s t : νPfin2 ∞} → force2 s ≡ force2 t → s ≡ t
force2 (force2-inj eq i) = {!eq i!}


-- force2-inj : ∀{s t : νPfin2 ∞} → force2 s ≡ force2 t → s ≡ t
-- force2 (force2-inj eq i) = eq i

-- force2-iso1 : ∀ s → force2 (thunk s) ≡ s
-- force2-iso1 s = refl

-- force2-iso2 : ∀ s → thunk (force2 s) ≡ s
-- force2-iso2 s = force2-inj refl

-- ana : ∀{X} (c : X → Pfin X) → X → νPfin2
-- ana' : ∀{X} (c : X → Pfin X) → Pfin X → Pfin νPfin2
-- force2 (ana c x) = ana' c (c x)
-- ana' c = mapPfin (ana c)

-- -- ana' c ø = ø
-- -- ana' c (η x) = η (ana c x)
-- -- ana' c (s ∪ s₁) = ana' c s ∪ ana' c s₁
-- -- ana' c (com s s₁ i) = com (ana' c s) (ana' c s₁) i
-- -- ana' c (ass s s₁ s₂ i) = ass (ana' c s)  (ana' c s₁) (ana' c s₂) i
-- -- ana' c (idem s i) = idem (ana' c s) i
-- -- ana' c (nr s i) = nr (ana' c s) i
-- -- ana' c (trunc p q x y i j) = trunc _ _ (cong (ana' c) x) (cong (ana' c) y) i j

-- -- anaEq : ∀{X} (c : X → Pfin X) (x : X)
-- --   → force2 (ana c x) ≡ mapPfin (ana c) (c x)
-- -- anaEq' : ∀{X} (c : X → Pfin X) (s : Pfin X)
-- --   → ana' c s ≡ mapPfin (ana c) s
-- -- anaEq c x = anaEq' c (c x)
-- -- anaEq' c =
-- --   elimPfinProp (λ s → _ , trunc _ _)
-- --     refl (λ _ → refl) λ p₁ p₂ → cong₂ _∪_ p₁ p₂ 

-- -- anaEq2 : ∀{X} (c : X → Pfin X) (x : X)
-- --   → ana c x ≡ thunk (mapPfin (ana c) (c x))
-- -- anaEq2 c x = force2-inj (anaEq' c (c x)) 

-- -- ana-uniq' : ∀{X} (c : X → Pfin X)
-- --   → (f : X → νPfin2) (eq : ∀ x → f x ≡ thunk (mapPfin f (c x)))
-- --   → ∀ s → ana' c s ≡ mapPfin f s
-- -- -- ana-uniq'' : ∀{X} (c : X → Pfin X)
-- -- --   → (f : X → νPfin2) (eq : ∀ x → force2 (f x) ≡ mapPfin f (c x))
-- -- --   → ∀ x → ana' c (c x) ≡ force2 (f x)
-- -- ana-uniq : ∀{X} (c : X → Pfin X)
-- --   → (f : X → νPfin2) (eq : ∀ x → f x ≡ thunk (mapPfin f (c x)))
-- --   → ∀ x → ana c x ≡ thunk (mapPfin f (c x))
-- -- ana-uniq' c f eq ø = refl
-- -- ana-uniq' c f eq (η x) = cong η (ana-uniq c f eq x ∙ sym (eq x))
-- -- ana-uniq' c f eq (s ∪ s₁) = cong₂ _∪_ (ana-uniq' c f eq s) (ana-uniq' c f eq s₁)
-- -- ana-uniq' c f eq (com s s₁ i) = {!!}
-- -- ana-uniq' c f eq (ass s s₁ s₂ i) = {!!}
-- -- ana-uniq' c f eq (idem s i) = {!!}
-- -- ana-uniq' c f eq (nr s i) = {!!}
-- -- ana-uniq' c f eq (trunc s s₁ x y i i₁) = {!!}

-- -- --ana-uniq'' c f eq x = ana-uniq' c f eq (c x) ∙ sym (eq x)

-- -- force2 (ana-uniq c f eq x i) = ana-uniq' c f eq (c x) i

-- -- {-
-- -- bisim2 : (t₁ t₂ : νPfin2) → Bisim2 t₁ t₂ → force2 t₁ ≡ force2 t₂
-- -- bisim2' : (t₁ t₂ : Pfin νPfin2) → relLiftₛ Bisim2 t₁ t₂ → relLiftₛ _≡_ t₁ t₂
-- -- bisim2 t₁ t₂ b i = {!bisim2' (force2 t₁) (force2 t₂) ?!} --(bisim2' (force2 t₁) (force2 t₂) (forceEq2 b .fst)) , bisim2' (force2 t₂) (force2 t₁) (forceEq2 b .snd)
-- -- bisim2' t₁ t₂ b x mx = ∥map∥ (λ { (y , my , eq) → y , my , force2-inj (bisim2 x y eq)}) (b x mx)
-- -- -}

-- -- {-
-- -- bisim2 : (t₁ t₂ : νPfin2) → Bisim2 t₁ t₂ → t₁ ≡ t₂
-- -- bisim2' : (t₁ t₂ : Pfin νPfin2) → relLiftₛ Bisim2 t₁ t₂ → relLiftₛ _≡_ t₁ t₂ 
-- -- force2 (bisim2 t₁ t₂ b i) =
-- --   symrelLiftₛEq (force2 t₁) (force2 t₂) (bisim2' (force2 t₁) (force2 t₂) (forceEq2 b .fst) , bisim2' (force2 t₂) (force2 t₁) (forceEq2 b .snd)) i
-- -- bisim2' t₁ t₂ b x mx = ∥map∥ (λ { (y , my , eq) → y , my , bisim2 x y eq}) (b x mx)
-- -- -}

-- -- {-
-- -- record νPfin2 (i : Size) : Type₀ where
-- --   constructor thunk
-- --   coinductive
-- --   field
-- --     force2 : {j : Size< i} → Pfin (νPfin2 j)
-- -- open νPfin2 public

-- -- record Bisim2 (i : Size) (j : Size< i) (s₁ s₂ : νPfin2 i) : Type where
-- --   coinductive
-- --   field
-- --     forceEq2 : {k : Size< j} → symrelLiftₛ (Bisim2 j k) (force2 s₁) (force2 s₂)
-- -- open Bisim2

-- -- bisim2 : ∀{j}{k : Size< j} (t₁ t₂ : νPfin2 j) → Bisim2 j k t₁ t₂ → t₁ ≡ t₂
-- -- bisim2' : ∀{j}{k : Size< j} (t₁ t₂ : Pfin (νPfin2 j)) → relLiftₛ (Bisim2 j k) t₁ t₂ → relLiftₛ _≡_ t₁ t₂ 
-- -- force2 (bisim2 t₁ t₂ b i) =
-- --   symrelLiftₛEq (force2 t₁) (force2 t₂) ({!bisim2' (force2 t₁) (force2 t₂) ?!} , {!!}) {!!}
-- -- --  symrelLiftₛEq (force2 t₁) (force2 t₂) (bisim2' (force2 t₁) (force2 t₂) (forceEq2 b .fst) , bisim2' (force2 t₂) (force2 t₁) (forceEq2 b .snd)) i
-- -- bisim2' t₁ t₂ b x mx = ∥map∥ (λ { (y , my , eq) → y , my , bisim2 x y eq}) (b x mx)
-- -- -}

-- -- -- refl-Bisim2 : (t : νPfin2) → Bisim2 t t
-- -- -- forceEq2 (refl-Bisim2 t) =
-- -- --   (λ x mx → ∣ x , mx , refl-Bisim2 x ∣) ,
-- -- --   (λ x mx → ∣ x , mx , refl-Bisim2 x ∣)

-- -- -- misib2 : (t₁ t₂ : νPfin2) → t₁ ≡ t₂ → Bisim2 t₁ t₂
-- -- -- misib2 t₁ t₂ = J (λ x p → Bisim2 t₁ x) (refl-Bisim2 t₁) 

-- -- -- force2-inj' : ∀{s t} → force2 s ≡ force2 t → Bisim2 s t
-- -- -- fst (forceEq2 (force2-inj' eq)) x m = ∣ x , subst (λ z → ⟨ x ∈ₛ z ⟩) eq m , refl-Bisim2 x ∣
-- -- -- snd (forceEq2 (force2-inj' eq)) x m = ∣ x , subst (λ z → ⟨ x ∈ₛ z ⟩) (sym eq) m , refl-Bisim2 x ∣

-- -- -- force2-inj : ∀{s t} → force2 s ≡ force2 t → s ≡ t
-- -- -- force2-inj eq = bisim2 _ _ (force2-inj' eq)

-- -- -- thunk-inj' : ∀{s t} → Bisim2 (thunk s) (thunk t) → s ≡ t
-- -- -- thunk-inj' b = symrelLiftₛEq _ _
-- -- --   ((λ x mx → {!forceEq2 b .fst x mx!}) ,
-- -- --    {!!})

-- -- -- force2-thunk : ∀ s → force2 (thunk s) ≡ s
-- -- -- force2-thunk s = refl

-- -- -- thunk-force2 : ∀ s → Bisim2 (thunk (force2 s)) s
-- -- -- fst (forceEq2 (thunk-force2 s)) x m = ∣ x , m , refl-Bisim2 x ∣
-- -- -- snd (forceEq2 (thunk-force2 s)) x m = ∣ x , m , refl-Bisim2 x ∣

-- -- -- thunk-surj : ∀ s → ∃[ t ∈ Pfin νPfin2 ] thunk t ≡ s
-- -- -- thunk-surj s = ∣ force2 s , bisim2 _ _ {!!} ∣


-- -- -- -- ana : ∀{X} (c : X → Pfin X) → X → νPfin
-- -- -- -- ana' : ∀{X} (c : X → Pfin X) → Pfin X → Pfin νPfin
-- -- -- -- force (ana c x) = ana' c (c x)
-- -- -- -- ana' c ø = ø
-- -- -- -- ana' c (η x) = η (ana c x)
-- -- -- -- ana' c (s ∪ s₁) = ana' c s ∪ ana' c s₁
-- -- -- -- ana' c (com s s₁ i) = com (ana' c s) (ana' c s₁) i
-- -- -- -- ana' c (ass s s₁ s₂ i) = ass (ana' c s)  (ana' c s₁) (ana' c s₂) i
-- -- -- -- ana' c (idem s i) = idem (ana' c s) i
-- -- -- -- ana' c (nr s i) = nr (ana' c s) i
-- -- -- -- ana' c (trunc p q x y i j) = trunc _ _ (cong (ana' c) x) (cong (ana' c) y) i j

-- -- -- -- anaEq : ∀{X} (c : X → Pfin X) (x : X)
-- -- -- --   → force (ana c x) ≡ mapPfin (ana c) (c x)
-- -- -- -- anaEq' : ∀{X} (c : X → Pfin X) (s : Pfin X)
-- -- -- --   → ana' c s ≡ mapPfin (ana c) s
-- -- -- -- anaEq c x = anaEq' c (c x)
-- -- -- -- anaEq' c =
-- -- -- --   elimPfinProp (λ s → _ , trunc _ _)
-- -- -- --     refl (λ _ → refl) λ p₁ p₂ → cong₂ _∪_ p₁ p₂ 



-- -- -- -- misib : (t₁ t₂ : νPfin) → t₁ ≡ t₂ → Bisim t₁ t₂
-- -- -- -- misib t₁ t₂ = J (λ x p → Bisim t₁ x) (refl-Bisim t₁) 

-- -- -- -- bisim : (t₁ t₂ : νPfin) → Bisim t₁ t₂ → t₁ ≡ t₂ --relLiftₛ _≡_ (force t₁) (force t₂)
-- -- -- -- bisim' : (t₁ t₂ : Pfin νPfin) → relLiftₛ Bisim t₁ t₂ → relLiftₛ _≡_ t₁ t₂ --{x : νPfin} → ⟨ x ∈ₛ t₁ ⟩ → ⟨ {!!} ⟩ 
-- -- -- -- force (bisim t₁ t₂ b i) = {!!}
-- -- -- -- --  relLiftₛEq (force t₁) (force t₂) (bisim' (force t₁) (force t₂) (forceEq b)) i
-- -- -- -- bisim' t₁ t₂ b x mx with b x mx
-- -- -- -- ... | ∣ y , my , eq ∣ = ∣ y , my , bisim x y eq ∣
-- -- -- -- ... | squash y z i = {!!}
-- -- -- -- -- --  (λ x mx → ∥map∥ (λ { (y , my , eq) → y , my , bisim x y eq}) (b₁ x mx)) ,
-- -- -- -- -- --  (λ y my → ∥map∥ (λ { (x , mx , eq) → x , mx , bisim x y eq}) (b₂ y my))

-- -- -- -- -- ana-uniq : ∀{X} (c : X → Pfin X)
-- -- -- -- --   → (f : X → νPfin) (eq : ∀ x → relLiftₛ _≡_ (force (f x)) (mapPfin f (c x)))
-- -- -- -- --   → ∀ x → Bisim (ana c x) (f x)
-- -- -- -- -- forceEq (ana-uniq c f eq x) = {!!}
-- -- -- -- -- -- 
-- -- -- -- -- --   (λ t mt →
-- -- -- -- -- --      ∥rec∥ propTruncIsProp
-- -- -- -- -- --        (λ {(y , my , eqy) → ∥map∥ (λ { (t' , mt' , eqt') → t' , mt' , misib _ _ (sym eqy ∙ bisim _ _ (ana-uniq c f eq y) ∙ sym eqt')}) (eq x .snd (f y) (∈ₛmapPfin f y (c x) my))} ) 
-- -- -- -- -- --        (pre∈ₛmapPfin (ana c) t (c x) (subst (λ z → ⟨ t ∈ₛ z ⟩) (anaEq' c (c x)) mt)) ) , 
-- -- -- -- -- --   {!!}



record Str (A : Type) : Type where
  coinductive
  field
    force : A × Str A
open Str

force-inj : ∀{A} {s s' : Str A} → force s ≡ force s' → s ≡ s'
force (force-inj eq i) = eq i

mutual
  data StrSz (j : Size) (A : Type) : Type where
    cons : A → StrSz' j A → StrSz j A
  record StrSz' (j : Size) (A : Type) : Type where
    coinductive
    field
      forceSz : {k : Size< j} → StrSz k A
open StrSz'

forceSz-inj : ∀{A} {s s' : StrSz' ∞ A} → forceSz s ≡ forceSz s' → s ≡ s'
forceSz (forceSz-inj eq i) = {!eq i!}

{-
record StrSz (j : Size) (A : Type) : Type where
  coinductive
  field
    forceSz : {k : Size< j} → A × StrSz k A
open StrSz

forceSz-inj : ∀{A} {s s' : StrSz ∞ A} → forceSz s ≡ forceSz s' → s ≡ s'
forceSz (forceSz-inj eq i) = {!eq i!}
-}


