# Mix.Tasks.Spex

Run spex files - executable specifications for AI-driven development.

SexySpex provides a framework for writing executable specifications that serve as
both tests and living documentation, optimized for AI-driven development workflows.

Each spex file manages its own application lifecycle using setup_all and setup blocks:
- setup_all: Application startup and shutdown
- setup: State reset between tests
- Context passing between test steps
- Integration with external tools (like ScenicMCP for GUI testing)

## Usage

    mix spex                    # Run all spex files
    mix spex path/to/file.exs   # Run specific spex file
    mix spex --help             # Show this help

## Options

    --pattern       File pattern to match (default: test/spex/**/*_spex.exs)
    --verbose       Show detailed spex Reporter output (quiet by default)
    --timeout       Test timeout in milliseconds (default: 60000)
    --manual        Interactive manual mode - step through each action
    --speed         Execution speed: fast (default), medium, slow
    --trace         Enable ExUnit trace mode (shows test execution details)
    --slowest N     Print timing information for the N slowest tests
    --formatter     ExUnit formatter module (default: ExUnit.CLIFormatter)
                    Can be specified multiple times
    --jsonl [PATH]  Output failures as JSONL (default: spex_failures.jsonl)
    --stale         Only run spex files that have changed or reference changed modules
    --force         Force all spex files to run (use with --stale to reset)

## Examples

    mix spex
    mix spex test/spex/user_login_spex.exs
    mix spex --pattern "**/integration_*_spex.exs"
    mix spex --verbose
    mix spex --manual           # Interactive step-by-step mode
    mix spex --speed slow       # Slower automatic execution
    mix spex --speed medium --verbose  # Medium speed with detailed output
    mix spex --trace            # Show detailed test execution
    mix spex test/spex/file.exs --trace
    mix spex --slowest 5        # Show timing for 5 slowest tests

## Configuration

You can configure spex behavior in your config files:

    config :sexy_spex,
      manual_mode: false,
      step_delay: 0

Application lifecycle is handled in individual spex files using setup_all blocks.

## Important: Test Environment Setup

To ensure spex runs in the test environment with proper module compilation,
add this to your project's mix.exs:

    def project do
      [
        # ... other config
        preferred_cli_env: [
          spex: :test
        ]
      ]
    end

This ensures that `mix spex` always runs in the test environment and compiles
modules with test-specific code paths (e.g., test/support directories).