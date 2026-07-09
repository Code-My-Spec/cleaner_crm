# Tds.Ecto.VarChar

A Tds adapter Ecto Type that wraps erlang string into tuple so TDS driver
can understand if erlang string should be encoded as NVarChar or Varchar.

Due to some limitations in Ecto and Tds driver, it is not possible to
support collations other than the one set on connection during login.
Please be aware of this limitation if you plan to store varchar values in
your database using Ecto since you will probably lose some codepoints in
the value during encoding. Instead use `tds_encoding` library and first
encode value and then annotate it as `:binary` by calling `Ecto.Query.API.type/2`
in your query. This way all codepoints will be properly preserved during
insert to database.

## cast/1

Casts to string.

## cast!/1

Same as `cast/1` but raises `Ecto.CastError` on invalid arguments.

## load/1

Loads the DB type as is.

## dump/1

Converts a string representing a VarChar into a tuple `{value, :varchar}`.

Returns `:error` if value is not binary.