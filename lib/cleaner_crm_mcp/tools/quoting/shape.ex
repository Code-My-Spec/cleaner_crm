defmodule CleanerCrmMcp.Tools.Quoting.Shape do
  @moduledoc false
  # Presenters and helpers shared by the quoting tools.

  alias CleanerCrmMcp.Present

  def quote_summary(q) do
    q
    |> Present.pick([
      :id,
      :client_id,
      :client_name,
      :client_phone,
      :pricing_model,
      :status,
      :sent_at,
      :inserted_at
    ])
    |> Map.merge(Present.money("total", q.total_cents))
  end

  def quote(q) do
    q
    |> quote_summary()
    |> Map.merge(Present.pick(q, [:bedroom_count, :bathroom_count, :square_feet, :hours]))
    |> Map.put("items", Enum.map(q.quote_items, &line_item/1))
  end

  @doc "A priced line (quote item struct or pricing map)."
  def line_item(item) do
    %{"description" => item.description, "quantity" => item.quantity}
    |> Map.merge(Present.money("rate", item.rate_cents))
    |> Map.merge(Present.money("amount", item.amount_cents))
  end

  def rate_card(rc) do
    %{
      "add_on_rates" =>
        Map.new(rc.add_on_rates_cents || %{}, fn {key, cents} ->
          {key, %{"cents" => cents, "dollars" => cents / 100}}
        end),
      "weekly_discount_percent" => rc.weekly_discount_percent,
      "biweekly_discount_percent" => rc.biweekly_discount_percent,
      "monthly_discount_percent" => rc.monthly_discount_percent
    }
    |> Map.merge(Present.money("bedroom_rate", rc.per_room_bedroom_rate_cents))
    |> Map.merge(Present.money("bathroom_rate", rc.per_room_bathroom_rate_cents))
    |> Map.merge(Present.money("sqft_rate", rc.per_sqft_rate_cents))
    |> Map.merge(Present.money("hourly_rate", rc.hourly_rate_cents))
    |> Map.merge(Present.money("minimum_visit", rc.minimum_visit_cents))
  end

  @models ~w(per_room per_sqft hourly)
  @frequencies ~w(one_time weekly biweekly monthly)

  def parse_model(nil), do: {:ok, nil}
  def parse_model(v) when v in @models, do: {:ok, String.to_existing_atom(v)}
  def parse_model(_), do: {:error, "pricing_model must be one of: #{Enum.join(@models, ", ")}"}

  def parse_frequency(nil), do: {:ok, nil}
  def parse_frequency(v) when v in @frequencies, do: {:ok, String.to_existing_atom(v)}

  def parse_frequency(_),
    do: {:error, "frequency must be one of: #{Enum.join(@frequencies, ", ")}"}

  @doc "Pricing model from an explicit value, else inferred from which size fields were given."
  def resolve_model(args) do
    with {:ok, explicit} <- parse_model(args["pricing_model"]) do
      cond do
        explicit -> {:ok, explicit}
        args["bedrooms"] || args["bathrooms"] -> {:ok, :per_room}
        args["square_feet"] -> {:ok, :per_sqft}
        args["hours"] -> {:ok, :hourly}
        true -> {:error, "give pricing_model, or one of bedrooms/bathrooms, square_feet or hours"}
      end
    end
  end

  def size_attrs(args) do
    %{
      bedroom_count: args["bedrooms"],
      bathroom_count: args["bathrooms"],
      square_feet: args["square_feet"],
      hours: args["hours"]
    }
    |> Map.reject(fn {_k, v} -> is_nil(v) end)
  end

  def size_params do
    [
      %{
        name: "pricing_model",
        type: :string,
        required: false,
        description: "per_room, per_sqft or hourly. Inferred from the size fields when omitted."
      },
      %{
        name: "bedrooms",
        type: :integer,
        required: false,
        description: "Bedroom count (per_room)"
      },
      %{
        name: "bathrooms",
        type: :integer,
        required: false,
        description: "Bathroom count (per_room)"
      },
      %{
        name: "square_feet",
        type: :integer,
        required: false,
        description: "Square footage (per_sqft)"
      },
      %{name: "hours", type: :integer, required: false, description: "Hours of work (hourly)"}
    ]
  end

  @doc "Passes nil through; errors unless `value` is a valid UUID."
  def check_uuid(nil, _name), do: {:ok, nil}

  def check_uuid(value, name) do
    case Ecto.UUID.cast(value) do
      {:ok, uuid} -> {:ok, uuid}
      :error -> {:error, "#{name} is not a valid id: #{value}"}
    end
  end
end
