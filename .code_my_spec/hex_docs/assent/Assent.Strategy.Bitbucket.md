# Assent.Strategy.Bitbucket

Bitbucket Cloud OAuth 2.0 strategy.

## Configuration

- `:user_emails_url` - The API path or URL to fetch e-mails from, defaults to `/user/emails`

See `Assent.Strategy.OAuth2` for more.

## Usage

    config = [
      client_id: "REPLACE_WITH_CONSUMER_KEY",
      client_secret: "REPLACE_WITH_CONSUMER_SECRET",
      redirect_uri: "http://localhost:4000/auth/callback"
    ]