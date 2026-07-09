# Sobelow.DOS.StringToAtom

# Denial of Service via `String.to_atom`

In Elixir, atoms are not garbage collected. As such, if user input
is passed to the `String.to_atom` function, it may result in memory
exhaustion. Prefer the `String.to_existing_atom` function for untrusted
user input.

`String.to_atom` checks can be ignored with the following command:

    $ mix sobelow -i DOS.StringToAtom