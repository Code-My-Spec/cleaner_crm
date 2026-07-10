# ReqCassette.Session

Tracks interaction indices for sequential cassette matching.

Sequential matching is enabled when:
- `sequential: true` is passed to `with_cassette/3`
- `template: [...]` is passed (templates imply sequential matching)

When sequential matching is enabled, requests match interactions in order
(request 1 → interaction 0, request 2 → interaction 1, etc.) instead of
first-match. This is essential for:
- Identical requests expecting different responses (polling, state changes)
- Templated cassettes where multiple requests have the same structure
- Nested `with_cassette` calls using the same cassette name

## Two Modes

### Default Mode (Process Dictionary)

For single-process tests (the common case), session state is stored in the process
dictionary. This is simple and requires no setup:

    # Explicit sequential matching
    with_cassette("test", [sequential: true], fn plug ->
      Req.get!("/status")  # Matches interaction 0
      Req.get!("/status")  # Matches interaction 1
    end)

    # Templates automatically enable sequential
    with_cassette("test", [template: [preset: :common]], fn plug ->
      Req.post!(...)  # Matches interaction 0
      Req.post!(...)  # Matches interaction 1
    end)

### Shared Session Mode (Agent)

For cross-process tests where HTTP requests are made from spawned processes
(Task.async, GenServer, etc.), you must explicitly create a shared session:

    session = ReqCassette.start_shared_session()
    try do
      with_cassette("test", [session: session, sequential: true], fn plug ->
        Task.async(fn ->
          Req.post!(..., plug: plug)  # Works across processes!
        end) |> Task.await()
      end)
    after
      ReqCassette.end_shared_session(session)
    end

The shared session uses an Agent process for cross-process state sharing.
All operations are serialized through the Agent, guaranteeing consistency.

## start_shared_session/0

Creates a shared session for cross-process cassette matching.

Returns an Agent pid that should be passed to `with_cassette/3` via
the `session` option. The session must be ended with `end_shared_session/1`
when done.

## Example

    session = ReqCassette.Session.start_shared_session()
    try do
      with_cassette("test", [session: session], fn plug ->
        Task.async(fn -> Req.post!(..., plug: plug) end) |> Task.await()
      end)
    after
      ReqCassette.Session.end_shared_session(session)
    end

## end_shared_session/1

Ends a shared session by stopping its Agent process.

Should be called in an `after` block to ensure cleanup even on errors.

## start_session/2

Starts tracking a cassette path within a session.

For shared sessions (Agent), initializes the path's index in the Agent state.
For default sessions (process dictionary), initializes in pdict.

Returns a session_id that combines the mode and tracking info.

## end_session/2

Ends tracking for a cassette path within a session.

## get_current_index/2

Gets the current interaction index for sequential matching.

## get_and_advance_index/2

Atomically gets the current index and advances it.

Essential for concurrent access in shared sessions to prevent race conditions.
For local sessions, this is equivalent to get + advance but kept for API consistency.

## advance_index/2

Advances the interaction index after a successful match.