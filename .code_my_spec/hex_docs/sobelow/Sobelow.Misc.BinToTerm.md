# Sobelow.Misc.BinToTerm

# Insecure use of `binary_to_term`

If user input is passed to Erlang's `binary_to_term` function
it may result in memory exhaustion or code execution. Even with
the `:safe` option, `binary_to_term` will deserialize functions,
and shouldn't be considered safe to use with untrusted input.

`binary_to_term` checks can be ignored with the following command:

    $ mix sobelow -i Misc.BinToTerm