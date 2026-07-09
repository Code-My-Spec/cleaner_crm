# Credo.Sources

This module is used to find and read all source files for analysis.

## find/1

Finds sources for a given `Credo.Execution`.

Through the `files` key, configs may contain a list of `included` and `excluded`
patterns. For `included`, patterns can be file paths, directory paths and globs.
For `excluded`, patterns can also be specified as regular expressions.

    iex> Sources.find(%Credo.Execution{files: %{excluded: ["not_me.ex"], included: ["*.ex"]}})

    iex> Sources.find(%Credo.Execution{files: %{excluded: [~r/messy/], included: ["lib/mix", "root.ex"]}})

## find_in_dir/3

Finds sources in a given `directory` using a list of `included` and `excluded`
patterns. For `included`, patterns can be file paths, directory paths and globs.
For `excluded`, patterns can also be specified as regular expressions.

    iex> Sources.find_in_dir("/home/rrrene/elixir", ["*.ex"], ["not_me.ex"])

    iex> Sources.find_in_dir("/home/rrrene/elixir", ["*.ex"], [~r/messy/])