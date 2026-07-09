defmodule CleanerCrmWeb.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CleanerCrmWeb.Telemetry,
      CleanerCrm.Repo,
      {DNSCluster, query: Application.get_env(:cleaner_crm, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: CleanerCrm.PubSub},
      CleanerCrm.Vault,
      CleanerCrm.Integrations.OAuthStateStore,
      {Oban, Application.fetch_env!(:cleaner_crm, Oban)},
      # Start a worker by calling: CleanerCrm.Worker.start_link(arg)
      # {CleanerCrm.Worker, arg},
      # Start to serve requests, typically the last entry
      CleanerCrmWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CleanerCrm.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CleanerCrmWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
