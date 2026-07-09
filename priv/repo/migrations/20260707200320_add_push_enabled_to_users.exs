defmodule CleanerCrm.Repo.Migrations.AddPushEnabledToUsers do
  use Ecto.Migration

  # Notifications needs a way to represent "this cleaner has no push
  # channel registered" — there's no push-registration flow yet, so a
  # simple opt-out flag stands in for it (see the sms-delivery ADR's
  # push-falls-back-to-SMS path).
  def change do
    alter table(:users) do
      add :push_enabled, :boolean, null: false, default: true
    end
  end
end
