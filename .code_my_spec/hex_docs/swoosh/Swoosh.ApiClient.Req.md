# Swoosh.ApiClient.Req

Req-based ApiClient for Swoosh.

    config :swoosh, :api_client, Swoosh.ApiClient.Req

Any `client_options` that are set will be passed along to `Req.post` but the
following keys will be overwritten as they are set by Swoosh explicitly:
  * `headers`
  * `body`
  * `decode_body` - set to false as Adapters expect the raw response