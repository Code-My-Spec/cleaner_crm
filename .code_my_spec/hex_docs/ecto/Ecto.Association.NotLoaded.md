# Ecto.Association.NotLoaded

Struct returned by associations when they are not loaded.

The fields are:

  * `__field__` - the association field in `owner`
  * `__owner__` - the schema that owns the association
  * `__cardinality__` - the cardinality of the association