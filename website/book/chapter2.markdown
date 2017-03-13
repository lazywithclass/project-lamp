---
layout: page
title: Chapter 2 - Little Languages
permalink: /chapter2/
custom_js:
- jquery.min
- ace.min
- mode-haskell.min
- bundle
- index
---
In this chapter, we incorporate the concepts we studied in the previous chapter to introduce the simplicity and benefit of writing *interpreters* in functional languages.

### 1. The Big Picture
The idea of interpreting is generally used in the context of translating one spoken language into another. As a computer program, an *interpreter* is essentially a program that translates one respresentation of data into another. Thus, before we can write an interpreter, we have to properly classify *what* kind of data representation we're interpreting and *how* to re-represent it.

#### a. We're Not in PureScript Anymore -- Representing the λ-calculus

In the first chapter, we briefly went over the fundamental concepts of the λ-calculus. We now have the opportunity to go quite a bit more in depth into details of the calculus and explain what the calculus is actually designed to do. An effective way of doing this is to develop an interpreter for the λ-calculus! This not only gives us the experience of actually writing an interpreter but also a more holistic understanding of the λ-calculus itself. 

As we mentioned earlier in this chapter, to write an interpreter, we must first classify the kind of data we're trying to interpret. Here, we have a few choices:

1. Use a `String` to represent all λ-calculus expressions.
2. Use our own *data type* to define distinct λ-calculus expressions.

There are benefits and pitfalls in *both* methods of representing data. Since PureScript features a powerful type system and pattern matching, we would benefit more from choosing option `(2)`. The main pitfall of choosing option `(1)` is that individual `String` elements cannot be distinguished from each other in a type system--a `String` is *just* a `String`. This also has the unfortunate side-effect of disallowing the use of pattern matching. We can, however, start with representation `(1)`, then create a sort of *intermediary* interpreter (i.e., a *tokenizer*) to translate `String`s into a more convenient form of data (like `(2)`). For the sake of time, we opt to simply start with representation `(2)`.

Representing the λ-calculus in terms of a PureScript data type is quite simple since the λ-calculus is comprised only of three expressions:
```haskell
-- `type` is used for aliasing names
type Name = String

data Term = Var Name
          | Lam Name Term
          | App Term Term
```
Believe it or not, despite its simplicity, the λ-calculus is a *Turing-complete* language. This is a fancy way of saying that the given language can encode *every* possible computation one should ever want to do. Should the reader desire to discover more on *how* the λ-calculus is Turing-complete, we refer them to myriad of historical sources and proofs concerned with it.

For our purposes, we opt to provide extensions to the calculus with more familiar language expressions to perform more complex expressions, namely *conditional branches*, some arithmetic expressions and numbers. This, however, is not necessary since the language can already encode the extensions we include (albeit in a significantly more complex way). This brings us to the data representation of the λ-calculus that we will use for the remainder of this chapter:
{% basic_hidden calculus#instance showTerm :: Show Term where
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
#type Name = String

data Term = Num Number        -- numbers
          | Sub Term Term     -- subtraction
          | Mul Term Term     -- multiplication
          | IsZero Term       -- zero predicate
          | If Term Term Term -- if branch
          | Var Name
          | Lam Name Term
          | App Term Term%}
		  
We have now successfully implemented an appropriate representation of the (extended) λ-calculus inside of PureScript. Before we can proceed to implementing the full interpreter, we must first determine the representation of our target language and as well as a few fundamental components of every interpreter.

#### b. No Hacks Required -- Values and Environments

A simple way to determine the representation of our target language is to determine what kinds of *values* our language should be able to encode. This is synonymous with determining the first-class values of a given language. Since our little language encodes arithmetic and conditional branching computations, we would naturally need the appropriate values that result from these computations: `Number`s and `Boolean`s. It is, however, a good idea, from what we've already seen in Chapter 1, to include *functions* as first-class values in a language. Thus, we can represent our target language as a small data type for `Value`s, with constructors for `Number`s, `Boolean`s, and functions:
{% basic_hidden values#instance showValue :: Show Value where
  show (N x) = "N " <> show x-- .n
  show (B x) = "B " <> show x-- .b
  show (F _) = "Function"#data Value = N Number
           | B Boolean
           | F (Value -> Value)%}

**Aside**: We *must* wrap our target language's values in term-constructors. This is so we can have our interpreter return into the `Value` type and treat every all three of the above expressions equally as `Value`s.

