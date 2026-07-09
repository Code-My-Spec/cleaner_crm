# Sobelow.Config.CSP

# Missing Content-Security-Policy

Content-Security-Policy is an HTTP header that helps mitigate
a number of attacks, including Cross-Site Scripting.

Read more about CSP here:
https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP

Missing Content-Security-Policy is flagged by `sobelow` when
a pipeline implements the `:put_secure_browser_headers` plug,
but does not provide a Content-Security-Policy header in the
custom headers map.

When it comes to CSP, just about any policy is better than none.
If you are unsure about which policy to use, the following
mitigates most typical XSS vectors:

`plug :put_secure_browser_headers, %{"content-security-policy" => "default-src 'self'"}`

Documentation on the `put_secure_browser_headers` plug function
can be found here:
https://hexdocs.pm/phoenix/Phoenix.Controller.html#put_secure_browser_headers/2

Content-Security-Policy checks can be ignored with the following command:

    $ mix sobelow -i Config.CSP