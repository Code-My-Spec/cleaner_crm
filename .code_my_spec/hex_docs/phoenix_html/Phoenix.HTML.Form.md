# Phoenix.HTML.Form



## fetch/2

Defines the Phoenix.HTML.Form struct.

Its fields are:

  * `:source` - the data structure that implements the form data protocol

  * `:action` - The action that was taken against the form. This value can be
    used to distinguish between different operations such as the user typing
    into a form for validation, or submitting a form for a database insert.

  * `:impl` - the module with the form data protocol implementation.
    This is used to avoid multiple protocol dispatches.

  * `:id` - the id to be used when generating input fields

  * `:index` - the index of the struct in the form

  * `:name` - the name to be used when generating input fields

  * `:data` - the field used to store lookup data

  * `:params` - the parameters associated with this form

  * `:hidden` - a keyword list of fields that are required to
    submit the form behind the scenes as hidden inputs

  * `:options` - a copy of the options given when creating the
    form without any form data specific key

  * `:errors` - a keyword list of errors that are associated with
    the form

## input_value/2

Returns a value of a corresponding form field.

The `form` should either be a `Phoenix.HTML.Form` or an atom.
The field is either a string or an atom. If the field is given
as an atom, it will attempt to look data with atom keys. If
a string, it will look data with string keys.

When a form is given, it will look for changes, then
fallback to parameters, and finally fallback to the default
struct/map value.

Since the function looks up parameter values too, there is
no guarantee that the value will have a certain type. For
example, a boolean field will be sent as "false" as a
parameter, and this function will return it as is. If you
need to normalize the result of `input_value`, see
`normalize_value/2`.

## input_id/2

Returns an id of a corresponding form field.

The form should either be a `Phoenix.HTML.Form` or an atom.

## input_id/3

Returns an id of a corresponding form field and value attached to it.

Useful for radio buttons and inputs like multiselect checkboxes.

## input_name/2

Returns a name of a corresponding form field.

The first argument should either be a `Phoenix.HTML.Form` or an atom.

## Examples

    iex> Phoenix.HTML.Form.input_name(:user, :first_name)
    "user[first_name]"

## input_changed?/3

Receives two forms structs and checks if the given field changed.

The field will have changed if either its associated value, errors,
action, or implementation changed. This is mostly used for optimization
engines as an extension of the `Access` behaviour.

## input_validations/2

Returns the HTML validations that would apply to
the given field.

## normalize_value/2

Normalizes an input `value` according to its input `type`.

Certain HTML input values must be cast, or they will have idiosyncracies
when they are rendered. The goal of this function is to encapsulate
this logic. In particular:

  * For "datetime-local" types, it converts `DateTime` and
    `NaiveDateTime` to strings without the second precision

  * For "checkbox" types, it returns a boolean depending on
    whether the input is "true" or not

  * For "textarea", it prefixes a newline to ensure newlines
    won't be ignored on submission. This requires however
    that the textarea is rendered with no spaces after its
    content

## options_for_select/3

Returns options to be used inside a select element.

`options` is expected to be an enumerable which will be used to
generate each `option` element. The function supports different data
for the individual elements:

  * keyword lists - each keyword list is expected to have the keys
    `:key` and `:value`. Additional keys such as `:disabled` may
    be given to customize the option.
  * two-item tuples - where the first element is an atom, string or
    integer to be used as the option label and the second element is
    an atom, string or integer to be used as the option value
  * simple atom, string or integer - which will be used as both label and value
    for the generated select

## Option groups

If `options` is map or keyword list where the first element is a string,
atom or integer and the second element is a list or a map, it is assumed
the key will be wrapped in an `<optgroup>` and the value will be used to
generate `<options>` nested under the group.

## Examples

    options_for_select(["Admin": "admin", "User": "user"], "admin")
    #=> <option value="admin" selected>Admin</option>
    #=> <option value="user">User</option>

Multiple selected values:

    options_for_select(["Admin": "admin", "User": "user", "Moderator": "moderator"],
      ["admin", "moderator"])
    #=> <option value="admin" selected>Admin</option>
    #=> <option value="user">User</option>
    #=> <option value="moderator" selected>Moderator</option>

Groups:

    options_for_select(["Europe": ["UK", "Sweden", "France"], ...], nil)
    #=> <optgroup label="Europe">
    #=>   <option>UK</option>
    #=>   <option>Sweden</option>
    #=>   <option>France</option>
    #=> </optgroup>

Custom option tags:

    options_for_select(["Admin": "admin", "User": "user"], nil, tag: "opt")
    #=> <opt value="admin">Admin</opt>
    #=> <opt value="user">User</opt>

Horizontal separators can be added:

    options_for_select(["Admin", "User", :hr, "New"], nil)
    #=> <option>Admin</option>
    #=> <option>User</option>
    #=> <hr/>
    #=> <option>New</option>

    options_for_select(["Admin": "admin", "User": "user", hr: nil, "New": "new"], nil)
    #=> <option value="admin" selected>Admin</option>
    #=> <option value="user">User</option>
    #=> <hr/>
    #=> <option value="new">New</option>