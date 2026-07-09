# SexySpex.StepExecutor

Core step execution system for SexySpex.

Handles stepping, manual mode, timing, and execution control across all adapters.
This module provides framework-agnostic step control, allowing manual mode to work
with any testing scenario (Scenic, Phoenix, libraries, etc.).

## execute_step/3

Executes a step with the configured execution mode.

Supports:
- Normal execution (immediate)
- Timed execution (with delays)
- Manual mode (step-by-step with user prompts)

## Parameters

  * `step_type` - The type of step ("Given", "When", "Then", "And")
  * `description` - Human-readable description of the step
  * `step_function` - The function to execute for this step (arity 0)

## Configuration

Reads configuration from application environment:
- `:sexy_spex, :manual_mode` - Boolean, enables manual stepping
- `:sexy_spex, :step_delay` - Integer, delay in ms between steps
- `:sexy_spex, :speed` - Atom, execution speed (:slow, :normal, :fast, :manual)

## execute_step/4

Executes a step with context passed as argument (like ExUnit setup).

## Parameters

  * `step_type` - The type of step ("Given", "When", "Then", "And")
  * `description` - Human-readable description of the step
  * `context` - Current context map
  * `step_function` - Function that receives context and returns updated context