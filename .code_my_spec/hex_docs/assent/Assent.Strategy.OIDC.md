# Assent.Strategy.OIDC

OpenID Connect strategy.

This is built upon the `Assent.Strategy.OAuth2` strategy with added OpenID
Connect capabilities.

## Configuration

  - `:client_id` - The client id, required
  - `:base_url` - The OIDC issuer, required
  - `:openid_configuration_uri` - The URI for OpenID Provider, optional,
    defaults to `/.well-known/openid-configuration`
  - `:client_authentication_method` - The Client Authentication method to
    use, optional, defaults to `client_secret_basic`.  The value may be one
    of the following:

    - `none` - No client authentication, used with public clients
    - `client_secret_basic` - Authenticate with basic authorization header
    - `client_secret_post` - Authenticate with post params
    - `client_secret_jwt` - Authenticate with JWT using `:client_secret` as
      secret
    - `private_key_jwt` - Authenticate with JWT using `:private_key_path` or
      `:private_key` as secret
  - `:client_secret` - The client secret, required if
    `:client_authentication_method` is `client_secret_basic`,
    `:client_secret_post`, or `:client_secret_jwt`
  - `:openid_configuration` - The OpenID configuration, optional, the
    configuration will be fetched from `:openid_configuration_uri` if this is
    not defined
  - `:id_token_signed_response_alg` - The `id_token_signed_response_alg`
    parameter sent by the Client during Registration, defaults to `RS256`
  - `:id_token_ttl_seconds` - The number of seconds from `iat` that an ID
    Token will be considered valid, optional, defaults to nil
  - `:nonce` - The nonce to use for authorization request, optional, MUST be
    session based and unguessable
  - `:trusted_audiences` - A list of audiences that are trusted, optional.

See `Assent.Strategy.OAuth2` for more configuration options.

## Examples

    defmodule OIDCAuth do
      import Plug.Conn

      alias Assent.Strategy.OIDC

      defp config do
        [
          client_id: Application.fetch_env!(:my_app, :oidc, :client_id),
          client_secret: Application.fetch_env!(:my_app, :oidc, :client_secret),
          base_url: "https://server.example.com",
          authorization_params: [scope: "user:read user:write"],
          redirect_uri: "http://localhost:4000/auth/callback"
        ]
      end

      def request(conn) do
        config()
        |> OIDC.authorize_url()
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
        |> OIDC.callback(params)
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

## Nonce

`:nonce` can be set in the provider config. The `:nonce` will be returned in
the `:session_params` along with `:state`. You can use this to store the value
in the current session e.g. a httpOnly session cookie.

A random value generator can look like this:

    16
    |> :crypto.strong_rand_bytes()
    |> Base.encode64(padding: false)

Assent will dynamically generate one for the session if `:nonce` is set to
`true`.

See `Assent.Strategy.OIDC.authorize_url/1` for more.

## authorize_url/1

Generates an authorization URL for request phase.

The authorization url will be fetched from the OpenID configuration URI.

`openid` will automatically be added to the `:scope` in
`:authorization_params`, unless `:openid_default_scope` has been set.

Add `:nonce` to the config to pass it with the authorization request. The
nonce will be returned in `:session_params`. The nonce MUST be session based
and unguessable. A cryptographic hash of a cryptographically random value
could be stored in a httpOnly session cookie.

See `Assent.Strategy.OAuth2.authorize_url/1` for more.

## callback/3

Callback phase for generating access token and fetch user data.

The token url will be fetched from the OpenID configuration URI.

If the returned ID Token is signed with a symmetric key, `:client_secret`
will be required and used to verify the ID Token. If it was signed with a
private key, the appropriate public key will be fetched from the `jwks_uri`
setting in the OpenID configuration to verify the ID Token.

The ID Token will be validated per
[OpenID Connect Core 1.0 rules](https://openid.net/specs/openid-connect-core-1_0.html#IDTokenValidation).

See `Assent.Strategy.OAuth2.callback/3` for more.

## fetch_user/2

Fetches user params from ID token.

The ID Token is validated, and the claims is returned as the user params.
Use `fetch_userinfo/2` to fetch the claims from the `userinfo` endpoint.

## validate_id_token/2

Validates the ID token.

The OpenID configuration will be dynamically fetched if not set in the
config.

The ID Token will be validated per
[OpenID Connect Core 1.0 rules](https://openid.net/specs/openid-connect-core-1_0.html#IDTokenValidation).

## fetch_userinfo/2

Fetches claims from userinfo endpoint.

The userinfo will be fetched from the `userinfo_endpoint` OpenID
configuration.

The returned claims will be validated against the `id_token` verifying that
`sub` is equal.