# Credo.Check.Params

This module provides functions for handling parameters ("params") given to
checks through `.credo.exs` (i.e. the `Credo.ConfigFile`).

## get/3

Returns the given `field`'s `params` value.

Example:

    defmodule SamepleCheck do
      def param_defaults do
        [foo: "bar"]
      end
    end

    iex> Credo.Check.Params.get([], :foo, SamepleCheck)
    "bar"
    iex> Credo.Check.Params.get([foo: "baz"], :foo, SamepleCheck)
    "baz"