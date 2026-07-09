# Swoosh.ApiClient.Finch

Finch-based ApiClient for Swoosh.

    config :swoosh, :api_client, Swoosh.ApiClient.Finch

In order to use `Finch` API client, you must start `Finch` and provide a :name.
Often in your supervision tree:

    children = [
      {Finch, name: Swoosh.Finch}
    ]

Or, in rare cases, dynamically:

    Finch.start_link(name: Swoosh.Finch)

If a name different from `Swoosh.Finch` is used, or you want to use an existing Finch instance,
you can provide the name via the config.

    config :swoosh,
      api_client: Swoosh.ApiClient.Finch,
      finch_name: My.Custom.Name