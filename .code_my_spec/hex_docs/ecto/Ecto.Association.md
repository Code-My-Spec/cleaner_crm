# Ecto.Association



## association_from_schema!/2

Retrieves the association from the given schema.

## association_key/2

Returns the association key for the given module with the given suffix.

## Examples

    iex> Ecto.Association.association_key(Hello.World, :id)
    :world_id

    iex> Ecto.Association.association_key(Hello.HTTP, :id)
    :http_id

    iex> Ecto.Association.association_key(Hello.HTTPServer, :id)
    :http_server_id

## filter_through_chain/3

Build an association query through the given associations from the specified owner table
and through the given associations. Finally filter by the provided values of the owner_key of
the first relationship in the chain. Used in Ecto.assoc/2.

## join_through_chain/3

Join the target table given a list of associations to go through starting from the owner table.

## combine_joins_query/3

Add the default assoc query where clauses to a join.

This handles only `where` and converts it to a `join`,
as that is the only information propagate in join queries.

## combine_assoc_query/2

Add the default assoc query where clauses a provided query.

## joins_query/3

Build a join query with the given `through` associations starting at `counter`.

## related_from_query/2

Retrieves related module from queryable.

## Examples

    iex> Ecto.Association.related_from_query({"custom_source", Schema}, :comments_v1)
    Schema

    iex> Ecto.Association.related_from_query(Schema, :comments_v1)
    Schema

    iex> Ecto.Association.related_from_query("wrong", :comments_v1)
    ** (ArgumentError) association :comments_v1 queryable must be a schema or a {source, schema}. got: "wrong"

## apply_defaults/3

Applies default values into the struct.

## validate_defaults!/3

Validates `defaults` for association named `name`.

## validate_preload_order!/2

Validates `preload_order` for association named `name`.

## merge_source/2

Merges source from query into to the given schema.

In case the query does not have a source, returns
the schema unchanged.

## update_parent_prefix/2

Updates the prefix of a changeset based on the metadata.

## on_repo_change/4

Performs the repository action in the related changeset,
returning `{:ok, data}` or `{:error, changes}`.