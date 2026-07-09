# Phoenix.LiveViewTest.ClientProxy



## encode!/1

Encoding used by the Channel serializer.

## stop/2

Stops the client proxy gracefully.

## root_view/1

Returns the tokens of the root view.

## report_upload_progress/6

Reports upload progress to the proxy.

## start_link/1

Starts a client proxy.

## Options

  * `:caller` - the required `{ref, pid}` pair identifying the caller.
  * `:view` - the required `%Phoenix.LiveViewTest.View{}`
  * `:html` - the required string of HTML for the document.