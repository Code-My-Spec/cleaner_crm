# Credo.CLI.Output.UI

This module provides functions used to create the UI.

    >>> alias Credo.CLI.Output.UI
    >>> UI.puts "This is a test."
    This is a test.
    nil

    >>> alias Credo.CLI.Output.UI
    >>> UI.warn "This is a warning."
    This is a warning.
    nil

## edge/0

Returns the edge (`┃`) which is used in much of Credo's output as a binary.

## truncate/2

Truncate a line to fit within a specified maximum length.
Truncation is indicated by a trailing ellipsis (…), and you can override this
using an optional third argument.

    iex> Credo.CLI.Output.UI.truncate(nil, 7)
    ""
    iex> Credo.CLI.Output.UI.truncate("  7 chars\n", 7)
    "  7 ch…"
    iex> Credo.CLI.Output.UI.truncate("  more than 7\n", 7)
    "  more…"
    iex> Credo.CLI.Output.UI.truncate("  more than 7\n", 7, " ...")
    "  m ..."