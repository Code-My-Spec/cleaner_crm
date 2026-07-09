# Assent.Strategy.Twitter

Twitter OAuth strategy.

The Twitter user endpoint only returns verified email, `email_verified` will
always be `true`.

## Usage

    config = [
      consumer_key: "REPLACE_WITH_CONSUMER_KEY",
      consumer_secret: "REPLACE_WITH_CONSUMER_SECRET",
      redirect_uri: "http://localhost:4000/auth/callback"
    ]

See `Assent.Strategy.OAuth` for more.