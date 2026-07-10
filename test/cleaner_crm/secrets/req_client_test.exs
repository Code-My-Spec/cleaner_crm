defmodule CleanerCrm.Secrets.ReqClientTest do
  # Guards the SSM-bootstrap boot path, which nothing else exercises in
  # test: a broken ReqClient only surfaces as a UAT/prod container that
  # cannot boot (it did once — req 0.5 ships gzip responses that
  # `raw: true` left compressed, crashing ExAws's JSON parse).
  use ExUnit.Case, async: true

  alias CleanerCrm.Secrets.ReqClient

  defp gzip_plug(conn) do
    body = ~s({"Parameters":[{"Name":"/cleaner_crm/uat/KEY","Value":"secret"}]})

    conn
    |> Plug.Conn.put_resp_header("content-encoding", "gzip")
    |> Plug.Conn.put_resp_content_type("application/x-amz-json-1.1")
    |> Plug.Conn.resp(200, :zlib.gzip(body))
  end

  defp plain_plug(conn) do
    conn
    |> Plug.Conn.put_resp_content_type("application/x-amz-json-1.1")
    |> Plug.Conn.resp(200, ~s({"Parameters":[]}))
  end

  test "decompresses a gzipped response body before handing it to ExAws" do
    {:ok, %{status_code: 200, body: body}} =
      ReqClient.request(:post, "http://ssm.test/", "{}", [{"content-type", "json"}],
        plug: &gzip_plug/1
      )

    assert body =~ "/cleaner_crm/uat/KEY"
    assert {:ok, %{"Parameters" => [_]}} = Jason.decode(body)
  end

  test "returns the body as an undecoded binary" do
    {:ok, %{status_code: 200, body: body}} =
      ReqClient.request(:post, "http://ssm.test/", "{}", [], plug: &plain_plug/1)

    assert is_binary(body)
  end
end
