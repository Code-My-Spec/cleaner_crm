# Sobelow.RCE.EEx

# Insecure EEx evaluation

If user input is passed to EEx eval functions, it may result in
arbitrary code execution. The root cause of these issues is often
directory traversal.

EEx checks can be ignored with the following command:

    $ mix sobelow -i RCE.EEx