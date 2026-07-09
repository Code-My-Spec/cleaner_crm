# Phoenix.LiveView.Session



## verify_session/4

Verifies the session token.

Returns the decoded map of session data or an error.

## Examples

    iex> verify_session(AppWeb.Endpoint, "topic", encoded_token, static_token)
    {:ok, %Session{} = decoded_session}

    iex> verify_session(AppWeb.Endpoint, "topic", "bad token", "bac static")
    {:error, :invalid}

    iex> verify_session(AppWeb.Endpoint, "topic", "expired", "expired static")
    {:error, :expired}