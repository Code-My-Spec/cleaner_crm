defmodule CleanerCrmWeb.SettingsLive.BookingPolicy do
  @moduledoc """
  Owner-only editor for the account's `CleanerCrm.Portal.CancellationPolicy`
  (story 851 follow-up, issue db25b304): the notice-window hours, the
  late and same-day cancellation fees, and the policy text shown to a
  client at booking and in their portal. Before this page existed,
  the only way to set any of it was a direct database edit.

  Fees are entered in dollars and converted to cents before they ever
  reach the changeset — `CancellationPolicy` itself only stores
  integer cents — mirroring `CleanerCrmWeb.QuoteLive.RateCard`'s own
  rate inputs.

  An account with no saved policy yet edits the same fresh, unsaved,
  all-zero-fee default that `CleanerCrm.Portal.get_cancellation_policy/1`
  hands the portal itself — the portal keeps working with those
  defaults whether or not this page has ever been visited.

  Also hosts the public booking storefront toggle
  (`CleanerCrm.Accounts.set_storefront/2`) — the account
  `CleanerCrm.Booking.public_scope/0` prices `/book` against. Unlike
  the cancellation policy above, this is owner-only (see
  `CleanerCrm.Authorization`): flipping it can silently steal the
  public storefront from another account, so an admin viewing this
  page sees its current value but can't change it.

  ## Route

    * `/app/settings/booking` (`:edit`) — office-only, gated the same as
      every other office surface (`CleanerCrmWeb.RequireOfficeRole`).

  ## Dependencies

  - `CleanerCrm.Accounts`
  - `CleanerCrm.Portal`
  """

  use CleanerCrmWeb, :live_view

  alias CleanerCrm.Accounts
  alias CleanerCrm.Portal
  alias CleanerCrm.Portal.CancellationPolicy

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Cancellation Policy
        <:subtitle>
          Notice window and fees enforced on self-service reschedule/cancel in the client portal
        </:subtitle>
      </.header>

      <div class="card bg-base-100 border border-base-300 mb-6">
        <div class="card-body">
          <h2 class="card-title">Public Booking Storefront</h2>
          <p class="text-sm text-base-content/70">
            Only one company can be the public <code>/book</code> storefront at a time.
          </p>

          <label class="label cursor-pointer justify-start gap-3">
            <input
              type="checkbox"
              class="toggle toggle-primary"
              checked={@account.storefront}
              disabled={!@is_owner}
              phx-click="toggle_storefront"
              data-test="storefront-toggle"
            />
            <span>Use this company as the public booking storefront</span>
          </label>

          <p
            :if={@account.storefront}
            data-test="storefront-active-note"
            class="text-sm text-success"
          >
            This company is currently the public <code>/book</code> storefront.
          </p>
          <p :if={!@is_owner} class="text-sm text-base-content/70">
            Only the account owner can change this.
          </p>
        </div>
      </div>

      <.form
        for={@form}
        id="cancellation-policy-form"
        data-test="cancellation-policy-form"
        phx-change="validate"
        phx-submit="save"
      >
        <div class="card bg-base-100 border border-base-300 mb-6">
          <div class="card-body">
            <.input
              field={@form[:notice_window_hours]}
              type="number"
              min="0"
              label="Notice window (hours)"
              data-test="notice-window-input"
            />
            <p class="text-sm text-base-content/70 mb-4">
              How much notice a client must give to cancel or reschedule free of the late fee.
            </p>

            <.input
              type="number"
              step="0.01"
              min="0"
              name="policy[late_fee]"
              id={@form[:late_fee_cents].id}
              label="Late cancellation fee ($)"
              value={@fee_inputs.late_fee}
              errors={field_errors(@form[:late_fee_cents])}
              data-test="late-fee-input"
            />
            <.input
              type="number"
              step="0.01"
              min="0"
              name="policy[same_day_fee]"
              id={@form[:same_day_fee_cents].id}
              label="Same-day cancellation fee ($)"
              value={@fee_inputs.same_day_fee}
              errors={field_errors(@form[:same_day_fee_cents])}
              data-test="same-day-fee-input"
            />
            <p class="text-sm text-base-content/70 mb-4">
              Charged instead of the late fee when a visit is cancelled the same day it's scheduled.
            </p>

            <.input
              field={@form[:policy_text]}
              type="textarea"
              label="Policy text shown to clients"
              data-test="policy-text-input"
            />
          </div>
        </div>

        <footer class="flex justify-end">
          <.button
            phx-disable-with="Saving..."
            variant="primary"
            data-test="save-cancellation-policy-button"
          >
            Save Policy
          </.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope
    policy = Portal.get_cancellation_policy(scope.active_account_id)
    account = Accounts.get_account!(scope, scope.active_account_id)
    is_owner = Accounts.get_user_role(scope, scope.user.id, scope.active_account_id) == :owner

    {:ok,
     socket
     |> assign(:page_title, "Cancellation Policy")
     |> assign(:policy, policy)
     |> assign(:fee_inputs, fee_inputs(policy))
     |> assign(:account, account)
     |> assign(:is_owner, is_owner)
     |> assign(:form, to_form(Portal.change_cancellation_policy(scope, policy), as: :policy))}
  end

  @impl true
  def handle_event("toggle_storefront", _params, socket) do
    scope = socket.assigns.current_scope

    case Accounts.set_storefront(scope, !socket.assigns.account.storefront) do
      {:ok, updated} ->
        {:noreply,
         socket
         |> assign(:account, updated)
         |> put_flash(:info, storefront_flash(updated))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Couldn't update the storefront setting.")}
    end
  end

  @impl true
  def handle_event("validate", %{"policy" => params}, socket) do
    {:noreply, apply_params(socket, params, :validate)}
  end

  def handle_event("save", %{"policy" => params}, socket) do
    scope = socket.assigns.current_scope
    {attrs, fee_inputs} = build_attrs(params)

    case Portal.set_cancellation_policy(scope, attrs) do
      {:ok, updated} ->
        {:noreply,
         socket
         |> put_flash(:info, "Cancellation policy updated.")
         |> assign(:policy, updated)
         |> assign(:fee_inputs, fee_inputs(updated))
         |> assign(:form, to_form(Portal.change_cancellation_policy(scope, updated), as: :policy))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:fee_inputs, fee_inputs)
         |> assign(:form, to_form(changeset, as: :policy))}
    end
  end

  defp apply_params(socket, params, action) do
    {attrs, fee_inputs} = build_attrs(params)

    changeset =
      socket.assigns.current_scope
      |> Portal.change_cancellation_policy(socket.assigns.policy, attrs)
      |> Map.put(:action, action)

    socket
    |> assign(:fee_inputs, fee_inputs)
    |> assign(:form, to_form(changeset, as: :policy))
  end

  # Builds the changeset attrs (dollar inputs converted to cents)
  # alongside the raw dollar strings to redisplay — the same pair
  # both `validate` and `save` need, so both event handlers go through
  # here, mirroring `CleanerCrmWeb.QuoteLive.RateCard#build_attrs/2`.
  defp build_attrs(params) do
    fee_inputs = %{
      late_fee: Map.get(params, "late_fee", ""),
      same_day_fee: Map.get(params, "same_day_fee", "")
    }

    attrs = %{
      "notice_window_hours" => Map.get(params, "notice_window_hours"),
      "late_fee_cents" => dollars_to_cents(fee_inputs.late_fee),
      "same_day_fee_cents" => dollars_to_cents(fee_inputs.same_day_fee),
      "policy_text" => Map.get(params, "policy_text")
    }

    {attrs, fee_inputs}
  end

  defp storefront_flash(%{storefront: true}),
    do: "This company is now the public booking storefront."

  defp storefront_flash(%{storefront: false}),
    do: "This company is no longer the public booking storefront."

  defp fee_inputs(%CancellationPolicy{} = policy) do
    %{
      late_fee: cents_to_dollars(policy.late_fee_cents),
      same_day_fee: cents_to_dollars(policy.same_day_fee_cents)
    }
  end

  defp cents_to_dollars(nil), do: ""

  defp cents_to_dollars(cents),
    do: cents |> Decimal.new() |> Decimal.div(Decimal.new(100)) |> Decimal.to_string(:normal)

  # An unparseable dollar amount (or a blank input) becomes `nil`
  # rather than raising, left for `CancellationPolicy.changeset/2`'s
  # own `validate_required`/`validate_number` to reject.
  defp dollars_to_cents(dollars) when is_binary(dollars) do
    case Decimal.parse(String.trim(dollars)) do
      {decimal, ""} ->
        decimal |> Decimal.mult(100) |> Decimal.round(0, :half_up) |> Decimal.to_integer()

      _ ->
        nil
    end
  end

  defp dollars_to_cents(_dollars), do: nil

  defp field_errors(field) do
    if Phoenix.Component.used_input?(field),
      do: Enum.map(field.errors, &translate_error/1),
      else: []
  end
end
