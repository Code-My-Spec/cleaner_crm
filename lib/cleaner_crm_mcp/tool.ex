defmodule CleanerCrmMcp.Tool do
  @moduledoc """
  A function a `run_script` Lua script can call, e.g. `list_jobs({ from = "2026-11-03" })`.

  ## Writing one

      defmodule CleanerCrmMcp.Tools.Scheduling.GetJob do
        use CleanerCrmMcp.Tool, name: "get_job"

        @impl true
        def description,
          do: \"\"\"
          Get one job by job number or id, with its client, property and cleaner.
          Returns nil and an error when there is no such job.
          \"\"\"

        @impl true
        def params,
          do: [
            %{name: "job_number", type: :integer, required: false, description: "The job's number, e.g. 1042"},
            %{name: "id", type: :string, required: false, description: "The job's id"}
          ]

        @impl true
        def example, do: ~s|local job = get_job({ job_number = 1042 })\\nreturn job.client.name|

        @impl true
        def call(args, scope) do
          ...
          {:ok, Present.job(job)}
        end
      end

  Then add the module to its group's `tools/0` (e.g. `CleanerCrmMcp.Tools.Scheduling`).

  ## Contract

    * `description/0`: the first line is the one-line summary shown in the
      `tool_docs` index; the rest is shown on the tool's own page. Say what it
      returns and when it errors.
    * `params/0`: declared parameters. `run_script` validates and coerces
      arguments against these BEFORE `call/2` runs (`CleanerCrmMcp.Catalog.coerce/2`),
      so `call/2` receives a map with string keys, required keys present, and
      values already converted: `:date` → `Date`, `:time` → `Time`,
      `:integer`, `:number`, `:boolean`, `:string`, `:list`, `:map`.
      Optional params that were not given are absent from the map.
    * `call/2` returns `{:ok, value}` with a value made of maps, lists, strings,
      numbers, booleans and nil (use `CleanerCrmMcp.Present` — never return
      structs), or `{:error, reason}` where reason is a string, atom or
      changeset (rendered for the script as an error table).
    * `mutates: true` in `use` marks tools that write. Their description must
      say what they change.
  """

  alias CleanerCrm.Users.Scope

  @type param_type :: :string | :integer | :number | :boolean | :date | :time | :list | :map
  @type param :: %{
          required(:name) => String.t(),
          required(:type) => param_type(),
          required(:description) => String.t(),
          optional(:required) => boolean()
        }

  @callback name() :: String.t()
  @callback description() :: String.t()
  @callback params() :: [param()]
  @callback example() :: String.t()
  @callback mutates?() :: boolean()
  @callback call(args :: %{optional(String.t()) => term()}, scope :: Scope.t()) ::
              {:ok, term()} | {:error, term()}

  defmacro __using__(opts) do
    name = Keyword.fetch!(opts, :name)
    mutates = Keyword.get(opts, :mutates, false)

    quote do
      @behaviour CleanerCrmMcp.Tool
      alias CleanerCrmMcp.Args
      alias CleanerCrmMcp.Present

      @impl true
      def name, do: unquote(name)

      @impl true
      def mutates?, do: unquote(mutates)

      @impl true
      def example, do: ""

      @impl true
      def params, do: []

      defoverridable example: 0, params: 0
    end
  end

  @doc "The one-line summary of a tool (first line of its description)."
  def summary(module) do
    module.description() |> String.split("\n", parts: 2) |> hd() |> String.trim()
  end
end
