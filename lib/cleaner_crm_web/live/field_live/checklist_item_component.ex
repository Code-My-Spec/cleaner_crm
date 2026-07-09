defmodule CleanerCrmWeb.FieldLive.ChecklistItemComponent do
  @moduledoc """
  A single checklist task: check it off, and attach before/after photo
  proof.

  Each task gets its own stateful component instance so its
  `:before_photo`/`:after_photo` uploads are scoped independently per
  task — a job's checklist can carry many tasks, each needing its own
  before/after slot, uploaded and consumed on its own.

  ## Offline-tolerant uploads

  A `CleanerCrm.Quality.Photo` row is created in `:pending` state the
  moment an upload starts — its first progress callback, before any
  bytes have landed in storage — and flipped to `:uploaded` only once
  the file finishes. If the connection drops (or this LiveView process
  itself restarts) before that flip, the pending row survives in the
  database: the next time this component mounts for that task, it
  finds the still-pending row (instead of creating a duplicate) and
  shows a "tap to retry" affordance that re-opens the same file picker.

  This is a manual retry, not true offline queuing — capturing a photo
  with no signal at all and having it upload itself once connectivity
  returns, with no action from the cleaner, would need client-side
  storage (e.g. a service worker or local queue) that a plain
  LiveView-uploads implementation doesn't have. That's out of scope
  here; a dropped upload waits, visibly, for the cleaner to tap retry.

  ## Assigns

  | Assign        | Type            | Required | Description                       |
  |---------------|-----------------|----------|------------------------------------|
  | id            | string          | yes      | LiveComponent DOM id                |
  | current_scope | `Scope.t()`     | yes      | caller scope, used for all context calls |
  | item          | `ChecklistItem.t()` | yes | the checklist item this instance renders |

  Notifies the parent LiveView with `send(self(), :checklist_changed)`
  after any change, so it can reload the checklist and pass fresh
  items back down.

  ## Dependencies

  - `CleanerCrm.Quality`
  """

  use CleanerCrmWeb, :live_component

  alias CleanerCrm.Quality

  @impl true
  def render(assigns) do
    ~H"""
    <li id={@id} class="py-2 border-b border-base-200 last:border-none">
      <div class="flex items-start gap-2">
        <button
          type="button"
          data-test={"checklist-item-#{@item.id}"}
          phx-click="toggle"
          phx-target={@myself}
          class={["btn btn-sm btn-circle btn-outline shrink-0", @item.checked && "btn-success"]}
        >
          <.icon :if={@item.checked} name="hero-check" class="size-4" />
        </button>

        <div class="flex-1">
          <p class={@item.checked && "line-through opacity-60"}>
            {@item.task}
            <span :if={@item.skipped} class="badge badge-ghost badge-xs ml-1">Skipped</span>
          </p>

          <div class="flex gap-4 mt-1 text-xs">
            <.photo_zone kind={:before} item={@item} upload={@uploads.before_photo} myself={@myself} />
            <.photo_zone kind={:after} item={@item} upload={@uploads.after_photo} myself={@myself} />
          </div>
        </div>
      </div>
    </li>
    """
  end

  attr :kind, :atom, required: true
  attr :item, :map, required: true
  attr :upload, :map, required: true
  attr :myself, :any, required: true

  defp photo_zone(assigns) do
    assigns =
      assigns
      |> assign(:photo, existing_photo(assigns.item, assigns.kind))
      |> assign(:retry?, not is_nil(existing_pending_photo(assigns.item, assigns.kind)))

    ~H"""
    <form
      id={"task-#{@item.id}-#{@kind}-photo-form"}
      data-test={"task-#{@item.id}-#{@kind}-photo-form"}
      phx-change="noop"
      phx-target={@myself}
    >
      <label class="cursor-pointer">
        <.live_file_input upload={@upload} />

        <span :if={is_nil(@photo) and pending?(@upload)} data-test={"task-#{@item.id}-photo-pending"}>
          Uploading…
        </span>

        <span
          :if={is_nil(@photo) and not pending?(@upload) and @retry?}
          data-test={"task-#{@item.id}-#{@kind}-photo-retry"}
        >
          Upload interrupted — tap to retry
        </span>

        <span :if={is_nil(@photo) and not pending?(@upload) and not @retry?}>
          Add {@kind} photo
        </span>

        <span :if={@photo} data-test={"task-#{@item.id}-#{@kind}-photo"}>
          {@kind} photo attached <br />
          <span data-test={"task-#{@item.id}-#{@kind}-photo-timestamp"}>
            {Calendar.strftime(@photo.captured_at, "%Y-%m-%d %H:%M")}
          </span>
        </span>
      </label>
    </form>
    """
  end

  defp existing_photo(%{photos: photos}, kind) when is_list(photos),
    do: Enum.find(photos, &(&1.kind == kind and &1.upload_state == :uploaded))

  defp existing_photo(_item, _kind), do: nil

  # A `Photo` row left behind `:pending` from an upload that started
  # but never finished — either still running in this same session
  # (see `pending?/1`, which takes priority while that's true) or, if
  # this component has freshly mounted with no matching upload entry
  # in flight, abandoned by a dropped connection or a crashed process.
  # Finding it here (rather than always creating a new one) is what
  # lets a retry resume the same row instead of leaving an orphan.
  defp existing_pending_photo(%{photos: photos}, kind) when is_list(photos),
    do: Enum.find(photos, &(&1.kind == kind and &1.upload_state == :pending))

  defp existing_pending_photo(_item, _kind), do: nil

  defp pending?(%{entries: entries}), do: Enum.any?(entries, &(not &1.done?))

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:in_flight_photos, %{})
     |> allow_upload(:before_photo,
       accept: ~w(.jpg .jpeg .png),
       max_entries: 1,
       auto_upload: true,
       progress: &handle_progress/3
     )
     |> allow_upload(:after_photo,
       accept: ~w(.jpg .jpeg .png),
       max_entries: 1,
       auto_upload: true,
       progress: &handle_progress/3
     )}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("toggle", _params, socket) do
    {:ok, _item} =
      Quality.toggle_checklist_item(socket.assigns.current_scope, socket.assigns.item)

    notify_checklist_changed()
    {:noreply, socket}
  end

  def handle_event("noop", _params, socket), do: {:noreply, socket}

  # A `Photo` row is created `:pending` on the first progress callback
  # for a given upload — before any bytes have landed — and flipped to
  # `:uploaded` once the entry finishes. `in_flight_photos` remembers
  # which row belongs to this upload for the rest of this component's
  # lifetime, so a later chunk reuses it rather than creating a
  # duplicate; a fresh mount (after a dropped connection) instead finds
  # the still-pending row via `existing_pending_photo/2`.
  defp handle_progress(kind, entry, socket) do
    {socket, photo} = ensure_pending_photo(socket, kind)

    socket =
      if entry.done? do
        scope = socket.assigns.current_scope

        storage_key =
          consume_uploaded_entry(socket, entry, fn %{path: path} ->
            {:ok, store_upload!(path, entry)}
          end)

        {:ok, _photo} = Quality.complete_photo_upload(scope, photo, storage_key)

        notify_checklist_changed()
        assign(socket, :in_flight_photos, Map.delete(socket.assigns.in_flight_photos, kind))
      else
        socket
      end

    {:noreply, socket}
  end

  defp ensure_pending_photo(socket, kind) do
    case Map.get(socket.assigns.in_flight_photos, kind) do
      nil ->
        scope = socket.assigns.current_scope
        item = socket.assigns.item
        photo_kind = photo_kind(kind)

        photo =
          existing_pending_photo(item, photo_kind) ||
            create_pending_photo!(scope, item, photo_kind)

        {assign(socket, :in_flight_photos, Map.put(socket.assigns.in_flight_photos, kind, photo)),
         photo}

      photo ->
        {socket, photo}
    end
  end

  defp create_pending_photo!(scope, item, kind) do
    {:ok, photo} =
      Quality.attach_photo(scope, item, kind, %{
        upload_state: :pending,
        captured_at: DateTime.utc_now()
      })

    photo
  end

  defp photo_kind(:before_photo), do: :before
  defp photo_kind(:after_photo), do: :after

  defp store_upload!(path, entry) do
    dest_dir = Path.join([:code.priv_dir(:cleaner_crm), "static", "uploads"])
    File.mkdir_p!(dest_dir)
    filename = "#{System.unique_integer([:positive])}-#{entry.client_name}"
    File.cp!(path, Path.join(dest_dir, filename))
    "/uploads/#{filename}"
  end

  defp notify_checklist_changed, do: send(self(), :checklist_changed)
end
