defmodule CleanerCrm.Audit.Recorder do
  @moduledoc """
  API other contexts call to append audit trail entries.

  Callers pass the acting scope, an action string, the subject being
  changed, and old/new value maps. Nothing here ever updates or deletes
  a row — this module only ever inserts.
  """

  import Ecto.Query, warn: false

  alias CleanerCrm.Repo
  alias CleanerCrm.Audit.AuditEntry
  alias CleanerCrm.Users.Scope

  @doc """
  Records an audit entry attributed to the scope's current user.
  """
  def record(
        %Scope{} = scope,
        action,
        subject_type,
        subject_id,
        old_value \\ %{},
        new_value \\ %{}
      )
      when is_binary(action) and is_binary(subject_type) do
    insert(scope, %{system: false, actor_id: scope.user && scope.user.id}, action, subject_type,
      subject_id: subject_id,
      old_value: old_value,
      new_value: new_value
    )
  end

  @doc """
  Records an audit entry attributed to the system rather than a human
  actor — for automated processes such as recurring job materialization.
  """
  def record_system(
        %Scope{} = scope,
        action,
        subject_type,
        subject_id,
        old_value \\ %{},
        new_value \\ %{}
      )
      when is_binary(action) and is_binary(subject_type) do
    insert(scope, %{system: true, actor_id: nil}, action, subject_type,
      subject_id: subject_id,
      old_value: old_value,
      new_value: new_value
    )
  end

  defp insert(%Scope{active_account_id: account_id}, actor_attrs, action, subject_type, rest)
       when not is_nil(account_id) do
    %AuditEntry{}
    |> AuditEntry.changeset(
      Map.merge(actor_attrs, %{
        account_id: account_id,
        action: action,
        subject_type: subject_type,
        subject_id: rest[:subject_id],
        old_value: rest[:old_value],
        new_value: rest[:new_value]
      })
    )
    |> Repo.insert()
  end

  @doc """
  Lists audit entries for a subject, most recent first.
  """
  def list_for_subject(%Scope{active_account_id: account_id}, subject_type, subject_id)
      when not is_nil(account_id) and is_binary(subject_type) do
    AuditEntry
    |> where(
      [e],
      e.account_id == ^account_id and e.subject_type == ^subject_type and
        e.subject_id == ^subject_id
    )
    |> order_by([e], desc: e.inserted_at)
    |> preload(:actor)
    |> Repo.all()
  end
end
