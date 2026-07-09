# Bunt.ANSI

Functionality to render ANSI escape sequences.

[ANSI escape sequences](https://en.wikipedia.org/wiki/ANSI_escape_code)
are characters embedded in text used to control formatting, color, and
other output options on video text terminals.

## enabled?/0

Checks if ANSI coloring is supported and enabled on this machine.

This function simply reads the configuration value for
`:ansi_enabled` in the `:elixir` application. The value is by
default `false` unless Elixir can detect during startup that
both `stdout` and `stderr` are terminals.