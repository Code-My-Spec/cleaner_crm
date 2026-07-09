# Phoenix.LiveView.Static



## render/2

Acts as a view via put_view to maintain the
controller render + instrumentation stack.

## verify_token/2

Verifies a LiveView token.

## render/3

Renders a live view without spawning a LiveView server.

  * `conn` - the Plug.Conn struct form the HTTP request
  * `view` - the LiveView module

## Options

  * `:router` - the router the live view was built at
  * `:action` - the router action
  * `:session` - the required map of session data
  * `:container` - the optional tuple for the HTML tag and DOM attributes

## nested_render/3

Renders a nested live view without spawning a server.

  * `parent` - the parent `%Phoenix.LiveView.Socket{}`
  * `view` - the child LiveView module

Accepts the same options as `render/3`.

## sign_token/2

Signs a LiveView token.