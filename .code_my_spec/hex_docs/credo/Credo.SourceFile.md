# Credo.SourceFile

`SourceFile` structs represent a source file in the codebase.

## parse/2

Returns a `SourceFile` struct for the given `source` code and `filename`.

## ast/1

Returns the AST for the given `source_file`.

## lines/1

Returns the lines of source code for the given `source_file`.

## source/1

Returns the source code for the given `source_file`.

## source_and_filename/2

Returns the source code and filename for the given `source_file_or_source`.

## line_at/2

Returns the line at the given `line_no`.

NOTE: `line_no` is a 1-based index.

## line_at/4

Returns the snippet at the given `line_no` between `column1` and `column2`.

NOTE: `line_no` is a 1-based index.

## column/3

Returns the column of the given `trigger` inside the given line.

NOTE: Both `line_no` and the returned index are 1-based.