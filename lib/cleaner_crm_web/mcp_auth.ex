defmodule CleanerCrmWeb.McpAuth do
  @moduledoc """
  Authenticates MCP requests by API token and puts the caller's scope in
  `conn.assigns.current_scope`, which Anubis copies into every tool's frame.

      Authorization: Bearer <token from `mix crm.api_token EMAIL`>
      X-Account-Id: <optional account id; defaults to the user's first account>

  Anything else is a 401 with a JSON-RPC-shaped body.
  """

  import Plug.Conn

  alias CleanerCrm.Accounts
  alias CleanerCrm.Users
  alias CleanerCrm.Users.Scope

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         %Users.User{} = user <- Users.get_user_by_api_token(String.trim(token)),
         %Scope{} = scope <-
           with_account(Scope.for_user(user), get_req_header(conn, "x-account-id")) do
      assign(conn, :current_scope, scope)
    else
      _ -> unauthorized(conn)
    end
  end

  defp with_account(scope, requested) do
    accounts = Accounts.list_accounts(scope)

    account =
      case requested do
        [id | _] -> Enum.find(accounts, &(to_string(&1.id) == id))
        [] -> List.first(accounts)
      end

    if account, do: %{scope | active_account: account, active_account_id: account.id}
  end

  defp unauthorized(conn) do
    body =
      Jason.encode!(%{
        jsonrpc: "2.0",
        error: %{code: -32_001, message: "unauthorized: send Authorization: Bearer <api token>"},
        id: nil
      })

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, body)
    |> halt()
  end
end
