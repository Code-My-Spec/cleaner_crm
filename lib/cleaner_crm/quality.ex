defmodule CleanerCrm.Quality do
  @moduledoc """
  Room-by-room checklists instantiated per job, before/after photo
  proof, incident reports (damage, missing items, unsafe conditions),
  and the scorecards that aggregate a cleaner's completed jobs.

  Every function is scoped to the caller's active account.
  """

  import Ecto.Query, warn: false

  alias CleanerCrm.Audit.Recorder
  alias CleanerCrm.Repo
  alias CleanerCrm.Scheduling.Job
  alias CleanerCrm.Users.Scope

  alias CleanerCrm.Quality.{
    Checklist,
    ChecklistItem,
    ChecklistTemplate,
    IncidentReport,
    Photo,
    Scorecard
  }

  ## Checklist templates

  def list_checklist_templates(%Scope{active_account_id: account_id})
      when not is_nil(account_id) do
    ChecklistTemplate
    |> where([t], t.account_id == ^account_id)
    |> order_by([t], asc: t.name)
    |> preload(:property)
    |> Repo.all()
  end

  def get_checklist_template!(%Scope{active_account_id: account_id}, id)
      when not is_nil(account_id) do
    ChecklistTemplate
    |> where([t], t.account_id == ^account_id)
    |> preload(:property)
    |> Repo.get!(id)
  end

  def change_checklist_template(%Scope{}, %ChecklistTemplate{} = template, attrs \\ %{}) do
    ChecklistTemplate.changeset(template, attrs)
  end

  def create_checklist_template(%Scope{active_account_id: account_id}, attrs)
      when not is_nil(account_id) do
    %ChecklistTemplate{account_id: account_id}
    |> ChecklistTemplate.changeset(attrs)
    |> Repo.insert()
  end

  def update_checklist_template(
        %Scope{active_account_id: account_id},
        %ChecklistTemplate{} = template,
        attrs
      )
      when not is_nil(account_id) do
    template
    |> ChecklistTemplate.changeset(attrs)
    |> Repo.update()
  end

  ## Checklists

  @doc """
  Instantiates a job's checklist from a template, copying its
  room/task/required lines down as the job's own checklist items.
  """
  def instantiate_checklist(%Scope{} = scope, %Job{} = job, %ChecklistTemplate{} = template) do
    create_checklist(scope, job, ChecklistTemplate.item_attrs(template), template_id: template.id)
  end

  @doc """
  Creates a job's checklist from `items` — each a `%{task:, required:}`
  map, optionally carrying `room:` — in the order given. Every
  checklist item starts unchecked and un-skipped.

  Called with an empty `items` list and no explicit `template_id` in
  `opts`, this looks for a `ChecklistTemplate` on the job's property
  and instantiates from it instead of leaving the checklist empty.
  This is what lets `FieldLive.Job`'s lazy
  `create_checklist(scope, job, [])` — called the first time a
  cleaner opens a job with no checklist yet — pick up a real,
  room-by-room checklist once the office has built one for the
  property, without that caller needing to know templates exist.
  """
  def create_checklist(
        %Scope{active_account_id: account_id} = scope,
        %Job{id: job_id} = job,
        items,
        opts \\ []
      )
      when not is_nil(account_id) and is_list(items) do
    {items, opts} = apply_property_template(scope, job, items, opts)

    Repo.transact(fn ->
      with {:ok, checklist} <-
             %Checklist{account_id: account_id}
             |> Checklist.changeset(%{job_id: job_id, checklist_template_id: opts[:template_id]})
             |> Repo.insert() do
        item_structs =
          items
          |> Enum.with_index()
          |> Enum.map(fn {attrs, position} ->
            insert_checklist_item!(checklist, attrs, position)
          end)

        {:ok, %{checklist | items: item_structs}}
      end
    end)
  end

  defp apply_property_template(_scope, _job, items, opts) when items != [], do: {items, opts}

  defp apply_property_template(scope, %Job{property_id: property_id}, [], opts) do
    cond do
      # `opts[:template_id]` is a keyword-list lookup (`Access.get/2`), which
      # isn't allowed in a guard — checked here in the body instead.
      not is_nil(opts[:template_id]) -> {[], opts}
      is_nil(property_id) -> {[], opts}
      true -> apply_found_template(scope, property_id, opts)
    end
  end

  defp apply_found_template(%Scope{active_account_id: account_id}, property_id, opts) do
    case find_template_for_property(account_id, property_id) do
      nil ->
        {[], opts}

      template ->
        {ChecklistTemplate.item_attrs(template), Keyword.put(opts, :template_id, template.id)}
    end
  end

  defp find_template_for_property(account_id, property_id) do
    ChecklistTemplate
    |> where([t], t.account_id == ^account_id and t.property_id == ^property_id)
    |> order_by([t], desc: t.updated_at)
    |> limit(1)
    |> Repo.one()
  end

  defp insert_checklist_item!(checklist, attrs, position) do
    params =
      attrs
      |> Map.new(fn {key, value} -> {to_string(key), value} end)
      |> Map.put("checklist_id", checklist.id)
      |> Map.put_new("position", position)

    %ChecklistItem{}
    |> ChecklistItem.changeset(params)
    |> Repo.insert!()
  end

  @doc """
  Fetches a job's checklist with its items and their photos
  preloaded, or `nil` if the job has none yet.
  """
  def get_checklist_for_job(%Scope{active_account_id: account_id}, %Job{id: job_id})
      when not is_nil(account_id) do
    Checklist
    |> where([c], c.account_id == ^account_id and c.job_id == ^job_id)
    |> preload(items: :photos)
    |> Repo.one()
  end

  @doc """
  Groups a checklist's items by room, in the order each room first
  appears. Items with no room (a flat, unrouted checklist) are
  grouped under `nil`.
  """
  def group_by_room(%Checklist{items: items}) do
    rooms = Enum.uniq_by(items, & &1.room) |> Enum.map(& &1.room)
    grouped = Enum.group_by(items, & &1.room)
    Enum.map(rooms, &{&1, Map.fetch!(grouped, &1)})
  end

  @doc "`{checked_count, total_count}` across a checklist's items."
  def progress(%Checklist{items: items}), do: {Enum.count(items, & &1.checked), length(items)}

  @doc """
  Toggles a checklist item's checked state. Checking an item clears
  any prior skip.
  """
  def toggle_checklist_item(%Scope{}, %ChecklistItem{checked: true} = item) do
    item |> ChecklistItem.uncheck_changeset() |> Repo.update()
  end

  def toggle_checklist_item(%Scope{}, %ChecklistItem{} = item) do
    item |> ChecklistItem.check_changeset() |> Repo.update()
  end

  @doc "Marks a required item skipped instead of done, with a reason."
  def skip_checklist_item(%Scope{}, %ChecklistItem{} = item, reason) do
    item |> ChecklistItem.skip_changeset(reason) |> Repo.update()
  end

  @doc """
  The required items still blocking completion: unchecked and not
  skipped. Empty means the checklist is ready to complete.
  """
  def incomplete_required_items(%Checklist{items: items}) do
    Enum.filter(items, &(&1.required and not &1.checked and not &1.skipped))
  end

  @doc """
  Completes a job's checklist: refused with the still-incomplete
  required items when any remain; otherwise the checklist is stamped
  done, scored, and the job itself is marked completed.
  """
  def complete_job(%Scope{} = scope, %Checklist{} = checklist) do
    case incomplete_required_items(checklist) do
      [] -> do_complete_job(scope, checklist)
      incomplete -> {:error, {:incomplete_required_tasks, incomplete}}
    end
  end

  defp do_complete_job(scope, checklist) do
    Repo.transact(fn ->
      with {:ok, completed} <- mark_checklist_completed(checklist),
           {:ok, _job} <- mark_job_completed(scope, completed.job_id) do
        {:ok, completed}
      end
    end)
  end

  defp mark_checklist_completed(checklist) do
    checklist
    |> Checklist.changeset(%{
      completed_at: DateTime.utc_now(),
      quality_score: Scorecard.score(checklist)
    })
    |> Repo.update()
  end

  defp mark_job_completed(%Scope{active_account_id: account_id} = scope, job_id) do
    job = Job |> where([j], j.account_id == ^account_id) |> Repo.get!(job_id)

    with {:ok, updated} <- job |> Job.changeset(%{status: :completed}) |> Repo.update() do
      Recorder.record(
        scope,
        "job_completed",
        "Job",
        updated.id,
        %{"status" => to_string(job.status)},
        %{"status" => "completed"}
      )

      {:ok, updated}
    end
  end

  @doc """
  Records the owner's 1-5 quality rating for a job, recomputing the
  checklist's combined quality score.
  """
  def rate_job(%Scope{}, %Checklist{} = checklist, rating) do
    rated = %{checklist | owner_rating: rating}

    checklist
    |> Checklist.changeset(%{owner_rating: rating, quality_score: Scorecard.score(rated)})
    |> Repo.update()
  end

  @doc """
  Creates a job's checklist already fully checked off with
  before/after photo proof, for callers that seed a completed job's
  proof of work directly (see
  `CleanerCrmSpex.Fixtures.job_with_proof_of_work_fixture/3`) rather
  than driving the checklist item by item. `items` is a list of
  `%{task:, before_photo:, after_photo:}` maps.
  """
  def complete_checklist(%Scope{active_account_id: account_id} = scope, %Job{} = job, items)
      when not is_nil(account_id) and is_list(items) do
    Repo.transact(fn ->
      with {:ok, checklist} <-
             create_checklist(
               scope,
               job,
               Enum.map(items, &Map.take(&1, [:task, :room, :required]))
             ) do
        checked_items =
          checklist.items
          |> Enum.zip(items)
          |> Enum.map(fn {item, proof} -> check_with_photos!(account_id, item, proof) end)

        checklist = %{checklist | items: checked_items}

        checklist
        |> Checklist.changeset(%{
          completed_at: DateTime.utc_now(),
          quality_score: Scorecard.score(checklist)
        })
        |> Repo.update()
      end
    end)
  end

  defp check_with_photos!(account_id, item, %{
         before_photo: before_photo,
         after_photo: after_photo
       }) do
    checked = item |> ChecklistItem.check_changeset() |> Repo.update!()
    before = insert_checklist_photo!(account_id, checked, :before, before_photo)
    aftr = insert_checklist_photo!(account_id, checked, :after, after_photo)
    %{checked | photos: [before, aftr]}
  end

  defp insert_checklist_photo!(account_id, %ChecklistItem{} = item, kind, storage_key) do
    %Photo{account_id: account_id}
    |> Photo.changeset(%{
      checklist_item_id: item.id,
      kind: kind,
      upload_state: :uploaded,
      storage_key: storage_key,
      captured_at: DateTime.utc_now()
    })
    |> Repo.insert!()
  end

  @doc "Attaches a before/after photo to a checklist item, `:pending` until uploaded."
  def attach_photo(%Scope{active_account_id: account_id}, %ChecklistItem{} = item, kind, attrs)
      when not is_nil(account_id) and kind in [:before, :after] do
    %Photo{account_id: account_id}
    |> Photo.changeset(Map.merge(%{checklist_item_id: item.id, kind: kind}, attrs))
    |> Repo.insert()
  end

  @doc "Flips a pending photo to uploaded once its bytes land in storage."
  def complete_photo_upload(%Scope{}, %Photo{} = photo, storage_key) do
    photo |> Photo.uploaded_changeset(storage_key) |> Repo.update()
  end

  ## Incident reports

  @doc """
  Files an incident report for a job. `attrs` needs `:type`
  (`"damage"`, `"missing_item"`, or `"unsafe_condition"`) and
  `:description`; a `:photo` (the same attrs `attach_photo/4` takes)
  is required unless `:type` is `"unsafe_condition"`. The cleaner and
  filing time are always the caller's and now — never accepted from
  `attrs` — and nothing about a filed report can change afterward.
  """
  def file_incident_report(%Scope{active_account_id: account_id, user: user}, %Job{} = job, attrs)
      when not is_nil(account_id) do
    {photo_attrs, report_attrs} = attrs |> stringify_keys() |> Map.pop("photo")

    Repo.transact(fn ->
      with {:ok, report} <-
             %IncidentReport{account_id: account_id}
             |> IncidentReport.changeset(
               Map.merge(report_attrs, %{
                 "job_id" => job.id,
                 "cleaner_id" => user && user.id,
                 "filed_at" => DateTime.utc_now()
               }),
               not is_nil(photo_attrs)
             )
             |> Repo.insert() do
        photo = photo_attrs && insert_incident_photo!(account_id, report, photo_attrs)
        {:ok, %{report | photos: Enum.filter([photo], & &1)}}
      end
    end)
  end

  defp stringify_keys(attrs), do: Map.new(attrs, fn {key, value} -> {to_string(key), value} end)

  defp insert_incident_photo!(account_id, %IncidentReport{} = report, photo_attrs) do
    %Photo{account_id: account_id}
    |> Photo.changeset(
      Map.merge(stringify_keys(photo_attrs), %{
        "incident_report_id" => report.id,
        "kind" => "incident",
        "upload_state" => "uploaded",
        "captured_at" => DateTime.utc_now()
      })
    )
    |> Repo.insert!()
  end

  @doc """
  Lists an account's incident reports, most recently filed first,
  with job (and its client), cleaner, and photos preloaded.
  """
  def list_incident_reports(%Scope{active_account_id: account_id}) when not is_nil(account_id) do
    IncidentReport
    |> where([r], r.account_id == ^account_id)
    |> order_by([r], desc: r.filed_at)
    |> preload([:cleaner, :photos, job: [:client, :property]])
    |> Repo.all()
  end

  ## Scorecards

  @doc """
  The cleaner's average quality score and trend across their
  completed jobs, oldest first (see `CleanerCrm.Quality.Scorecard`).
  """
  def cleaner_scorecard(%Scope{active_account_id: account_id}, cleaner_id)
      when not is_nil(account_id) do
    Checklist
    |> join(:inner, [c], j in Job, on: j.id == c.job_id)
    |> where(
      [c, j],
      c.account_id == ^account_id and j.cleaner_id == ^cleaner_id and
        not is_nil(c.completed_at)
    )
    |> order_by([c], asc: c.completed_at)
    |> select([c], c.quality_score)
    |> Repo.all()
    |> Enum.reject(&is_nil/1)
    |> Scorecard.aggregate()
  end
end
