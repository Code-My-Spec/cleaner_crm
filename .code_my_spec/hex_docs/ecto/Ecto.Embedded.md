# Ecto.Embedded

The embedding struct for `embeds_one` and `embeds_many`.

Its fields are:

  * `cardinality` - The association cardinality
  * `field` - The name of the association field on the schema
  * `owner` - The schema where the association was defined
  * `related` - The schema that is embedded
  * `on_cast` - Function name to call by default when casting embeds
  * `on_replace` - The action taken on associations when schema is replaced