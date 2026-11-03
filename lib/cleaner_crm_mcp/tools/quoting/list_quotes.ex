defmodule CleanerCrmMcp.Tools.Quoting.ListQuotes do
  use CleanerCrmMcp.Tool, name: "list_quotes"

  alias CleanerCrm.Quoting
  alias CleanerCrmMcp.Tools.Quoting.Shape

  @impl true
  def description,
    do: """
    List the account's quotes, newest first.
    Returns a list of quote summaries (id, client_name, client_id, pricing_model, status, total, sent_at). Use get_quote for line items. Errors on an unknown status.
    """

  @impl true
  def params,
    do: [
      %{name: "status", type: :string, required: false, description: "draft or sent"},
      %{
        name: "client_id",
        type: :string,
        required: false,
        description: "Only quotes for this client"
      },
      %{name: "limit", type: :integer, required: false, description: "Max results (default 50)"}
    ]

  @impl true
  def example, do: ~s|local qs = list_quotes({ status = "sent", limit = 5 })\nreturn #qs|

  @impl true
  def call(args, scope) do
    with {:ok, status} <- status(args["status"]),
         {:ok, client_id} <- Shape.check_uuid(args["client_id"], "client_id") do
      opts =
        [status: status, client_id: client_id, limit: args["limit"] || 50]
        |> Enum.reject(fn {_, v} -> is_nil(v) end)

      {:ok, scope |> Quoting.list_quotes(opts) |> Enum.map(&Shape.quote_summary/1)}
    end
  end

  defp status(nil), do: {:ok, nil}
  defp status("draft"), do: {:ok, :draft}
  defp status("sent"), do: {:ok, :sent}
  defp status(_), do: {:error, "status must be draft or sent"}
end
