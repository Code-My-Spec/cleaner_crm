# Tailwind



## configured_version/0

Returns the configured tailwind version.

## configured_version/1

Returns the configured tailwind version for a specific profile.

If the profile does not exist or a version is not explicitly configured,
falls back to `configured_version/0`.

## configured_target/0

Returns the configured tailwind target.

By default, it is automatically detected based on `configured_version/0`.

## configured_target/1

Returns the configured tailwind target for the given `profile`.

By default, it is automatically detected based on `configured_version/1`.

## config_for!/1

Returns the configuration for the given profile.

Raises if the profile does not exist.

## bin_path/1

Returns the path to the executable for the given `version`.

The executable may not be available if it was not yet installed.

## bin_version/0

Returns the version of the executable.

Returns `{:ok, vsn}` on success or `:error` when the executable
is not available.

## bin_version/1

Returns the version of the executable for the given `profile`.

Returns `{:ok, vsn}` on success or `:error` when the executable
is not available.

## run/2

Runs the tailwind CLI for the given `profile` with `args`.

The given args will be appended to the configured args.
The task output will be streamed directly to stdio. It
returns the status of the underlying call.

## install_and_run/2

Installs, if not available, and then runs the tailwind CLI.

Returns the same as `run/2`.

## default_base_url/0

Returns the default URL to install Tailwind from.

## install/1

Installs tailwind with `configured_version/0`.

If given, the executable is downloaded from `base_url`,
otherwise, `default_base_url/0` is used.