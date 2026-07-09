# Assent.Strategy.OIDC.Base

OIDC OAuth 2.0 strategy base.

## Usage

    defmodule MyApp.MyOIDCStrategy do
      use Assent.Strategy.OIDC.Base

      def default_config(_config) do
        [
          base_url: "https://oidc.example.com"
        ]
      end

      def normalize(_config, user), do: {:ok, user}
    end