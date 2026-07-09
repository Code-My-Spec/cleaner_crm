# Assent.HTTPAdapter

HTTP adapter helper module.

You can configure the which HTTP adapter Assent uses by setting the
configuring:

    http_adapter: Assent.HTTPAdapter.Httpc

Default options can be set by passing a list of options:

    http_adapter: {Assent.HTTPAdapter.Httpc, [...]}

You can also set global application config:

    config :assent, :http_adapter, Assent.HTTPAdapter.Httpc

## Usage

    defmodule MyApp.MyHTTPAdapter do
      @behaviour Assent.HTTPAdapter

      @impl true
      def request(method, url, body, headers, opts) do
        # ...
      end
    end

## user_agent_header/0

Sets a user agent header.

The header value will be `Assent-VERSION` with VERSION being the `:vsn` of
`:assent` app.

## decode_response/2

Decodes request response body.

## Options

- `:json_library` - The JSON library to use, see
  `Assent.json_library/1`