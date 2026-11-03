defmodule CleanerCrmMcp.Tools.Quoting.GetQuote do
  use CleanerCrmMcp.Tool, name: "get_quote"

  alias CleanerCrm.Quoting
  alias CleanerCrmMcp.Tools.Quoting.Shape

  @impl true
  def description,
    do: """
    Get one quote by id, with its frozen line items.
    Returns the quote (status, total, sizes, items). Errors when the account has no such quote.
    """

  @impl true
  def params, do: [%{name: "id", type: :string, required: true, description: "The quote's id"}]

  @impl true
  def example, do: ~s|local q = get_quote({ id = "..." })\nreturn q.items|

  @impl true
  def call(%{"id" => id}, scope) do
    case Quoting.fetch_quote(scope, id) do
      nil -> {:error, "no quote with id #{id}"}
      quote -> {:ok, Shape.quote(quote)}
    end
  end
end
