---
layout: page
title: Chapter 2 - Little Languages
permalink: /chapter2/
custom_js:
- jquery.min
- anchor.min
- ace.min
- mode-haskell.min
- bundle
- index
---
In this chapter, we implement a basic interpreter in PureScript for a small programming language. This helps expand on the concepts we covered in the previous chapter while also providing a substantial example of writing code in functional languages.

### 1. The Big Picture
The idea of interpreting is generally used in the context of translating one spoken language into another. As a computer program, an *interpreter* is a program that translates one data respresentation into another. Before we can write an interpreter, we must first classify our data representation and determine *how* to re-represent it.

#### a. We're Not in PureScript Anymore -- Representing the λ-calculus

In the first chapter, we briefly went over the fundamental concepts of the λ-calculus. We now have the opportunity to go quite a bit more in depth into details of the calculus and show off what the calculus is designed to do. An effective way of doing this is to develop an interpreter for the untyped λ-calculus, which not only gives us the experience of actually writing an interpreter but also a more holistic understanding of the λ-calculus itself. 

As we mentioned earlier in this chapter, to write an interpreter, we must first classify the kind of data we're trying to interpret. Here, we have a few choices:

1. Use a `String` to represent all λ-calculus expressions.
2. Use our own *data type* to define distinct λ-calculus expressions.

There are benefits and pitfalls in *both* methods of representing data. Since PureScript features a powerful type system and pattern matching, we would benefit more from choosing option `(2)`. The main pitfall of choosing option `(1)` is that individual `String` elements cannot be distinguished from each other in a type system--a `String` is *just* a `String`. We can, however, start with representation `(1)`, then create a sort of *intermediary* interpreter (i.e., a *tokenizer*) to translate `String`s into a more convenient form of data, like `(2)`. For the sake of time, however, we opt to start with representation `(2)`.

To represent the λ-calculus in PureScript, we use a data type definition. Representing the λ-calculus in terms of a PureScript data type is quite simple since the λ-calculus is comprised only of three expressions:
```haskell
-- `type` is used for aliasing names
type Name = String

data Term = Var Name
          | Lam Name Term
          | App Term Term
```
**Aside:** Believe it or not, despite its simplicity, the λ-calculus is a *Turing-complete* language. This is a fancy way of saying that the given language can encode *every* possible computation one should ever want to do. Should the reader desire to discover more on *how* the λ-calculus is Turing-complete, we refer them to myriad of historical sources and proofs concerned with it.

On top of the three base constructors for the λ-calculus, we opt to provide several extensions which represent some other basic computations, namely *conditional branches*, arithmetic and numbers. This brings us to the data representation of the λ-calculus that we use for the remainder of this chapter:
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
		  
We have now successfully implemented an appropriate representation of the (extended) λ-calculus inside of PureScript. The next step is to specify our *target language* or the data representation we are interpreting into.

#### b. There's a Data Type For That -- Representing Values

We determine the representation of our target language by classifying the kinds of *values* our language can return. This is synonymous with determining the first-class values of a given language. Since our little language encodes arithmetic and conditional branching computations, we would naturally need the appropriate values that result from these computations: `Number`s and `Boolean`s. It is, however, a good idea, from what we've already seen in Chapter 1, to include *functions* as first-class values in a language. Thus, we can represent our target language as a small data type for `Value`s, with constructors for `Number`s, `Boolean`s, and functions:
{% basic_hidden values#instance showValue :: Show Value where
  show (N x) = "N " <> show x-- .n
  show (B x) = "B " <> show x-- .b
  show (F _) = "Function"#data Value = N Number
           | B Boolean
           | F (Value -> Value)%}

**Aside**: We *must* wrap our target language's values in term-constructors. This is so we can have our interpreter return into the `Value` type and treat all three of the above expressions equally as its return `Value`s.

**NOTE**: In PureScript, the type of every function is represented with an *arrow-type* (viz. `->`) between two other types. Since our interpreter returns `Value`s, the functions in our language should naturally be of type `Value -> Value`, since they are meant to interact with `Value`s internal to the language and are *also* `Value`s themselves. This also exposes the fact that we are implementing the value of functions in our language as PureScript functions!

