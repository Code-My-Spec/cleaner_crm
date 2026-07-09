defmodule CleanerCrmWeb.ClientLive.Index do
  @moduledoc """
  Lists the account's active clients and hosts the new-client form.

  ## Dependencies

  - `CleanerCrm.Clients`
  """

  use CleanerCrmWeb, :live_view

  alias CleanerCrm.Clients
  alias CleanerCrm.Clients.Client
  alias CleanerCrmWeb.ClientLive.FormComponent

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Clients
        <:subtitle>Manage your clients and their properties</:subtitle>
        <:actions>
          <.button navigate={~p"/clients/new"} variant="primary">
            <.icon name="hero-plus" class="size-4 mr-1" /> New Client
          </.button>
        </:actions>
      </.header>

      <div :if={@live_action == :new} class="card bg-base-100 border border-base-300 mb-6">
        <div class="card-body">
          <.live_component
            module={FormComponent}
            id="client-form"
            current_scope={@current_scope}
            action={:new}
            client={%Client{}}
          />
        </div>
      </div>

      <p :if={Enum.empty?(@clients)} class="text-center py-12 text-base-content/70">
        No clients yet.
      </p>

      <.table :if={Enum.any?(@clients)} id="clients" rows={@clients}>
        <:col :let={client} label="Name">{client.name}</:col>
        <:col :let={client} label="Card on file">
          {if client.card_on_file, do: "Yes", else: "No"}
        </:col>
        <:action :let={client}>
          <.link navigate={~p"/clients/#{client}"} class="btn btn-sm btn-ghost">View</.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :clients, Clients.list_active_clients(socket.assigns.current_scope))}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :page_title, page_title(socket.assigns.live_action))}
  end

  defp page_title(:index), do: "Clients"
  defp page_title(:new), do: "New Client"
end
