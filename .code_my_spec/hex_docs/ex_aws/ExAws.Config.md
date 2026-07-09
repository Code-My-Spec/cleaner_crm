# ExAws.Config

Generates the configuration for a service.

It starts with the defaults for a given environment and then merges in the
common config from the ex_aws config root, and then finally any config
specified for the particular service.

## Refreshable fields

Some fields are marked as refreshable. These fields will be fetched through
the auth cache even if they are passed in as overrides. This is so stale
credentials aren't used, for example, with long running streams.

This behaviour must be explicitly enabled by passing `refreshable: true` as an option
to Config.new/2

## new/2

Builds a complete set of config for an operation.

  1. Defaults are pulled from `ExAws.Config.Defaults`
  2. Common values set via e.g `config :ex_aws` are merged in.
  3. Keys set on the individual service e.g `config :ex_aws, :s3` are merged in
  4. Finally, any configuration overrides are merged in

## http_config/2

Builds a minimal HTTP configuration.