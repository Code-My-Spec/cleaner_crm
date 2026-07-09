# Assent.Strategy.OAuth2.Base

OAuth 2.0 strategy base.

## Usage

    defmodule MyApp.MyOAuth2Strategy do
      use Assent.Strategy.OAuth2.Base

      def default_config(_config) do
        [
          base_url: "https://api.example.com",
          user_url: "/authorization.json"
        ]
      end

      @impl true
      def normalize(_config, user) do
        {:ok,
          # Conformed to https://openid.net/specs/openid-connect-core-1_0.html#rfc.section.5.1
          %{
            "sub"   => user["id"],
            "name"  => user["name"],
            "email" => user["email"]
          # },
          # # Provider specific data not part of the standard claims spec
          # %{
          #  "https://example.com/bio" => user["bio"]
          }
        }
      end
    end