module Lang

open FStar.Mul
open FStar.Fin
open FStar.List

// Example of a refinement type
// type pos = x: nat { x > 0 }

// Array dimensions are a tuple of two positive numbers
type dim = pos & pos

// We limit the ranks of arrays to be three
val rank : dim -> int
let rank d = match (fst d > 1) with
  | true -> 2
  | false -> if (snd d > 1) then 1 else 0

// A scalar is encoded as an array with dimensions 1,1
val scalar : dim
let scalar = 1,1

// Vector takes a stride arguments and returns an array with dimensions 1,stride
// That is, an array which has a single row and a stride > 1 is a vector.
val vector : pos -> dim
let vector stride = 1,stride

// Matrix is like a vector but thats also rows
val matrix : pos -> pos -> dim
let matrix rows stride = rows,stride

let _ = assert (vector 1 = scalar)
let _ = assert (matrix 1 1 = scalar)
let _ = assert (vector 4 = matrix 1 4)

let rec flatten (dims: list dim): list dim = match dims with
  | [] -> []
  | (a, b) :: tail -> vector (a * b) :: flatten tail

let rec shape (dims: list dim): list pos = match dims with
  | [] -> []
  | (a, b) :: tail -> a :: b :: shape tail

let rec product (nats: list pos) : pos = match nats with
  | [] -> 1
  | x :: xs -> x * product xs

let rec max (l: list int { length l > 0 }) : Tot int (decreases l) =
  match l with
  | [h] -> h
  | h :: t ->
    if h > (max t) then h
    else max t

let rec min (l: list int { length l > 0 }) : Tot int (decreases l) =
  match l with
  | [h] -> h
  | h :: t ->
    if h < (min t) then h
    else min t

// An (crude) abstract sum operation can be encoded such that it takes two dimensions
// w and x s.t. x is constrained by refinement types to have either the same stride
// as w, or then the stride of w or x is a scalar.
val sum:
  (w: dim) ->
  (x: dim {
    // Rank polymorphism over scalars has no refinement for components
    (min [rank w; rank x] = 0)
    // Rank polymorphism over vectors has a refinement for the second component
    \/ (min [rank w; rank x] = 1 && snd w = snd x)
    // Rank polymorphism over matrices has a refinement for both components
    \/ (min [rank w; rank x] = 2 && snd w = snd x && fst w = fst x)
  }) ->
  (res: dim {
    // sum always preserves the higher rank
    rank res = max [rank w; rank x] &&
    res = (if rank w > rank x then w else x)
  }
)
let sum w x =
  match (min [rank w; rank x]) with
  | 0 ->
    matrix (fst w * fst x) (snd w * snd x)
  | 1 ->
    assert (snd w = snd x);
    assert ((fst x * fst w) = max [fst x; fst w]);
    matrix (max [fst x; fst w]) (snd w)
  | 2 ->
    assert (w = x);
    w

let _ = assert (sum scalar scalar == scalar)
let _ = assert (sum (vector 4) scalar == vector 4) // This shows that rank polymorphism actually works.
let _ = assert (sum (vector 4) (vector 4) == vector 4)
let _ = assert (sum (vector 4) (vector 1) == vector 4)
let _ = assert (sum (matrix 2 2) (vector 2) == matrix 2 2)
let _ = assert (sum (matrix 2 2) scalar == matrix 2 2)
let _ = assert (sum (matrix 2 2) (matrix 2 2) == matrix 2 2)

// iota can be encoded such that it always takes a len and return a vector of that length.
val iota : pos -> dim
let iota len = vector len

// We could start encoding the grammar such that there are a set of functions.
type fn =
  | Plus : fn

// We could also come up with fold which matches on the rank to return some new type.
val reduce : fn -> dim -> dim
let reduce op x = match rank x with
  | 0 -> scalar
  | 1 -> scalar
  | 2 -> vector (fst x)

// Indeed, we can assert that reducing an iota operation returns us a scalar.
let _ = assert (reduce Plus (iota 4) == scalar)
let _ = assert (sum scalar (reduce Plus (iota 4)) == scalar)

