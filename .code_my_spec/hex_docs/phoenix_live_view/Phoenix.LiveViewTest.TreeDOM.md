# Phoenix.LiveViewTest.TreeDOM



## filter/2

Filters nodes according to `fun`. Walks the tree in a post-walk manner, visiting children before parents.

## reverse_filter/2

Filters nodes and returns them in reverse order.

## tag/1

Returns the tag name of the node.

## attribute/2

Returns the value of the attribute `key` from the node or nil if not found.

## to_html/1

Returns the HTML representation of the node.

## to_text/2

Returns the text representation of the node, removing extra whitespace.

## by_id!/2

Returns the node with the given `id`, raises an error if not found.

## child_nodes/1

Returns the child nodes of the node.

## attrs/1

Returns all attributes of the node.

## inner_html!/2

Returns the children of the node with the given `id`, raises an error if not found.

## all_attributes/2

Returns all values of the attribute `name` from the node.

## all_values/1

Returns all values of the attributes from the node.

Handles phx-value-* attributes.

## reduce/3

Reduces the tree with the given function.

## walk/2

Walks the tree and updates nodes based on the given function.

## set_attr/3

Sets the attribute `name` to the value `val` on the node.

## inspect_html/1

Returns an HTML representation of the nodes for showing in error messages.

## find_live_views/1

Find live views in the given HTML tree.

## remove_stream_children/1

Removes stream children from the given HTML tree.

## normalize_to_tree/2

Normalizes the given HTML to a tree with optional sorting of attributes.