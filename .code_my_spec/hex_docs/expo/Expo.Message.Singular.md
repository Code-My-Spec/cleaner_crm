# Expo.Message.Singular

Struct for non-plural messages.

For example:

    msgid "Hello"
    msgstr ""

See [`%Expo.Message.Singular{}`](`__struct__/0`) for documentation on the fields of this struct.

## key/1

Returns the **key** of the message.

The key takes the msgctxt into consideration by returning a tuple `{msgctxt, msgid}`.
Both `msgctxt` and `msgid` are normalized to binaries (instead of keeping line information)
for easier comparison.

## Examples

    iex> Singular.key(%Singular{msgid: ["foo"]})
    {"", "foo"}

    iex> Singular.key(%Singular{msgid: ["foo"], msgctxt: ["con", "text"]})
    {"context", "foo"}

## rebalance/1

Re-balances all strings in the given message.

This function does these things:

  * Puts one string per newline of `msgid`/`msgstr`
  * Puts all flags onto one line
  * Puts all references onto a separate line

### Examples

    iex> Singular.rebalance(%Singular{
    ...>   msgid: ["", "hello", "\n", "", "world", ""],
    ...>   msgstr: ["", "hello", "\n", "", "world", ""],
    ...>   flags: [["one", "two"], ["three"]],
    ...>   references: [[{"one", 1}, {"two", 2}], ["three"]]
    ...> })
    %Singular{
      msgid: ["hello\n", "world"],
      msgstr: ["hello\n", "world"],
      flags: [["one", "two", "three"]],
      references: [[{"one", 1}], [{"two", 2}], ["three"]]
    }

## source_line_number/3

Gets the source line number of the message.

## Examples

    iex> %Expo.Messages{messages: [message]} = Expo.PO.parse_string!("""
    ...> msgid "foo"
    ...> msgstr "bar"
    ...> """)
    iex> Singular.source_line_number(message, :msgid)
    1
    iex> Singular.source_line_number(message, :msgstr)
    2

## merge/2

Merges two singular messages.

## Examples

    iex> msg1 = %Expo.Message.Singular{msgid: ["test"], flags: [["one"]]}
    ...> msg2 = %Expo.Message.Singular{msgid: ["test"], flags: [["two"]]}
    ...> Expo.Message.Singular.merge(msg1, msg2)
    %Expo.Message.Singular{msgid: ["test"], flags: [["two", "one"]]}