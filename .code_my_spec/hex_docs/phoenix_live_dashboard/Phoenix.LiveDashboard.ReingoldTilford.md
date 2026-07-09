# Phoenix.LiveDashboard.ReingoldTilford



## nodes/1

Returns all nodes in a ReingoldTilford tree.

## dimensions/1

Returns the dimensions of a canvas to render all given
ReingoldTilford nodes.

## build/2

Builds a ReingoldTilfolrd tree.

The given tree is in the shape `{value, [child]}`.
The function receives the value and returns the
node label. The label is used to compute its width.

## lines/1

Returns the tree lines.