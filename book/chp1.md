---
layout: page
title: Chapter 1 - First Steps
permalink: /pl-chp1/
---
In this chapter, we introduce the foundation of all functional languages and its related concepts, we talk about types and their relationship with functional languages, and end with a discussion on the different ways that we commonly write purely functional programs.

### 1. The λ-calculus
One might be thinking *"Calculus? I thought this was about programming?"* It might come as a surprise to some, but mathematics and computer programming actually have quite a long history and continue to find themselves intertwined as time goes on. One can easily find themselves lost in the history and the theory of it all, but that's not the purpose of this book. We introduce the λ-calculus solely for the reason that it is the foundation of all functional languages.

#### a. Three's Company -- Foundations
The λ-calculus can be thought of as a simple programming language made up of three components: variables, functions, and function application. In many functional languages, the λ-calculus is used at the fundamental level (e.g. function representation and function application) but some of them use it for many other interesting things, which is a testament to how flexible the calculus truly is.

How about a few examples?
```haskell
-- these are variables
x = 5
y = 6

-- this is a function
foo1 = \x -> x

-- this is also a function
foo2 f x y = f x

-- function application
app1 = foo1 x
app2 = foo2 foo1 y x
```
In functional languages, one is free to assign values (i.e., Integers, Booleans, etc.) to variables. As is the case in PureScript and Haskell, variables (including function names) are required to begin with a *lower-case* letter. It is, however, impossible to *re-assign* new values to variables (i.e., we cannot re-associate `x` with another value once it has already been associated; it's always `5`).

A key feature in functional languages is the appearance of functions as *first-class* values. This simply means that one can do with functions as one can do with normal values, as is the case with `foo1`, which itself is a variable associated with the value `(\x -> x)`, an example of an *anonymous function*. Having functions first-class allows one to pass functions as arguments to other functions (as is the case in `foo2`'s first argument, `f`). As we see later on in this chapter, this allows a considerable amount of flexibility in writing our code.

Finally, functions are applied using *juxtaposition*, or simply placing the function beside its arguments. An interesting part of function application in similar functional languages is that we can use *partial function application*. That is, the expression `(foo2 foo1)` is just as valid as `(foo2 foo1 y)`, etc., all of which are also considered first-class values! Imagine the possibilities.

#### b. The Fine Print -- β-reduction

Another thing to note about functions is that they have what is known as a *local namespace*. This means that names contained within functions (i.e, the names of their parameters) are different from those defined outside of the function. In the above examples, we have defined `x` and `y` to hold the value `5` and `6`, respectively. We then later pass these names through function application into `foo1` and `foo2`, which themselves make reference to a certain `x` and `y`. It might then come as a surprise that the value that `app2` results in is `6` and not `5`! The reason for this is that the `x` and `y` defined outside of `foo1` and `foo2` are said to be defined *globally*, while the `x` and `y` in the definition of `foo1` and `foo2` are defined *locally* and are thus different from one another.

To make this concept a bit clearer, it might help to see how `app2` comes up with its answer. In the λ-calculus, this is done through what is known as *β-reduction*. The name *reduction* seems a bit off-putting, since each step in a *β-reduction* is essentially an expansion of expressions into their respective values. This is where a language like PureScript becomes rather helpful, since the act of reducing is simply taking an expression from the left hand side of an `=` sign to the value on the right. Another thing that happens at each step is that with every function application, a function's namespace grows, where the names of its parameters are associated with the values passed in their place. We represent this *namespace growth* as the expression contained within curly braces, `{}`, placed beside the given function being applied. Once all of a function's parameters have their associated value, all occurances of names inside of its body (i.e., the expression after the `->`) are replaced with the respective values mapped inside of its namespace. This continues until there is no other possible reduction. In a later chapter, we show how to simulate this step-by-step calculation inside of PureScript itself!

For now, let's see β-reduction in action!
```
app2 
=(a)= foo2 foo1 y x
=(a)= (\f x y -> f x) foo1 y x
=(a)= (\f x y -> f x) (\x -> x) 6 5
=(b)= ((\f x y -> f x){}) (\x -> x) 6 5
=(c)= ((\x y -> f x){f : (\x -> x)}) 6 5
=(c)= ((\y -> f x){f : (\x -> x), x : 6}) 5
=(c)= ((f x){f : (\x -> x), x : 6, y : 5})
=(d)= (\x -> x) 6
=(b)= ((\x -> x){}) 6
=(c)= (x{x : 6})
=(d)= 6
```

The further iterate, we also annotate each line of the above reduction with one of the corresponding reduction rules:
```
a. Expression to Value
b. Start of Function Application 
c. Namespace Expansion
d. Namespace Reference
```
An added benefit of understanding β-reduction is that every reduction can be thought of as an *equivalence*. That is, `app2` is β-equivalent to `(foo2 foo1 y x)` and so on, even all the way down to the final value, `6`. This is only true because of a feature of purely functional languages called *referential transparency*. This simply means that a function, given a value (i.e., a context), will **always** return the same value under that same context, giving the programmer of a functional language the ability to reason about the equality of program *expressions* without even having to execute any code. Doing so is called *equational reasoning*, an example of which is included in this chapter's exercises!

<!-- The λ-calculus is a simple programming language made up of only 3 components: variables, abstractions and applications. We can succintly represent every expression in the language (i.e., λ-expression, Λ), by way of a *grammar*: -->
<!-- ``` -->
<!-- Λ = x | λx . Λ | Λ Λ -->
<!-- ``` -->
<!-- In general, grammars are defined *recursively* but don't necessarily have to be. The grammar for λ-calculus (above) is defined recursively to reflect that λ-expressions can be composed with other λ-expressions. In PureScript, we can define the grammar for the λ-calculus in the following way: -->
<!-- ```haskell -->
<!-- data Lam = Var String -->
<!--          | Abs String Lam -->
<!--          | Lam Lam -->
<!-- ``` -->
<!-- In languages like PureScript, representing a language in such way also defines what is known as a *data type* and allows us to manipulate expressions as data. For example, let's define the *identity function* of the λ-calculus as an expression of our grammar: -->
<!-- ```haskell -->
<!-- identity = Abs "x" (Var "x") -->
<!-- ``` -->
<!-- Of course, since PureScript is already founded on the λ-calculus, we can define the identity function using PureScript's own representation, which is: -->
<!-- ```haskell -->
<!-- id = \x -> x -->
<!-- ``` -->
<!-- The benefit of defining a language using our own defined data type is that we are not constrained in the manner of using our language. We take advantage of this benefit in a later chapter ([Chapter 3]()). -->

<!-- The phrase *Turing-complete* is just a fancy way of describing a language that can encode *every possible computation*, which makes the λ-calculus the perfect foundation for a programming language. -->

### 2. Types in Programming Languages
Many programming languages, functional or otherwise, feature entities that are known as *types*. The more familiar types, such as `Int`, `Boolean` and `String`, are found in virtually every programming language and contain (or, in math lingo, are *inhabited*) by values like `42`, `true` and `"apple"`, respectively. In some functional languages, however, types play a more intimate and important role, giving them certain *benefits* and *abilities* over others. In this chapter, we introduce the basics about types in purely functional languages and as well as a few key concepts about them that every functional programmer should be aware of.

<!-- In a sense, types go hand-in-hand with functional languages like peanut butter goes with jelly (or whatever one likes with their peanut butter sandwich). -->

#### a. Everyone gets a Type! -- Inhabitance
In a statically typed language, one has *values*, and one has *types*. The two are related in a rather simple way: *every value has a type*. For the purposes of this chapter, we need not go any further than this statement (which is an aside to the reader that there is indeed more to it than that).

Alas, the benefit of having this constraint is that everything one chooses to write inside of a typed programming language *must* have a corresponding type, and, indeed, that type must be the *correct* one. If, for example, a programmer mistakenly causes an expression to be typed incorrectly, the program fails to run, and the programmer receives a *type error* from the language's *type checker*. One might have seen a few of these while trying to solve the exercises in the introduction of this book.

But never fear! Type errors are here to help. It might seem difficult at first, and it might seem that one has to (painfully) wrestle with the type system to get *any* program working at all! However, the type system is actually here to help the programmer correctly specify what they want their program to do and know precisely what needs to happen to ammend something done incorrectly. One not need look any further than JavaScript to see how helpful type errors are (see **undefined errors**).

Let's see a few examples! **Note:** these are wrong on purpose.
```haskell
wrong :: Int -> Boolean -> Int
wrong i b = b

meaningOfLife :: Int
meaningOfLife = wrong false 42
```
When one is presented with type errors, there usually isn't one set way to fix everything. In our simple example above, we can actually do one of several fixes to relieve ourselves of the type error. In general, one can safely use the information provided by the type error to fix type errors, proactively fixing individual errors until one's program finally loads, which is precisely what we do below.

The first of these is to fix the type error of `wrong`, which *should* be a function that takes an `Int` and a `Boolean` and returns an `Int`. Intuitively, it would make sense to return the `Int` passed to the function (viz. the `i` parameter) instead of returning `b`, the `Boolean`, which is how the function is incorrectly defined above. After fixing this mistake, we still have another type error inside of `meaningOfLife`. This mistake is a little bit sneakier than the one prior to it, since we have to inspect the internal definition of `meaningOfLife`. Upon closer inspection, it appears that we have simply misused `wrong` and mixed up the order of its arguments!

There are many more mistakes that trigger type errors, some more complex than others. It is, however, probably safe to say that the most common of these errors are generally associated with *incorrectly using/defining functions* (as is the case with the example above).

#### b. Just What I Needed -- User Defined Types
<!-- TODO:
Pattern matching
deriving

-->

It would be a bit silly to say all these great and wonderful things about the power of types in functional languages if we cannot define our own types. Fortunately, in many functional languages, we are free to do so and still reap the benefits of the powerful type system and type chcecker for our own user-defined types.

Defining our own types require that we adhere to a simple set of rules. To make this immediately clear, we'll define the type of `Point`:
```haskell
data Point = Point Number Number
```
That is, a `Point` is a type with one *type-constructor* (also called `Point`), which is a function that takes two `Number`s, respresnting the `x` and `y` values of a given point on an x-y axis. Here, unlike variables, the names of types and type constructors must start with an *upper-case* letter. As a liberty to the programmer, PureScript allows type-constructors to use the same name as the type that they are defined for only when the given type is designed to have only *one* constructor (this practice is called constructor *punning*). That is, in the event that a type requires more than one constructor, each constructor requires a unique name to properly differentiate it from the other ways of constructing the given type.

This is latest statement is due to the fact that type-constructors are considered a special kind of value. Unlike normal values (e.g. numbers), type-constructors can be *pattern matched*, which allows for an elegant way of defining functions over some given types. As an example, let's define a type for `IntList`, the type inhabited by lists of Integers, then define a function `isEmpty` that determines whether or not a given `IntList` contains no elements or not.

First, the definition of `IntList`:
```haskell
data IntList = Empty
             | Push Int IntList
```
Here, unlike `Point`, `IntList` requires two constructors: `Empty` and `Push`. These constructors represent the two ways in which to construct an `IntList` (i.e., an *empty* one or a way to add individually add `Int` elements to another `IntList`). This is a common way of defining *linked-list*-like structures in functional languages. For example, here a few `IntList`s:
```haskell
emp :: IntList
emp = Empty

ls1 :: IntList
ls1 = Push 2 emp

ls2 :: IntList
ls2 = Push 1 ls1
```
Now, let's define `isEmpty`. With the power of pattern matching, writing this function becomes rather intuitive, since we can simply match over the possible values (as determined by the definition) of `IntList` to determine whether or not the given list is empty (i.e., `Empty`) or not. We don't need any special conditional expressions at all!
```haskell
isEmpty :: IntList -> Boolean
isEmpty Empty       = true
isEmpty (Push i is) = false
```
Up until now, we haven't mentioned the pecuilarities of the `Boolean` type in PureScript. That is, the values of `true` and `false` *should* start with a capital letters (just as they do in Haskell) since they are actually both type-constructors for the `Boolean` type. In the case of PureScript, however, these two entitites appear lower-cased solely because this is how they appear in JavaScript.

**Random Question**: What happens when we pattern match over a constructor that doesn't belong to the type that we are defining our function over? Say, for example, we add the following case to `isEmpty`:
```haskell
isEmpty false = false
```
#### c. The Lord of the Foos -- Polymorphism

### 3. Recursion and its Principles

#### a. Over, and Over, and Over, and Over...
#### b. The Essence of Recursion -- Fold

### Exercises:
<!-- TODO:

append-reverse
define shapes, write a function
left and right folds

-->
#### Equational Reasoning
Consider the following definitions of `append` and `rev`.

```haskell
append :: forall a. List a -> List a -> List a
append Nil ys    = ys
append (x:xs) ys = x:(append xs ys)

rev :: forall a. List a -> List a
rev Nil    = Nil
rev (x:xs) = append (rev xs) (singleton x)
```

This implementation of `rev` (reverses a list) works quite well for smaller sized lists. However, on larger lists, its performance suffers quite a bit, due to the fact that it also calls another recursively defined function, `append`.

We can improve its performance using *equational reasoning*, as described in the first section of this chapter, to remove the dependency of `rev` on `append`. We can do this by implementing another function that specializes the *appending* job that is done in `rev`. We'll call this function `appendRev` and use it to define `fastRev`.

We'll start by using this preliminary definition of `appendRev`:
<!-- NOTE: DO NOT MAKE THIS CODE INTERACTABLE! -->
```
appendRev :: forall a. List a -> List a -> List a
appendRev xs ys = append (rev xs) ys
```
Then, using the results of `(1)` and `(2)`, define a new version that no longer uses `append`.
```haskell
appendRev :: forall a. List a -> List a -> List a
appendRev Nil ys    = undefined -- (1) goes here
appendRev (x:xs) ys = undefined -- (2) goes here
```

1. Using β-reduction, calculate `appendRev [] ys`.
2. In the same way as `(1)`, calculate `appendRev (x:xs) ys`.

*Voila!* The following function, `fastRev`, should now be significantly faster than `rev`! **Magical**.
```haskell
fastRev :: forall a. List a -> List a
fastRev xs = appendRev xs Nil
```

#### Defining Shapes and Shape Functions
#### Recursion Principles
