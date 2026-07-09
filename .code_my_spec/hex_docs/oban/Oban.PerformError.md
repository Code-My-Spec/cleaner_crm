# Oban.PerformError

Wraps the reason returned by `{:error, reason}`, `{:cancel, reason}`, or `{:discard, reason}` in
a proper exception.

The original return tuple is available in the `:reason` key.