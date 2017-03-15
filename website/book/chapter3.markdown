---
layout: default
permalink: /chapter3/
custom_js:
- jquery.min
- anchor.min
- ace.min
- mode-haskell.min
- bundle
- index
---

{%pagination chapter2#%}

# Chapter 3 - Continuing w/ Style

In this chapter, we introduce *continuations* and writing functions in *continuation passing style* (CPS). We also discuss the reasons for writing CPSed programs.

## 1. Continuation Passing Style
In essence, a continuation is a higher-order function that abstracts over an extended content for performing a certain computation. This is much more easily explained in a functional language, since we can treat continuations simply as a special form of accumulator, where the value being "accumulated" is a function. Doing this also has the added benefit of providing control over program evaluation.

### a. Callback Everyday -- Continuations
<!-- Convert a few basic functions -->
As we mentioned, a continuation is a higher-order function and writing in CPS is synonymous with using a function as an accumulator.

With this in mind, let's take a few steps back and recall writing in APS. In Chapter 1, we described how to convert a generally recursive definition into one that uses APS. To reiterate, here is the definition of `sum` written using general recursion:
```haskell
sum :: List Int -> Int
sum Nil    = 0
sum (x:xs) = x + (sum xs)
```
To convert `sum` to its APS equivalent, we add a accumulator parameter, update its value during the recursive step, then return it once the base case is reached.
```haskell
sum :: List Int -> Int
sum xs = sumAcc xs 0
  where
    sumAcc :: List Int -> Int -> Int
    sumAcc Nil acc    = acc
    sumAcc (x:xs) acc =
      sumAcc xs (acc + x)
```
From here, translating an APSed program to a CPSed equivalent requires that we abstract over the accumulator by replacing it with a higher-order function. In this case, `sumAcc` has two arguments, a `List Int` and an `Int`, where the second is the accumulator. Replacing this value with a higher-order function means that we have the following type for `sumCPS`:
```haskell
sumCPS :: List Int -> (... -> ...) -> Int
```
Let's complete this type declaration and fill in the two `...` with the appropriate types. To determine these types, we can reason about:

1. The type of the continuation's parameter.
2. The return type of the continuation.

`(1)` and `(2)` are synonymous with the type of `acc` in `sumAcc`. If we inspect the initial value of `acc` in the context of `sum`, we discover that it's initialized to the value `0`, an `Int`. This means that the first `...` is `Int`.
```haskell
sumCPS :: List Int -> (Int -> ...) -> Int
```
The second `...` is the type of `acc` after being updated during each recursive case. During the recursive case, given that we peform addition on `acc`, it should come with no surprise that the type is *also* `Int`.
```haskell
sumCPS :: List Int -> (Int -> Int) -> Int
```
Declaring this type dictates the definition of `sumCPS` in two ways:

1. We must apply the continuation to our base case, `0`.
2. We must extend the continuation during the recursive case.

For `(1)`, we apply a continuation to the value `0`, the original return value of `sum`. For `(2)`, we recur normally, while treating our continuation as a form of accumulator. Here, we are **not** performing the addition to a set value like in `sumAcc` but are, instead, creating a function that performs the addition under the context of some other computation, `k`. Thus, extending a continuation is synonymous with defining how `sum` *continues* with its *next* computation.
{% repl_only sumcps#sum :: List Int -> Int
sum xs = sumCPS xs id
  where
    sumCPS :: List Int -> (Int -> Int) -> Int
    sumCPS Nil k    = -- (1)
      k 0 
    sumCPS (x:xs) k = -- (2)
      sumCPS xs (\acc -> k (acc + x))%}

To further illustrate the behavior of this CPSed function, we include a trace of the `List` and continuation value in computing `(sum (1:2:3:Nil))`:
```haskell
-- Recursive case => Continuations are extended
(1:2:3:Nil) id
(2:3:Nil) (\acc -> id (acc + 1))
(3:Nil) (\acc -> (\acc -> id (acc + 1)) (acc + 2))
Nil (\acc -> (\acc -> (\acc -> id (acc + 1)) (acc + 2)) (acc + 3))
-- Base case is reached => Continuations are applied
(\acc -> (\acc -> (\acc -> id (acc + 1)) (acc + 2)) (acc + 3)) 0
(\acc -> (\acc -> id (acc + 1)) (acc + 2)) 3
(\acc -> id (acc + 1)) 5
id 6
-- Final continuation is applied
id 6
6
```

**Aside:** `id` is our old friend the identity function. Since continuations are functions, to properly model the behavior of an accumulator, their base value must be `id`.

### b. One Step at a Time -- Control Flow
<!-- explicit order of operations -->
<!-- near stateful computation -->

The primary benefit of writing in CPS is the control over a function's evaluation order. To illustrate this point, we need a more complex example than `sum`. Let's bring back `append` and `rev` from Chapter 1:
```haskell
append :: forall a. List a -> List a -> List a
append Nil ys    = ys
append (x:xs) ys = x:(append xs ys)

rev :: forall a. List a -> List a
rev Nil    = Nil
rev (x:xs) = append (rev xs) (x:Nil)
```
Let's CPS both of these functions. First, let's determine the appropriate types for their CPSed equivalents.

Since neither of these function are written in APS, we must add a continuation parameter to both of their type declarations:
```haskell
append :: forall a. List a -> List a -> (List a -> List a) -> List a
rev :: forall a. List a -> (List a -> List a) -> List a
```
In both cases, the type of the continuation parameter is `(List a -> List a)`, since both functions return a `List a`. Let's start by implementing the CPSed version of `append`.
```haskell
append Nil ys k    = ?basecase
append (x:xs) ys k = ?recur
```
In the original definition of `append`, we return `ys` in the event that `xs` is `Nil`. In the CPSed version, we return `ys` by applying `k` to it:
```haskell
append Nil ys k = k $ ys
```
In the recursive case, we extend our continuation to perform the `:` operation.
```haskell
append (x:xs) ys k =
  append xs ys (\ans -> k (x:ans))
```
Next, we implement the CPSed version of `rev`:
```haskell
rev Nil k    = ?basecase
rev (x:xs) k = ?recur
```
On the other hand, implementing `rev` requires that we perform certain computations before others. This is a quite bit different from the general functional style of writing code. Since the base case of `rev` is straightforward to implement, let's focus on its recursive case:
```haskell
rev (x:xs) = append (rev xs) (x:Nil)
```
Here, we are calling `append` *and* `rev`. The question is: *Which one happens first?* The natural answer would be that the call to `rev` happens first. In general, this is correct, but writing code in the general functional style provides us the liberty of not having to reason about which call happens first!

In CPSing `rev`, we gain the ability to choose which call happens first. 
{% repl_only revCps#append :: forall a. List a -> List a ->
          (List a -> List a) -> List a
append Nil ys k    =
  k ys
append (x:xs) ys k =
  append xs ys (\ans -> k (x:ans))
  
rev :: forall a. List a ->
       (List a -> List a) -> List a
rev Nil k    =
  k Nil
rev (x:xs) k =
  rev xs $ \xs' ->
  append xs' (x:Nil) $ \ans ->
  k ans%}
**NOTE:** Don't forget to use `id` when calling these functions!

Here, we've implemented `rev` to first evaluate the recursive call to itself. Doing this, we discover that the recursive call to `rev` *must* happen before the call to `append`! This is because `append` depends on the result of the `rev` computation, which is made clearer when written in CPS style. For example, it is impossible to evaluate the call to `append` without first having `xs'`, the reversed list.

### c. If You Squint Your Eyes -- Tail Calls
One might have noticed someting strange about the implementation of fully CPSed functions, especially in the way we've written `append` and `rev` above. This particular *something* is not actually strange at all but instead is one of the other benefits of writing in CPS.

In a CPSed function, every call is a tail call. This is a side-effect of regaining control over the flow of program execution. That is, the execution of each line happens right when we expect them to, just like it would in an imperative language! Let's focus again on the recursive case in `rev`:
```haskell
rev (x:xs) k =
  rev xs $ \xs' ->
  append xs' (x:Nil) $ \ans ->
  k ans
```
Then, let's add a bit of whitespace, η-exand and rename our continuation variable, `k`:
```haskell
rev (x:xs) Nil return =
  rev xs             $ \xs' ->
  append xs' (x:Nil) $ \ans ->
  return ans
```
*Whoa*. Doesn't that look familiar?

In this maner, looking at a CPS function feels almost analogous to looking at an implementation in an imperative language. That is, in the recursive case of `rev`, we *know* that the following happens:

1. The call to `rev` is executed.
2. Once `(1)` finishes, the current continuation is applied to its result.
3. From `(2)`, the variable `xs'` holds the value of `(rev xs)`.
4. After the continuation is applied in `(2)`, the code continues with the next line.
5. Once `(4)` finishes, the current continuation is applied to its result.
6. From `(5)`, the variable `ans` holds the value of `(append xs' (x:Nil))`.
7. After the continuation is applied to `(4)`, the code continues with the next line.
8. Finally, applying `return` to `ans` results in program exit.

**NOTE:** Just like how it was earlier, the last line of the recursive call to `rev` should be:
```haskell
append xs' (x:Nil) return
```
In this case, we η-expanded to appeal to the more familiar structure of imperative code.

## 2. CPS the Interpreter -- Implementation
<!-- interpreter goes here -->
{% basic_hidden terms#instance showEnv :: Show a => Show (Env a) where
  show env = show' env true where
    show' EmptyEnv b | b         = "{}"
                     | otherwise = "}"
    show' (Ext e env) true =
      "{" <> e.name <> ": (" <>
      show e.val <> ")" <>
      show' env false
    show' (Ext e env) x =
      ", " <> e.name <> ": (" <>
      show e.val <> ")" <>
      show' env x

data Env a = EmptyEnv
           | Ext { name :: Name, val :: a } (Env a)

lookUp :: forall a. Env a -> Name -> a
lookUp EmptyEnv n = error $ "unbound variable: " <> show n
lookUp (Ext e env) n | n == e.name = e.val
                     | otherwise   = lookUp env n

extend :: forall a. Name -> a -> Env a -> Env a
extend n v = Ext { name : n, val : v }
instance showTerm :: Show Term where
  show (Num n)     = show n
  show (Sub x y)   = "(" <> show x <> " - " <> show y <> ")"
  show (Mul x y)   = "(" <> show x <> " * " <> show y <> ")"
  show (IsZero x)  = "(zero? " <> show x <> ")"
  show (If x y z)  =
    "If " <> show x <>
    " then " <> show y <>
    " else " <> show z
  show (Var n)     = n
  show (Lam n x)   =
    "(λ(" <> n <> ") . " <> show x <> ")"
  show (App x y)   =
    "(" <> show x <> " " <> show y <> ")"
type Name = String
data Term = Num Number
          | Sub Term Term
          | Mul Term Term
          | IsZero Term
          | If Term Term Term
          | Var Name
          | Lam Name Term
          | App Term Term
instance showValueC :: Show ValueC where
  show (NC x) = "NC " <> show x-- .n
  show (BC x) = "BC " <> show x-- .b
  show (FC (Closure clos)) =
    "Function from " <> clos.name <>
    " returns " <> show clos.body <>
    ", with context " <> show clos.env#newtype Closure = Closure {
  name  :: Name,
  body :: Term,
  env  :: Env ValueC
}

data ValueC = NC Number
            | BC Boolean
            | FC Closure%}