**NOTE**: The type of every function is represented with an *arrow-type* (viz. `->`) between two other types. Since our interpreter returns `Value`s, the functions in our language should naturally be of type `Value -> Value`, since they are meant to interact with `Value`s internal to the language and are *also* `Value`s themselves.

We now have all the data types necessary to write an interpreter! Actually writing an interpreter, however, requires one extra piece of knowledge. To thoroughly introduce this new concept, we will write a few simple functions to enable an interpreter to interact seamlessly with what is known as an *environment*.

To put it simply, an *environment* is a mapping of `Name`s to `Value`s. When we say *mapping*, this is synonmous to *any* `List`-like data structure, however, this structure is more similar to a *dictionary* where we can provide `Name`s and (possibly) obtain a `Value` (basically a `JSON`). This leads us to the following data type for `Env`s:

{% basic_hidden envdef#instance showEnv :: Show a => Show (Env a) where
  show env = show' env Nil where
    show' EmptyEnv Nil    = "{}"
    show' EmptyEnv _      = "}"
    show' (Ext e env) Nil =
      "{" <> e.name <> ": (" <>
      show e.val <> ")" <>
      show' env (0:Nil)
    show' (Ext e env) x =
      ", " <> e.name <> ": (" <>
      show e.val <> ")" <>
      show' env x#data Env a = EmptyEnv
           | Ext { name :: Name, val :: a } (Env a)%}

Here, we implement the `Env` type using PureScript's *record syntax*. The expressions contained within curly braces, `{}`, are known as a record. One can access the elements of a record using dot-notation.

If one recalls the β-reduction example in Chapter 1, we mentioned that with every function application, a function's namespace grows. This namespace *is* an environment of sorts. The job of the environment is to keep track of the names associated with values in a computation, which is extended whenever a function is applied to a `Value`. Naturally, we would want to then define a function that looks up the values contained within a given environment. We'll call this function `lookUp`.

Before we provide the implementation of `lookUp`, let's take the time to discuss its type and as well as what should happen in the event that we attempt to look up an unbound variable:

1. `lookUp` looks up `Name`s in an arbitrary `Env`.
2. In the event that the given `Name` is **not** contained, `lookUp` should raise some sort of an `unbound error`.
3. In the event that the given `Name` is contained within the `Env`, `lookUp` should return its associated `Value`.

Since the rest of this chapter is focused on extending a basic interpreter into more complex interpreters, we abstract the return value of `lookUp` to be an `a`, an unspecified type of `Value`. This is also a good idea since `Env` is parameterized over an `a` as well and not a particular form of `Value`. We now know that `lookUp` is parameterized over a `Name` and an `Env`, thus its type should be:
```haskell
lookUp :: forall a. Env a -> Name -> a
```
Next, for `(2)`, we need to signal some sort of error in the event that `lookUp` is passed a `Name` that is not contained with the provided `Env`. Since we are iterating over a `List`-like structure, we *only* know when a given variable is unbound in the event that we reach the *end* of the environment (i.e., when the `Env` is `EmptyEnv`), which gives us the first line of `lookUp`:
```haskell
lookUp EmptyEnv n = error $ "unbound variable: " <> n
```
Here, `error` takes a `String` representing an error and `<>` is an appending function for composable data structures (i.e., `List`s, `String`s, etc.).

For `(3)`, we simply keep iterating over the `Env`, looking for the `Name` passed to `lookUp`. In the event that we find it, we return the associated `Value`. Otherwise, we keep looking on the *rest* of the `Env`. For brevity, we can do this using PureScript's `guard` syntax:
```haskell
lookUp (Ext e env) n | n == e.name = e.val
                     | otherwise   = lookUp env n
```
We then come up with the final definition for `lookUp`, which we include below with some examples of `Env`s and an `extend` function for extending `Env`s:
{% repl_only lookup#lookUp :: forall a. Env a -> Name -> a
lookUp EmptyEnv n = error $ "unbound variable: " <> show n
lookUp (Ext e env) n | n == e.name = e.val
                     | otherwise   = lookUp env n

extend :: forall a. Name -> a -> Env a -> Env a
extend n v = Ext { name : n, val : v }

env1 :: Env Value
env1 = extend "x" (N 5.0) EmptyEnv

env2 :: Env Value
env2 = extend "y" (N 6.0) env1

env3 :: Env Value
env3 = extend "z" (B true) env2%}

