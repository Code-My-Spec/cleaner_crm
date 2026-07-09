# Expo.Message

Functions to work on message structs (`Expo.Message.Singular` and `Expo.Message.Plural`).

A message is a single PO singular or plural message. For example:

    msgid "Hello"
    msgstr ""

Message structs are used both to represent reference messages (where the `msgstr` is empty)
in POT files as well as actual translations.

## key/1

Returns a "key" that can be used to identify a message.

This function returns a "key" that can be used to uniquely identify a
message assuming that no "same" messages exist; for what "same"
means, look at the documentation for `same?/2`.

The purpose of this function is to be used in situations where we'd like to
group or sort messages but where we don't need the whole structs.

## Examples

    iex> t1 = %Expo.Message.Singular{msgid: ["foo"]}
    iex> t2 = %Expo.Message.Singular{msgid: ["", "foo"]}
    iex> Expo.Message.key(t1) == Expo.Message.key(t2)
    true

    iex> t1 = %Expo.Message.Singular{msgid: ["foo"]}
    iex> t2 = %Expo.Message.Singular{msgid: ["bar"]}
    iex> Expo.Message.key(t1) == Expo.Message.key(t2)
    false

## same?/2

Tells whether two messages are the same message according to their
`msgid`.

This function returns `true` if `message1` and `message2` are the same
message, where "the same" means they have the same `msgid` or the same
`msgid` and `msgid_plural`.

## Examples

    iex> t1 = %Expo.Message.Singular{msgid: ["foo"]}
    iex> t2 = %Expo.Message.Singular{msgid: ["", "foo"]}
    iex> Expo.Message.same?(t1, t2)
    true

    iex> t1 = %Expo.Message.Singular{msgid: ["foo"]}
    iex> t2 = %Expo.Message.Singular{msgid: ["bar"]}
    iex> Expo.Message.same?(t1, t2)
    false

## has_flag?/2

Tells whether the given `message` has the given `flag` specified.

### Examples

    iex> Expo.Message.has_flag?(%Expo.Message.Singular{msgid: [], flags: [["foo"]]}, "foo")
    true

    iex> Expo.Message.has_flag?(%Expo.Message.Singular{msgid: [], flags: [["foo"]]}, "bar")
    false

## append_flag/2

Appends the given `flag` to the given `message`.

Keeps the line formatting intact.

### Examples

    iex> message = %Expo.Message.Singular{msgid: [], flags: []}
    iex> Expo.Message.append_flag(message, "foo")
    %Expo.Message.Singular{msgid: [], flags: [["foo"]]}

## source_line_number/3

Get the source line number of the message.

## Examples

    iex> %Expo.Messages{messages: [message]} = Expo.PO.parse_string!("""
    ...> msgid "foo"
    ...> msgstr "bar"
    ...> """)
    iex> Expo.Message.source_line_number(message, :msgid)
    1

## merge/2

Merges two messages.

If both messages are `Expo.Message.Singular`, the result is a singular message.
If one of the two messages is a `Expo.Message.Plural`, the result is a plural message.
This is consistent with the behavior of GNU Gettext.

## Examples

    iex> msg1 = %Expo.Message.Singular{msgid: ["test"], flags: [["one"]]}
    ...> msg2 = %Expo.Message.Singular{msgid: ["test"], flags: [["one", "two"]]}
    ...> Expo.Message.merge(msg1, msg2)
    %Expo.Message.Singular{msgid: ["test"], flags: [["one", "two"]]}

    iex> msg1 = %Expo.Message.Singular{msgid: ["test"]}
    ...> msg2 = %Expo.Message.Plural{msgid: ["test"], msgid_plural: ["tests"]}
    ...> Expo.Message.merge(msg1, msg2)
    %Expo.Message.Plural{msgid: ["test"], msgid_plural: ["tests"]}