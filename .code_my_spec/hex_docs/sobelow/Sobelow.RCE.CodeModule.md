# Sobelow.RCE.CodeModule

# Code Execution in `eval` function

Arbitrary strings passed to the `Code.eval_*` functions can be
executed as malicious code.

Ensure the the code passed to the function is not user-controlled
or remove the function call completely.

Read more about Elixir RCE here:
https://erlef.github.io/security-wg/secure_coding_and_deployment_hardening/sandboxing

Code Execution checks can be ignored with the following command:

    $ mix sobelow -i RCE.CodeModule