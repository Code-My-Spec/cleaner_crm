# Sobelow.Traversal.SendDownload

# Directory Traversal in `send_download`

This submodule checks for directory traversal vulnerabilities in the
`send_download` function of a Phoenix Controller.

Ensure that the path passed to `send_download` is not user-controlled.

Send Download checks can be ignored with the following command:

    $ mix sobelow -i Traversal.SendDownload