# Credo.Code.Scope

This module provides helper functions to determine the scope name at a certain
point in the analysed code.

## mod_name/1

Returns the module part of a scope.

    iex> Credo.Code.Scope.mod_name("Credo.Code")
    "Credo.Code"

    iex> Credo.Code.Scope.mod_name("Credo.Code.ast")
    "Credo.Code"

## name/2

Returns the scope for the given line as a tuple consisting of the call to
define the scope (`:defmodule`, `:def`, `:defp` or `:defmacro`) and the
name of the scope.

Examples:

    {:defmodule, "Foo.Bar"}
    {:def, "Foo.Bar.baz"}