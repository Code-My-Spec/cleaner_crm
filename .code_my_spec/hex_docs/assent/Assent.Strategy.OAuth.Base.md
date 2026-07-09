# Assent.Strategy.OAuth.Base

OAuth 1.0 strategy base.

## Usage

    defmodule MyApp.MyOAuthStratey do
      use Assent.Strategy.OAuth

      @impl true
      def default_config(_config) do
        [
          base_url: "https://api.example.com",
          authorize_url: "/authorization/new",
          access_token_url: "/authorization/access_token"
          request_token_url: "/authorization/request_token",
          user_url: "/authorization.json",
          authorization_params: [scope: "default"]
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