# Mix.Tasks.ReqCassette.Inspect

Inspects ReqCassette cassette files and displays template information.

This task is useful for:
- Verifying templates were applied correctly after recording
- Understanding what variables were extracted and where they appear
- Debugging template matching issues

## Usage

    $ mix req_cassette.inspect path/to/cassette.json
    $ mix req_cassette.inspect cassette1.json cassette2.json

## Options

  * `--verbose`, `-v` - Show full request/response bodies
  * `--json`, `-j` - Output as JSON for programmatic use

## Examples

    # Basic inspection
    $ mix req_cassette.inspect test/cassettes/llm_chat.json

    Cassette: test/cassettes/llm_chat.json
    Version: 2.0
    Interactions: 2

    Interaction #1 (recorded: 2025-01-15T10:30:00Z)
      Template: ENABLED
      Patterns: msg_id, toolu_id
      Recorded Values:
        msg_id.0 = "msg_01XzW7o3s58J6KauMpLBFtEf"
        toolu_id.0 = "toolu_01K6u2Q9D6W7heeVvKAcLcAJ"
      Request: POST https://api.anthropic.com/v1/messages
      Response: 200 OK

    # JSON output for scripting
    $ mix req_cassette.inspect --json test/cassettes/llm_chat.json | jq '.interactions[0].recorded_values'