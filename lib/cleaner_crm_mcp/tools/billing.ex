defmodule CleanerCrmMcp.Tools.Billing do
  @moduledoc """
  Tool group: Billing: invoices, payments, tips and cancellation policies.

  Each tool is a module under `CleanerCrmMcp.Tools.Billing.*` implementing
  `CleanerCrmMcp.Tool`. List it in `tools/0` to make it callable from scripts.
  """

  @doc "Tool modules in this group, in documentation order."
  def tools,
    do: [
      __MODULE__.ListInvoices,
      __MODULE__.GetInvoice,
      __MODULE__.GenerateInvoiceForJob,
      __MODULE__.ListPayments,
      __MODULE__.GetPayment,
      __MODULE__.GetCancellationPolicy,
      __MODULE__.ListTips
    ]
end
