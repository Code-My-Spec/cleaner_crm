# NimbleOptions.ValidationError

An error that is returned (or raised) when options are invalid.

Since this is an exception, you can either raise it directly with `raise/1`
or turn it into a message string with `Exception.message/1`.

See [`%NimbleOptions.ValidationError{}`](`__struct__/0`) for documentation on the fields.

## message/1

The error struct.

Only the following documented fields are considered public. All other fields are
considered private and should not be referenced:

  * `:key` (`t:atom/0`) - The key that did not successfully validate.

  * `:keys_path` (list of `t:atom/0`) - If the key is nested, this is the path to the key.

  * `:value` (`t:term/0`) - The value that failed to validate. This field is `nil` if there
    was no value provided.