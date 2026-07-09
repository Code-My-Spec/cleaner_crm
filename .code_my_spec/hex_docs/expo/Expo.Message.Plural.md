# Expo.Message.Plural

Struct for plural messages.

For example:

    msgid "Cat"
    msgid_plural "Cats"
    msgstr ""

See [`%Expo.Message.Plural{}`](`__struct__/0`) for documentation on the fields of this struct.

## key/1

Returns the **key** of the message.

The key takes the msgctxt into consideration by returning a tuple `{msgctxt, msgid}`.
Both `msgctxt` and `msgid` are normalized to binaries (instead of keeping line information)
for easier comparison.

## Examples

    iex> Plural.key(%Plural{msgid: ["cat"], msgid_plural: ["cats"]})
    {"", "cat"}

## rebalance/1

Re-balances all strings in the message.

This function does these things:

  * Put one string per newline of `msgid`/`msgid_plural`/`msgstr`
  * Put all flags onto one line
  * Put all references onto a separate line

### Examples

    iex> Plural.rebalance(%Plural{
    ...>   msgid: ["", "hello", "\n", "", "world", ""],
    ...>   msgid_plural: ["", "hello", "\n", "", "world", ""],
    ...>   msgstr: %{0 => ["", "hello", "\n", "", "world", ""]},
    ...>   flags: [["one", "two"], ["three"]],
    ...>   references: [[{"one", 1}, {"two", 2}], ["three"]]
    ...> })
    %Plural{
      msgid: ["hello\n", "world"],
      msgid_plural: ["hello\n", "world"],
      msgstr: %{0 => ["hello\n", "world"]},
      flags: [["one", "two", "three"]],
      references: [[{"one", 1}], [{"two", 2}], ["three"]]
    }

## source_line_number/3

Get the source line number of the message.

## Examples

    iex> %Expo.Messages{messages: [message]} = Expo.PO.parse_string!("""
    ...> msgid "foo"
    ...> msgid_plural "foos"
    ...> msgstr[0] "bar"
    ...> """)
    iex> Plural.source_line_number(message, :msgid)
    1
    iex> Plural.source_line_number(message, {:msgstr, 0})
    3

## merge/2

Merges two plural messages.

## Examples

    iex> msg1 = %Expo.Message.Plural{msgid: ["test"], msgid_plural: ["one"], flags: [["one"]], msgstr: %{0 => "une"}}
    ...> msg2 = %Expo.Message.Plural{msgid: ["test"], msgid_plural: ["two"], flags: [["two"]], msgstr: %{2 => "deux"}}
    ...> Expo.Message.Plural.merge(msg1, msg2)
    %Expo.Message.Plural{msgid: ["test"], msgid_plural: ["two"], flags: [["two", "one"]], msgstr: %{0 => "une", 2 => "deux"}}