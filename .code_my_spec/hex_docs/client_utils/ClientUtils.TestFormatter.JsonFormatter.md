# ClientUtils.TestFormatter.JsonFormatter

Handles formatting of ExUnit test results into JSON-compatible maps.

## format_stats/3

Receives test stats and formats them to JSON

## format_suite_start_event/1

Formats the suite start streaming event.

## format_suite_end_event/1

Formats the suite end streaming event.

## format_suite_result/4

Formats the final suite result with all test data.

## format_test_event/2

Formats a streaming event for a test.

## format_test_pass/1

Receives a test and formats its information

## format_test_pending/1

Formats a skipped or excluded test as pending.

## format_test_failure/2

Receives a test and formats its failure.

## format_test_case_failure/2

Receives a test case and formats its failure.