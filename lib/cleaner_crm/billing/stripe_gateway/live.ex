defmodule CleanerCrm.Billing.StripeGateway.Live do
  @moduledoc """
  Talks to the real Stripe API over `Req` and verifies webhook
  signatures per Stripe's documented scheme (HMAC-SHA256 over
  `"{timestamp}.{raw body}"`, compared against the `Stripe-Signature`
  header).

  Requires `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET` (see
  `.code_my_spec/integrations/stripe.md`). Verifying the signature
  needs the exact raw request bytes, which normal body parsing
  discards — `CleanerCrmWeb.CacheBodyReader` stashes them into
  `conn.assigns[:raw_body]` for the webhook route specifically.

  Missing credentials are a recoverable operational condition, not a
  bug: `create_payment_intent/1` returns `{:error, %{"code" =>
  "not_configured", ...}}` and `verify_webhook_event/1` returns
  `{:error, :invalid_signature}` rather than raising, so a deploy
  without keys degrades to a friendly error for the caller instead of
  crashing the LiveView or returning a raw 500 from the public
  `/pay/:token` or `/webhooks/stripe` endpoints. `config/dev.exs`
  avoids this entirely by defaulting to `StripeGateway.Test` — dev
  machines don't carry these secrets.
  """

  @behaviour CleanerCrm.Billing.StripeGateway

  @base_url "https://api.stripe.com/v1"

  @impl true
  def create_payment_intent(%{amount_cents: amount_cents} = params) do
    with {:ok, key} <- fetch_secret_key() do
      body =
        %{
          "amount" => amount_cents,
          "currency" => "usd",
          # Card-only, no redirect-based methods: confirming without a
          # return_url (server-side here, or the client-side Elements
          # flow's own `redirect: "if_required"`) requires redirects off.
          "automatic_payment_methods[enabled]" => true,
          "automatic_payment_methods[allow_redirects]" => "never"
        }
        |> put_confirmation(params)
        |> put_metadata(Map.get(params, :metadata, %{}))

      @base_url
      |> Kernel.<>("/payment_intents")
      |> Req.post(form: body, auth: {:bearer, key})
      |> handle_response()
    end
  end

  # `confirm: false` — the Stripe Elements flow (see
  # `CleanerCrm.Booking.confirm_booking/3`) — leaves the intent
  # unconfirmed for the client to finish with its own `client_secret`.
  defp put_confirmation(body, %{confirm: false}), do: body

  defp put_confirmation(body, %{payment_method: payment_method} = params) do
    body
    |> Map.put("payment_method", payment_method)
    |> Map.put("confirm", true)
    |> Map.put("off_session", Map.get(params, :off_session, false))
  end

  # A misconfigured deploy (secret unset) is a recoverable operational
  # condition here, not a bug — callers already handle `{:error, _}` by
  # showing the payer/owner a friendly message, so this must never raise.
  defp fetch_secret_key do
    case secret_key() do
      nil ->
        {:error,
         %{"code" => "not_configured", "message" => "STRIPE_SECRET_KEY is not configured"}}

      key ->
        {:ok, key}
    end
  end

  defp handle_response(
         {:ok, %{status: status, body: %{"id" => id, "status" => stripe_status} = body}}
       )
       when status in 200..299 do
    {:ok, %{id: id, status: stripe_status, client_secret: Map.get(body, "client_secret")}}
  end

  defp handle_response({:ok, %{body: %{"error" => error}}}), do: {:error, error}

  defp handle_response({:error, reason}),
    do: {:error, %{"code" => "request_failed", "message" => inspect(reason)}}

  defp put_metadata(body, metadata) do
    Enum.reduce(metadata, body, fn {key, value}, acc ->
      Map.put(acc, "metadata[#{key}]", to_string(value))
    end)
  end

  @impl true
  def verify_webhook_event(conn) do
    with {:ok, secret} <- fetch_webhook_secret(),
         [signature_header] <- Plug.Conn.get_req_header(conn, "stripe-signature"),
         raw_body when is_binary(raw_body) <- conn.assigns[:raw_body],
         {:ok, timestamp, expected_signature} <- parse_signature_header(signature_header),
         true <- Plug.Crypto.secure_compare(sign(secret, timestamp, raw_body), expected_signature) do
      {:ok, conn.params}
    else
      _ -> {:error, :invalid_signature}
    end
  end

  defp fetch_webhook_secret do
    case webhook_secret() do
      nil -> :error
      secret -> {:ok, secret}
    end
  end

  defp parse_signature_header(header) do
    parts =
      header
      |> String.split(",")
      |> Map.new(fn part ->
        case String.split(part, "=", parts: 2) do
          [key, value] -> {key, value}
          [key] -> {key, nil}
        end
      end)

    case parts do
      %{"t" => t, "v1" => v1} -> {:ok, t, v1}
      _ -> :error
    end
  end

  defp sign(secret, timestamp, raw_body) do
    :hmac
    |> :crypto.mac(:sha256, secret, "#{timestamp}.#{raw_body}")
    |> Base.encode16(case: :lower)
  end

  defp secret_key, do: Keyword.get(config(), :secret_key)
  defp webhook_secret, do: Keyword.get(config(), :webhook_secret)

  defp config, do: Application.get_env(:cleaner_crm, CleanerCrm.Billing.StripeGateway, [])
end
