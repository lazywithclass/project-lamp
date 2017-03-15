---
layout: default
permalink: /chapter1/
custom_js:
- jquery.min
- anchor.min
- ace.min
- mode-haskell.min
- bundle
- index
---

{%pagination introduction#chapter2%}

# Chapter 1 - First Steps

In this chapter, we introduce the foundation of all functional languages and their related concepts, we talk about types and their relationship with functional languages, and end with a discussion on the different ways that one can write basic functional programs.

### 1. The λ-calculus
One might be thinking *"Calculus? I thought this was about programming?"* It might come as a surprise to some, but mathematics and computer programming have quite a long history and continue to find themselves intertwined as time goes on. One can easily find themselves lost in the history and theory, but that's not the purpose of this book. For our purposes (and at least for the duration of this chapter), the λ-calculus is simply the foundation of functional languages.

#### a. Three's Company -- Foundation
The λ-calculus can be thought of as a simple programming language made up of three components: variables, functions, and function application. In many functional languages, the λ-calculus is used at the fundamental level (e.g. function representation and function application), but some use it for many other interesting things, which is a testament to how flexible and powerful the calculus truly is.

How about a few examples?
{% repl_only lambda-examples#-- these are variables
x = 5
y = 6

-- this is a function
foo1 = \x -> x

-- this is also a function
foo2 f x y = f x

-- function application
app = foo1 x
partial = foo2 foo1%}
One can think of variables as *names* associated with a certain value. In functional languages, one is free to assign values (i.e., Integers, Booleans, Functions, etc.) to variables. It is, however, impossible to *re-assign* new values to variables once the code has been executed. In PureScript, variable names (function names are variables too!) must be prefixed with a *lower-case* letter.

A key feature in functional languages is the appearance of functions as *first-class* values. This means that one can do with functions as one can do with normal values. In the example above, we have associated the name `foo1` with the value `(\x -> x)`, a nameless function or an *anonymous function*. First-class functions are also allowed to be passed to other functions as arguments. Functions with functions as arguments are called *higher-order functions*, an example of which is `foo2` with its argument `f`. As we see later on in this chapter, first-class functions enable a considerable amount of flexibility in writing our code.

Finally, functions are applied using *juxtaposition*, or simply placing the function beside its arguments. An interesting part of function application in many functional languages is that we can use *partial function application*. In the example above, `partial` applies `foo2` to `foo1` and *returns* a function! This happens because `foo2` is parameterized over three arguments, but `partial` only applies it to one, resulting in a function parameterized over the remaining two arguments of `foo2`.

Try writing `(partial y x)` in the REPL above.

#### b. The Fine Print -- β-reduction

Another thing to note about functions is that they have what is known as a *local namespace*. This means that names defined within functions (i.e, the names of their parameters) are different from those defined outside of the function. In the examples above, we have defined `x` and `y` to hold the value `5` and `6`, respectively. We then later pass `x` to `foo1`, which makes reference to a certain *other* `x`. It might come as a surprise that `(partial y x)` evaluates to `6` and not `5`! The reason for this is that the `x` and `y` defined outside of `foo1` and `foo2` are said to be defined *globally*, while the `x` and `y` in the definition of `foo1` and `foo2` are defined *locally* and are thus different from one another.

It might help to see how `(partial y x)` comes up with its answer. In the λ-calculus, this is done through what is known as a *β-reduction*. The name *reduction* seems a bit off-putting, since each step in a *β-reduction* is essentially an expansion of expressions into their respective values. This is where a language like PureScript becomes rather helpful, since the act of reducing is simply taking an expression from the left hand side of an `=` sign to the value on the right. Aside from this, with every function application, a function's namespace grows, where the names of its parameters are associated with the values passed in their place. We represent this *namespace growth* as the expression contained within curly braces, `{}`, placed beside the given function being applied. Once all of a function's parameters have been applied, all occurances of names inside of its body (i.e., the expression after the `->`) are replaced with the respective values mapped inside of its namespace. This continues until there is no other possible reduction. In a [later chapter]({{ site.baseurl }}/chapter2), we show how to simulate this step-by-step calculation inside of PureScript itself!

Let's see a β-reduction in action:
```haskell
partial y x
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

We also annotate each line with one of the corresponding reduction rules:
```
a. Expression to Value
b. Start of Function Application 
c. Namespace Expansion
d. Namespace Reference
```
An added benefit of understanding β-reduction is that every reduction can be thought of as an *equivalence*. That is, `(partial y x)` is β-equivalent to `(foo2 foo1 y x)` and so on, even all the way down to the final value, `6`. This is only true because of a feature of purely functional languages called *referential transparency*. This means that a function, given an input (i.e., a context), will **always** return the same output, giving the programmer of a functional language the ability to reason about the equality of program *expressions* without even having to execute the code itself. Doing so is called *equational reasoning*, an example of which is included in this chapter's exercises!

### 2. Types in Programming Languages
Many programming languages, functional or otherwise, feature entities that are known as *types*. The more familiar types, such as `Int`, `Boolean` and `String`, are found in virtually every programming language and contain (or, in math speak, *are inhabited*) by values like `42`, `true` and `"apple"`, respectively. In some functional languages, however, types play a more intimate and dynamic role, giving them certain *benefits* and *abilities* over others. In this section, we introduce the basics about types in functional languages and as well as a few key concepts about them that every functional programmer should be aware of.

#### a. Everyone gets a Type! -- Inhabitance
In a statically typed language, one has *values*, and one has *types*. The two are related in a rather simple way: *every value has a type*. For the purposes of this chapter, we need not go any further than this statement.

Alas, the benefit of having this constraint is that everything one chooses to write inside of a typed programming language *must* have a corresponding type, and, indeed, that type must be the *correct* one. If, for example, a programmer mistakenly causes an expression to be typed incorrectly, the program does not execute, and the programmer receives a *type error* from the language's *type checker*. One might have seen a few of these while trying to solve the exercises in the introduction of this book.

But never fear! Type errors are here to help--the type system is actually here to help the programmer specify the behaviors of programs. One not need look any further than JavaScript to see how helpful type errors are (see **undefined errors**).

Let's see a few examples! **Note:** these are wrong on purpose and are thus uneditable.
```haskell
wrong :: Int -> Boolean -> Int
wrong i b = b

meaningOfLife :: Int
meaningOfLife = wrong false 42
```
When one is presented with type errors, there usually isn't one set way to fix everything. In our simple example above, we can actually do one of several fixes to relieve ourselves of the type error. In general, one can safely use the information provided by the type error to fix type errors, proactively fixing individual errors until one's program successfully executes, which is precisely what we do below.

The first type error is triggered by the definition of `wrong`, which *should* be a function that takes an `Int` and a `Boolean` and returns an `Int`. `wrong`, however, actually returns a `Boolean`. Intuitively, it would make sense to return the `Int` passed to the function, `i`, instead of returning `b`, the `Boolean`. Next, we have another type error inside of `meaningOfLife`. Upon closer inspection, it appears that we have simply misused `wrong` and mixed up the order of its arguments!

<!-- There are many more mistakes that trigger type errors, some more complex than others. It is, however, probably safe to say that the most common of these errors are related to *incorrectly using/defining functions* (as is the case with the example above). -->

#### b. Just What I Needed -- User Defined Types
It would be a bit silly to say all these great and wonderful things about the power of types in functional languages if one cannot define their own types. Fortunately, in many functional languages, we are free to do so and still reap the benefits of the powerful type system and type checker for our own user-defined types.

Defining our own types require that we adhere to a simple set of rules. To make this immediately clear, we'll define the type of `Point`:
```haskell
data Point = Point Number Number
```
A `Point` is a type with one *term-constructor* (also called `Point`), which is a function that takes two `Number`s, representing the `x` and `y` values of a given point on an x-y axis. Here, unlike variables, the names of types and type constructors must start with an *upper-case* letter. As a liberty to the programmer, PureScript allows term-constructors to use the same name as the type that they are defined for when the given type is designed with only *one* constructor (this practice is called constructor *punning*). In the event that a type requires more than one constructor, each constructor requires a unique name to properly differentiate it from the other ways of constructing values of the type.

Term-constructors can also be *pattern matched*, which allows for an elegant way of defining functions. As an example, let's define the type `IntList`, the type inhabited by lists of `Int`, then define a function `isEmpty` which determines whether or not a given `IntList` contains any elements.

First, the definition of `IntList`:
{% basic_hidden listdef#instance showIntList :: Show IntList where
  show Empty       = "Empty"
  show (Push i is) = "(Push " <> show i <> " " <> show is <> ")"#data IntList = Empty
             | Push Int IntList%}
Here, unlike `Point`, `IntList` is defined by two term-constructors: `Empty` and `Push`. These constructors represent the two ways to construct an `IntList`: an *empty* one or extending another `IntList` with another `Int`. This is a common way of defining *linked-list* structures. For example, here a few `IntList`s:

{% basic listexamples#emp :: IntList
emp = Empty

ls1 :: IntList
ls1 = Push 2 emp

ls2 :: IntList
ls2 = Push 1 ls1%}

Now, let's define `isEmpty`. With the power of pattern matching, writing this function becomes rather intuitive--we simply match over the possible ways of creating an `IntList` to determine whether or not the given list is empty or not. We don't need any special conditional expressions at all!
{% repl_only isempty#isEmpty :: IntList -> Boolean
isEmpty Empty       = true
isEmpty (Push i is) = false%}

On top of this, when we declare our function to be parameterized over an `IntList`, the type checker is actually aware of all the ways of constructing an `IntList` and provides the programmer aid in defining cases for each of its constructors. Should the programmer forget to provide a case for one of a type's constructors, the type checker provides an error detailing all the other cases missing. Try removing one of the cases for `isEmpty` and see what happens when you execute the above code snippet!

**Aside**: PureScript treats `Boolean`s a bit differently than Haskell. The values `true` and `false` *should* start with a capital letters (just as they do in Haskell) since they are both term-constructors of the `Boolean` type. In the case of PureScript, however, these two entitites appear lower-cased solely because this is how they appear in JavaScript.

**Random Question**: What happens when we pattern match over a constructor that doesn't belong to the type that we are defining our function over? Say, for example, we add the following case to `isEmpty`:
```haskell
isEmpty false = false
```
#### c. The Lord of the Foos -- Polymorphism
One might be thinking, *"Gee, all this stuff about types is cool and all, but I'm going to miss be able to define a few functions that work for multiple different inputs!"* Indeed, in an untyped functional language, one has the liberty of writing *one* function that accepts every possible input. Take, for example, Racket, an untyped, impure functional language, where one has the liberty of writing functions such as the ones below:
```racket
(define (add1 n) (+ n 1))
(define (sub1 n) (- n 1))
```
These functions work for every possible input, like the ones that one should want them to work for (i.e., *number*-like values). The problem with *not* having types, however, is that these functions *work for every possible input!* One is not constrained at all to write `(add1 "Banana")`, which results in a *contract violation* (which is similar to a type error but fundamentally different):
```racket
add1: contract violation
  expected: number?
  given: "Banana"
```
In this simple example, it's easy to see where one incorrectly used the function `add1`, but in more complex situations, for example if one used `add1` multiple times in one's program, it can be rather difficult to determine where/how the actual error occurred.

*"I'll just program correctly then,"* one might be thinking.

The truth of the matter is that statically typed functional languages *still* allow one to define functions similar to `add1` and `sub1` but in ways that prevent the common pitfalls caused by the lack of types. This is where *polymorphism* comes in handy, which is synonymous with a type parameterized over another type or a *higher-order type*.

In the introduction of this book, one might have seen the functions `id` and `const`. We include them now below with their respective types:
{% repl_only typed-calculus#id :: forall a. a -> a
id x = x

const :: forall a b. a -> b -> a
const x y = x%}
**NOTE**: When it comes to polymorphic functions, there is less flexibility and variance in constructing return values. For example, the only way that `id` and `const` can return an `a` is by returning their first argument. This is because, in general, it is impossible to return an element of an arbitrary type.

These functions work for *every* possible input, and they represent the polymorphic functions of the λ-calculus known as the *identity* and *constant* combinators. They, in fact, *should* work for all possible inputs, which is precisely what their type declarations specify. That is, `id` takes an `a` and returns an `a`, where `a` can be *any* type. In the case of `const`, `a` and `b` are also of type *any*. Here, the variable names are different to specify that `const` returns a value of the type of its first argument.

Aside from being able to write functions that work over *all* inputs, we can also write polymorphic functions with a constrained set of *any* using *type-classes*. In the introduction of this book, we defined `quicksort`, which has the type:
```haskell
forall a. (Ord a) => List a -> List a
```
This means that `quicksort` works for *any* `List` type, given that the elements of the `List` are `Ord` values. This relieves one from having to write `quicksort` that works for `List`s containing *non-sortable* elements. 

Aside from functions, polymorphism can also be used with types. Using polymorphism, we can define a more general `List` type. This polymorphic definition allows us to have one definition of `List` that includes all other instances of `List`s regardless of the type of their elements. This type comes pre-defined in PureScript and is a type parameterized over all types `a`:
```haskell
data List a = Nil
            | Cons a (List a)
```
We can then define a function similar to `isEmpty` that works for every possible list, regardless of the type of the elements the given list actually contains. 
{% repl_only isallempty#intList :: List Int
intList = (1:2:Nil)

boolList :: List Boolean
boolList = (true:false:Nil)

empty :: forall a. List a -> Boolean
empty Nil    = true
empty (x:xs) = false%}

**NOTE:** The `:` symbol is an infix reader sugar for the `Cons` constructor.

### 3. Recursion and its Principles
We end this chapter with an overview of writing in a *recursive style*. The idea of recursion is not unique to functional languages, as recursion is central and fundamental to all computer programming. As we mentioned in the introduction of this book, there are stark differences in the way that imperative and functional programs are written, which can be seen quite clearly in how a functional language incorporates a certain style of recursion. <!-- while an imperative languge incorporates and encourages recursion via recursive constructs like `for` and `while`, which are (basically) abset in *purely* functional programs. -->

#### a. Over, and Over, and Over, and Over...
To put it simply, a recursive program is a program that performs a certain *repeated* computation. There are many reasons why one would do this, and one would not really get very far without having to write a recursive program.

Let's start with a simple program written in Python:
```python
sum = 0
arr = [1,2,3,4,5]
for elem in arr:
  sum += elem
print sum
```
Here, we have an array, `arr`, which we calculate the sum of its elements. We achieve this is by iterating over the elements in `arr` using a `for` loop, individually adding each element in the array and add them to `sum`. If we were to translate this program directly into PureScript, we would find that we are missing the ability to *iteratively loop* over a structure. To do this in a functional language, we would be required to abstract over the *stateful* computation that happens when `sum` is updated in each iteration of the `for` loop. While this is indeed possible, it is by far *not* the simplest way to do so (we return to this idea in [Chapter 4]({{ site.baseurl }}/chapter4)).

In a functional language, we instead have the ability to write a recursive function that performs a *step-wise* computation. This style of writing follows a certain pattern:

1. Determine a base case -- *When should the computation end, and what should it return?*
2. Determine what to do *repeatedly* until the base case is reached.

In the case of *list-like* structures, such as an array, we associate `(1)` and `(2)` with the cases that the given structure is *empty* and when it's not. Thus, we know that writing a function to recur over a similar structure must cover both cases. In this case, we use pattern matching!

Let's write a function that sums the elements of a list in PureScript. For simplicity and to model the Python program above, we constrain the input of this function to lists of `Int`:
{% repl_only sum#sum :: List Int -> Int
sum Nil    = 0            -- base case
sum (x:xs) = x + (sum xs) -- repeated computation%}
Let's take the time to digest what exactly is going on in this function.

In the first line, we define our function's *base-case*. This means that we determine that our recursive computation should end when the given list is empty, in which case we return the value `0`. Furthermore, this also follows the logic that the sum of an empty list is `0`.

In the second line, we define what our function should do in the event that the given list is *not* empty. If we inspect the type of `x` and `xs`, we find that `x` is an `Int` and `xs` is a `List Int`. Logically, we would want to sum over the list we have, `xs`, by passing it to `sum` (recurring over `xs`). Doing so provides the *rest* of the computation and according to the type definiton of `sum` results in an `Int`. We would then want to add `x` to the result of summing the rest of the elements to implement the proper behavior of the function.

For clarity, we can *trace* each step in the computation by performing a β-reduction. For example, if we call `sum` on the list `(1:2:3:4:5:Nil)`, we get the following reduction:
```haskell
sum (1:2:3:4:5:Nil)
== 1 + (sum (2:3:4:5:Nil))
== 1 + (2 + (sum (3:4:5:Nil)))
== 1 + (2 + (3 + (sum (4:5:Nil))))
== 1 + (2 + (3 + (4 + (sum (5:Nil)))))
== 1 + (2 + (3 + (4 + (5 + (sum Nil)))))
== 1 + (2 + (3 + (4 + (5 + 0))))
== 1 + (2 + (3 + (4 + 5)))
== 1 + (2 + (3 + 9))
== 1 + (2 + 12)
== 1 + 14
== 15
```
`15`! That's precisely the answer we were looking for! Mission complete.

But wait! One might have noticed that this reduction is a bit long, especially for the simple act of summing the elements of a list. This verbosity is actually the reason for why many imperative languages avoid using recursion: it's very memory heavy. The fact that computation seems to *accumulate* work reflects how a recursive program consumes a significant amount of memory when compared to a program written in an iterative style.

We can, however, alleviate the memory strain by making a small change. Instead of adding individual list elements to the *remaining* computation, we can use an *accumulator* and add elements to it instead. This style of writing recursive programs is known as *accumulator passing style* (APS). We provide the alternative definition of a summing function, `sumAcc`, written in APS and as well as its resulting reduction trace. We also show how to define internal helper functions, here `sumAcc'` (read as `sumAcc` *prime*), using the `where` construct.
{% repl_only sumacc#sumAcc :: List Int -> Int
sumAcc xs = sumAcc' 0 xs
  where sumAcc' acc Nil    = acc
        sumAcc' acc (x:xs) = sumAcc' (acc + x) xs%}
```haskell
sumAcc (1:2:3:4:5:Nil)
== sumAcc' 0 (1:2:3:4:5:Nil)
== sumAcc' (0 + 1) (2:3:4:5:Nil)
== sumAcc' (1 + 2) (3:4:5:Nil)
== sumAcc' (3 + 3) (4:5:Nil)
== sumAcc' (6 + 4) (5:Nil)
== sumAcc' (10 + 5) Nil
== 15
```

#### b. The Essence of Recursion -- Folding
Let's take the idea of recursion one step further. Earlier, we stated that *every* recursive program follows a set pattern. To reiterate, we said that these programs must have a base case and define a computation to repeat. We can actually take advantage of this attribute and encapsulate it in a function that abstracts over the recursive pattern, otherwise known as a *fold* function or a *recursion principle*.

In real life, when one *folds* something, like a T-shirt, one is essentially taking something "big" and making it *smaller*. This is precisely what a fold function is meant to do. That is, take a structure and "fold" it into something else. If one is familiar with JavaScript, one might have used a function called `reduce`. The `reduce` function in JavaScript is synonymous to a fold function defined for list-like structures. In reality, however, one can define a fold function for virtually *every* type.

Let's continue with lists. Let's imagine what one might want to do with a list: one might combine its elements in some way, like `sum`, or one might want to change the values contained in the list and return a new list, like a *mapping function*. All of this is the essence of what a fold function over a list is meant to do. To make this clearer, let's think about what the appropriate type for this particular fold function, `foldList`, should be:

1. This function should be able return any arbitrary value.
2. This function should be able to handle *any* list (i.e., `List Int`, `List Boolean`, `List (List Int)`, etc.).
3. This function should abstract over the pattern of all possible functions over lists.

Now, let's piece it together. From `(1)`, we know that this function should return an *any* type. This means we need a polymorphic return value. Let's call it `r`. From `(2)`, this function should be able to accept *any* list. This means we need another polymorphic variable that is parameterized under the `List` type; let's call it `List a`. So far, we have the following:
```haskell
foldList :: forall a r. ... -> List a -> r
```
Hoorah. We're almost done. Our function now accepts *any* list and returns a value of an arbitrary type. 

For `(3)`, we must acknowledge a few things. Firstly, for a function to capture the *essence* of every function defined over a list, it itself must be recursive. This is because lists are recursively defined. We have already seen how a function defined for lists should look like. In this sense, we can start to imagine how `foldList` should be implemented. Since we are defining `foldList` to be able to return an `r`, an arbitrary value, we naturally need an `r` to return in the event the given list is empty. Let's update our type definition to reflect this:
```haskell
foldList :: forall a r. r -> ... -> List a -> r
```
Finally, we need to abstract the ability to build up from the final return value from the given elements of the provided list. Let's take `sum` as an example once more, and let's think about how its final return value is built up on. If we recall correctly, we used the `+` function:
```haskell
+ :: Int -> Int -> Int
```
This dictated that the list passed to `sum` contain only elements of type `Int` and that we use `0` as our final return value. In the case of `foldList`, however, we know that we are not just handling `Int`s anymore. For `foldList`, the provided `List` contains elements of type `a`, and we are returning elements of the type `r`. Thus, we need a *builder* function of type `a -> r -> r`.

Thus, we now have the final type definition of `foldList`:
```haskell
foldList :: forall a r. r -> (a -> r -> r) -> List a -> r
```
Filling out the definition of this function becomes rather straightforward due to its polymorphic nature:
{% basic foldlist#foldList :: forall a r. r -> (a -> r -> r) -> List a -> r
foldList base build Nil    = base
foldList base build (x:xs) = build x (foldList base build xs)%}
Alternatively, we can also use the same strategy to write `sumAcc` to alleviate memory strain of `foldList` by defining another fold function that immediately applies `build` at each step of the computation:
{% basic foldlist2#foldList' :: forall a r. r -> (a -> r -> r) -> List a -> r
foldList' acc build Nil    = acc
foldList' acc build (x:xs) = foldList' (build x acc) build xs%}

Theses fold functions abstract over the method of recursion used for writing functions like `sum`. Thus, we can define `sumFold` as follows:
{% repl_only sumfold#sumFold :: List Int -> Int
sumFold = foldList 0 (\x ans -> x + ans)
-- this is a comment: try switching the definition!
-- sumFold = foldList' 0 (\x ans -> x + ans) %}

## Exercises:
Since this is the first set of (real) exercises in this book, we take the time to provide some clear instructions on how to interact with them.

Some of the examples below have a small test suite (`100` generated tests) attached to them that determines whether the inputted code works as intended. These tests perform a property check on the code defined in the editor and also provide appropriate errors when necessary.

One is also free to use *typed-holes*. To use typed-holes, one is required to provide a name for the hole prefixed with `?`. For example:
```haskell
anotherConst :: forall a b. a -> b -> a
anotherConst a b = ?help
```
Executing the above code in an interactable editor will result in the following message:
```
  Hole 'help' has the inferred type

    a0

  You could substitute the hole with one of these values:

    a               :: a0
    Main.undefined  :: forall a. a

  in the following context:

    a :: a0
    b :: b1


  in value declaration anotherConst
```
Which helps us determine that `anotherConst` should return its first argument `a` as specified by its type-declaration. While there are several other uses for typed-holes, we won't go into detail on them here--just try them out!

#### i. Equational Reasoning
Consider the following definitions of `append` and `rev`.

{% repl_only appendrev#append :: forall a. List a -> List a -> List a
append Nil ys    = ys
append (x:xs) ys = x:(append xs ys)

rev :: forall a. List a -> List a
rev Nil    = Nil
rev (x:xs) = append (rev xs) (singleton x)%}

This implementation of `rev` (a function that reverses a list) works quite well for smaller sized lists. However, on larger lists, its performance suffers quite a bit, due to the fact that it also calls another recursively defined function, `append`.

We can improve its performance using *equational reasoning*, as described in the first section of this chapter, to remove the dependency of `rev` on `append`. We can do this by implementing another function that specializes the *appending* job that is done in `rev`. We'll call this function `appendRev` and use it to define `fastRev`.

We'll start by using this preliminary definition of `appendRev`:
<!-- NOTE: DO NOT MAKE THIS CODE INTERACTABLE! -->
```haskell
appendRev :: forall a. List a -> List a -> List a
appendRev xs ys = append (rev xs) ys
```
Then, using the results of `(1)` and `(2)`, below,  define a new version that no longer uses `append`.

1. Using β-reduction, calculate `appendRev Nil ys`.
2. In the same way as `(1)`, calculate `appendRev (x:xs) ys`.

The first β-reduction step has been provided. Each reduced expression is interchangeable with another, so `appendRev` and `fastRev` should still perform correctly regardless of which step of the reduction is currently defined. This is a great way to check the correctness of each reduction!

{% testable revProp#revProp :: List Int -> Result
revProp l = fastRev l === rev l#appendRev :: forall a. List a -> List a -> List a
appendRev Nil ys    =
  -- (1) 
  append (rev Nil) ys
appendRev (x:xs) ys =
  -- (2) 
  append (rev (x:xs)) ys

fastRev :: forall a. List a -> List a
fastRev xs = appendRev xs Nil%}

*Voila!* The following function, `fastRev`, should now be significantly faster than `rev`! **Magical**.
#### ii. Recursion Principles
Consider the definition of the simplest foldable data structure: the *Natural Number*!
{% basic_hidden nat#toInt :: Nat -> Int
toInt n = toInt' n 0
  where toInt' Zero ans     = ans
        toInt' (Add1 n) ans = toInt' n (1 + ans)

instance showNat :: Show Nat where
  show n = show $ toInt n

derive instance eqNat :: Eq Nat

instance arbNat :: Arbitrary Nat where
  arbitrary = do
    x <- chooseInt 0 (100)
    pure $ fromInt x

fromInt x | x <= 0 = Zero
fromInt x = Add1 $ fromInt (x-1)#data Nat = Zero
         | Add1 Nat%}

A natural number is either `Zero` or the successor of (i.e., 1 value greater than) another natural number. Think *peano numbers*. With this, we have defined a data structure that includes all positive integers and as well as 0.

Let's define some basic functions for Natural Numbers:
{% repl_only natfuns#-- add two natural numbers
plus :: Nat -> Nat -> Nat
plus Zero     y = y
plus (Add1 x) y = Add1 (x `plus` y)

-- multiply two natural numbers
times :: Nat -> Nat -> Nat
times Zero     _ = Zero
times (Add1 x) y = (x `times` y) `plus` y

-- factorial
fact :: Nat -> Nat
fact Zero     = Add1 Zero
fact (Add1 n) = (Add1 n) `times` (fact n)%}
Consider the following definition of `foldNat`:
{% basic foldnat#foldNat :: forall a. a -> (a -> a) -> Nat -> a
foldNat base build Zero     = base
foldNat base build (Add1 n) = foldNat (build base) build n%}
**Hint**: You may find it useful to define a few natural numbers to avoid having to write out a long series of `Add1`s every time you want to test your functions. For example:

{% basic nats#two  = Add1 (Add1 Zero)
five = Add1 (Add1 (Add1 (Add1 (Add1 Zero))))%}
* Define `plusFold` that behaves like `plus` but uses `foldNat`.

{% testable plusProp#plusProp :: Nat -> Nat -> Result
plusProp m n = m `plusFold` n === m `plus` n#plusFold :: Nat -> Nat -> Nat
plusFold m n = undefined%}
* Define `timesFold` that behaves like `times` but uses `foldNat`.

{% testable timesId#timesProp :: Nat -> Nat -> Result
timesProp m n = m `timesFold` n === m `times` n#timesFold :: Nat -> Nat -> Nat
timesFold m n = undefined%}
* *BONUS!!* Do the same for `fact`. **HINT**: `Tuple`.

{% repl_only factProp#factFold :: Nat -> Nat
factFold n = undefined%}
**NOTE**: Due to the recursive nature of factorial and natural numbers, we can only test a limited number of inputs (`#FeelsBadMan`). We recommend manually testing this function. You should be able to calculate:
```haskell
factFold five
```

{%pagination intro#chapter2%}