**Random Question**: Evaluating `env1` through `env3` results in a rather nice (JSON-esque) representation of the given environment. However, attempting to evaluate `EmptyEnv` results in an error! Why do you think that is?

### 2. Let's Get Down to Business -- Implementation

We now have everything in place to write a basic interpreter for our language! Implementing our interpreter requires us to handle the term-constructors defined for the data definition of `Term` (i.e., a total of *Eight* cases). Let's break it up into little pieces. We'll implement this function line-by-line and in three sections:

1. `Number` value expressions
2. `Boolean` and `Branching` expressions
3. λ-calculus expressions

We also want to have our basic interpreter, `interp`, to be parameterized over an `Env` of `Value`s and a `Term` to interpret to a `Value`, which gives us the type:
```haskell
interp :: Env Value -> Term -> Value
```
Let's begin!

#### a. Number Valued Expressions
Our language features `Number` expressions and the ability to `Sub` and `Mul`. In the `Term` data definition, these expressions are:
```haskell
Num Number | Sub Term Term | Mul Term Term
```
So, let's write a preliminary definition of `interp` that includes pattern match cases for the above:
```haskell
interp e (Num i)   = ?fstline
interp e (Sub x y) = ?sndline
interp e (Mul x y) = ?thdline
```
To fill in each of the above holes, we need to think about how the given `Term` expression should be translated to into a `Value`. Let's start with the hole `?fstline` that handles `(Num i)` expressions. In this case, translating a `(Num i)` into the appropriate value is simple, since `Value` includes a `(N i)` expression, where both `i`s are of type `Number`.
```haskell
interp _ (Num i) = N i
```
The next two holes require a bit of thinking. We know that *both* `Sub` and `Mul` expressions are parameterized over two `Term`s. Interpretting these two terms result in a `Value`, which should be number values (`(N i)`). Intuitively, the `Value` returned by `Sub` and `Mul` expressions should also be an `(N i)`, which we can achieve by appealing to the built-in `-` and `*` functions. This gives us the following:

1. Interpret the two `Term`s in `Sub` and `Mul` expressions.
2. Determine whether or not the resulting `Value`s have the pattern `(N i)`.
3. Use `-` or `*` appropriately on the resulting numbers. Otherwise, signal an error.

```haskell
interp e (Sub x y)   = N $ case interp e x of
  N x -> case interp e y of
    N y -> x - y
    _   -> error "arithmetic on non-number"
  _   -> error "arithmetic on non-number"
interp e (Mul x y)   = N $ case interp e x of
  N x -> case interp e y of
    N y -> x * y
    _   -> error "arithmetic on non-number"
  _   -> error "arithmetic on non-number"
```

Wow. Looks messy, but this actually works as intended! We can do better though.

Looking carefully at the above code snippet, we can see that we have the opportunity to abstract over our code and remove repetitions. To remedy this, we must do the *opposite* of β-reduction and peform an *η-expansion*.

To do this, we must first figure out where the code snippets differ. Suprisingly, the two cases only differ in using `-` and `*`! The similarities are:

1. `interp` both expressions, `x` and `y`.
2. Pattern match with the `N i` pattern on the result of `(1)`. Any other pattern, signal an error.
3. Perform `-` or `*` on the numbers resulting from `(2)`.

For `(1)` and `(2)`, we can write the function, `f`, which takes a `Term`, passes it to `interp` and pattern matches over the `N i` case:
```haskell
\e x ->
  case interp e x of
    N num -> num
    _     ->
      error "arithmetic on non-number"
```
This function is applied to both `Term`s, then passed to either `-` or `*`. To do this, we can write a function that takes a certain `f` and applies it to two expressions, then applies a certain `op` to their results, which looks like:
```haskell
\op f x y -> f x `op` f y
```
Filling in the appropriate types, we can then derive the definitions for `on` and `calcValue`:
{% basic somehelpers#on :: forall a b c.
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
      error "arithmetic on non-number"%}

This allows us to condense our implementation for the number valued expressions:
```haskell
interp _ (Num i)   = N i
interp e (Sub x y) = N (calcValue e (-) x y)
interp e (Mul x y) = N (calcValue e (*) x y)
```
#### b. Boolean and Branching Expressions
We now have to handle the `Term` expressions for:
```haskell
IsZero Term | If Term Term Term
```