We now have all the data types necessary to write an interpreter! Before we start work on implementing an interpreter, however, we must go over one extra piece of knowledge. To thoroughly introduce this new concept, we will write a few simple functions to enable our interpreter to interact seamlessly with *environments*.

#### c. My Name is Merriam-Webster -- Environments

To put it simply, an *environment* is a mapping of `Name`s to `Value`s. When we say *mapping*, this is synonmous to *any* `List`-like data structure, however, this structure is more similar to a *dictionary*, from which we can provide `Name`s and (possibly) obtain a `Value`. The job of the environment is to keep track of the names associated with values in a given computation.
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

Here, we implement the `Env` type using PureScript's *record syntax*. The expressions contained within curly braces, `{}`, are known as a record, which we use represent one entry in an environment. We can access the elements of an entry using dot-notation. To clarify this, let's write a function, `lookUp`, that searches for a given `Name` in an `Env` and returns its associated `Value`.

Before we provide the implementation of `lookUp`, let's take the time to discuss its type and what should happen in the event that we attempt to look up a `Name` not contained in the given `Env` (i.e., an unbound variable):

1. `lookUp` looks up `Name`s in an arbitrary `Env`.
2. In the event that the given `Name` is unbound, `lookUp` should raise an `unbound error`.
3. In the event that the given `Name` is contained within the `Env`, `lookUp` should return its associated `Value`.

We abstract the return value of `lookUp` to be an `a`. This is because `Env` is parameterized over an `a` and not specifically a `Value`. While constraining `lookUp` to environments of type `Env Value` is *not* wrong, we don't actually have to do any extra work to implement `lookUp` in such a way. Instead, we are able to implement a more flexible definition of `lookUp`. In addition to an `Env`, `lookUp` is parameterized over a `Name`, which means its type should be:
```haskell
lookUp :: forall a. Env a -> Name -> a
```
For `(2)`, we signal an error in the event that `lookUp` is passed an unbound `Name`. Since our `Env` data type is essentially a `List`, we *only* know when a given variable is unbound in the event that we reach the *end* of the environment, `EmptyEnv`, which gives us the first line of `lookUp`:
```haskell
lookUp EmptyEnv n = error $ "unbound variable: " <> n
```
**NOTE**: `error` takes a `String` representing an error and `<>` is an appending function for composable data structures (i.e., `List`s, `String`s, etc.).

For `(3)`, we keep iterating over the given `Env`, looking for the `Name` passed to `lookUp`. In the event that we find it, we return the associated `Value`. For brevity, we can do this using PureScript's `guard` syntax:
```haskell
lookUp (Ext e env) n | n == e.name = e.val -- record field-accessing
                     | otherwise   = lookUp env n
```
This bring us to our final definition of `lookUp`, which we include below with some examples of `Env`s and an `extend` function for extending `Env`s:
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

We now have the necessary framework to write a basic interpreter for our language! Implementing our interpreter requires us to handle every term-constructor defined for the `Term` data definition, a total of *Eight* cases. Let's break it up into little pieces. We'll implement this function line-by-line and in three sections:

1. `Number` value expressions
2. `Boolean` and `Branching` expressions
3. λ-calculus expressions

We also want to have our basic interpreter, `interp`, to be parameterized over an `Env` of `Value`s and a `Term` to interpret to a `Value`, which gives us the type:
```haskell
interp :: Env Value -> Term -> Value
```
Let's begin!

#### a. Number Valued Expressions
Our language features `Number` expressions and the ability to `Sub` and `Mul` two `Terms`. In the `Term` data definition, these expressions are:
```haskell
Num Number | Sub Term Term | Mul Term Term
```
Let's start with the simplest case. Translating a `(Num i)` into the appropriate value is simple, since `Value` includes an `(N i)` expression, where both `i`s are of type `Number`.
```haskell
interp _ (Num i) = N i
```
**NOTE**: The `_` is a wildcard pattern. It matches over *everything*. It's useful for signaling an unused parameter, which in this case is the `Env`. Since a `(Num i)` will never contain any `Name`s, an environment is not necessary for interpreting it.

Next, we have `Sub` and `Mul`. Returning to the type definition for `Term`, we know that *both* `Sub` and `Mul` expressions are parameterized over two other `Term`s. We would then need to interpret these two sub-`Term`s to obtain two `Value`s, which *should* both be number `Value`s. Intuitively, the `Value` returned by `Sub` and `Mul` expressions should also be a number `Value`. This gives us the following:

