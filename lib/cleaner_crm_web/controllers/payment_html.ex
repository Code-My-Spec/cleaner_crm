defmodule CleanerCrmWeb.PaymentHTML do
  @moduledoc """
  This module contains pages rendered by PaymentController.

  See the `payment_html` directory for all templates available.
  """
  use CleanerCrmWeb, :html

  embed_templates "payment_html/*"
end