These aren't too different from number valued expressions, except for the fact that `IsZero` returns a `Boolean` expression, `(B b)`, while `If` returns whatever type its branches have depending on the value of its first `Term`.

Let's start with `IsZero`. To implement its functionality, we must first interpret the `Term` passed to `IsZero`, then determine whether or not the resulting value is the value `(N 0.0)`:
```haskell
interp e (IsZero x)  =
  B $ case interp e x of
    N 0.0 -> true
    _     -> false
```

In the case of `If` expressions, we first evaluate its first `Term`, determine whether or not the value is `true` or `false`, then interpret the appropriate branch. For simplicity, we assume that all other `Value`s (e.g. `N` and `F`) are *truthy*.
```haskell
interp e (If x y z) =
  case interp e x of
    B boo | boo       -> interp e y
          | otherwise -> interp e z
    _     -> interp e y
```

#### c. λ-calculus Expressions
*Only three cases to go!!*

We have successfully implemented the majority of our language. We now return to implementing the interpretation for λ-calculus expressions. We must handle the following expressions:
```haskell
Var Name | Lam Name Term | App Term Term
```

Let's start with the simplest case: `Var`. From the definition of the `Var` expression, we see that its parameterized over a single expression, a `Name`. As with all other cases in our interpreter, we must return a `Value`. We would then need a way to convert a `Name` into the appropriate `Value`. For this, we can simply use `lookUp` to find the `Value` associated with the `Name` in `Var`:
```haskell
interp e (Var x) = lookUp e x
```
Next, we handle `Lam` expressions. `Lam` expressions are our language's representation of functions, so we need to return the appropriate function `Value`, `(F f)` where `f` is of type `Value -> Value`. Aside from this, each `Lam` expression contains a `Name` and a `Term`, which represent the formal parameter and the body of a given function. To model the proper behavior of a function, we must find the value of the body under then extended context of having associated the `Name` parameter with the `Value` that is *eventually* passed to the function. This is synonymous with creating a function that receives a `Value`, then extends the `Env` in which the given function is called with the association of the given `Name` and `Value`.
```haskell
interp e (Lam v b) =
  F $ \a -> interp (extend v a e) b
```
This makes a bit more sense after we implement how functions in our language are applied, which is handled by the `App` case. Here, we first interpret the value of the first `Term`, which *should* be a function, then apply the resulting function to the value of the second `Term`. In the event that a non-function value is applied, we signal an error.
```haskell
interp e (App l r) =
  case interp e l of
    F foo -> foo $ interp e r
    _     ->
      error $ "applied non function value"
```

*And that's all she wrote!* We have now implemented an interpreter, `interp`, for a Turing-complete programming language, `Term`. We have included the complete interpreter below and as well as a few example `Term` programs.

{% basic basicinterpreter#interp :: Env Value -> Term -> Value
interp _ (Num i)     = N i
interp e (Sub x y)   = N (calcValue e (-) x y)
interp e (Mul x y)   = N (calcValue e (*) x y)
interp e (IsZero x)  =
  B $ case interp e x of
    N 0.0 -> true
    _     -> false
interp e (If x y z) =
  case interp e x of
    B boo | boo       -> interp e y
          | otherwise -> interp e z
    _     -> interp e y
interp e (Var x)   =
  lookUp e x
interp e (Lam v b) =
  F $ \a -> interp (extend v a e) b
interp e (App l r) =
  case interp e l of
    F foo -> foo $ interp e r
    _     ->
      error $ "applied non function value"%}

The following are *combinators* that represent the `Y` and `fact` functions in the λ-calculus. `Y` is used for generating recursive functions. Try writing a few of your own by following the format used in `factComb`!

{% repl_only combinators#yComb :: Term
yComb =
  (Lam "rec"
   (App (Lam "f" (App (Var "f") (Var "f")))
    (Lam "f"
     (App (Var "rec")
      (Lam "x"
       (App (App (Var "f") (Var "f"))
        (Var "x")))))))

factComb :: Term
factComb =
  (Lam "fact"
   (Lam "num"
    (If (IsZero (Var "num"))
     (Num 1.0)
     (Mul (Var "num")
      (App (Var "fact")
       (Sub (Var "num") (Num 1.0)))))))

-- pass this to an interpretter
fact n = App (App yComb factComb) (Num n)%}

Try calculating `fact` of `20.0`, like so:
```haskell
interp EmptyEnv (fact 20.0)
```

