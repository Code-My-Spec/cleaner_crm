defmodule CleanerCrm.Billing.ReceiptNotifier do
  @moduledoc """
  Emails the client a receipt once a card-on-file or payment-link
  charge has been submitted to Stripe — submitted, not confirmed; per
  the payments-stripe ADR the invoice itself only becomes `:paid` on
  the webhook.
  """

  import Swoosh.Email

  alias CleanerCrm.Billing.Invoice
  alias CleanerCrm.Mailer
  alias CleanerCrm.Money

  def deliver_receipt(email, %Invoice{} = invoice) when is_binary(email) do
    message =
      new()
      |> to(email)
      |> from(Application.fetch_env!(:cleaner_crm, :mailer_from))
      |> subject("Your receipt")
      |> text_body("""
      Thanks! We've charged #{Money.format_cents(invoice.amount_cents)} for your recent cleaning.

      This confirms the charge was submitted — you'll receive nothing further unless it's declined.
      """)

    Mailer.deliver(message)
  end
end
