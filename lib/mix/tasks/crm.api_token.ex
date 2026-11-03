defmodule Mix.Tasks.Crm.ApiToken do
  @shortdoc "Creates an API token for a user (for the MCP server)"
  @moduledoc """
  Creates an API token for an existing user and prints it once.

      mix crm.api_token john@desertfirstcleaning.com

  Use it as `Authorization: Bearer <token>` against `/mcp`. The token acts as
  that user, in their first account (or the one named by `X-Account-Id`).
  """

  use Mix.Task
  use Boundary, classify_to: CleanerCrm

  @requirements ["app.start"]

  @impl true
  def run([email]) do
    case CleanerCrm.Users.get_user_by_email(email) do
      nil -> Mix.raise("no user with email #{email}")
      user -> Mix.shell().info(CleanerCrm.Users.create_api_token(user))
    end
  end

  def run(_), do: Mix.raise("usage: mix crm.api_token EMAIL")
end