1. Interpret the two `Term`s in `Sub` and `Mul` expressions.
2. Determine whether or not the resulting `Value`s have the pattern `(N i)`, a number `Value`.
3. Use `-` or `*` appropriately on the resulting number `Value`s. Otherwise, signal an error.

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

That looks a bit messy, but this actually works as intended! With the power of functional programming, we can do better.

Looking carefully at the above code snippet, we can see that we have the opportunity to abstract over our code and remove repetitions. To remedy this, we must do the *opposite* of β-reduction and peform an *η-expansion* (pronounced *eta*).

To do this, we must first figure out where the code snippets differ. Suprisingly, the two cases only differ in using `-` and `*`! The similarities are:

1. `interp` both sub-`Term`s, `x` and `y`.
2. Pattern match with the `(N i)` pattern on the result of `(1)`. Any other pattern, signal an error.
3. Perform `-` or `*` on the number `Value`s resulting from `(2)`.

For `(1)` and `(2)`, we can write the function, `f`, which takes a `Term`, passes it to `interp` and pattern matches over the `(N i)` case:
```haskell
\e x ->
  case interp e x of
    N num -> num
    _     ->
      error "arithmetic on non-number"
```
The result of this function, `num`, is then passed to either `-` or `*`. We can then write a function that takes a certain `f`, applies it to two expressions, then applies an `op` to their results, which looks like:
```haskell
\op f x y -> f x `op` f y
```
For historial reasons, we name this function `on`. Using `on`, we determine that `f` is `interp` and `op` is either `-` or `*`. From this, we derive the definition for `calcValue`:
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

This allows us to significanlty condense our implementation:
```haskell
interp _ (Num i)   = N i
interp e (Sub x y) = N (calcValue e (-) x y)
interp e (Mul x y) = N (calcValue e (*) x y)
```
#### b. Boolean and Branching Expressions
In this section, we handle the `Term` expressions for:
```haskell
IsZero Term | If Term Term Term
```

These aren't too different from number valued expressions, except for the fact that `IsZero` returns a `Boolean` `Value`, `(B b)`, while `If` returns a value of the type of its branches.

Let's start with `IsZero`. To implement its functionality, we first interpret the `Term` passed to `IsZero`, then determine whether or not the resulting value is the value `(N 0.0)`:
```haskell
interp e (IsZero x)  =
  B $ case interp e x of
    N 0.0 -> true
    _     -> false
```

In the case of `If` expressions, we evaluate its first `Term`, determine whether or not the value is `true` or `false`, then interpret the appropriate branch. For simplicity, we assume that all other `Value`s (e.g. `N` and `F` values) are *truthy*.
```haskell
interp e (If x y z) =
  case interp e x of
    B boo | boo       -> interp e y
          | otherwise -> interp e z
    _     -> interp e y -- every other Value is equivalent to true
```

#### c. λ-calculus Expressions
*Only three cases to go!!*

Finally, we implement interpretation for λ-calculus expressions:
```haskell
Var Name | Lam Name Term | App Term Term
```

Let's start with the simplest case: `Var`. From the definition of the `Var` expression, we see that it is parameterized over a single sub-expression, a `Name`. To convert a `Name` into a `Value`, we use `lookUp` to return the `Value` associated with given `Name`:
```haskell
interp e (Var x) = lookUp e x
```
Next, we handle `Lam` expressions. `Lam` expressions are our language's representation of functions, which we re-represent as function `Value`s, `(F f)`. Aside from this, each `Lam` expression contains a `Name` and a `Term`, which represent the formal parameter and the body of a function. To model the proper behavior of a function, we must find the value of its body under then extended context of its `Name` parameter associated with the `Value` passed to the function when it is applied. This is synonymous with creating a function that receives a `Value`, then extends the `Env` with the association of the given `Name` and `Value`.
```haskell
interp e (Lam v b) =
  F $ \a -> interp (extend v a e) b
```
This makes a bit more sense after we implement the case for function application, which is handled by the `App` case. Here, we interpret the value of the first `Term`, which *should* be a function `Value`, then apply the resulting function to the `Value` of the second `Term`. In the event that a non-function value is applied, we signal an error.
```haskell
interp e (App l r) =
  case interp e l of
    F foo -> foo $ interp e r
    _     ->
      error $ "applied non function value"
```

