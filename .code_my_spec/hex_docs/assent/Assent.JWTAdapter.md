# Assent.JWTAdapter

JWT adapter helper module.

You can configure the JWT adapter by updating the configuration:

    jwt_adapter: {Assent.JWTAdapter.AssentJWT, [...]}

Default options can be set by passing a list of options:

    jwt_adapter: {Assent.JWTAdapter.AssentJWT, [...]}

You can also set global application config:

    config :assent, :jwt_adapter, Assent.JWTAdapter.AssentJWT

## Usage

    defmodule MyApp.MyJWTAdapter do
      @behaviour Assent.JWTAdapter

      @impl true
      def sign(claims, alg, secret, opts) do
        # ...
      end

      @impl true
      def verify(token, secret, opts) do
        # ...
      end
    end

## load_private_key/1

Loads a private key from the provided configuration.

## Options

- `:private_key_path` - The path to the private key file, optional.
- `:private_key` - The private key, required if `:private_key_path` is not set.