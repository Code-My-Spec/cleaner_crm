defmodule CleanerCrm.Repo do
  use Ecto.Repo,
    otp_app: :cleaner_crm,
    adapter: Ecto.Adapters.Postgres
end
