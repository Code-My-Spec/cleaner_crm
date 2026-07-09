# Phoenix.Router.Helpers



## define/2

Generates the helper module for the given environment and routes.

## defhelper/2

Receives a route and returns the quoted definition for its helper function.

In case a helper name was not given, or route is forwarded, returns nil.

## raise_route_error/6

Callback for generate router catch all.

## encode_param/1

Callback for properly encoding parameters in routes.