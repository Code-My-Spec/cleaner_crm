# Assent.Strategy.OAuth2

OAuth 2.0 strategy.

This strategy only supports the Authorization Code flow per
[RFC 6749](https://tools.ietf.org/html/rfc6749#section-1.3.1).

`authorize_url/1` returns a map with a `:url` and `:session_params` key. The
`:session_params` should be stored and passed back into `callback/3` as part
of config when the user returns. The `:session_params` carries a `:state`
value for the request [to prevent
CSRF](https://tools.ietf.org/html/rfc6749#section-4.1.1). If `:code_verifier`
is set to true, the `:session_params` will also carry PKCE [code verification
parameters](https://datatracker.ietf.org/doc/html/rfc7636#section-4).

This library also supports JWT tokens for client authentication as per
[RFC 7523](https://tools.ietf.org/html/rfc7523).

## Configuration

  - `:client_id` - The OAuth2 client id, required
  - `:base_url` - The base URL of the OAuth2 server, required
  - `:auth_method` - The authentication strategy used, optional. If not set,
    no authentication will be used during the access token request (e.g.
    public clients). The value may be one of the following:

    - `:client_secret_basic` - Authenticate with basic authorization header
    - `:client_secret_post` - Authenticate with post params
    - `:client_secret_jwt` - Authenticate with JWT using `:client_secret` as
      secret
    - `:private_key_jwt` - Authenticate with JWT using `:private_key_path` or
      `:private_key` as secret
  - `:client_secret` - The OAuth2 client secret, required if `:auth_method`
    is `:client_secret_basic`, `:client_secret_post`, or `:client_secret_jwt`
  - `:private_key_id` - The private key ID, required if `:auth_method` is
    `:private_key_jwt`
  - `:private_key_path` - The path for the private key, required if
    `:auth_method` is `:private_key_jwt` and `:private_key` hasn't been set
  - `:private_key` - The private key content that can be defined instead of
    `:private_key_path`, required if `:auth_method` is `:private_key_jwt` and
    `:private_key_path` hasn't been set
  - `:jwt_algorithm` - The algorithm to use for JWT signing, optional,
    defaults to `HS256` for `:client_secret_jwt` and `RS256` for
    `:private_key_jwt`
  - `:state` - A boolean or a string with the value of the state, optional,
    defaults to `true`. When set to `true` a random 32 byte long url safe
    string is generated. When set to `false` state will not be verified.
  - `:code_verifier` - Boolean to generate and use a random 128 byte long
    url safe code verifier for PKCE flow, optional, defaults to `false`. When
    set to `true` the session params will contain `:code_verifier`,
    `:code_challenge`, and `:code_challenge_method` params.

## Examples

    defmodule OAuth2 do
      import Plug.Conn

      alias Assent.Strategy.OAuth2

      defp config do
        [
          client_id: Application.fetch_env!(:my_app, :oidc, :client_id),
          client_secret: Application.fetch_env!(:my_app, :oidc, :client_secret),
          auth_method: :client_secret_post,
          base_url: "https://auth.example.com",
          authorization_params: [scope: "user:read user:write"],
          user_url: "https://example.com/api/user",
          redirect_uri: "http://localhost:4000/auth/callback"
        ]
      end

      def request(conn) do
        config()
        |> OAuth2.authorize_url()
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
        |> OAuth2.callback(params)
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
  - `:authorize_url` - The path or URL for the OAuth2 server to redirect
    users to, defaults to `/oauth/authorize`
  - `:authorization_params` - The authorization parameters, defaults to `[]`

## callback/3

Callback phase for generating access token with authorization code and fetch
user data. Returns a map with access token in `:token` and user data in
`:user`.

## Options

  - `:token_url` - The path or URL to fetch the token from, optional,
    defaults to `/oauth/token`
  - `:user_url` - The path or URL to fetch user data, required
  - `:session_params` - The session parameters that was returned from
    `authorize_url/1`, optional

## grant_access_token/3

Grants an access token.

## refresh_access_token/3

Refreshes the access token.

## request/6

Performs a HTTP request to the API using the access token.

## fetch_user/4

Fetch user data with the access token.

Uses `request/6` to fetch the user data.