val select:
  (w: dim) ->
  (x: dim {
    // A weak refinement is to say the flattened shape w <= x
    product (shape (flatten [w])) <= product (shape (flatten [x]))
    // A general refinement is to say that the rank of w <= x
    /\ rank w <= rank x
    // A refinement for scalars is that the rank of x must at least be a vector
    // This cannot be completely type-checked: the selection is data-dependent
    /\ (rank w == 0 ==> rank x >= 1)
    // A refinemenet for vectors is to say that the second component must be a partition
    // The partition must evenly split
    /\ (snd x % snd w == 0)
    // A refinement for matrices is to say the partition is a kernel
    /\ (fst x % fst w == 0)
  }) ->
  (res: dim {
    rank res = rank w
  })
let select w x =
  match (rank w) with
  | 0 ->
    // If you want to select a single element, then x must be at least a vector
    assert (rank x >= 1);
    w
  | 1 ->
    assert (snd w <= snd x);
    vector (snd w)
  | 2 ->
    assert (snd w <= snd x);
    assert (fst w <= fst x);
    matrix (fst w) (fst w)

let _ = assert (select scalar (vector 4) = scalar)

// Standard definitions for some types of functions:
irreducible type trigger (#a: Type) (x:a) = True
type injection (#a:Type) (#b:Type) (f:a -> Tot b) = (forall (x:a) (y:a). f x == f y ==> x == y)
type surjection (#a:Type)(#b:Type) (f:a -> Tot b) = (forall (y:b). {:pattern (trigger y)} (exists (x:a). f x == y))
// Bijections can be encoded such that the f is both an injection and a surjection.
type bijection (#a:Type) (#b:Type) (f:a -> Tot b) = injection f /\ surjection f
// Inverses can be checked s.t. we take two functions f and g and make sure that composition in each order returns the initial argument.
type inverses (#a:Type) (#b:Type) (f:a -> Tot b) (g:b -> Tot a) = (forall (y:b). f (g y) == y) /\ (forall (x:a). g (f x) == x)

// A computational Under takes three functions: g, f, and g_inv and an argument x.
val under_comp: #a: Type -> #b: Type -> g: (a -> b) -> f: (b -> b) -> g_inv: (b -> a) -> x: a -> Lemma
  (requires (inverses g g_inv))
  (ensures (bijection g))
// We can also leave the proving of the implementation to the SMT solver as below.
let under_comp #a #b g f g_inv x = ()

let addition (w x: int) = w + x
let subtraction (w x: int) = w - x

type op =
  | Addition : op
  | Subtraction : op

let undo op (w:int) (x:int) : int = match op with
  | Addition -> subtraction w x
  | Subtraction -> addition w x

let apply op (w: int) (x:int): int = match op with
  | Addition ->
    assert (undo Subtraction w x = addition w x);
    addition w x
  | Subtraction -> subtraction w x

let _ = assert(undo Addition 5 1 == 4)
let _ = assert(undo Subtraction 3 1 == 4)

// We would need higher order types.
let shift (x: int) = x + 5
let unshift (y: int) = y - 5
let double (y: int) = y * 2

let u_u (f: int -> int) (g: op & int) (x: int): int =
  undo (fst g) (snd g) (f (apply (fst g) x (snd g)))
let en_u (cipher: int) (x: int): int =
  u_u double (Subtraction, cipher) x
let _ = assert(en_u 5 8 == 11)

unopteq
type lens (s: Type) (v: Type) = {
  get: s -> v;
  put: v & s -> s;

  put_get: v': v -> s': s -> Lemma
    (requires True)
    (ensures get (put (v', s')) == v');

  get_put: s': s -> Lemma
    (requires True)
    (ensures put (get(s'), s') == s');

  put_put: v': v -> v'': v -> s': s -> Lemma
    (requires True)
    (ensures put(v'', put (v', s')) == put (v'', s'));
}

val under : #s:Type -> #v:Type -> lens s v -> (v -> v) -> (s -> s)
let under { get; put; } f g = put (f (get g), g)
