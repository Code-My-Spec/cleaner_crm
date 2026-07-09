# ClientUtils.CloudflareTunnel

GenServer that manages a Cloudflare Tunnel process via an Erlang port.

Supports two modes:

## Quick tunnel (default)

Runs `cloudflared tunnel --url <origin>` which assigns a random
`*.trycloudflare.com` URL — no account, credentials, or DNS required.

The GenServer parses the tunnel URL from cloudflared's stdout and
reconfigures the Phoenix endpoint so URL helpers generate correct
public URLs.

    {ClientUtils.CloudflareTunnel,
      origin_url: "http://127.0.0.1:4000",
      endpoint: MyAppWeb.Endpoint,
      otp_app: :my_app}

## Named tunnel

Uses a pre-configured Cloudflare named tunnel with a fixed hostname.
Requires credentials and DNS configured in Cloudflare dashboard.

    {ClientUtils.CloudflareTunnel,
      mode: :named,
      hostname: "dev.myapp.com",
      tunnel_id: "...",
      account_tag: "...",
      tunnel_secret: "...",
      origin_url: "http://127.0.0.1:4000",
      endpoint: MyAppWeb.Endpoint,
      otp_app: :my_app}

## Required opts (both modes)

  * `:origin_url` — local origin URL (e.g. `"http://127.0.0.1:4000"`)
  * `:endpoint` — Phoenix Endpoint module (e.g. `MyAppWeb.Endpoint`)
  * `:otp_app` — OTP app atom (e.g. `:my_app`)

## Additional required opts (named mode)

  * `:hostname` — public hostname for the tunnel
  * `:tunnel_id` — Cloudflare tunnel UUID
  * `:account_tag` — Cloudflare account tag
  * `:tunnel_secret` — tunnel credential secret (base64)

## Optional opts

  * `:enabled` — `true` (default) or `false`; when `false`, the tunnel is not started
  * `:mode` — `:quick` (default) or `:named`
  * `:name` — GenServer name registration (default: `__MODULE__`)
  * `:additional_hostnames` — list of extra hostnames to route through the tunnel
    (named mode only). Each hostname is added as an ingress rule pointing to
    the same `:origin_url`. Useful for white-label custom domains in dev.

## url/0

Returns the current tunnel URL, or nil if not yet established.

## url/1

Returns the current tunnel URL for the given server name.