# Phoenix.HTML.FormField

The struct returned by `form[field]`.

It has the following fields:

  * `:errors` - a list of errors belonging to the field
  * `:field` - the field name as an atom or a string
  * `:form` - the parent `form` struct
  * `:id` - the `id` to be used as form input as a string
  * `:name` - the `name` to be used as form input as a string
  * `:value` - the value for the input

This struct also implements the `Access` behaviour,
but raises if you try to access a field that is not defined.