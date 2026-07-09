# Credo.CLI.Filename

This module can be used to handle filenames given at the command line.

## contains_line_no?/1

Returns `true` if a given `filename` contains a pos_suffix.

    iex> Credo.CLI.Filename.contains_line_no?("lib/credo/sources.ex:39:8")
    true

    iex> Credo.CLI.Filename.contains_line_no?("lib/credo/sources.ex:39")
    true

    iex> Credo.CLI.Filename.contains_line_no?("lib/credo/sources.ex")
    false

## pos_suffix/2

Returns a suffix for a filename, which contains a line and column value.

    iex> Credo.CLI.Filename.pos_suffix(39, 8)
    ":39:8"

    iex> Credo.CLI.Filename.pos_suffix(39, nil)
    ":39"

These are used in this way: lib/credo/sources.ex:39:8

## remove_line_no_and_column/1

Removes the pos_suffix for a filename.

    iex> Credo.CLI.Filename.remove_line_no_and_column("lib/credo/sources.ex:39:8")
    "lib/credo/sources.ex"

## with/2

Adds a pos_suffix to a filename.

    iex> Credo.CLI.Filename.with("test/file.exs", %{:line_no => 1, :column => 2})
    "test/file.exs:1:2"