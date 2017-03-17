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
To convert `sum` to its APS equivalent, we add an accumulator parameter, update its value during the recursive step, then return it once the base case is reached.
```haskell
sum :: List Int -> Int
sum xs = sumAcc xs 0
  where
    sumAcc :: List Int -> Int -> Int
    sumAcc Nil acc    = acc
    sumAcc (x:xs) acc =
      sumAcc xs (x + acc)
```
From here, translating an APSed program to a CPSed equivalent requires that we abstract over the accumulator by replacing it with a higher-order function. In this case, `sumAcc` has two arguments, a `List Int` and an `Int`, where the second is the accumulator. Replacing this value with a higher-order function means that we have the following type for `sumCPS`:
```haskell
sumCPS :: List Int -> (... -> ...) -> Int
```
Let's complete this type declaration. We need to think about:

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

1. Since our continuation is acting as an accumulator, we must apply the continuation to our base case, `0`.
2. We must extend the continuation during the recursive case.

For `(1)`, we apply a continuation to the value `0`, the original return value of `sum`. For `(2)`, we recur normally, while treating our continuation as a form of accumulator. Here, we are **not** performing the addition to a set value like in `sumAcc` but are, instead, creating a function that performs the addition under the context of some other computation, `k`, and is eventually applied to `0` when the base case is reached. Thus, extending a continuation is synonymous with defining how `sum` *continues* with its *next* computation.
{% repl_only sumcps#sum :: List Int -> Int
sum xs = sumCPS xs id
  where
    sumCPS :: List Int -> (Int -> Int) -> Int
    sumCPS Nil k    = -- (1)
      k 0 
    sumCPS (x:xs) k = -- (2)
      sumCPS xs ((+) x >>> k)%}

To further illustrate the behavior of this CPSed function, we include a trace of the `List` and continuation value in computing `(sum (1:2:3:Nil))`:
```haskell
-- Recursive case => Continuations are extended
(1:2:3:Nil) id
(2:3:Nil) ((+) 1 >>> id)
(3:Nil) ((+) 2 >>> (+) 1 >>> id)
Nil ((+) 3 >>> (+) 2 >>> (+) 1 >>> id)
-- Base case is reached => Continuations are applied
((+) 3 >>> (+) 2 >>> (+) 1 >>> id) 0
((+) 2 >>> (+) 1 >>> id) 3
((+) 1 >>> id) 5
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
  append xs ys ((:) x >>> k)
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
  append xs ys ((:) x >>> k)
  
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

**NOTE:** Because of η-reduction, the last line of the recursive case in `rev` should be:
```haskell
append xs' (x:Nil) return
```
In this case, we η-expanded to appeal to the more familiar structure of imperative code.

## 2. CPS the Interpreter -- Implementation
*We're bringing interpreters back!*

In this section, we'll implement a CPSed interpreter by making changes to `interpD` from Chapter 2. With the complexity of an interpreter, we are able to further illustrate the power of having explicit control over the flow of program evaluation.

We'll start with a few changes in the `Closure` type and the `ValueD` Type:
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
derive instance eqValueC :: Eq ValueC
derive instance eqClosure :: Eq Closure
derive instance eqTerm :: Eq Term
derive instance eqEnvC :: Eq (Env ValueC)
makeClosure :: Name -> Term -> Env ValueC -> Closure
makeClosure n b e = Closure { name : n, body : b, env : e }
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

Then we'll implement the rest of the interpreter in the same way we did in Chapter 2:

1. Number `Value`d expressions
2. Boolean and Branching expressions
3. λ-calculus expressions

Let's begin!

### a. Number Valued Expressions
Let's recall our previous implementation for number `Value`d expressions:
```haskell
interpD _ (Num i)    = ND i
interpD e (Sub x y)  = ND (calcValueD e (-) x y)
interpD e (Mul x y)  = ND (calcValueD e (*) x y)
```
Here, we defined `calcValue` to handle the special case of `Sub` and `Mul`, which is defined as:
```haskell
on :: forall a b c.
      (b -> b -> c) -> (a -> b) ->
      a -> a -> c
on op f x y = f x `op` f y

calcValue :: Env Value -> (Number -> Number -> Number) ->
             Term -> Term -> Number
calcValue e op =
  on op $ \x ->
  case interp e x of
    N num -> num
    _     ->
      error "arithmetic on non-number"
