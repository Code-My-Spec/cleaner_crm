defmodule CleanerCrm.Billing.StripeGateway do
  @moduledoc """
  Hides the Stripe API behind two operations: submitting a charge as a
  PaymentIntent, and verifying an inbound webhook request. `CleanerCrm.Billing`
  calls through the configured adapter — `Test` in test (see
  `config/test.exs`), `Live` everywhere else — so a test never reaches
  the real Stripe API, and the real adapter is the only one that ever
  checks a webhook signature.

  Configure the adapter and (for `Live`) credentials with:

      config :cleaner_crm, CleanerCrm.Billing.StripeGateway,
        adapter: CleanerCrm.Billing.StripeGateway.Live,
        secret_key: System.get_env("STRIPE_SECRET_KEY"),
        webhook_secret: System.get_env("STRIPE_WEBHOOK_SECRET")
  """

  @type charge_params :: %{
          required(:amount_cents) => pos_integer(),
          optional(:payment_method) => String.t(),
          optional(:confirm) => boolean(),
          optional(:off_session) => boolean(),
          optional(:metadata) => map()
        }

  @doc """
  `confirm: false` (or simply omitting `:payment_method`) leaves the
  intent unconfirmed — the booking-acceptance page's Stripe Elements
  flow (`CleanerCrmWeb.BookingLive.Accept`) needs the returned
  `client_secret` to confirm the card client-side. Every other caller
  (card-on-file charges, `/pay/:token`) still passes a
  `:payment_method` and gets a synchronously confirmed intent, exactly
  as before.
  """
  @callback create_payment_intent(charge_params()) ::
              {:ok, %{id: String.t(), status: String.t(), client_secret: String.t() | nil}}
              | {:error, map()}

  @callback verify_webhook_event(Plug.Conn.t()) :: {:ok, map()} | {:error, atom()}

  def create_payment_intent(params), do: adapter().create_payment_intent(params)

  def verify_webhook_event(conn), do: adapter().verify_webhook_event(conn)

  defp adapter do
    :cleaner_crm
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:adapter, __MODULE__.Live)
  end
end
