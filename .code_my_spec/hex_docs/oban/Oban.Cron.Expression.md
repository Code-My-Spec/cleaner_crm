# Oban.Cron.Expression



## now?/2

Check whether a cron expression matches the current date and time.

## Example

Check against the default `utc_now`:

    iex> "* * * * *" |> parse!() |> now?()
    true

Check against a provided date time:

    iex> "0 1 * * *" |> parse!() |> now?(~U[2025-01-01 01:00:00Z])
    true

    iex> "0 1 * * *" |> parse!() |> now?(~U[2025-01-01 02:00:00Z])
    false

Check if it is time to reboot:

    iex> "@reboot" |> parse!() |> now?()
    true

## next_at/2

Returns the next DateTime that matches the cron expression.

When given a DateTime, it finds the next matching time after that DateTime. When given
a timezone string, it finds the next matching time in that timezone.

## Examples

Find the next matching time after a given DateTime:

    iex> "0 1 * * *" |> parse!() |> next_at(~U[2025-01-01 00:00:00Z])
    ~U[2025-01-01 01:00:00Z]

Find the next matching time in a specific timezone:

    iex> "0 1 * * *" |> parse!() |> next_at("America/New_York")
    ~U[2025-01-02 01:00:00-05:00]

## last_at/2

Returns the most recent DateTime that matches the cron expression.

When given a DateTime, it finds the last matching time before that DateTime. When given
a timezone string, it finds the last matching time in that timezone.

## Examples

Find the last matching time before a given DateTime:

    iex> "0 1 * * *" |> parse!() |> last_at(~U[2025-01-01 01:00:00Z])
    ~U[2025-01-01 00:01:00Z]

Find the last matching time in a specific timezone:

    iex> "0 1 * * *" |> parse!() |> last_at("America/New_York")
    ~U[2025-01-01 05:01:00-05:00]