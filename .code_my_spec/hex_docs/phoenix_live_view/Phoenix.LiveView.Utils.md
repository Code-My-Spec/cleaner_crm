# Phoenix.LiveView.Utils



## assign/3

Assigns a value if it changed.

## assign_new/3

Assigns the given `key` with value from `fun` into `socket_or_assigns` if one does not yet exist.

## force_assign/3

Forces an assign on a socket.

## force_assign/4

Forces an assign with the given changed map.

## clear_changed/1

Clears the changes from the socket assigns.

## clear_temp/1

Clears temporary data (flash, pushes, etc) from the socket privates.

## changed?/1

Checks if the socket changed.

## changed?/2

Checks if the given assign changed.

## cid/1

Returns the CID of the given socket.

## configure_socket/5

Configures the socket for use.

## random_id/0

Returns a random ID with valid DOM tokens

## post_mount_prune/1

Prunes any data no longer needed after mount.

## normalize_layout/1

Validates and normalizes the layout.

## get_flash/1

Returns the socket's flash messages.

## replace_flash/2

Puts a new flash with the socket's flash messages.

## clear_flash/1

Clears the flash.

## clear_flash/2

Clears the key from the flash.

## put_flash/3

Puts a flash message in the socket.

## changed_flash/1

Returns a map of the flash messages which have changed.

## push_event/4

Annotates the changes with the event to be pushed.

By default, events are dispatched on the JavaScript side after
the current patch is invoked. If the LiveView redirects,
any pending events are dispatched before the redirection occurs.
If the `dispatch: :before` option is passed, this event will be
dispatched before patching the DOM.

## put_reply/2

Annotates the reply in the socket changes.

## get_push_events/1

Returns the push events in the socket.

## get_reply/1

Returns the reply in the socket.

## salt!/1

Returns the configured signing salt for the endpoint.

## raise_bad_mount_and_live_patch!/0

Raises error message for bad live patch on mount.

## maybe_call_live_view_mount!/5

Calls the `c:Phoenix.LiveView.mount/3` callback, otherwise returns the socket as is.

## maybe_call_live_component_mount!/2

Calls the `c:Phoenix.LiveComponent.mount/1` callback, otherwise returns the socket as is.

## handle_mount_options!/3

Handle all valid options on mount/on_mount.

## call_handle_params!/5

Calls the `handle_params/3` callback, and returns the result.

This function expects the calling code has checked to see if this function has
been exported, otherwise it assumes the function has been exported.

Raises an `ArgumentError` on unexpected return types.

## maybe_call_update!/3

Calls the optional `update/2` or `update_many/1` callback, otherwise updates the socket(s) directly.

## sign_flash/2

Signs the socket's flash into a token if it has been set.

## verify_flash/2

Verifies the socket's flash token.