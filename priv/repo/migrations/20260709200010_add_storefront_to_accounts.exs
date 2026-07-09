defmodule CleanerCrm.Repo.Migrations.AddStorefrontToAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :storefront, :boolean, null: false, default: false
    end

    # Defense in depth alongside `CleanerCrm.Accounts.set_storefront/2`'s
    # own transactional unset-others-first logic: the database itself
    # never allows two accounts to claim the public `/book` storefront
    # at once.
    create unique_index(:accounts, [:storefront],
             where: "storefront = true",
             name: :accounts_storefront_unique_index
           )
  end
end
