# SexySpex.Reporter

Handles reporting and output formatting for spex execution.

Provides a clean interface for tracking spex execution progress and
generating human-readable output.

## Quiet Mode (Default)

Reporter output is suppressed by default. Use `--verbose` flag to enable
detailed Reporter output alongside ExUnit results.

## JSONL Output

Use `--jsonl` flag to output test failures as JSONL for machine parsing.
Each failure includes BDD step context (Given/When/Then) alongside error info.

## start_spex/2

Starts reporting for a new specification.

## spex_passed/1

Reports successful completion of a specification.

## spex_failed/3

Reports failure of a specification.

## start_scenario/1

Starts reporting for a new scenario.

## scenario_passed/1

Reports successful completion of a scenario.

## scenario_failed/3

Reports failure of a scenario.

## step/2

Reports execution of a Given-When-Then step.