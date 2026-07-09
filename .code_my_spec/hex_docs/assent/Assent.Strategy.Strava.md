# Assent.Strategy.Strava

Strava OAuth strategy.

The athlete endpoint, describing the currently authenticated user, does not
return an email address - [changelog](https://developers.strava.com/docs/changelog/#january-17-2019).

## Usage

    config = [
      client_id: "REPLACE_WITH_CLIENT_ID",
      client_secret: "REPLACE_WITH_CLIENT_SECRET",
      redirect_uri: "http://localhost:4000/auth/callback"
    ]

See `Assent.Strategy.OAuth2` for more.