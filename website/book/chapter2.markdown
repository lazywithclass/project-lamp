---
layout: page
title: Chapter 2 - Little Languages w/ Style
permalink: /chapter2/
custom_js:
- jquery.min
- ace.min
- mode-haskell.min
- bundle
- index
---
In this chapter, we incorporate the concepts we studied in the previous chapter to introduce the simplicity and benefit of writing *interpreters* in functional languages.

<!-- In the previous chapter, we introduced the foundation of functional languages, a few key concepts on types, and the basis of writing recursive programs in functional languages. In this chapter, we take a bit of all three concepts and introduce the simplicity of writing *interpreters* in functional languages. -->

### 1. The Big Picture
The idea of interpreting is generally used in the context of translating one spoken language into another. On the other hand, as a computer program, an *interpreter* is essentially a program that translates one respresentation of data into another. Thus, before we can write an interpreter, we have to properly classify *what* kind of data representation we're interpreting and *how* to re-represent it in another.

#### a. We're Not in PureScript Anymore -- Representing the λ-calculus
<!--
Thank you Alonzo Church
Turing complete
-->

In the first chapter, we briefly went over the fundamental concepts of the λ-calculus. We now have the opportunity to go quite a bit more in depth into details of the calculus and explain what the calculus is actually designed to do. An effective way of doing this is to develop an interpreter for the λ-calculus! This not only gives us the experience of actually writing an interpreter but also a more holistic understanding of the λ-calculus itself. 

As we mentioned earlier in this chapter, to write an interpreter, we must first classify the kind of data we're trying to interpret. Here, we have a few choices:

1. Use a `String` to represent all λ-calculus expressions.
2. Use our own *data type* to define distinct λ-calculus expressions.

There are benefits and pitfalls in *both* methods of representing data. Since PureScript features a powerful type system and pattern matching, we would benefit more from choosing option `(2)`. The main pitfall of choosing option `(1)` is that individual `String` elements cannot be distinguished from each other in a type system--a `String` is *just* a `String`. This also has the unfortunate side-effect of disallowing the use of pattern matching. We can, however, start with representation `(1)`, then create a sort of *intermediary* interpreter (i.e., a *tokenizer*) to translate `String`s into a more convenient form of data (like `(2)`). For the sake of time, we opt to simply start with representation `(2)`.

Representing the λ-calculus in terms of a PureScript data type is quite simple since the λ-calculus is comprised only of three expressions:
```haskell
type Name = String

data Term = Var Name
          | Lam Name Term
          | App Term Term
```
Believe it or not, despite its simplicity, the λ-calculus is a *Turing-complete* language. This is a fancy way of saying that the given language can encode *every* possible computation one should ever want to do. Should the reader desire to discover more on *how* the λ-calculus is Turing-complete, we refer them to myriad of historical sources and proofs concerned with it.

For our purposes, we opt to provide extensions to the calculus with more familiar language expressions to perform more complex expressions, namely *conditional branches*, some arithmetic expressions and numbers. This, however, is not necessary since the language can already encode the extensions we include (albeit in a significantly more complex way). This brings us to the data representation of the λ-calculus that we will use for the remainder of this chapter:
{% basic_hidden calculus#instance showTerm :: Show Term where
  show (Num n)    = show n
  show (Sub x y)  = "(" <> show x <> " - " <> show y <> ")"
  show (Mul x y)  = "(" <> show x <> " * " <> show y <> ")"
  show (Equ x y)  = "(" <> show x <> " == " <> show y <> ")"
  show (If x y z) =
    "If " <> show x <>
    " then " <> show y <>
    " else " <> show z
  show (Var n)     = n
  show (Lam n x)   =
    "(λ(" <> n <> ") . " <> show x <> ")"
  show (App x y)   =
    "(" <> show x <> " " <> show y <> ")"#-- `type` is used for aliasing names
type Name = String

data Term = Num Number        -- numbers
          | Sub Term Term     -- subtraction
          | Mul Term Term     -- multiplication
          | Equ Term Term     -- equality
          | If Term Term Term -- if branch
          | Var Name
          | Lam Name Term
          | App Term Term%}
		  
We have now successfully implemented an appropriate representation of the (extended) λ-calculus inside of PureScript. Before we can proceed to implementing the full interpreter, we must first determine the representation of our target language and as well as a few fundamental components of every interpreter.

#### b. No Hacks Required -- Values and Environments
<!--
obviously
interpreter goes here
show what it can do (factorial)
-->
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
      "{" <> e.name <> ": " <>
      show e.val <>
      show' env (0:Nil)
    show' (Ext e env) x =
      ", " <> e.name <> ": " <>
      show e.val <>
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

### 2. Show Me the Data

#### a. One Does Not Simply Show Functions -- Function Representation
<!--
Why can't we show functions?
show how other languages do it (haskell, racket, javascript)
-->
#### b. A Happy Medium -- Closures
<!--
The essence of a function (pieces)
interpreter goes here (little changes only)
-->

### 3. Continuing with Interpreters

#### a. One Step at a Time -- Continuation Passing Style
<!-- 
What is a continuation
Convert a few basic function
-->
#### b. If You Squint Your Eyes -- Tail Calls
<!--
calling in tail position
graze on what writing in this way looks like
interpreter goes here
-->
