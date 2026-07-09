# Assent.Strategy.Auth0

Auth0 OpenID Connect strategy.

## Configuration

- `:base_url` - The Auth0 base URL, required

## Usage

    config = [
      client_id: "REPLACE_WITH_CLIENT_ID",
      client_secret: "REPLACE_WITH_CLIENT_SECRET",
      base_url: "https://my-domain.auth0.com",
      redirect_uri: "http://localhost:4000/auth/callback"
    ]

See `Assent.Strategy.OAuth2` for more.