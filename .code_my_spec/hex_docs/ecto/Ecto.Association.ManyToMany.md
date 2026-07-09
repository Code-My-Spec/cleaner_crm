# Ecto.Association.ManyToMany

The association struct for `many_to_many` associations.

Its fields are:

  * `cardinality` - The association cardinality
  * `field` - The name of the association field on the schema
  * `owner` - The schema where the association was defined
  * `related` - The schema that is associated
  * `owner_key` - The key on the `owner` schema used for the association
  * `queryable` - The real query to use for querying association
  * `on_delete` - The action taken on associations when schema is deleted
  * `on_replace` - The action taken on associations when schema is replaced
  * `defaults` - Default fields used when building the association
  * `relationship` - The relationship to the specified schema, default `:child`
  * `join_keys` - The keyword list with many to many join keys
  * `join_through` - Atom (representing a schema) or a string (representing a table)
    for many to many associations
  * `join_defaults` - A list of defaults for join associations
  * `preload_order` - Default `order_by` of the association, used only by preload