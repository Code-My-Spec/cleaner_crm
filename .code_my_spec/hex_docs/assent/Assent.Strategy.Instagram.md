# Assent.Strategy.Instagram

Instagram OAuth 2.0 strategy.

The Instagram user object does not provide data on email verification, email
is considered unverified.

## Usage

    config = [
      client_id: "REPLACE_WITH_CLIENT_ID",
      client_secret: "REPLACE_WITH_CLIENT_SECRET",
      redirect_uri: "http://localhost:4000/auth/callback"
    ]

See `Assent.Strategy.OAuth2` for more.