# Sobelow.CI.System

# Command Injection via `System`

This submodule of the `CI` module checks for Command Injection
vulnerabilities through usage of the `System.cmd` function.

Ensure the the command passed to `System.cmd` is not user-controlled.

`System.cmd` Injection checks can be ignored with the following command:

    $ mix sobelow -i CI.System