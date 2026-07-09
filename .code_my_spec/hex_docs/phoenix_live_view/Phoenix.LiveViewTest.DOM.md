# Phoenix.LiveViewTest.DOM



## to_tree/2

Turns a lazy into a tree.

## to_lazy/1

Turns a tree into a lazy.

## css_escape/1

Escapes a string for use as a CSS identifier.

## Examples

    iex> css_escape("hello world")
    "hello\\ world"

    iex> css_escape("-123")
    "-\\31 23"

## find_static_views/1

Find static information in the given HTML tree.