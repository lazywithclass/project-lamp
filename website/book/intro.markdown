---
layout: default
permalink: /introduction/
custom_js:
- jquery.min
- anchor.min
- ace.min
- mode-haskell.min
- bundle
- index
---

{%pagination #chapter1%}

# Introduction - Starting Out, Nice and Easy

## 1. Functional Programming?
Functional Programming (FP) can be thought of as a method of writing computer programs where *specification* takes precedence over direct manipulation of computer memory and executable *instructions*. This is a bit of an oversimplification, as FP offers quite a bit more benefits that simply allowing a programmer to program *differently*.

Nonetheless, direct memory manipulation is (probably) the more familiar programming concept. In fact, it is the primary idealogy behind languages like C, Java and Python.  The languages allow developers to freely manipulate information stored in memory. Through these languages, programmers compose instructions for the computer to `read` and `write` data. For example, let's consider the following code snippet written in Python:
```python
x = 3
y = x + 2
print(x, y)
```
To those familiar with programming in *imperative* languages (like Python), we know that the above code executes from top to bottom, line by line. Given this, we can reason that the following occurs when the code is executed by a computer:
1. The value `3` is stored inside a variable named `x`.
2. The value stored in the variable `x` is read from memory, the value `2` is added to it  and is stored in the new variable `y` (*Note*: the value stored in `x` is unchanged).
3. Both variables `x` and `y` are read from memory and stored inside a tuple, resulting in the value `(3, 5)` being printed onto the console.
4. Once the end of the program is reached, the program terminates.

With this, we can say that the code snippet *reflects* how a computer would peform the above computation. While in certain situations, a programmer might find this method of programming useful (indeed, *necessary* at times), programming in such a way is not always desirable or necessary.

On the other hand, while functional languages don't (quite) offer the seamless access to computer memory and don't (necessarily) feature an inherit structure in the order in which code is executed (we'll get back to this point later), functional languages offer something unique and powerful that imperative languages do not. To illustrate our point, let's take the standard, poster-child example of functional programming: `quicksort`. Let's first recall how `quicksort` is implemented by writing some pseudocode:
1. Choose a `pivot` element inside the given array/list
2. Split the array into two new arrays, one containing elements less than `pivot` (`ls1`) and the other containing elements greater than`pivot` (`ls2`), arbitrarily breaking ties.
3. Recur on both of the new lists to sort them.
4. Place the `pivot` element in between the newly sorted lists (e.g. result = `ls1` + `pivot` + `ls2`).

The above pseudocode, more or less, reflects how to implement `quicksort` in an imperative language. To do this, the programmer would need to design the individual *steps* in such a way that the computer executing the code peforms each of the above points in the correct manner. Now, let's see how to implement `quicksort` in Haskell, a pure, functional programming language:
```haskell
quicksort :: (Ord a) => [a] -> [a]
quicksort []     = []
quicksort (x:xs) = xsLess ++ [x] ++ xsMore
  where xsLess = quicksort (filter (<= x)  xs)
        xsMore = quicksort (filter (> x) xs)
```
Yes. 5 lines, and, with some inlining, we can compress the above definition down into 3 lines. Writing short code, however, is *not* the only reason to write in a language like Haskell. If we take the time to study the code above, we can see that it's *not* designed as a step-by-step instruction of what a computer should do to peform the intended computation but more as a *specification* of what the computation itself is supposed to do. When we write code using a functional language, we do not need to worry about what the computer actually needs to do. We simply focus on designing the proper logic around so that it peforms as intended. Thus, at the cost of some performance (i.e., imperative code *generally* performs slightly better than functional code), we alleviate the need to design all the intermediary steps of a computation and instead are allowed to work at a *higher-level* of designing computer programs.

We won't go into much more detail about the differences between imperative and functional code. For now, it is important to clearly state that there are benefits and pitfalls in designing computer programs in both manners of writing code.

## 2. What We're Doing Here
This is **Пroject λamp** (PL), a simple, down to earth introduction to the vast and ever-expanding world of functional programming. This project can be thought of as a tutorial into the core concepts of languages that feature some functional programming ideals and as well as those that rely heavily on them.

For this book, we are using the *PureScript* programming language, a flavor of Haskell. Unlike Haskell, PureScript is intended for use as a *JavaScript replacement*, giving us the needed flexibility for developing a browser-based teaching tool that not only *teaches* functional programming but also allows users to interact with working code within their browser. We are taking direct inspiration from *[Eloquent JavaScript](http://eloquentjavascript.net/)*, which provides much of the same utility for learning the JavaScript programming language.

We must clarify that this book is **not** a book that teaches PureScript (one can find that [here](https://leanpub.com/purescript/read)). Our goal is to provide a seamless and hands-on experience of learning functional languages (like Haskell and PureScript), because we believe that this method of learning is valueable, especially when it comes to learning about functional programming and its core concepts and ideals.

## 3. How to Use this Book
Throughout this book, one will find *many* code examples, most of which are written in PureScript (sometimes made to look like Haskell) and all of which are user-interactable. That is, if one should desire to mess around with the given examples, one is able (in fact, *encouraged*) to do so!

It should be mentioned, however, that, unlike a language like JavaScript, a purely functional language does not have easy access to *effectful computations*, the simplest example of which is `print`. To those more familiar with languages that allow the free-reign usage of `print` functions, this might take some getting used to. One should not be too wary, as functional languages offer something that is also quite useful, some would argue *more* so than being able to interact seamlessly with the console, which brings us to our next point.

In this book, we let **exercises** do the talking, a liberty that is present due in part to an advantage of certain functional languages. We hope that the reader will soon come to understand what we mean by this.

# Exercises

### i. Quicksort in PureScript
{%
repl_only quicksort
#quicksort :: forall a. (Ord a) => List a -> List a
quicksort Nil    = Nil
quicksort (x:xs) = xsLess <> (singleton x) <> xsMore
    where xsLess = quicksort (filter (\a -> a <= x) xs)
          xsMore = quicksort (filter (\a -> a > x) xs)%}

**NOTE:** To compile editable PureScript code, click into the snippet you want executed and press `CTRL + ENTER`, or on OS X press `CMD + ENTER`. If compilation goes well, nothing happens! This *generally* means everything went well. If something went wrong, you will receive an error message in red underneath the editor--try it out by removing the last `)` in the above editable code.

What do you suppose the first line of the code (the *type declaration*) says about this function? `quicksort` is a function that, well, sorts `List`s *quickly*. What sorts of `List`s does this function work with? It might come as a surprise to hear, but one should not have to worry about understanding *how* the code sorts `List`s to answer this question. We, however, have included a `REPL` to interact with the code above (and for *all* other PureScript code on this page). Try a few things and see what happens!

How about:
```haskell
quicksort (89:81:13:71:52:Nil)
```

### ii. Dabble in Types

What do you think the *types* are of the following function definitions?
{%
basic type-declaration#id x = x

const x y = x%}

**HINT**: Look back at exercise 1. What does the variable `a` mean in the type declaration for `quicksort`?

If you don't see any errors, chances are, you added the correct types!

{%pagination #chapter1%}