```
`calcValue` also used the function `on` to apply the function that `interp`s to both sub-expressions of `Sub` and `Mul` and pattern matches on their `(N i)` case.

Before we CPS these functions for our new interpreter, let's take the time to reason about what happens in each of them and the order that they should occur. 

For `on`:
1. A function, `f`, is applied to both `x` and `y`.
2. An `op` function is applied to the results of `(1)`.
3. The result of `(2)` is returned.

Thus, to CPS `on`, we must first apply an `f` to an `x` and `y` *before* returning the result of applying an `op` to their results. This gives us:
```haskell
onC op f x y return =
  f x $ \x ->
  f y $ \y ->
  return $ x `op` y
```
We'll get back to properly declaring a type for `onC`. First, let's take a look at what `calcValue` does:

1. Using `on`, two `Term`s are passed to a function.
2. This function takes `Term`, passes it to `interp`, determines whether or not its `Value` represents a number.
3. If the `Value` is a number, the number is returned.
4. Otherwise, an error is raised.

This gives us:
```haskell
calcValueC e op =
  onC op $ \a return ->
  interpC e a $ \a ->
  case a of
    NC num -> return num
    _      ->
      error "arithmetic on non-number"
```
Providing the proper type for `calcValueC` is rather straightforward since its specialized to only handle certain inputs. Originally, `calcValue` takes an `Env ValueC`, an `op` function, two `Term`s and returns `Number`. In this case, however, when we properly CPS this function, it returns a `ValueC`!
```haskell
calcValueC :: Env ValueC -> (Number -> Number -> Number) ->
              Term -> Term -> (Number -> ValueC) -> ValueC
```
After we CPSed `calcValue`, we revealed that its return value depends on the result of a call to `interp`. This dicates the type of the continuation passed to `calcValue`, which consequently affects the type of the continuation in `onC`.

We held off providing the type declaration for `onC` due to its complexity. Given that `on` is polymorphic, its type declaration must provide the correct details for the context it can be used in. This is why, in general, the practice of CPSing polymorphic functions is a bit more complex than functions with concrete return types.

To properly derive the type of `onC`, let's recall its non-CPSed type declaration:
```haskell
on :: forall a b c.
      (b -> b -> c) -> (a -> b) ->
      a -> a -> c
```
From its type definition, it is clear that `on` function returns an element of type `c`. When we derive the type of CPSed functions similar to `onC`, we must do the following:

1. Add an additional polymorphic variable, representing the function's return type.
2. Every CPSed function argument inherits this return type.
3. The function's return type is changed in the same way as `(2)`.

For `(1)`, let's add the type variable `r` to represent the return type of `onC`.
```haskell
forall a b c r.
(b -> b -> c) -> (a -> b) ->
a -> a -> c
```
Then, with `(2)`, we must determine which function arguments passed to `onC` are CPSed. In this case, `onC` itself is a CPSed function and `f`, the second function argument, is also CPSed. In the context of our interpreter, since `f` includes a call to our CPSed interpreter, `interpC`, it also must be CPSed. On the other hand, `op` just calls the *non-CPSed* operations of `(*)` and `(-)`.

This means there are two functions types that need to inherit the return type `r`:
```haskell
f :: a -> b
on :: (b -> b -> c) -> (a -> b) -> a -> a -> c
```
First, let's fix the type for `f`. Since `f` originally returned a `b`, this means that its CPSed equivalent will have a continuation of type `(b -> r)` and return an `r`, which gives us its new type:
```haskell
f :: a -> (b -> r) -> r
```
Lastly, we need to change the type for the entire function. Since `on` originally returned a `c`, this means that its CPSed equivalent will have a continuation of type `(c -> r)` and return an `r`.
```haskell
onC :: forall a b c r.
       (b -> b -> c) -> (a -> (b -> r) -> r) ->
       a -> a -> (c -> r) -> r
```
This completes the definitions for `onC` and `calcValueC`:
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

We then use `calcValue` to define the following cases in our interpreter:
```haskell
interpC _ (Num i) return    =
  return $ NC i
interpC e (Sub x y) return  =
  calcValueC e (-) x y $
  return <<< NC
interpC e (Mul x y) return  =
  calcValueC e (*) x y $
  return <<< NC
```

### b. Boolean and Branching Expressions
Next, let's handle the cases for `IsZero` and `If`. In `interpD`, these cases were defined as follows:
```haskell
interpD e (IsZero x) =
  BD $ interpD e x == ND 0.0 
interpD e (If x y z) =
  case interpD e x of
    BD b | b         -> interpD e y
         | otherwise -> interpD e z
    _    -> interpD e y
