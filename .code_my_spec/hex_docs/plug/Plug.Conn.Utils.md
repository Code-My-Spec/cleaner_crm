# Plug.Conn.Utils

Utilities for working with connection data

## list/1

Parses a comma-separated list of header values.

## Examples

    iex> list("foo, bar")
    ["foo", "bar"]

    iex> list("foobar")
    ["foobar"]

    iex> list("")
    []

    iex> list("empties, , are,, filtered")
    ["empties", "are", "filtered"]

    iex> list("whitespace , , ,,   is   ,definitely,optional")
    ["whitespace", "is", "definitely", "optional"]

## validate_utf8!/3

Validates the given binary is valid UTF-8.