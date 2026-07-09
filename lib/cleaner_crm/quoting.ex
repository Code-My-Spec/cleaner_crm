defmodule CleanerCrm.Quoting do
  @moduledoc """
  Quotes built from the account's rate card using per-room, per-sqft,
  or hourly pricing models.

  Every function is scoped to the caller's active account. A quote is
  built up in memory (see `CleanerCrm.Quoting.Pricing`) and only ever
  persisted at the moment it's sent — `send_quote/3` freezes the rate
  card's current rates into the quote's line items, so later rate-card
  edits never alter an already-sent quote.
  """

  import Ecto.Query, warn: false

  alias CleanerCrm.Repo
  alias CleanerCrm.Users.Scope
  alias CleanerCrm.Audit.Recorder
  alias CleanerCrm.Quoting.{Quote, QuoteItem, RateCard, Pricing}

  ## Rate card

  @doc """
  Returns the account's rate card, creating a blank one on first use.
  """
  def get_or_create_rate_card(%Scope{active_account_id: account_id})
      when not is_nil(account_id) do
    case Repo.get_by(RateCard, account_id: account_id) do
      nil -> Repo.insert!(%RateCard{account_id: account_id})
      rate_card -> rate_card
    end
  end

  def change_rate_card(%Scope{}, %RateCard{} = rate_card, attrs \\ %{}) do
    RateCard.changeset(rate_card, attrs)
  end

  def update_rate_card(%Scope{active_account_id: account_id}, %RateCard{} = rate_card, attrs)
      when not is_nil(account_id) do
    rate_card
    |> RateCard.changeset(attrs)
    |> Repo.update()
  end

  ## Quotes

  def change_quote(%Scope{}, %Quote{} = quote, attrs \\ %{}) do
    Quote.changeset(quote, attrs)
  end

  @doc """
  Lists the account's quotes, most recently sent first.
  """
  def list_quotes(%Scope{active_account_id: account_id}) when not is_nil(account_id) do
    Quote
    |> where([q], q.account_id == ^account_id)
    |> order_by([q], desc: q.inserted_at)
    |> Repo.all()
  end

  def get_quote!(%Scope{active_account_id: account_id}, id) when not is_nil(account_id) do
    Quote
    |> where([q], q.account_id == ^account_id)
    |> preload(:quote_items)
    |> Repo.get!(id)
  end

  @doc """
  Finalizes a draft quote against the current rate card: prices every
  line item, then inserts the quote and its `CleanerCrm.Quoting.QuoteItem`s
  together, freezing the rates and amounts at this moment.

  Refuses with `{:error, :not_finalizable}` when any priced line item
  is missing a rate on the rate card, or the total isn't positive — a
  sent quote can never be a zero-dollar or partially-rated quote.
  """
  def send_quote(
        %Scope{active_account_id: account_id} = scope,
        %Quote{} = draft,
        %RateCard{} = rate_card
      )
      when not is_nil(account_id) do
    line_items = Pricing.line_items(rate_card, draft)

    if Pricing.finalizable?(line_items) do
      insert_sent_quote(scope, account_id, draft, line_items)
    else
      {:error, :not_finalizable}
    end
  end

  defp insert_sent_quote(scope, account_id, draft, line_items) do
    quote_attrs = %{
      client_id: draft.client_id,
      client_name: draft.client_name,
      client_phone: draft.client_phone,
      pricing_model: draft.pricing_model,
      bedroom_count: draft.bedroom_count,
      bathroom_count: draft.bathroom_count,
      square_feet: draft.square_feet,
      hours: draft.hours,
      status: :sent,
      total_cents: Pricing.total_cents(line_items),
      sent_at: DateTime.utc_now()
    }

    Repo.transaction(fn ->
      with {:ok, quote} <-
             %Quote{account_id: account_id} |> Quote.changeset(quote_attrs) |> Repo.insert(),
           {:ok, _items} <- insert_quote_items(quote, line_items) do
        Recorder.record(scope, "quote_sent", "Quote", quote.id, %{}, %{
          "total_cents" => quote.total_cents
        })

        quote
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  defp insert_quote_items(quote, line_items) do
    Enum.reduce_while(line_items, {:ok, []}, fn line_item, {:ok, acc} ->
      case %QuoteItem{quote_id: quote.id} |> QuoteItem.changeset(line_item) |> Repo.insert() do
        {:ok, quote_item} -> {:cont, {:ok, [quote_item | acc]}}
        {:error, _changeset} = error -> {:halt, error}
      end
    end)
  end
end
