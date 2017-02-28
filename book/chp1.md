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
In functional languages, one is free to assign values (i.e., Integers, Booleans, etc.) to variables. As is the case in PureScript and Haskell, variables (including function names) are constrained by *lower-case* names. It is, however, impossible to *re-assign* new values to variables (i.e., we cannot re-associate `x` with another value once it has already been associated; it's always `5`).

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

### 2. What is this about Types and Programming Languages?
Many programming languages, functional or otherwise, feature entities that are known as *types*. The more familiar types, such as `Int`, `Boolean` and `String`, are found in virtually every programming language and contain (or, in math lingo, are *inhabited*) by values like `42`, `true` and `"apple"`, respectively. In some functional languages, however, types play a more intimate and important role, giving them certain *benefits* and *abilities* over others. In this chapter, we introduce the basics about types in purely functional languages and as well as a few key concepts about them that every functional programmer should be aware of.

<!-- In a sense, types go hand-in-hand with functional languages like peanut butter goes with jelly (or whatever one likes with their peanut butter sandwich). -->

#### a. Everyone gets a Type! -- Inhabitance
In a statically typed language, one has *values*, and one has *types*. The two are related in a rather simple way: *every value has a type*. For the purposes of this book, we need not go any further than this statement (which is an aside to the reader that there is indeed more to it than that).

Alas, the benefit of having this constraint is that everything one chooses to write inside of a typed programming language *must* have a corresponding type, and, indeed, that type must be the *correct* one. If, for example, a programmer mistakenly cause an expression to be typed incorrectly, the program fails to run, and the programmer receives a *type error* from the languages *type checker*. One might have seen a few of these while trying to solve the exercises in the introduction of this book.

But never fear! Type errors are here to help. It might seem difficult at first, and it might seem that one has to (painfully) wrestle with the type system to get *any* program working at all! However, the type system is actually here to help the programmer correctly specify what they want their program to do and know precisely what needs to happen to ammend something done incorrectly. One not need look any further than JavaScript to see how helpful type errors are (see **undefined errors**).

Let's see a few examples! **Note:** these are wrong on purpose.
```haskell
wrong :: Int -> Boolean -> Int
wrong i b = b

meaningOfLife :: Int
meaningOfLife = wrong false 42
```
There are many more mistakes that trigger type errors, however, it is probably safe to say that the most common of these errors are generally associated with *incorrectly using/defining functions* (as is the case with the above).

#### b. Just What I Needed -- User Defined Types
<!-- TODO:
Pattern matching
deriving

-->
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
