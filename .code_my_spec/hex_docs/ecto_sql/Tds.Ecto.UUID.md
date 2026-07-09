# Tds.Ecto.UUID

A TDS adapter type for UUIDs strings.

If you are using Tds adapter and UUIDs in your project, instead of `Ecto.UUID`
you should use Tds.Ecto.UUID to generate correct bytes that should be stored
in database.

## cast/1

Casts to UUID.

## cast!/1

Same as `cast/1` but raises `Ecto.CastError` on invalid arguments.

## dump/1

Converts a string representing a UUID into a binary.

## load/1

Converts a binary UUID into a string.

## generate/0

Generates a version 4 (random) UUID.

## bingenerate/0

Generates a version 4 (random) UUID in the binary format.