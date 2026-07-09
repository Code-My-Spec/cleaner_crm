defmodule CleanerCrmWeb.ClientLive.FormComponent do
  @moduledoc """
  Create/edit a client's name and billing preference.

  On successful save, navigates to the client's own page directly
  (rather than notifying the parent to do it) — a parent's `handle_info`
  reacting to a component's self-sent message runs one mailbox message
  after the "save" event's own reply, too late for
  `Phoenix.LiveViewTest.render_submit/1` to observe the redirect.

  ## Assigns

  | Assign        | Type          | Required | Description                          |
  |---------------|---------------|----------|----------------------------------------|
  | id            | string        | yes      | LiveComponent DOM id                   |
  | current_scope | `Scope.t()`   | yes      | caller scope, used for all context calls |
  | action        | `:new \\| :edit` | yes   | which mode the form is in              |
  | client        | `Client.t()`  | yes      | `%Client{}` (blank for `:new`, loaded for `:edit`) |

  ## Dependencies

  - `CleanerCrm.Clients`
  """

  use CleanerCrmWeb, :live_component

  alias CleanerCrm.Clients

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <.header>{form_title(@action)}</.header>

      <.form
        for={@form}
        id={"#{@id}-form"}
        data-test="client-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:card_on_file]} type="checkbox" label="Card on file" />

        <footer>
          <.button phx-disable-with="Saving...">Save Client</.button>
        </footer>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{client: client} = assigns, socket) do
    changeset = Clients.change_client(assigns.current_scope, client)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate", %{"client" => client_params}, socket) do
    changeset =
      socket.assigns.current_scope
      |> Clients.change_client(socket.assigns.client, client_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"client" => client_params}, socket) do
    save_client(socket, socket.assigns.action, client_params)
  end

  defp save_client(socket, :new, params) do
    case Clients.create_client(socket.assigns.current_scope, params) do
      {:ok, client} ->
        {:noreply, push_navigate(socket, to: ~p"/clients/#{client}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_client(socket, :edit, params) do
    case Clients.update_client(socket.assigns.current_scope, socket.assigns.client, params) do
      {:ok, client} ->
        {:noreply, push_navigate(socket, to: ~p"/clients/#{client}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp form_title(:new), do: "New Client"
  defp form_title(:edit), do: "Edit Client"
end
