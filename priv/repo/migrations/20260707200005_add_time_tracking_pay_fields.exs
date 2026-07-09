defmodule CleanerCrm.Repo.Migrations.AddTimeTrackingPayFields do
  use Ecto.Migration

  # Additive columns only — `jobs` and `accounts` stay owned by
  # Scheduling/Accounts, but a job's pay arrangement and an account's
  # drive-time policy are read and written by TimeTracking (the same
  # relationship `agreed_price_cents` already has with Billing).
  def change do
    alter table(:jobs) do
      add :pay_type, :string
      add :hourly_rate_cents, :integer
      add :piece_rate_cents, :integer
    end

    alter table(:accounts) do
      add :drive_time_policy, :string, null: false, default: "unpaid"
    end
  end
end
