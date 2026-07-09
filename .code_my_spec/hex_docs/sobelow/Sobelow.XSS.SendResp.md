# Sobelow.XSS.SendResp

# XSS in `send_resp`

This submodule looks for XSS vulnerabilities in the `body`
argument of `Conn.send_resp`.

SendResp checks can be ignored with the following command:

    $ mix sobelow -i XSS.SendResp