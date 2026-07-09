# Swoosh.TestAssertions



## set_swoosh_global/1

Sets Swoosh test adapter to global mode.

In global mode, emails are consumed by the current test process,
doesn't matter which process sent it.

An ExUnit case where tests use Swoosh in global mode cannot be `async: true`.

## Examples

    defmodule MyTest do
      use ExUnit.Case, async: false

      import Swoosh.Email
      import Swoosh.TestAssertions

      setup :set_swoosh_global

      test "it sends email" do
        # ...
        assert_email_sent(subject: "Hi Avengers!")
      end
    end