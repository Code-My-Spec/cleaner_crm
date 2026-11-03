defmodule CleanerCrmWeb.McpEndpointTest do
  @moduledoc """
  Drives `/mcp` the way an MCP client does (initialize → tools/list →
  tools/call) over the real router, auth plug and Anubis transport.
  """

  use CleanerCrmTest.ConnCase, async: false

  alias CleanerCrm.Accounts
  alias CleanerCrm.Users
  alias CleanerCrm.UsersFixtures

  @protocol "2025-06-18"

  setup do
    user = UsersFixtures.user_fixture()
    {:ok, account} = Accounts.create_account(Users.Scope.for_user(user), %{name: "MCP Test Co"})
    %{token: Users.create_api_token(user), account: account}
  end

  describe "authentication" do
    test "rejects a request without a token" do
      conn = post_json(build_conn(), nil, %{jsonrpc: "2.0", id: 1, method: "ping"})
      assert conn.status == 401
      assert %{"error" => %{"code" => -32_001}} = Jason.decode!(conn.resp_body)
    end

    test "rejects an unknown token" do
      conn = post_json(build_conn(), "not-a-real-token", %{jsonrpc: "2.0", id: 1, method: "ping"})
      assert conn.status == 401
    end
  end

  describe "an authenticated client" do
    setup %{token: token} do
      %{session: initialize!(token)}
    end

    test "sees exactly the two code-mode tools", %{token: token, session: session} do
      %{"result" => %{"tools" => tools}} = call!(token, session, "tools/list", %{})
      assert tools |> Enum.map(& &1["name"]) |> Enum.sort() == ["run_script", "tool_docs"]
    end

    test "tool_docs answers with the function index", %{token: token, session: session} do
      text = tool_text!(token, session, "tool_docs", %{})
      assert text =~ "list_jobs"
    end

    test "run_script runs Lua against the CRM in the caller's account", %{
      token: token,
      session: session
    } do
      text = tool_text!(token, session, "run_script", %{"script" => "return 40 + 2"})
      assert text =~ "42"

      text =
        tool_text!(token, session, "run_script", %{
          "script" =>
            ~s|local jobs = list_jobs({ from = "2026-01-01", to = "2026-12-31" })\nreturn #jobs|
        })

      assert text =~ "0"
    end

    test "a script error comes back as a tool error, not a transport error", %{
      token: token,
      session: session
    } do
      %{"result" => result} =
        call!(token, session, "tools/call", %{
          "name" => "run_script",
          "arguments" => %{"script" => "this is not lua"}
        })

      assert result["isError"] == true
    end
  end

  # --- a minimal MCP client over Phoenix.ConnTest ---

  defp initialize!(token) do
    conn =
      post_json(build_conn(), token, %{
        jsonrpc: "2.0",
        id: 1,
        method: "initialize",
        params: %{
          protocolVersion: @protocol,
          capabilities: %{},
          clientInfo: %{name: "ex_unit", version: "0"}
        }
      })

    assert conn.status == 200, conn.resp_body
    assert %{"result" => %{"serverInfo" => %{"name" => "cleaner-crm"}}} = decode(conn)
    [session] = get_resp_header(conn, "mcp-session-id")

    notified =
      post_json(
        build_conn(),
        token,
        %{jsonrpc: "2.0", method: "notifications/initialized"},
        session
      )

    assert notified.status in [200, 202]
    session
  end

  defp call!(token, session, method, params) do
    conn =
      post_json(
        build_conn(),
        token,
        %{jsonrpc: "2.0", id: System.unique_integer([:positive]), method: method, params: params},
        session
      )

    assert conn.status == 200, conn.resp_body
    decode(conn)
  end

  defp tool_text!(token, session, name, arguments) do
    %{"result" => %{"content" => content} = result} =
      call!(token, session, "tools/call", %{"name" => name, "arguments" => arguments})

    refute result["isError"], inspect(result)
    Enum.map_join(content, "\n", & &1["text"])
  end

  defp post_json(conn, token, body, session \\ nil) do
    conn
    |> put_req_header("accept", "application/json, text/event-stream")
    |> put_req_header("content-type", "application/json")
    |> put_req_header("mcp-protocol-version", @protocol)
    |> then(fn c ->
      if token, do: put_req_header(c, "authorization", "Bearer " <> token), else: c
    end)
    |> then(fn c -> if session, do: put_req_header(c, "mcp-session-id", session), else: c end)
    |> post("/mcp", Jason.encode!(body))
  end

  # Responses are plain JSON or a one-event SSE stream depending on the transport's choice.
  defp decode(conn) do
    body = conn.resp_body

    if String.contains?(Enum.join(get_resp_header(conn, "content-type")), "event-stream") do
      body
      |> String.split("\n")
      |> Enum.filter(&String.starts_with?(&1, "data:"))
      |> Enum.map(&(&1 |> String.trim_leading("data:") |> String.trim() |> Jason.decode!()))
      |> Enum.find(&Map.has_key?(&1, "id"))
    else
      Jason.decode!(body)
    end
  end
end
