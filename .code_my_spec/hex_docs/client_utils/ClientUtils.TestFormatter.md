# ClientUtils.TestFormatter

ExUnit formatter that:
- Delegates to CLIFormatter for normal terminal output
- Writes JSON results to a file (if configured)
- Caches test events for later querying