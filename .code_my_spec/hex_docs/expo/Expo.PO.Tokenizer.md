# Expo.PO.Tokenizer



## tokenize/2

Converts a string into a list of tokens.

A "token" is a tuple formed by:

  * the `:str` tag or a keyword tag (like `:msgid`)
  * the line the token is at
  * the value of the token if the token has a value (for example, a `:str`
    token will have the contents of the string as a value)

Some examples of tokens are:

  * `{:msgid, 33}`
  * `{:str, 6, "foo"}`