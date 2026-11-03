defmodule CleanerCrmMcp.Tools.Clients.GetClient do
  use CleanerCrmMcp.Tool, name: "get_client"

  alias CleanerCrm.{Clients, Scheduling}
  alias CleanerCrmMcp.Tools.Clients.Shape

  @impl true
  def description,
    do: """
    Get one client with their properties and a summary of recent and upcoming jobs.
    Returns the client fields plus `properties` (no access codes), `upcoming_jobs` (next 5) and `recent_jobs` (last 5).
    Errors when the client does not exist in your account.
    """

  @impl true
  def params,
    do: [%{name: "id", type: :string, required: true, description: "The client's id"}]

  @impl true
  def example, do: ~s|local c = get_client({ id = "..." })\nreturn #c.upcoming_jobs|

  @impl true
  def call(%{"id" => id}, scope) do
    with {:ok, client} <- Clients.fetch_client(scope, id) |> nf("client") do
      today = Date.utc_today()
      jobs = scope |> Scheduling.list_jobs() |> Enum.filter(&(&1.client_id == client.id))
      {upcoming, past} = Enum.split_with(jobs, &(Date.compare(&1.scheduled_date, today) != :lt))

      {:ok,
       client
       |> Shape.client()
       |> Map.merge(%{
         "properties" => scope |> Clients.list_properties(client) |> Enum.map(&Shape.property/1),
         "upcoming_jobs" => upcoming |> Enum.take(5) |> Enum.map(&Shape.job_line/1),
         "recent_jobs" => past |> Enum.reverse() |> Enum.take(5) |> Enum.map(&Shape.job_line/1)
       })}
    end
  end

  defp nf({:ok, _} = ok, _), do: ok
  defp nf(_, what), do: Shape.not_found(what)
end
