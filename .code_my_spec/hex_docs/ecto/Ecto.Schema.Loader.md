# Ecto.Schema.Loader



## load_struct/3

Loads a struct to be used as a template in further operations.

## unsafe_load/3

Loads data coming from the user/embeds into schema.

Assumes data does not all belong to schema/struct
and that it may also require source-based renaming.

## unsafe_load/4

Loads data coming from the user/embeds into struct and types.

Assumes data does not all belong to schema/struct
and that it may also require source-based renaming.

## safe_dump/3

Dumps the given data.