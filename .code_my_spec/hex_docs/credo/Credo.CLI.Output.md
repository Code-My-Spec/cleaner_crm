# Credo.CLI.Output

This module provides helper functions regarding command line output.

## issue_color/1

Returns a suitable color for a given priority.

    iex> Credo.CLI.Output.issue_color(%Credo.Issue{priority: :higher})
    :red

    iex> Credo.CLI.Output.issue_color(%Credo.Issue{priority: 20})
    :red

## priority_arrow/1

Returns a suitable arrow for a given priority.

    iex> Credo.CLI.Output.priority_arrow(:high)
    "↗"

    iex> Credo.CLI.Output.priority_arrow(10)
    "↗"

    iex> Credo.CLI.Output.priority_arrow(%Credo.Issue{priority: 10})
    "↗"

## priority_name/1

Returns a suitable name for a given priority.

    iex> Credo.CLI.Output.priority_name(:normal)
    "normal"

    iex> Credo.CLI.Output.priority_name(1)
    "normal"

    iex> Credo.CLI.Output.priority_name(%Credo.Issue{priority: 1})
    "normal"

## foreground_color/1

Returns a suitable foreground color for a given `background_color`.

    iex> Credo.CLI.Output.foreground_color(:yellow)
    :black

    iex> Credo.CLI.Output.foreground_color(:blue)
    :white