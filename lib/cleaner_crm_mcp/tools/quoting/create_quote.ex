defmodule CleanerCrmMcp.Tools.Quoting.CreateQuote do
  use CleanerCrmMcp.Tool, name: "create_quote", mutates: true

  alias CleanerCrm.Quoting
  alias CleanerCrm.Quoting.Quote
  alias CleanerCrmMcp.Tools.Quoting.Shape

  @impl true
  def description,
    do: """
    Price and save a quote (status "sent") for a client or lead.
    Writes a new quote with line items priced from the CURRENT rate card, frozen at this moment. Quotes are only ever persisted as sent, so there is no draft; it does not message the client. Use estimate_price first to preview.
    Returns the saved quote with items. Errors when a needed rate is missing from the rate card, the total is not positive, or client_id is not valid.
    """

  @impl true
  def params,
    do:
      Shape.size_params() ++
        [
          %{
            name: "client_id",
            type: :string,
            required: false,
            description: "An existing client's id"
          },
          %{
            name: "client_name",
            type: :string,
            required: false,
            description: "Name of a lead who is not a client yet"
          },
          %{name: "client_phone", type: :string, required: false, description: "Lead's phone"}
        ]

  @impl true
  def example,
    do:
      ~s|local q = create_quote({ client_name = "Dana", bedrooms = 2, bathrooms = 1 })\nreturn q.total|

  @impl true
  def call(args, scope) do
    with {:ok, model} <- Shape.resolve_model(args) do
      draft =
        struct(
          Quote,
          args
          |> Shape.size_attrs()
          |> Map.merge(%{pricing_model: model})
          |> Map.merge(Args.take(args, ~w(client_id client_name client_phone)))
        )

      rate_card = Quoting.get_or_create_rate_card(scope)

      case Quoting.send_quote(scope, draft, rate_card) do
        {:ok, quote} ->
          {:ok, Shape.quote(Quoting.fetch_quote(scope, quote.id))}

        {:error, :not_finalizable} ->
          {:error,
           "cannot price this quote: the rate card is missing a rate for the chosen model, nothing was entered, or the total is zero. See get_rate_card."}

        {:error, other} ->
          {:error, other}
      end
    end
  end
end