```
Let's use the same strategy we employed in defining the cases for number `Value`d expressions for the above.

First, let's reason about what happens in each case:

For `IsZero`:
1. `interp` the sub-expression `x`.
2. Determine whether the result of `(1)` is the representation of the value `0`.
3. Wrap the result of `(2)` with the `Boolean` `Value` constructor.
4. The result of `(3)` is returned.

For `If`:
1. `interp` the sub-expression `x`.
2. Determine the truthiness of the result of `(1)`.
3. `interp` the appropriate sub-expression (`y` or `z`).

Which gives us the following:
```haskell
interpC e (IsZero x) return =
  interpC e x $
  return <<< BC <<< ((==) $ NC 0.0)
interpC e (If x y z) return =
  interpC e x $ \x ->
  case x of
    BC boo
      | boo       -> interpC e y return
      | otherwise -> interpC e z return
    _ -> interpC e y return
```

### c. λ-calculus Expressions
*And then there were three.*

To compare, let's recall how λ-expressions were handled by `interpD`:
```haskell
interpD e (Var n)   = lookUp e n
interpD e (Lam n b) = FD $ makeClosure n b e
interpD e (App l r) = case interpD e l of
  FD foo -> applyClosure foo (interpD e r)
  _      -> error "applied non function value"
```
Let's start with the `Var` case. Here, `lookUp` is *not* a CPSed function, so we can simply return its result.
```haskell
interpC e (Var x) return   =
  return $ lookUp e x
```
If we had CPSed `lookUp`, we would be required to first evalaute the call to `lookUp`, then return its result, which would look like this:
```haskell
lookUp e x return
```

Next, let's implement the case for `Lam` expressions. In `interpD`, we used `makeClosure` to create a `Closure`, then wrapped it in the `FD` constructor. For `interpC`, we've chosen *not* to CPS `makeClosure`, thus we simply return the result of applying `FC` to a call to `makeClosure`:
```haskell
interpC e (Lam n b) return =
  return $ FC (makeClosure n b e)
```

Lastly, let's implement the case for `App` expressions. In `interpD`, this case is a bit more complex than the cases for `Var` and `Lam`. For the `App` case, the following occurs:

1. `interp` the sub-expression `l`.
2. Determine whether the result of `(1)` is a function value or not.
3. In the event that `(1)` is a function, `interp` the sub-expression `r`. Otherwise, raise an error.
4. When `(3)` suceeds, the value of `(1)` and `(3)` are passed to `applyClosure`.

Before we can CPS the case for `App`, we need to determine whether or not `applyClosure` should be a CPSed function or not. With it is original implementation:
```haskell
applyClosure :: Closure -> ValueD -> ValueD
applyClosure (Closure clos) val =
  interpD (extend clos.name val clos.env) clos.body
```
We discover that `applyClosure` calls an `interp` function. Since our `interp` function is CPSed, `applyClosure` must also be CPSed. Luckily, this function is rather straightforward to implement. We just add a continuation parameter, then thanks to η-reduction, the new `applyClosure` looks almost exactly the same! This is because the call to `interp` in `applyClosure` is *already* a tail-call.

{% basic closfuns#applyClosure :: Closure -> ValueC -> (ValueC -> ValueC) -> ValueC
applyClosure (Closure clos) val =
  interpC (extend clos.name val clos.env) clos.body%}

We then implement the `App` case as described above:
```haskell
interpC e (App l r) return =
  interpC e l $ \l ->
  case l of
    FC foo ->
      interpC e r $ \val ->
      applyClosure foo val return
    _      -> error "applied non-function value"
