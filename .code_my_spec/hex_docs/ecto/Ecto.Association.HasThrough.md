# Ecto.Association.HasThrough

The association struct for `has_one` and `has_many` through associations.

Its fields are:

  * `cardinality` - The association cardinality
  * `field` - The name of the association field on the schema
  * `owner` - The schema where the association was defined
  * `owner_key` - The key on the `owner` schema used for the association
  * `through` - The through associations
  * `relationship` - The relationship to the specified schema, default `:child`