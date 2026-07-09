# Sobelow.Traversal.FileModule

# Directory Traversal in `File` function

This submodule checks for directory traversal vulnerabilities in the `File`
module.

Ensure that the path passed to `File` functions is not user-controlled.

File checks can be ignored with the following command:

    $ mix sobelow -i Traversal.FileModule