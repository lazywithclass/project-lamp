---
layout: page
title: Chapter 3 - Continuing with Style
permalink: /chapter3/
custom_js:
- jquery.min
- anchor.min
- ace.min
- mode-haskell.min
- bundle
- index
---
In this chapter, we introduce *continuations* and writing functions in *continuation passing style* (CPS). We also discuss the reasons for writing CPSed programs.

### 1. Continuation Passing Style
In essence, a continuation is a higher-order function that abstracts over an extended content for performing a certain computation. This is much more easily explained in a functional language, since we can treat continuations simply as a special form of accumulator, where the value being "accumulated" is a function.

#### a. Callback Everyday -- Continuations
<!-- Convert a few basic functions -->
As we mentioned, a continuation is a higher-order function and writing in CPS is synonymous with using a function as an accumulator.

With this in mind, let's take a few steps back and recall writing in APS. In Chapter 1, we described how to convert a generally recursive definition into one that incorporates APS. To reiterate, here is the definition of `sum` written using general recursion:
```haskell
sum :: List Int -> Int
sum Nil    = 0
sum (x:xs) = x + (sum xs)
```
To convert `sum` into its APS equivalent, we add a parameter, representing an accumulated value, update its value during every recursive step, then return it once the base case is reached.
```haskell
sum :: List Int -> Int
sum xs = sumAcc xs 0
  where sumAcc Nil acc    = acc
        sumAcc (x:xs) acc = sumAcc (acc + x) xs
```
From here, translating an APSed program to a CPSed equivalent requires that we abstract over the accumulator by replacing it with a higher-order function, which gives us the following preliminary type definition for the CPS equivalent of `sum`, `sumCPS`:
```haskell
sumCPS :: List Int -> (... -> ...) -> Int
```

To derive the appropriate type for this function, we must do the following:

1. Determine the type of the final return value.
2. Determine the type of the recursive expression.

In this example, we know that `sum` should return an `Int`. Thus, we know the type of our continuation should *also* return an `Int`.
```haskell
sumCPS :: List Int -> (... -> Int) -> Int
```
Next, we need to determine the type of continuation's parameter, which we can determine by inspecting the type of the value we return for `sum`'s recursive case. In this case, the type is `Int`.
```haskell
sumCPS :: List Int -> (Int -> Int) -> Int
```
We then implement this function as follows:
{% repl_only sumcps#sum :: List Int -> Int
sum xs = sumCPS xs (\x -> x)
  where sumCPS Nil k    = k 0
        sumCPS (x:xs) k =
          sumCPS xs (\acc -> k (acc + x))%}

<!-- todo: explain this and id as base -->

with input List `(1:2:3:Nil)`
```haskell
-- Continuations are extended
id
(\acc -> id (acc + 1))
(\acc -> (\acc -> id (acc + 1)) (acc + 2))
(\acc -> (\acc -> (\acc -> id (acc + 1)) (acc + 2)) (acc + 3))
-- Continuations are applied
(\acc -> (\acc -> (\acc -> id (acc + 1)) (acc + 2)) (acc + 3)) 0
(\acc -> (\acc -> id (acc + 1)) (acc + 2)) 3
(\acc -> id (acc + 1)) 5
id 6
-- Final continuation is applied
id 6
6
```

#### b. One Step at a Time -- Control Flow
<!-- explicit order of operations -->
<!-- near stateful computation -->

#### c. If You Squint Your Eyes -- Tail Calls
<!-- calling in tail position -->
<!-- graze on what writing in this way looks like -->

### 2. CPS the Interpreter -- Implementation
<!-- interpreter goes here -->

## Exercises:

#### i. CPS Basic Functions
#### ii. From CPS to State Machine
