# Assent.Strategy

Used for creating strategies.

## Usage

Set up `my_strategy.ex` the following way:

    defmodule MyStrategy do
      @behaviour Assent.Strategy

      alias Assent.Strategy, as: Helpers

      @impl Assent.Strategy
      def authorize_url(config) do
        # Generate redirect URL

        {:ok, %{url: url, ...}}
      end

      @impl Assent.Strategy
      def callback(config, params) do
        # Fetch user data

        user = Helpers.normalize_userinfo(userinfo)

        {:ok, %{user: user, ...}}
      end
    end

## http_request/5

Makes a HTTP request.

See `Assent.HTTPAdapter.request/5`.

## decode_json/2

Decode a JSON string.

## Options

- `:json_library` - The JSON library to use, see
  `Assent.json_library/1`

## verify_jwt/3

Verifies a JSON Web Token.

See `Assent.JWTAdapter.verify/3` for options.

## sign_jwt/4

Signs a JSON Web Token.

See `Assent.JWTAdapter.sign/3` for options.

## to_url/3

Generates a URL.