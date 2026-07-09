# LazyHTML.Tree

This module deals with HTML documents represented as an Elixir tree
data structure.

## prereduce/3

Performs a depth-first, pre-order traversal of the given tree.

This function traverses the tree without modifying it, check `postwalk/2` and
`postwalk/3` if you need to modify the tree.

## postreduce/3

Performs a depth-first, post-order traversal of the given tree.

This function traverses the tree without modifying it, check `postwalk/2` and
`postwalk/3` if you need to modify the tree.

## postwalk/3

Performs a depth-first, post-order traversal of the given tree.

The mapper `fun` can return a list of nodes to replace the given
node. In order to remove a node, return an empty list.

## postwalk/2

Same a `postwalk/3`, but with no accumulator.