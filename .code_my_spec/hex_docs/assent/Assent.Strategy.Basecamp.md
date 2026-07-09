# Assent.Strategy.Basecamp

Basecamp OAuth 2.0 strategy.

In the normalized user response a `basecamp_accounts` field is included that
can be used to limit access to users belonging to a particular account.

The Basecamp user endpoint does not provide data on email verification, email
is considered unverified.

## Usage

    config = [
      client_id: "REPLACE_WITH_CLIENT_ID",
      client_secret: "REPLACE_WITH_CLIENT_SECRET",
      redirect_uri: "http://localhost:4000/auth/callback"
    ]

See `Assent.Strategy.OAuth2` for more.