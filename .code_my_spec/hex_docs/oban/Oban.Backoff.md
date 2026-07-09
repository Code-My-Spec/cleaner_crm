# Oban.Backoff



## exponential/2

Calculate an exponential backoff in seconds for a given attempt.

By default, the exponent is clamped to a maximum of 10 to prevent unreasonably long delays.

## Examples

    iex> Oban.Backoff.exponential(1)
    2

    iex> Oban.Backoff.exponential(1, mult: 100)
    200

    iex> Oban.Backoff.exponential(1, min_pad: 10)
    12

    iex> Oban.Backoff.exponential(10)
    1024

    iex> Oban.Backoff.exponential(11)
    1024

## jitter/2

Applies a random amount of jitter to the provided value.

## Examples

    iex> jitter = Oban.Backoff.jitter(200)
    ...> jitter in 180..220
    true

    iex> jitter = Oban.Backoff.jitter(200, mode: :inc)
    ...> jitter in 200..220
    true

    iex> jitter = Oban.Backoff.jitter(200, mode: :dec)
    ...> jitter in 180..200
    true

## with_retry/2

Attempt a database interaction repeatedly until it succeeds or retries are exhausted.

Failed attempts are spaced out using exponential backoff with jitter. By default, functions are
retried _infinitely_ with a maximum of ~100 seconds between retries.

This function is designed to guard against flickering database errors and retry safety only
applies `DBConnection.ConnectionError`, `Postgrex.Error`, and `GenServer` timeouts.

## Examples

    iex> Oban.Backoff.with_retry(fn -> :ok end)
    :ok

    iex> Oban.Backoff.with_retry(fn -> :ok end, :infinity)
    :ok

    iex> Oban.Backoff.with_retry(fn -> :ok end, 10)
    :ok