defmodule CleanerCrmMcp.Tools.Billing.Shape do
  @moduledoc false
  # Presenters shared by the billing tools.

  alias CleanerCrmMcp.Present

  def invoice(inv) do
    job = loaded(inv.job)
    client = job && loaded(job.client)

    inv
    |> Present.pick([:id, :job_id, :status, :stripe_payment_intent_id, :inserted_at, :updated_at])
    |> Map.merge(Present.money("amount", inv.amount_cents))
    |> Map.put("job_number", job && job.job_number)
    |> Map.put("client", client && Present.pick(client, [:id, :name]))
  end

  def payment(p) do
    p
    |> Present.pick([
      :id,
      :invoice_id,
      :status,
      :provider,
      :source,
      :stripe_payment_intent_id,
      :inserted_at
    ])
    |> Map.merge(Present.money("amount", p.amount_cents))
  end

  def tip(t) do
    cleaner = loaded(t.cleaner)

    t
    |> Present.pick([:id, :invoice_id, :cleaner_id, :inserted_at])
    |> Map.merge(Present.money("amount", t.amount_cents))
    |> Map.put("cleaner_name", cleaner && cleaner.name)
  end

  def policy(p) do
    %{"notice_window_hours" => p.notice_window_hours, "policy_text" => p.policy_text}
    |> Map.merge(Present.money("late_fee", p.late_fee_cents))
    |> Map.merge(Present.money("same_day_fee", p.same_day_fee_cents))
  end

  defp loaded(%Ecto.Association.NotLoaded{}), do: nil
  defp loaded(other), do: other

  @doc "Optional enum string -> atom among `allowed`."
  def parse_enum(nil, _name, _allowed), do: {:ok, nil}

  def parse_enum(value, name, allowed) do
    if value in allowed,
      do: {:ok, String.to_existing_atom(value)},
      else: {:error, "#{name} must be one of: #{Enum.join(allowed, ", ")}"}
  end

  def compact(opts), do: Enum.reject(opts, fn {_, v} -> is_nil(v) end)

  @doc "Passes nil through; errors unless `value` is a valid UUID."
  def check_uuid(nil, _name), do: {:ok, nil}

  def check_uuid(value, name) do
    case Ecto.UUID.cast(value) do
      {:ok, uuid} -> {:ok, uuid}
      :error -> {:error, "#{name} is not a valid id: #{value}"}
    end
  end
end
