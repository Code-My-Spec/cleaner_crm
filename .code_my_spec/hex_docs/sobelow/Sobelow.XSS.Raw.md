# Sobelow.XSS.Raw

# XSS in `raw`

This submodule checks for the use of `raw` in templates
as this can lead to XSS vulnerabilities if taking user input.

Raw checks can be ignored with the following command:

    $ mix sobelow -i XSS.Raw