### 3. One More Thing -- The Value of Functions
Our interpreter is working just as intended. We recommend the reader spend some time experimenting with it to see if there are any particular *oddities* about its behavior. In this section, we'll mention one of them and go over how to fix it.

#### i. One Does Not Simply Show Functions -- Function Representation
<!--
Why can't we show functions?
show how other languages do it (haskell, racket, javascript)
-->
There is a rather strange repercussion of having functions as first-class expressions in a language: we *cannot* print their values! For this example, let's bring back our friends `id` and `const` but represent them in terms of a `Term` program:
{% repl_only showfunctions#id    = Lam "x" (Var "x")
const = Lam "x" (Lam "y" (Var "x"))%}
Then try:
```haskell
interp EmptyEnv id
```

`Function`. Seems legit. The reason why `Function` is being printed is because we have no access to the elements of the function we are trying to print! The reason for this is that we've implemented function values in terms of PureScript functions.

To properly *show* function values, we need an intermediary data structure that encapsulates the individual *components* of a function.

#### ii. A Happy Medium -- Closures
<!--
The essence of a function (pieces)
interpreter goes here (little changes only)
-->
There are several important pieces to every function, two of which are made immediately clear from its data definition: a `Name` and a body, `Term`. We have already mentioned several times that a function also keeps track of its local namespace, which in the context of an interpreter is an `Env`. We can then represent a function's value as a conjunction between a `Name`, a `Term` and an `Env`, which is otherwise known as a `Closure`.

{% basic closures#newtype Closure = Closure {
  var  :: Name,
  body :: Term,
  env  :: Env ValueD
}%}

A `Closure` is the result of evaluating a function. The benefit of representing function values in this way is that we don't immediately have to appeal to the built-in functions of a given language and instead are able to evaluate them in whatever we please.

## Exercises:
For this chapter's exercises, we will translate `interp` into a new interpreter that incoprorates the `Closure` type. This requires a few changes to several functions and our definition of `Value`:

{% basic_hidden valuedef#instance showValueD :: Show ValueD where
  show (ND x) = "ND " <> show x-- .n
  show (BD x) = "BD " <> show x-- .b
  show (FD (Closure clos)) =
    "Function from " <> clos.var <>
    " returns " <> show clos.body <>
    ", with context " <> show clos.env
#data ValueD = ND Number
            | BD Boolean
            | FD Closure

calcValueD :: Env ValueD -> (Number -> Number -> Number) ->
              Term -> Term -> Number
calcValueD e op =
  on op $ \x ->
  case interpD e x of
    ND num -> num
    _      ->
      error "arithmetic on non-number"%}
Here, we have modified the definition of `Value` into a new type called `ValueD`. The only change is the names of the constructors and that the `FD` constructor is parameterized over the `Closure` type as opposd to the PureScript arrow-type. We have also modifed the definition of `calcValue` to reflect the changes in `ValueD`.

Since we are no longer using the built-in functions of PureScript, we must also specify how a `Closure` should be applied and created. The first step is to implement these functions:

{% basic clos#applyClosure :: Closure -> ValueD -> ValueD
applyClosure (Closure clos) rat = undefined

makeClosure :: Name -> Term -> Env ValueD -> Closure
makeClosure n t e = undefined%}

Correctly implementing the above should result in identical behavior for `interp` and `interpD`.

<!-- todo implement arbitrary class for Term -->

{% repl_only defuninterp#interpD :: Env ValueD -> Term -> ValueD
interpD _ (Num i)    = ND i
interpD e (Sub x y)  = ND (calcValueD e (-) x y)
interpD e (Mul x y)  = ND (calcValueD e (*) x y)
interpD e (IsZero x) =
  BD $ case interpD e x of
    ND 0.0 -> true
    _      -> false
interpD e (If x y z) =
  case interpD e x of
    BD b | b         -> interpD e y
         | otherwise -> interpD e z
    _    -> interpD e y
interpD e (Var x)   = lookUp e x
interpD e (Lam v b) = FD $ makeClosure v b e
interpD e (App l r) = case interpD e l of
  FD foo -> applyClosure foo (interpD e r)
  _      -> error "applied non function value"%}

We can now also evaluate arbitrary functions like:
```haskell
interpD EmptyEnv id
```
and obtain a more detailed answers:
```haskell
Function from x returns x, with context {}
```
