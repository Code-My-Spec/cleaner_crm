# ClientUtils.TestFormatter.TestCache

Caches test events to a JSON file, keyed by file.
Callers can query: "was file X tested after time Y?"

Uses JSON files for persistent storage that can be shared between
separate Erlang VM instances.

Events are stored as base64-encoded Erlang terms to preserve
all type information (tuples, structs, etc).

## events_file/0

Returns the events file path.
Uses the configured :agent_test_dir, or can be overridden via AGENT_TEST_EVENTS_FILE environment variable.

## ensure_started/0

No-op for compatibility. JSON files don't need setup.

## setup/0

No-op for compatibility. JSON files don't need setup.

## store_events/3

Stores a batch of events to the JSON file as a new run.
`for_callers` is a list of PIDs (as strings) that this run is for.

## get_events_for_file/2

Gets all events for a file that were recorded after the given time.

## get_events_after/1

Gets all events from runs completed after the given time.

## file_tested_after?/2

Returns true if the file was tested after the given time.

## files_tested_after?/2

Returns true if all files were tested after the given time.
If files is empty, returns true (vacuous truth).

## extract_file/1

Extracts the file path from a test event.

## list_cached_files/0

Returns a summary of all cached files with their timestamps.
Useful for debugging. Returns a list of {file, min_timestamp, max_timestamp, event_count}.

## clear/0

Clears all cached events.

## destroy/0

Deletes the events file entirely. Useful for cleanup.

## close/0

No-op for compatibility. JSON files don't need closing.