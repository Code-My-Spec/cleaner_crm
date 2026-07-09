# Assent.Strategy.VK

VK.com OAuth 2.0 strategy.

The VK token endpoint does not provide data on email verification, email is
considered unverified.

## Configuration

- `:user_url_params` - Parameters to send along with the user fetch request,
  optional, defaults to `[]`

See `Assent.Strategy.OAuth2` for more.

## Usage

    config = [
      client_id: "REPLACE_WITH_CLIENT_ID",
      client_secret: "REPLACE_WITH_CLIENT_SECRET",
      redirect_uri: "http://localhost:4000/auth/callback"
    ]