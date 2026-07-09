# Expo.PO

File handling for PO (`.po`) and POT (`.pot`) files.

## parse_string/2

Parses the given `string` into a `Expo.Messages` struct.

It returns `{:ok, messages}` if there are no errors, otherwise
`{:error, error}` where `error` is an exception struct.

## Examples

    iex> {:ok, po} = Expo.PO.parse_string("""
    ...> msgid "foo"
    ...> msgstr "bar"
    ...> """)
    iex> [message] = po.messages
    iex> message.msgid
    ["foo"]
    iex> message.msgstr
    ["bar"]
    iex> po.headers
    []

    iex> Expo.PO.parse_string("foo")
    {:error, %Expo.PO.SyntaxError{line: 1, reason: "unknown keyword 'foo'"}}

## parse_string!/2

Parses `string` into a `Expo.Messages` struct, raising an exception if there are
any errors.

Works exactly like `parse_string/1`, but returns a `Expo.Messages` struct
if there are no errors or raises an exception if there are.

## Examples

    iex> po = Expo.PO.parse_string!("""
    ...> msgid "foo"
    ...> msgstr "bar"
    ...> """)
    iex> [message] = po.messages
    iex> message.msgid
    ["foo"]
    iex> message.msgstr
    ["bar"]
    iex> po.headers
    []

    iex> Expo.PO.parse_string!("msgid")
    ** (Expo.PO.SyntaxError) 1: no space after 'msgid'

## parse_file/2

Parses the contents of a file into a `Expo.Messages` struct.

This function works similarly to `parse_string/1` except that it takes a file
and parses the contents of that file. It can return:

  * `{:ok, po}` if the parsing is successful

  * `{:error, error}` if there is an error with the contents of the
    `.po` file (for example, a syntax error); `error` is an exception struct

  * `{:error, reason}` if there is an error with reading the file (this error
    is one of the errors that can be returned by `File.read/1`)

## Examples

    {:ok, po} = Expo.PO.parse_file("messages.po")
    po.file
    #=> "messages.po"

    Expo.PO.parse_file("nonexistent")
    #=> {:error, :enoent}

## parse_file!/2

Parses the contents of a file into a `Expo.Messages` struct, raising if there
are any errors.

Works like `parse_file/1`, except that it raises an exception
if there are issues with the contents of the file or with reading the file.

## Examples

    Expo.PO.parse_file!("nonexistent.po")
    #=> ** (File.Error) could not parse "nonexistent.po": no such file or directory