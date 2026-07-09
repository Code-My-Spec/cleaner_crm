# Assent.Strategy.Telegram

Telegram authorization strategy.

Supports both
[Telegram Login Widget](https://core.telegram.org/widgets/login),
and  [Web Mini App](https://core.telegram.org/bots/webapps) authorizations.

Note that using the `authorize_url/1` instead of the Telegram JavaScript
embed script, will send the end-user to the `:return_to` path with a base64
url encoded JSON string in a URL fragment. This means that it can only be
accessed client-side, so it must be parsed with JavaScript and resubmitted
as query params:

    <script type="text/javascript">
      // Function to decode base64 without padding
      function decodeBase64Url(base64Url) {
        let base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
        switch (base64.length % 4) {
          case 2: base64 += '=='; break;
          case 3: base64 += '='; break;
        }
        return atob(base64);
      }

      // Parse the hash fragment
      const hash = window.location.hash.substr(1);
      const hashData = hash.split('=')

      if (hashData[0] == "tgAuthResult") {
        const data = JSON.parse(decodeBase64Url(hashData[1]))
        const params = new URLSearchParams(data);

        // Construct the new URL with query parameters
        const newUrl = new URL(window.location.href.split('#')[0]);
        params.forEach((value, key) => {
          newUrl.searchParams.append(key, value);
        });

        // Redirect to the new URL
        window.location.href = newUrl.toString();
      }
    </script>

Note that the returned user claims can vary widelty, and are depend on the
authorization channel and user settings.

## Configuration

  - `:bot_token` - The telegram bot token, required
  - `:authorization_channel` - The authorization channel, optional, defaults
    to `:login_widget`, may be one of `:login_widget` or `:web_mini_app`
  - `:origin` - The origin URL for `authorize_url/1`, required
  - `:return_to` - The return URL for `authorize_url/1`, required

## Usage

### Login Widget

The JavaScript Widget can be implemented with:

    <script async
      src="https://telegram.org/js/telegram-widget.js?22"
      data-telegram-login="REPLACE_WITH_BOT_USERNAME"
      data-auth-url="REPLACE_WITH_CALLBACK_URL"></script>

Configuration should have:

    config = [
      bot_token: "YOUR_FULL_BOT_TOKEN"
    ]

Note that if a user declines to authorize access, you have to handle it
client-side with JavaScript.

### Web Mini App

    config = [
      bot_token: "YOUR_FULL_BOT_TOKEN",
      authorization_channel: :web_mini_app
    ]

For the Web Mini App authorization, the strategy expects the original
`initData` query param to be passed in as-is.