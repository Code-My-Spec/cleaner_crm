# Assent.Strategy.OAuth

OAuth 1.0a strategy.

`authorize_url/1` returns a map with a `:session_params` and `:url` key. The
`:session_params` key carries a `:oauth_token_secret` value for the request.

## Configuration

  - `:consumer_key` - The OAuth consumer key, required
  - `:base_url` - The base URL of the OAuth server, required
  - `:signature_method` -  The signature method, optional, defaults to
    `:hmac_sha1`. The value may be one of the following:

    - `:hmac_sha1` - Generates signature with HMAC-SHA1
    - `:rsa_sha1` - Generates signature with RSA-SHA1
    - `:plaintext` - Doesn't generate signature
  - `:consumer_secret` - The OAuth consumer secret, required if
    `:signature_method` is either `:hmac_sha1` or `:plaintext`
  - `:private_key_path` - The path for the private key, required if
    `:signature_method` is `:rsa_sha1` and `:private_key` hasn't been set
  - `:private_key` - The private key content that can be defined instead of
    `:private_key_path`, required if `:signature_method` is `:rsa_sha1` and
    `:private_key_path` hasn't been set

## Examples

    defmodule OAuth do
      import Plug.Conn

      alias Assent.Strategy.OAuth

      defp config do
        [
          consumer_key: Application.fetch_env!(:my_app, :oauth, :consumer_key),
          consumer_secret: Application.fetch_env!(:my_app, :oauth, :consumer_secret),
          base_url: "https://auth.example.com",
          authorization_params: [scope: "user:read user:write"],
          user_url: "https://example.com/api/user",
          redirect_uri: "http://localhost:4000/auth/callback"
        ]
      end

      def request(conn) do
        config()
        |> OAuth.authorize_url()
        |> case do
          {:ok, %{url: url, session_params: session_params}} ->
            conn
            |> put_session(:session_params, session_params)
            |> put_resp_header("location", url)
            |> send_resp(302, "")

          {:error, _error} ->
            send_resp(conn, 500, "Failed authorization")
        end
      end

      def callback(conn) do
        %{params: params} = fetch_query_params(conn)
        session_params = get_session(conn, :session_params)
        conn = delete_session(conn, :session_params)

        config()
        |> Keyword.put(:session_params, session_params)
        |> OAuth.callback(params)
        |> case do
          {:ok, %{user: user, token: token}} ->
            conn
            |> put_session(:user, user)
            |> put_session(:token, token)
            |> put_resp_header("location", "/")
            |> send_resp(302, "")

          {:error, _error} ->
            send_resp(conn, 500, "Failed authorization")
        end
      end
    end

## authorize_url/1

Generate authorization URL for request phase.

## Options

  - `:redirect_uri` - The URI that the server redirects the user to after
    authentication, required
  - `:request_token_url` - The path or URL to fetch the token from, optional,
    defaults to `/oauth/request_token`
  - `:authorize_url` - The path or URL for the OAuth server to redirect users
    to, defaults to `/oauth/authenticate`
  - `:authorization_params` - The authorization parameters, defaults to `[]`

## callback/3

Callback phase for generating access token and fetch user data.

## Options

  - `:access_token_url` - The path or URL to fetch the access token from,
    optional, defaults to `/oauth/access_token`
  - `:user_url` - The path or URL to fetch user data, required
  - `:session_params` - The session parameters that was returned from
    `authorize_url/1`, optional

## request/6

Performs a signed HTTP request to the API using the oauth token.