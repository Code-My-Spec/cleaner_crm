# Phoenix.Endpoint.Supervisor



## start_link/3

Starts the endpoint supervision tree.

## server?/2

Checks if Endpoint's web server has been configured to start.

## config_change/3

Callback that changes the configuration from the app callback.

## static_lookup/2

Returns a two item tuple with the first element containing the
static path of a file in the static root directory
and the second element containing the sha512 of that file (for SRI).

When the file exists, it includes a timestamp. When it doesn't exist,
just the static path is returned.

The result is wrapped in a `{:cache | :nocache, value}` tuple so
the `Phoenix.Config` layer knows how to cache it.

## warmup/1

Invoked to warm up caches on start and config change.