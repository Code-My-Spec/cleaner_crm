# Postgrex.TypeInfo

The information about a type that is provided to the custom encoder/decoder
functions. See http://www.postgresql.org/docs/9.4/static/catalog-pg-type.html
for clarifications of the fields.

  * `oid` - The type's id;
  * `type` - The type name;
  * `send` - The name of the "send" function (the function postgres uses
    to convert the type to its binary format);
  * `receive` - The name of the "receive" function (the function postgres uses
    to convert the type from its binary format);
  * `output` - The name of the "output" function (the function postgres uses
    to convert the type to its text format);
  * `input` - The name of the "input" function (the function postgres uses
    to convert the type from its text format);
  * `array_elem` - If this is an array, the array elements' oid;
  * `base_type` - If this is a range type, the base type's oid;
  * `comp_elems` - If this is a composite type (record), the tuple
    elements' oid;