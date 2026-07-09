# Phoenix.LiveView.Diff



## new_components/1

Returns the diff component state.

## new_fingerprints/0

Returns the diff fingerprint state.

## to_iodata/2

Converts a diff into iodata.

It only accepts a full render diff.

## render_private/2

Render information stored in private changed.

## render/4

Renders a diff for the rendered struct in regards to the given socket.

## get_push_events_diff/1

Returns a diff containing only the events that have been pushed.

## write_component/4

Execute the `fun` with the component `cid` with the given `socket` as template.

It returns the updated `cdiffs` and the updated `components` or
`:error` if the component cid does not exist.

## read_component/4

Execute the `fun` with the component `cid` with the given `socket` and returns the result.

`:error` if the component cid does not exist.

## update_component/3

Sends an update to a component.

Like `write_component/4`, it will store the result under the `cid`
key in the `component_diffs` map.

If the component exists, a `{diff, new_components}` tuple
is returned. Otherwise, `:noop` is returned.

The component is preloaded before the update callback is invoked.

## Example

    {diff, new_components} = Diff.update_component(socket, state.components, update)

## mark_for_deletion_component/2

Marks a component for deletion.

It won't be deleted if the component is used meanwhile.

## delete_component/2

Deletes a component by `cid` if it has not been used meanwhile.

## component_to_rendered/4

Converts a component to a rendered struct.