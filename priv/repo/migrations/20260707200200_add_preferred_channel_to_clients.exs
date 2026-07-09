defmodule CleanerCrm.Repo.Migrations.AddPreferredChannelToClients do
  use Ecto.Migration

  # Notifications needs to know which channel a client wants their
  # appointment reminder on.
  def change do
    alter table(:clients) do
      add :preferred_channel, :string, null: false, default: "email"
    end
  end
end
