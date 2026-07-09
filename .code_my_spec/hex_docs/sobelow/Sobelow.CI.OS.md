# Sobelow.CI.OS

# Command Injection in `:os.cmd`

This submodule of the `CI` module checks for Command Injection
vulnerabilities through usage of the `:os.cmd` function.

Ensure the the command passed to `:os.cmd` is not user-controlled.

`:os.cmd` Injection checks can be ignored with the following command:

    $ mix sobelow -i CI.OS