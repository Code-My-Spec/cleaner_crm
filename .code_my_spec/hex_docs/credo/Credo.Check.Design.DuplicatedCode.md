# Credo.Check.Design.DuplicatedCode



## prune_hashes/2

Takes a map of hashes to nodes and prunes those nodes that are just
subnodes of others in the same set.

Returns the resulting map.

## calculate_hashes/4

Calculates hash values for all sub nodes in a given +ast+.

Returns a map with the hashes as keys and the nodes as values.

## to_hash/1

Returns a hash-value for a given +ast+.

## mass/1

Returns the mass (count of instructions) for an AST.