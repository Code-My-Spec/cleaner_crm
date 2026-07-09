defimpl Phoenix.Param, for: Date do
  @moduledoc """
  Lets a `Date` be interpolated directly into a `~p` route's query
  string (e.g. `~p"/app/field?date=#{Date.utc_today()}"`), the same way
  `FieldLive.Today`'s own look-ahead link would build one. Without
  this, `Phoenix.Param`'s default implementation raises, since `Date`
  carries no `:id` field for it to fall back on.
  """

  def to_param(%Date{} = date), do: Date.to_iso8601(date)
end
