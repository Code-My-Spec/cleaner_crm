{:ok, _} = Application.ensure_all_started(:wallaby)
Application.put_env(:wallaby, :base_url, CleanerCrmWeb.Endpoint.url())

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(CleanerCrm.Repo, :manual)