{% basic cpshelpers#onC :: forall a b c r.
       (b -> b -> c) -> (a -> (b -> r) -> r) ->
       a -> a -> (c -> r) -> r
onC op f x y return =
  f x $ \x ->
  f y $ \y ->
  return $ x `op` y

calcValueC :: Env ValueC -> (Number -> Number -> Number) ->
              Term -> Term -> (Number -> ValueC) -> ValueC
calcValueC e op =
  onC op $ \a return ->
  interpC e a $ \a ->
  case a of
    NC num -> return num
    _      ->
      error "arithmetic on non-number"%}

{% basic closfuns#applyClosure :: Closure -> ValueC -> (ValueC -> ValueC) -> ValueC
applyClosure (Closure clos) rat =
  interpC (extend clos.name rat clos.env) clos.body

makeClosure :: Name -> Term -> Env ValueC -> Closure
makeClosure n b e = Closure { name : n, body : b, env : e }%}

{% repl_only interpC#interpC :: Env ValueC -> Term -> (ValueC -> ValueC) -> ValueC
interpC _ (Num i) return    =
  return $ NC i
interpC e (Sub x y) return  =
  calcValueC e (-) x y $ \r ->
  return $ NC r
interpC e (Mul x y) return  =
  calcValueC e (*) x y $ \r ->
  return $ NC r
interpC e (IsZero x) return =
  interpC e x $ \x ->
  return <<< BC $
  case x of
    NC n -> n == 0.0
    _    -> false
interpC e (If x y z) return =
  interpC e x $ \x ->
  case x of
    BC bool ->
      if bool
      then interpC e y return
      else interpC e z return
    _       -> interpC e y return
interpC e (Var x) return   =
  return $ lookUp e x
interpC e (Lam n b) return =
  return $ FC (makeClosure n b e)
interpC e (App l r) return =
  interpC e l $ \l ->
  case l of
    FC foo ->
      interpC e r $ \val ->
      applyClosure foo val return
    _      -> error "applied non-function value"%}

