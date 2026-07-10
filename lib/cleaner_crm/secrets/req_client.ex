defmodule CleanerCrm.Secrets.ReqClient do
  @moduledoc """
  `ExAws.Request.HttpClient` adapter backed by `Req`.

  ExAws's default client is hackney `~> 1.x`, but this app's dependency
  tree already carries hackney 4.x (via httpoison), so the default is
  unusable. Req is already a first-class dependency here (Twilio
  delivery), making it the natural client. Only used by
  `CleanerCrm.Secrets` at boot.
  """

  @behaviour ExAws.Request.HttpClient

  @impl true
  def request(method, url, body, headers, http_opts) do
    # Retries are handled by CleanerCrm.Secrets' own bounded retry loop.
    # `decode_body: false` hands ExAws the body as a binary to parse
    # itself — but decompression must stay ON (`raw: true` would skip
    # it): req 0.5 requests gzip by default, and a still-gzipped body
    # crashes ExAws's JSON parse at boot (0x1F magic byte).
    # `http_opts` (ExAws's passthrough) lets tests inject `plug:`.
    case Req.request(
           [
             method: method,
             url: url,
             body: body || "",
             headers: headers,
             retry: false,
             decode_body: false
           ] ++ (http_opts || [])
         ) do
      {:ok, %Req.Response{status: status, headers: resp_headers, body: resp_body}} ->
        {:ok, %{status_code: status, headers: flatten_headers(resp_headers), body: resp_body}}

      {:error, reason} ->
        {:error, %{reason: reason}}
    end
  end

  # Req returns %{"name" => [v1, v2]}; ExAws expects [{name, value}].
  defp flatten_headers(headers) do
    for {name, values} <- headers, value <- List.wrap(values), do: {name, value}
  end
end
