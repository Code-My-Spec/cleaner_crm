# Credo.IssueMeta

IssueMeta provides helper functions for meta information which a check wants
to pass to the `issue_for(...)` function, i.e. the current SourceFile and check
params (by default).

## for/2

Returns an issue meta tuple for the given `source_file` and `check_params`.

## source_file/1

Returns the source file for the given `issue_meta`.

## params/1

Returns the check params for the given `issue_meta`.