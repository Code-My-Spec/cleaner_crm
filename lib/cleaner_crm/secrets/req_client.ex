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
  def request(method, url, body, headers, _http_opts) do
    # Retries are handled by CleanerCrm.Secrets' own bounded retry loop;
    # decompression is off because ExAws signs/parses the raw body.
    case Req.request(
           method: method,
           url: url,
           body: body || "",
           headers: headers,
           retry: false,
           decode_body: false,
           raw: true
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
