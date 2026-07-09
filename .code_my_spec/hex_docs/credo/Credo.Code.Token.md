# Credo.Code.Token

This module provides helper functions to analyse tokens returned by `Credo.Code.to_tokens/1`.

## eol?/1

Returns `true` if the given `token` contains a line break.

## position/1

Returns the position of a token in the form

    {line_no_start, col_start, line_no_end, col_end}