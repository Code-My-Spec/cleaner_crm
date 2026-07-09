# Sobelow.XSS.ContentType

# XSS in `put_resp_content_type`

If an attacker is able to set arbitrary content types for an
HTTP response containing user input, the attacker is likely to
be able to leverage this for cross-site scripting (XSS).

For example, consider an endpoint that returns JSON with user
input:

    {"json": "user_input"}

If an attacker can control the content type set in the HTTP
response, they can set it to "text/html" and update the
JSON to the following in order to cause XSS:

    {"json": "<script>alert(document.domain)</script>"}

Content Type checks can be ignored with the following command:

    $ mix sobelow -i XSS.ContentType