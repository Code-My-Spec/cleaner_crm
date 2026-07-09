defmodule CleanerCrm.SchedulingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `CleanerCrm.Scheduling` context.
  """

  alias CleanerCrm.Accounts
  alias CleanerCrm.Repo
  alias CleanerCrm.Scheduling
  alias CleanerCrm.Users.User

  def cleaner_fixture(scope, account, attrs \\ %{}) do
    {:ok, user} =
      %User{}
      |> Ecto.Changeset.cast(
        Enum.into(attrs, %{
          name: "Cleaner #{System.unique_integer([:positive])}",
          email: "cleaner#{System.unique_integer([:positive])}@example.com"
        }),
        [:name, :email]
      )
      |> Ecto.Changeset.validate_required([:email])
      |> Repo.insert()

    {:ok, _member} = Accounts.add_user_to_account(scope, user.id, account.id, :member)

    user
  end

  def job_fixture(scope, property, attrs \\ %{}) do
    {:ok, job} =
      attrs
      |> Enum.into(%{
        property_id: property.id,
        scheduled_date: Date.add(Date.utc_today(), 7),
        start_time: ~T[09:00:00],
        end_time: ~T[11:00:00]
      })
      |> then(&Scheduling.create_job(scope, &1))

    job
  end

  def recurring_plan_fixture(scope, property, attrs \\ %{}) do
    {:ok, {plan, _jobs}} =
      attrs
      |> Enum.into(%{
        property_id: property.id,
        recurrence: :weekly,
        start_date: Date.add(Date.utc_today(), 7),
        occurrence_count: 4
      })
      |> then(&Scheduling.create_recurring_plan(scope, &1))

    plan
  end

  def availability_block_fixture(scope, cleaner, attrs \\ %{}) do
    {:ok, block} =
      attrs
      |> Enum.into(%{cleaner_id: cleaner.id, date: Date.add(Date.utc_today(), 7), all_day: true})
      |> then(&Scheduling.create_availability_block(scope, &1))

    block
  end
end