```

*And that's all, folks!* We've successfully CPSed our interpreter!

{% repl_only interpC#interpC :: Env ValueC -> Term -> (ValueC -> ValueC) -> ValueC
interpC _ (Num i) return    =
  return $ NC i
interpC e (Sub x y) return  =
  calcValueC e (-) x y $
  return <<< NC
interpC e (Mul x y) return  =
  calcValueC e (*) x y $
  return <<< NC
interpC e (IsZero x) return =
  interpC e x $
  return <<< BC <<< ((==) $ NC 0.0)
interpC e (If x y z) return =
  interpC e x $ \x ->
  case x of
    BC boo
      | boo       -> interpC e y return
      | otherwise -> interpC e z return
    _ -> interpC e y return
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

One should be able to use this interpreter on every example `Term` from Chapter 2. Just remember to pass it an empty continuation in addition to its regular arguments!

We include a sample trace for evaluating the `Term`:
```haskell
(App (Lam "x" (Lam "y" (Var "x"))) (Num 6.0))
```

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
case FC (Closure {name:"x",body:(Lam "y" (Var "x")),env:EmptyEnv}) of
    FC foo ->
      interpC EmptyEnv (Num 6.0) $ \val ->
      applyClosure foo val id
    _      -> error "applied non-function value"
==
interpC EmptyEnv (Num 6.0) $ \val ->
applyClosure
  (Closure {name:"x",body:(Lam "y" (Var "x")),env:EmptyEnv})
  val id
==
\val ->
applyClosure
  (Closure {name:"x",body:(Lam "y" (Var "x")),env:EmptyEnv})
  val id $
NC 6.0
==
applyClosure
  (Closure {name:"x",body:(Lam "y" (Var "x")),env:EmptyEnv})
  (NC 6.0) id
==
interpC (extend "x" (NC 6.0) EmptyEnv) (Lam "y" (Var "x")) id
== 
id $
FC (makeClosure "y" (Var "x") (Ext {name:"x",val:(NC 6.0)} EmptyEnv))
==
FC (makeClosure "y" (Var "x") (Ext {name:"x",val:(NC 6.0)} EmptyEnv))
```

# Exercises:

* Define a CPSed `fact` function.

{% repl_only factCPS#fact :: Int -> Int
fact 0 = 1
fact n = n * fact (n - 1)

factC :: Int -> (Int -> Int) -> Int
factC 0 k = undefined
factC n k = undefined%}

* Define a CPSed `ack` function.

{% repl_only ackCPS#ack :: Int -> Int -> Int
ack 0 n = n + 1
ack m 0 = ack (m - 1) 1
ack m n = ack (m - 1) (ack m (n - 1))

ackC :: Int -> Int -> (Int -> Int) -> Int
ackC 0 n k = undefined
ackC m 0 k = undefined
ackC m n k = undefined%}

* Define a CPSed `fib` function.

{% repl_only fibCPS#fib :: Int -> Int
fib x | x == 0 || x == 1 = x
      | otherwise =
        fib (x - 2) + fib (x - 1)

fibC :: Int -> (Int -> Int) -> Int
fibC x k | x == 0 || x == 1 = undefined
         | otherwise        = undefined%}
		  
Too *easy*? How about *these*:

* Define a CPSed `map` function and derive its type.

{% repl_only mapCPS#map :: forall a b. (a -> b) -> List a -> List b
map f Nil    = Nil
map f (x:xs) = f x : map f xs 

mapC f Nil return    =
  undefined
mapC f (x:xs) return =
  undefined%}

* Define a CPSed `filter` function and derive its type.
{% repl_only filterCPS#filter :: forall a. (a -> Boolean) -> List a -> List a
filter f Nil    = Nil
filter f (x:xs) | f x       = x : filter f xs
                | otherwise = filter f xs

filterC f Nil return =
  undefined
filterC f (x:xs) return =
  undefined%}

* Define a CPSed `foldList` function and derive its type.
{% repl_only foldList#foldList :: forall a b. b -> (a -> b -> b) -> List a -> b
foldList base build Nil    = base
foldList base build (x:xs) = foldList (build x base) build xs

foldListC base build Nil return = 
    undefined
foldListC base build (x:xs) return =
    undefined%}

*Why no tests?* How about this one?
{% repl_only testCPS#testCPS :: forall a b c r.
           (a -> (b -> r) -> r) ->
           (b -> (Boolean -> r) -> r) ->
           c -> (b -> c -> (c -> r) -> r) ->
           List a -> (c -> r) -> r
testCPS foo pred base build xs return =
  mapC foo xs       $ \mapd ->
  filterC pred mapd $ \fild ->
  foldListC base build fild return%}

`testCPS` will trigger a type error if the types of `mapC`, `filterC` and `foldListC` are incorrect!

Here are some sample functions to pass to `testCPS`--feel free to add a few of your own!
{% basic samples#-- for param foo:
fibFactC a k = fibC a (\a -> factC a k)

-- for param pred:
lte120 x k = k (x <= 120)

-- for param build:
addC x y k = k (x + y)%}

Try `testCPS` with:
```haskell
testCPS fibFactC lte120 0 addC (1..5) id
```
Which does the following:
1. `factC` is mapped over the list `(1..5)`.
2. All elements greater than `120` is removed from the result of `(1)`.
3. The resulting list from `(2)` is summed.

{%pagination chapter2#%}
