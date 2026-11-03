defmodule CleanerCrmMcp.Tools.Billing.ListTips do
  use CleanerCrmMcp.Tool, name: "list_tips"

  alias CleanerCrm.Portal
  alias CleanerCrmMcp.Tools.Billing.Shape

  @impl true
  def description,
    do: """
    List tips clients paid cleaners, newest first.
    Returns tips (id, amount, cleaner_id, cleaner_name, invoice_id, inserted_at) (no totals; sum them in the script). from/to are inclusive dates.
    """

  @impl true
  def params,
    do: [
      %{
        name: "cleaner_id",
        type: :integer,
        required: false,
        description: "Only tips for this cleaner (user id)"
      },
      %{name: "from", type: :date, required: false, description: "On or after, YYYY-MM-DD"},
      %{name: "to", type: :date, required: false, description: "On or before, YYYY-MM-DD"},
      %{name: "limit", type: :integer, required: false, description: "Max results (default 100)"}
    ]

  @impl true
  def example, do: ~s|local tips = list_tips({ from = "2026-11-01" })\nreturn #tips|

  @impl true
  def call(args, scope) do
    opts =
      Shape.compact(
        cleaner_id: args["cleaner_id"],
        from: args["from"],
        to: args["to"],
        limit: args["limit"]
      )

    {:ok, scope |> Portal.list_tips(opts) |> Enum.map(&Shape.tip/1)}
  end
end
