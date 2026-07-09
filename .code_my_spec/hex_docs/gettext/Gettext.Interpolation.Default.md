# Gettext.Interpolation.Default

Default implementation for the `Gettext.Interpolation` behaviour.

Replaces `%{binding_name}` with the string value of the `binding_name` binding.

## runtime_interpolate/2

Interpolate a message or interpolatable with the given bindings.

Implementation of the `c:Gettext.Interpolation.runtime_interpolate/2` callback.

This function takes a message and some bindings and returns an `{:ok,
interpolated_string}` tuple if interpolation is successful. If it encounters
a binding in the message that is missing from `bindings`, it returns
`{:missing_bindings, incomplete_string, missing_bindings}` where
`incomplete_string` is the string with only the present bindings interpolated
and `missing_bindings` is a list of atoms representing bindings that are in
`interpolatable` but not in `bindings`.

## Examples

    iex> msgid = "Hello %{name}, you have %{count} unread messages"
    iex> good_bindings = %{name: "José", count: 3}
    iex> Gettext.Interpolation.Default.runtime_interpolate(msgid, good_bindings)
    {:ok, "Hello José, you have 3 unread messages"}
    iex> Gettext.Interpolation.Default.runtime_interpolate(msgid, %{name: "José"})
    {:missing_bindings, "Hello José, you have %{count} unread messages", [:count]}

    iex> msgid = "Hello %{name}, you have %{count} unread messages"
    iex> interpolatable = Gettext.Interpolation.Default.to_interpolatable(msgid)
    iex> good_bindings = %{name: "José", count: 3}
    iex> Gettext.Interpolation.Default.runtime_interpolate(interpolatable, good_bindings)
    {:ok, "Hello José, you have 3 unread messages"}
    iex> Gettext.Interpolation.Default.runtime_interpolate(interpolatable, %{name: "José"})
    {:missing_bindings, "Hello José, you have %{count} unread messages", [:count]}

## compile_interpolate/3

Compiles a static message to interpolate with dynamic bindings.

Implementation of the `c:Gettext.Interpolation.compile_interpolate/3` macro callback.

Takes a static message and some dynamic bindings. The generated
code will return an `{:ok, interpolated_string}` tuple if the interpolation
is successful. If it encounters a binding in the message that is missing from
`bindings`, it returns `{:missing_bindings, incomplete_string, missing_bindings}`,
where `incomplete_string` is the string with only the present bindings interpolated
and `missing_bindings` is a list of atoms representing bindings that are in
`interpolatable` but not in `bindings`.

## message_format/0

Implementation of `c:Gettext.Interpolation.message_format/0`.

## Examples

    iex> Gettext.Interpolation.Default.message_format()
    "elixir-format"