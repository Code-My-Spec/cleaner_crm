# Sobelow.Traversal.SendFile

# Directory Traversal in `send_file`

This submodule checks for directory traversal vulnerabilities in the
`send_file` function.

Ensure that the path passed to `send_file` is not user-controlled.

Send File checks can be ignored with the following command:

    $ mix sobelow -i Traversal.SendFile