# Postgrex.Utils



## default_extension?/1

Checks if a given extension is a default extension.

## default_extensions/1

List all default extensions.

## parse_version/1

Converts pg major.minor.patch (http://www.postgresql.org/support/versioning) version to an integer

## default_opts/1

Fills in the given `opts` with default options.
Only adds keys extracted via PGHOST if no endpoint-related keys are explicitly provided.

## encode_msg/3

Return encode error message.

## encode_msg/2

Return encode error message.

## type_msg/2

Return type error message.

## set_label/1

Set a process label if `Process.set_label/1` is available.