# Assent.Strategy.Slack

Slack OAuth 2.0 OpenID Connect strategy.

The Slack user endpoint does not provide data on email verification, email is
considered unverified.

## Configuration

- `:team_id` - The team id to restrict authorization for, optional, defaults to nil

See `Assent.Strategy.OAuth2` for more.

## Usage

    config = [
      client_id: "REPLACE_WITH_CLIENT_ID",
      client_secret: "REPLACE_WITH_CLIENT_SECRET",
      redirect_uri: "http://localhost:4000/auth/callback"
    ]

By default, the user can decide what team should be used for authorization.
If you want to limit to a specific team, please pass a team id to the
configuration:

    config = [
      client_id: "REPLACE_WITH_CLIENT_ID",
      client_secret: "REPLACE_WITH_CLIENT_SECRET",
      team_id: "REPLACE_WITH_TEAM_ID",
      redirect_uri: "http://localhost:4000/auth/callback"
    ]

This value will be not be used if you set a `authorization_params` key.
Instead you should set `team: TEAM_ID` in the `authorization_params` keyword
list.