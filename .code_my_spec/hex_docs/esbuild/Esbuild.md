# Esbuild



## configured_version/0

Returns the configured esbuild version.

## config_for!/1

Returns the configuration for the given profile.

Returns nil if the profile does not exist.

## bin_path/0

Returns the path to the executable.

The executable may not be available if it was not yet installed.

## bin_version/0

Returns the version of the esbuild executable.

Returns `{:ok, version_string}` on success or `:error` when the executable
is not available.

## run/2

Runs the given command with `args`.

The given args will be appended to the configured args.
The task output will be streamed directly to stdio. It
returns the status of the underlying call.

## install_and_run/2

Installs, if not available, and then runs `esbuild`.

This task may be invoked concurrently and it will avoid concurrent installs.

Returns the same as `run/2`.

## install/0

Installs esbuild with `configured_version/0`.

If invoked concurrently, this task will perform concurrent installs.