# SexySpex.ErrorCapture

Captures error logs during spex execution.

This module provides a way to detect if any error logs were emitted during
test execution, allowing spex to fail if errors occur even if no assertion failed.

## Usage

In your spex file, enable error capture:

    use SexySpex, fail_on_error_logs: true

Or start/stop manually:

    SexySpex.ErrorCapture.start()
    # ... run tests ...
    errors = SexySpex.ErrorCapture.get_errors()
    SexySpex.ErrorCapture.stop()

## How It Works

Uses an ETS table to store captured errors and a custom Logger handler
to intercept error-level log messages.

## start/0

Starts the error capture process and installs the Logger handler.

## stop/0

Stops the error capture process and removes the Logger handler.

## clear/0

Clears all captured errors.

## get_errors/0

Returns all captured errors.

## has_errors?/0

Returns true if any errors were captured.

## error_count/0

Returns error count.

## format_errors/0

Formats captured errors for display.

## check_and_raise!/0

Checks for errors and raises if any were found.