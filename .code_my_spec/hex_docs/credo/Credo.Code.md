# Credo.Code

`Credo.Code` contains a lot of utility or helper functions that deal with the
analysis of - you guessed it - code.

Whenever a function serves a general purpose in this area, e.g. getting the
value of a module attribute inside a given module, we want to extract that
function and put it in the `Credo.Code` namespace, so others can utilize them
without reinventing the wheel.

## prewalk/3

Prewalks a given `Credo.SourceFile`'s AST or a given AST.

Technically this is just a wrapper around `Macro.prewalk/3`.

## postwalk/3

Postwalks a given `Credo.SourceFile`'s AST or a given AST.

Technically this is just a wrapper around `Macro.postwalk/3`.

## ast/1

Returns an AST for a given `String` or `Credo.SourceFile`.

## to_lines/1

Converts a String or `Credo.SourceFile` into a List of tuples of `{line_no, line}`.

## to_tokens/1

Converts a String or `Credo.SourceFile` into a List of tokens using the `:elixir_tokenizer`.

## contains_child?/2

Returns true if the given `child` AST node is part of the larger
`parent` AST node.

## find_child/2

Returns the first child that matches the given `pattern` in the `parent` AST node.

## clean_charlists_strings_and_sigils/1

Takes a SourceFile and returns its source code stripped of all Strings and
Sigils.

## clean_charlists_strings_sigils_and_comments/2

Takes a SourceFile and returns its source code stripped of all Strings, Sigils
and code comments.

## remove_metadata/1

Returns an AST without its metadata.