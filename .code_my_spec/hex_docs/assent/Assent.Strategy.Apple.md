# Assent.Strategy.Apple

Apple Sign In OAuth 2.0 strategy.

You'll need to collect the 10-char long Team ID, the Services ID, the 10-char
Key ID and download the private key from the portal. Save the private key to
an accessible folder, or alternatively set `:private_key` with the content of
the private key.

## Usage

    config = [
      client_id: "REPLACE_WITH_SERVICES_ID",
      team_id: "REPLACE_WITH_TEAM_ID",
      private_key_id: "REPLACE_WITH_PRIVATE_KEY_ID",
      private_key_path: "/path/to/private_key.p8",
      redirect_uri: "http://localhost:4000/auth/callback"
    ]

## With JS SDK

You can use the JS SDK instead of handling it through `auhorize_url/2`. All you
have to do is to set up you HTML page with the following way:

    <html>
      <head>
          <meta name="appleid-signin-client-id" content="[CLIENT_ID]">
          <meta name="appleid-signin-scope" content="[SCOPES]">
          <meta name="appleid-signin-redirect-uri" content="[REDIRECT_URI]">
          <meta name="appleid-signin-state" content="[STATE]">
      </head>
      <body>
          <div id="appleid-signin" data-color="black" data-border="true" data-type="sign in"></div>
          <script type="text/javascript" src="https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/en_US/appleid.auth.js"></script>
      </body>
    </html>

You can get the state by generating the session params using the
`authorize_url/2`:

    {:ok, %{session_params: session_params}} = Assent.Strategy.Apple.authorize_url(config)

Use the `session_params[:state]` value for `[STATE]`. The callback phase
would be identical to how it's explained in the `Assent` docs.

See https://developer.apple.com/documentation/signinwithapplejs/configuring_your_webpage_for_sign_in_with_apple
for more.