# Phoenix.Config



## start_link/1

Starts a Phoenix configuration handler.

## put/3

Puts a given key-value pair in config.

## permanent/3

Adds permanent configuration.

Permanent configuration is not deleted on hot code reload.

## cache/3

Caches a value in Phoenix configuration handler for the module.

The given function needs to return a tuple with `:cache` if the
value should be cached or `:nocache` if the value should not be
cached because it can be consequently considered stale.

Notice writes are not serialized to the server, we expect the
function that generates the cache to be idempotent.

## clear_cache/1

Clears all cached entries in the endpoint.

## from_env/3

Reads the configuration for module from the given OTP app.

Useful to read a particular value at compilation time.

## merge/2

Take 2 keyword lists and merge them recursively.

Used to merge configuration values into defaults.

## config_change/3

Changes the configuration for the given module.

It receives a keyword list with changed config and another
with removed ones. The changed config are updated while the
removed ones stop the configuration server, effectively removing
the table.