```haskell
interpC EmptyEnv (App (Lam "x" (Lam "y" (Var "x"))) (Num 6.0)) id
==
interpC EmptyEnv (Lam "x" (Lam "y" (Var "x"))) $ \l ->
  case l of
    FC foo ->
      interpC EmptyEnv (Num 6.0) $ \val ->
      applyClosure foo val id
    _      -> error "applied non-function value"
== cont is applied
\l ->
  case l of
    FC foo ->
      interpC EmptyEnv (Num 6.0) $ \val ->
      applyClosure foo val id
    _      -> error "applied non-function value" $ 
FC (makeClosure "x" (Lam "y" (Var "x")) EmptyEnv)
==
case FC (Closure { name: "x", body: (Lam "y" (Var "x")), env: EmptyEnv}) of
    FC foo ->
      interpC EmptyEnv (Num 6.0) $ \val ->
      applyClosure foo val id
    _      -> error "applied non-function value"
==
interpC EmptyEnv (Num 6.0) $ \val ->
applyClosure (Closure { name: "x", body: (Lam "y" (Var "x")), env: EmptyEnv}) val id
==
\val ->
  applyClosure (Closure { name: "x", body: (Lam "y" (Var "x")), env: EmptyEnv}) val id $
NC 6.0
==
applyClosure (Closure { name: "x", body: (Lam "y" (Var "x")), env: EmptyEnv}) (NC 6.0) id
==
interpC (extend "x" (NC 6.0) EmptyEnv) (Lam "y" (Var "x")) id
== 
id $ FC (makeClosure "y" (Var "x") (Ext { name: "x", val: (NC 6.0) } EmptyEnv))
==
FC (makeClosure "y" (Var "x") (Ext { name: "x", val: (NC 6.0) } EmptyEnv))
```

# Exercises:

### i. CPS Basic Functions

* Define `map` using CPS and derive its type.
{% repl_only mapCPS#map f Nil return    =
  return Nil
map f (x:xs) return =
  f x $ \x' ->
  map f xs $ \xs' ->
  return $ x':xs'%}
* Define `filter` using CPS and derive its type.
* Define `foldList` using CPS and derive its type.
{% repl_only foldList#foldList base build Nil return = 
    undefined
foldList base build (x:xs) return =
    undefined%}


### ii. Bonus: A State Machine

{%pagination chapter2#%}
