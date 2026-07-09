# Sobelow.Config.Headers

# Missing Secure HTTP Headers

By default, Phoenix HTTP responses contain a number of
secure HTTP headers that attempt to mitigate XSS,
click-jacking, and content-sniffing attacks.

Missing Secure HTTP Headers is flagged by `sobelow` when
a pipeline accepts "html" requests, but does not implement
the `:put_secure_browser_headers` plug.

Secure Headers checks can be ignored with the following
command:

    $ mix sobelow -i Config.Headers