# FileSystem.Backend

A behaviour module for implementing different file system backend.

## backend/1

Get and validate backend module.

Returns `{:ok, backend_module}` upon success and `{:error, reason}` upon
failure.

When `nil` is given, will return default backend by OS.

When a custom module is given, make sure `start_link/1`, `bootstrap/0` and
`supported_system/0` are defnied.