defmodule CleanerCrmWeb.FieldLive.ChecklistComponent do
  @moduledoc """
  A job's checklist, grouped by room, with live progress and a gate on
  job completion until every required item is checked or explicitly
  skipped with a reason.

  "Still needed before this job is done" is recomputed from the
  checklist on every update, not cached from the last failed
  completion attempt — so it clears live the moment a cleaner checks
  off (or skips) the last required item, without needing to press
  "Finish Job" again. Skipping asks for a reason inline (its own
  `<form>`, scoped to that item) rather than hardcoding one; the
  reason is persisted on the `ChecklistItem` for `QualityLive.Review`
  to show the owner.

  Each item renders as its own `CleanerCrmWeb.FieldLive.ChecklistItemComponent`
  so its before/after photo uploads stay independently scoped.
  Completing the job also generates its invoice, when
  `CleanerCrm.Billing` is present, and requests a post-visit review,
  when `CleanerCrm.Reviews` is present — read defensively per the
  moduledoc note on `CleanerCrm.Billing.generate_for_job/2` about
  hooks like these not existing yet everywhere they're called from.

  ## Assigns

  | Assign        | Type              | Required | Description                    |
  |---------------|-------------------|----------|----------------------------------|
  | id            | string            | yes      | LiveComponent DOM id              |
  | current_scope | `Scope.t()`       | yes      | caller scope                      |
  | job           | `Job.t()`         | yes      | the checklist's job (for billing) |
  | checklist     | `Checklist.t()`   | yes      | the job's checklist, items preloaded |

  Notifies the parent LiveView with `send(self(), :job_completed)`
  once the job is marked complete, so it can reload the job and
  checklist.

  ## Dependencies

  - `CleanerCrm.Quality`
  - `CleanerCrm.Billing`
  - `CleanerCrm.Reviews`
  """

  use CleanerCrmWeb, :live_component

  alias CleanerCrm.Billing
  alias CleanerCrm.Quality
  alias CleanerCrm.Reviews
  alias CleanerCrmWeb.FieldLive.ChecklistItemComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="card bg-base-100 border border-base-300 mb-4">
      <div class="card-body">
        <div class="flex justify-between items-center">
          <h3 class="card-title text-sm">Checklist</h3>
          <span data-test="checklist-progress">{elem(@progress, 0)} of {elem(@progress, 1)}</span>
        </div>

        <div
          :for={{room, items} <- @rooms}
          data-test={"checklist-room-#{room || "General"}"}
          class="mt-2"
        >
          <h4 :if={room} class="font-medium text-xs uppercase opacity-60">{room}</h4>
          <ul>
            <.live_component
              :for={item <- items}
              module={ChecklistItemComponent}
              id={"checklist-item-#{item.id}"}
              current_scope={@current_scope}
              item={item}
            />
          </ul>
        </div>

        <div
          :if={@incomplete != []}
          data-test="incomplete-required-tasks-warning"
          class="alert alert-warning mt-3 text-sm"
        >
          <div class="w-full">
            <p class="font-semibold">Still needed before this job is done:</p>
            <ul>
              <li :for={item <- @incomplete} class="flex flex-col gap-1 py-1">
                <div class="flex items-center gap-2">
                  {item.task}
                  <button
                    type="button"
                    data-test={"skip-task-#{item.id}-button"}
                    phx-click="show_skip_form"
                    phx-value-item-id={item.id}
                    phx-target={@myself}
                    class="btn btn-xs btn-ghost"
                  >
                    Skip with reason
                  </button>
                </div>

                <form
                  :if={@skip_form_item_id == item.id}
                  id={"skip-reason-form-#{item.id}"}
                  data-test={"skip-reason-form-#{item.id}"}
                  phx-submit="skip"
                  phx-target={@myself}
                  class="flex items-center gap-2"
                >
                  <input type="hidden" name="item-id" value={item.id} />
                  <input
                    type="text"
                    name="reason"
                    placeholder="Why was this skipped?"
                    data-test={"skip-reason-input-#{item.id}"}
                    class="input input-xs input-bordered flex-1"
                    required
                  />
                  <button
                    type="submit"
                    data-test={"skip-reason-confirm-#{item.id}"}
                    class="btn btn-xs"
                  >
                    Confirm skip
                  </button>
                  <button
                    type="button"
                    data-test={"skip-reason-cancel-#{item.id}"}
                    phx-click="cancel_skip_form"
                    phx-target={@myself}
                    class="btn btn-xs btn-ghost"
                  >
                    Cancel
                  </button>
                </form>
              </li>
            </ul>
          </div>
        </div>

        <.button
          :if={is_nil(@checklist.completed_at)}
          data-test="mark-complete-button"
          phx-click="mark_complete"
          phx-target={@myself}
          class="mt-3"
        >
          Finish Job
        </.button>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:rooms, Quality.group_by_room(assigns.checklist))
     |> assign(:progress, Quality.progress(assigns.checklist))
     |> assign(:incomplete, Quality.incomplete_required_items(assigns.checklist))
     |> assign_new(:skip_form_item_id, fn -> nil end)}
  end

  @impl true
  def handle_event("mark_complete", _params, socket) do
    scope = socket.assigns.current_scope

    case Quality.complete_job(scope, socket.assigns.checklist) do
      {:ok, _completed} ->
        maybe_generate_invoice(scope, socket.assigns.job)
        maybe_request_review(socket.assigns.job)
        send(self(), :job_completed)
        {:noreply, assign(socket, :incomplete, [])}

      {:error, {:incomplete_required_tasks, incomplete}} ->
        {:noreply, assign(socket, :incomplete, incomplete)}
    end
  end

  def handle_event("show_skip_form", %{"item-id" => item_id}, socket) do
    {:noreply, assign(socket, :skip_form_item_id, item_id)}
  end

  def handle_event("cancel_skip_form", _params, socket) do
    {:noreply, assign(socket, :skip_form_item_id, nil)}
  end

  def handle_event("skip", %{"item-id" => item_id, "reason" => reason}, socket) do
    item = Enum.find(socket.assigns.checklist.items, &(&1.id == item_id))

    case Quality.skip_checklist_item(socket.assigns.current_scope, item, reason) do
      {:ok, _item} ->
        send(self(), :checklist_changed)
        {:noreply, assign(socket, :skip_form_item_id, nil)}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  # Not every account has `CleanerCrm.Billing` wired to this hook yet
  # (see its moduledoc) — read defensively so this component never
  # needs to change again once it lands.
  defp maybe_generate_invoice(scope, job) do
    if Code.ensure_loaded?(Billing) and function_exported?(Billing, :generate_for_job, 2) do
      Billing.generate_for_job(scope, job)
    end
  end

  # Not every account has `CleanerCrm.Reviews` wired to this hook yet
  # (see the moduledoc) — read defensively so this component never
  # needs to change again once it lands.
  defp maybe_request_review(job) do
    if Code.ensure_loaded?(Reviews) and function_exported?(Reviews, :request_review, 1) do
      Reviews.request_review(job)
    end
  end
end
