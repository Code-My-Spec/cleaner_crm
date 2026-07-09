defmodule CleanerCrm.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          name: String.t(),
          slug: String.t() | nil,
          drive_time_policy: :unpaid | :paid,
          storefront: boolean(),
          members: [CleanerCrm.Accounts.Member.t()] | Ecto.Association.NotLoaded.t(),
          users: [CleanerCrm.Users.User.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @reserved_slugs ~w(admin api www help support docs blog)

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "accounts" do
    field :name, :string
    field :slug, :string

    # Whether time spent driving between jobs counts toward a
    # cleaner's pay — read by `CleanerCrm.TimeTracking` alongside a
    # cleaner's earnings, set here rather than on a separate settings
    # table since it's the account's only pay policy so far.
    field :drive_time_policy, Ecto.Enum, values: [:unpaid, :paid], default: :unpaid

    # Which account's rate card and quote calculator the public `/book`
    # funnel prices against — at most one row ever has this set (see
    # the partial unique index in the `add_storefront_to_accounts`
    # migration). Never cast through the generic `changeset/2` below;
    # only `CleanerCrm.Accounts.set_storefront/2` ever writes it, since
    # flipping it also has to unset any other account's flag in the
    # same transaction.
    field :storefront, :boolean, default: false

    has_many :members, CleanerCrm.Accounts.Member, on_delete: :delete_all
    has_many :users, through: [:members, :user]

    timestamps()
  end

  def changeset(account, attrs) do
    account
    |> cast(attrs, [:name, :slug, :drive_time_policy])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_slug()
    |> unique_constraint(:slug)
  end

  def create_changeset(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> maybe_generate_slug()
  end

  defp validate_slug(changeset) do
    changeset
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/,
      message: "must contain only lowercase letters, numbers, and hyphens"
    )
    |> validate_length(:slug, min: 3, max: 50)
    |> validate_exclusion(:slug, @reserved_slugs, message: "is reserved and cannot be used")
    |> validate_format(:slug, ~r/^[a-z]/, message: "must start with a letter")
  end

  defp maybe_generate_slug(changeset) do
    case get_field(changeset, :slug) do
      nil ->
        name = get_field(changeset, :name)
        if name, do: put_change(changeset, :slug, generate_slug(name)), else: changeset

      _ ->
        changeset
    end
  end

  defp generate_slug(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]/, "-")
    |> String.replace(~r/-+/, "-")
    |> String.trim("-")
  end
end
