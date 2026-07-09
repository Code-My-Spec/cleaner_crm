# Sobelow.RCE

# Remote Code Execution

Remote Code Execution vulnerabilities are a result of
untrusted user input being executed or interpreted by
the system and may result in complete system compromise.

If you wish to learn more about the specific vulnerabilities
found within the Remote Code Execution category, you may run the
following commands to find out more:

        $ mix sobelow -d RCE.EEx
        $ mix sobelow -d RCE.CodeModule

Remote Code Execution checks of all types can be ignored with the
following command:

    $ mix sobelow -i RCE