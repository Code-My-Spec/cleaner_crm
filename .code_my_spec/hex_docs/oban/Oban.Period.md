# Oban.Period

Periods represent durations of time as either raw seconds or a unit tuple.

All periods are normalized to seconds internally. The tuple format provides a more expressive
way to specify durations in larger units:

    # Raw seconds
    60

    # Unit tuple
    {1, :minute}
    {5, :minutes}
    {2, :hours}

Supported time units are `:second`, `:seconds`, `:minute`, `:minutes`, `:hour`, `:hours`,
`:day`, `:days`, `:week`, and `:weeks`.

## to_seconds/1

Convert a period to seconds.

## Examples

    iex> Oban.Period.to_seconds(60)
    60

    iex> Oban.Period.to_seconds({1, :minute})
    60

    iex> Oban.Period.to_seconds({2, :hours})
    7200