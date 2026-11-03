defmodule CleanerCrmMcp.Tools.Scheduling.RegisterCleaner do
  use CleanerCrmMcp.Tool, name: "register_cleaner", mutates: true

  alias CleanerCrm.Scheduling
  alias CleanerCrmMcp.Tools.Scheduling.Shape

  @impl true
  def description,
    do: """
    Add a new cleaner to the account by name. MUTATES: creates a user (no login) and adds them as an account member.
    Returns {id, name}. Errors on a blank name.
    """

  @impl true
  def params,
    do: [
      %{name: "name", type: :string, required: true, description: "The cleaner's display name"}
    ]

  @impl true
  def example, do: ~s|return register_cleaner({ name = "Maria Lopez" })|

  @impl true
  def call(args, scope) do
    name = String.trim(args["name"])

    if name == "" do
      {:error, "name can't be blank"}
    else
      with {:ok, user} <- Scheduling.register_cleaner(scope, name), do: {:ok, Shape.cleaner(user)}
    end
  end
end
