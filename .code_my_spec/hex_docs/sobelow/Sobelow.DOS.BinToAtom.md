# Sobelow.DOS.BinToAtom

# Denial of Service via Unsafe Atom Interpolation

In Elixir, atoms are not garbage collected. As such, if user input
is used to create atoms (as in `:"foo#{bar}"`, or in `:erlang.binary_to_atom`),
it may result in memory exhaustion. Prefer the `String.to_existing_atom`
function for untrusted user input.

Atom interpolation checks can be ignored with the following command:

    $ mix sobelow -i DOS.BinToAtom