*And that's all she wrote!* `interp` is an interpreter for a Turing-complete programming language, `Term`. We have included the complete interpreter below and as well as a few example `Term` programs.

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

The following are *combinators* that represent the `Y` and `fact` functions in the λ-calculus. `Y` is used for generating recursive functions, since our language doesn't allow us to define self-referencing functions. Try writing a few recursive `Term` programs of your own by following the format used in `factComb`!

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
  (Lam "fact" -- the name of the function
   (Lam "num"
    (If (IsZero (Var "num"))
     (Num 1.0)
     (Mul (Var "num")
      (App (Var "fact") -- recursion
       (Sub (Var "num") (Num 1.0)))))))

fact n = App (App yComb factComb) (Num n)%}

Try calculating `fact` of `20.0`, like so:
```haskell
interp EmptyEnv (fact 20.0)
```

### 3. One More Thing -- The Value of Functions
Our completed interpreter is working as intended. Before continuing, we recommend the reader spend some time experimenting with it to see if there are any particular *oddities* about its behavior. In this section, we'll mention one of them and go over how to fix it.

#### i. One Does Not Simply Show Function Values -- Function Representation
<!--
Why can't we show functions?
show how other languages do it (haskell, racket, javascript)
-->
In many programming languages, one cannot simply `print` a function. This is because the value of a function is essentially *not* defined until it is applied and, in addition, is different depending on what input it receives. This is where using an intermediary structure to represent function values can help. 

Let's start with a few examples by bringing back our friends `id` and `const` but represented as `Term` programs:
{% repl_only showfunctions#id    = Lam "x" (Var "x")
const = Lam "x" (Lam "y" (Var "x"))%}

To get the `Value` of these functions, we pass them to `interp`:
```haskell
interp EmptyEnv id
interp EmptyEnv const
```

In both cases, we get `Function`. Seems legit. The reason for this is because once we pass `id` or `const` to `interp`, we receive a wrapped function `Value`, `(F f)`, where `f` is a PureScript function. At this point, we no longer have access to the individual components of the function, preventing us from exposing anything about the given function `Value`.

#### ii. A Happy Medium -- Closures
<!--
The essence of a function (pieces)
interpreter goes here (little changes only)
-->
There are several important pieces to every function, two of which are made immediately clear from its data definition: a `Name` and a `Term`, representing the body of the function. Aside from this, a function should also keep track of its local namespace, which in the context of an interpreter is an `Env`. Knowing this, the value of a function should be a data structure that includes a `Name`, a `Term` and an `Env`, which is otherwise known as a `Closure`.

{% basic closures#newtype Closure = Closure {
  var  :: Name,
  body :: Term,
  env  :: Env ValueD
}%}

A `Closure` is the result of evaluating a function, which we represent here as a record with three fields: `var`, `body` and `env`. The benefit of representing function values in this way is that we no longer have to rely on PureScript's built-in functions, allowing us to evaluate functions in our own way and return more a specific representation of their values.

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
Here, we have modified the definition of `Value` into a new type called `ValueD`. This changes the names of its constructors (i.e., suffixed with a `D`) and the constructor for functions, which is now parameterized over the `Closure` type. We have also modifed the definition of `calcValue` to reflect the changes in `ValueD`.

Since we are no longer using the built-in functions of PureScript, we must also specify how a `Closure` should be applied and created. The first step is to implement these functions:

{% basic clos#applyClosure :: Closure -> ValueD -> ValueD
applyClosure (Closure clos) rat = undefined

makeClosure :: Name -> Term -> Env ValueD -> Closure
makeClosure n t e = undefined%}

**HINT:** For `applyClosure`, look back at `interp` and inspect how functions are applied. For `makeClosure`, inspect how a function `Value` was created.

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
-- notice the changes made to these cases
interpD e (Lam v b) = FD $ makeClosure v b e
interpD e (App l r) = case interpD e l of
  FD foo -> applyClosure foo (interpD e r)
  _      -> error "applied non function value"%}

We can now also evaluate arbitrary functions like:
```haskell
interpD EmptyEnv id
```
and obtain more detailed answers:
```haskell
Function from x returns x, with context {}
```
