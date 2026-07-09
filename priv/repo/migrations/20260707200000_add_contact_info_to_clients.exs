defmodule CleanerCrm.Repo.Migrations.AddContactInfoToClients do
  use Ecto.Migration

  # Billing (receipts) and Notifications (reminders) both need a way to
  # reach the client outside the app — the clients table has no contact
  # info yet, just name/active/card_on_file.
  def change do
    alter table(:clients) do
      add :email, :string
      add :phone, :string
    end
  end
end
