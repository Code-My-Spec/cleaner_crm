# Sobelow.CI

# Command Injection

Command Injection vulnerabilities are a result of
passing untrusted input to an operating system shell,
and may result in complete system compromise.

Read more about Command Injection here:
https://www.owasp.org/index.php/Command_Injection

If you wish to learn more about the specific vulnerabilities
found within the Command Injection category, you may run the
following commands to find out more:

      $ mix sobelow -d CI.OS
      $ mix sobelow -d CI.System

Command Injection checks of all types can be ignored with the
following command:

    $ mix sobelow -i CI