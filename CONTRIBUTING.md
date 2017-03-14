Basic overview of how to contribute to this project.

## Content
If you would like to contribute book content, feel free to fork, then make your edits to `website/book`. Every chapter is included in this directory as a `.markdown` file.

## Conventions
This project uses the static site generator [Jekyll](https://jekyllrb.com/) (described below). Content must adhere to the following conventions:

* Paragraphs are single lines.
* Chapter content follow the format in `website/book/template`.
* Feel free to use puns for section titles.
* To add a link to your content in the Table of Contents, edit `website/_layouts/home.html`.

### Generating Code Snippetes

Uneditable code is wrapped with triple back-tics, (`), then a keyword for the appropriate syntax highlighting.

There are four types of editable code snippets:

* `basic`
* `basic_hidden`
* `reply_only`
* `testable`

which follow a rather strict convention:

```
Used for basic code examples
{% basic ID#CODE_HERE%}

Used for basic code examples with hidden code elements
{% basic_hidden ID#HIDDEN_HERE#CODE_HERE%}

Used for code examples with an interactable REPL
{% repl_only ID#CODE_HERE%}

Same as repl_only but includes property tests
{% testable PROPERTY_NAME#PROPERTY_TEST#CODE_HERE%}
```

Every editor requires an `ID`, which is translated into an HTML identifier. All other code should be written in an appropriate text-editor to respect proper code indentation, then copy-pasted into the appropriate expression (i.e., either `HIDDEN_HERE` or `CODE_HERE`).

Some **IMPORTANT** notes:

* The first line of every code snippet must *immediately* proceed the `#` symbol. This is the proper place to paste code snippets.
* The last line of every code snippet must be *immediately* proceeded by the closing `%}` symbol.

This is to avoid adding newlines and extra whitespace before and after editor code.

## Jekyll
This project is built using Jekyll. If you would like to see local edits live, install Jekyll, then after forking this repo, navigate to the `website` folder, then run `jekyll build`.

This should build the project's dependencies. Feel free to edit `website/Gemfile` to get your local copy working.

Afterwards, you should be able to run `jekyll serve --watch`, then watch your edits on `localhost:4000`.
