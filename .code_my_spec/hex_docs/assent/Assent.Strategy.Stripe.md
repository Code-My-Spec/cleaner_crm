# Assent.Strategy.Stripe

Stripe Connect OAuth 2.0 strategy.

## Usage

    config = [
      client_id: "REPLACE_WITH_CLIENT_ID",
      client_secret: "REPLACE_WITH_CLIENT_SECRET",
      redirect_uri: "http://localhost:4000/auth/callback"
    ]

See `Assent.Strategy.OAuth2` for more.

## Connect Express

This strategy uses Connect Standard by default. To use Connect Express, the
following config can be used:


    config = [
      client_id: "REPLACE_WITH_CLIENT_ID",
      client_secret: "REPLACE_WITH_CLIENT_SECRET",
      authorize_url: "https://connect.stripe.com/express/oauth/authorize"
      # authorization_params: [
      #   stripe_user: [business_type: "company", email: "user@example.com"],
      #   suggested_capabilities: ["transfers"]
      # ]
    ]