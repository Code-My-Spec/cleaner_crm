# Sobelow.DOS.ListToAtom

# Denial of Service via `List.to_atom`

In Elixir, atoms are not garbage collected. As such, if user input
is passed to the `List.to_atom` function, it may result in memory
exhaustion. Prefer the `List.to_existing_atom` function for untrusted
user input.

`List.to_atom` checks can be ignored with the following command:

    $ mix sobelow -i DOS.ListToAtom