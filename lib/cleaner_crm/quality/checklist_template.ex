defmodule CleanerCrm.Quality.ChecklistTemplate do
  @moduledoc """
  A reusable room-by-room task template for a property or service
  type, from which a job's own `CleanerCrm.Quality.Checklist` can be
  instantiated (see `CleanerCrm.Quality.instantiate_checklist/3`).
  """

  use Ecto.Schema
  import Ecto.Changeset

  defmodule TemplateItem do
    @moduledoc """
    One room/task line on a template, embedded — a template is a
    small, template-owned list, not something referenced elsewhere,
    so it lives inline rather than as its own table.
    """

    use Ecto.Schema
    import Ecto.Changeset

    @type t :: %__MODULE__{
            room: String.t() | nil,
            task: String.t() | nil,
            required: boolean()
          }

    @primary_key false
    embedded_schema do
      field :room, :string
      field :task, :string
      field :required, :boolean, default: true
    end

    def changeset(item, attrs) do
      item
      |> cast(attrs, [:room, :task, :required])
      |> validate_required([:task])
    end
  end

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          account_id: Ecto.UUID.t() | nil,
          property_id: Ecto.UUID.t() | nil,
          name: String.t() | nil,
          items: [TemplateItem.t()],
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "checklist_templates" do
    field :name, :string
    embeds_many :items, TemplateItem, on_replace: :delete

    belongs_to :account, CleanerCrm.Accounts.Account, type: :binary_id
    belongs_to :property, CleanerCrm.Clients.Property, type: :binary_id

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(template, attrs) do
    template
    |> cast(blank_property_id_to_nil(attrs), [:name, :property_id])
    |> cast_embed(:items,
      with: &TemplateItem.changeset/2,
      sort_param: :items_sort,
      drop_param: :items_drop
    )
    |> validate_required([:name])
  end

  defp blank_property_id_to_nil(%{"property_id" => ""} = attrs),
    do: %{attrs | "property_id" => nil}

  defp blank_property_id_to_nil(attrs), do: attrs

  @doc """
  This template's items as the flat `%{room:, task:, required:}` maps
  `CleanerCrm.Quality.create_checklist/4` expects.
  """
  def item_attrs(%__MODULE__{items: items}) do
    Enum.map(items, &Map.take(&1, [:room, :task, :required]))
  end
end
