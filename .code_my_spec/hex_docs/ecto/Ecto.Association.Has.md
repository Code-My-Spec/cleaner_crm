# Ecto.Association.Has

The association struct for `has_one` and `has_many` associations.

Its fields are:

  * `cardinality` - The association cardinality
  * `field` - The name of the association field on the schema
  * `owner` - The schema where the association was defined
  * `related` - The schema that is associated
  * `owner_key` - The key on the `owner` schema used for the association
  * `related_key` - The key on the `related` schema used for the association
  * `queryable` - The real query to use for querying association
  * `on_delete` - The action taken on associations when schema is deleted
  * `on_replace` - The action taken on associations when schema is replaced
  * `defaults` - Default fields used when building the association
  * `relationship` - The relationship to the specified schema, default is `:child`
  * `preload_order` - Default `order_by` of the association, used only by preload