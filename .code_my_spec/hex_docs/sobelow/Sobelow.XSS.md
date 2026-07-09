# Sobelow.XSS

# Cross-Site Scripting

Cross-Site Scripting (XSS) vulnerabilities are a result
of rendering untrusted input on a page without proper encoding.
XSS may allow an attacker to perform actions on behalf of
other users, steal session tokens, or access private data.

Read more about XSS here:
https://www.owasp.org/index.php/Cross-site_Scripting_(XSS)

If you wish to learn more about the specific vulnerabilities
found within the Cross-Site Scripting category, you may run the
following commands to find out more:

          $ mix sobelow -d XSS.SendResp
          $ mix sobelow -d XSS.ContentType
          $ mix sobelow -d XSS.Raw
          $ mix sobelow -d XSS.HTML

XSS checks of all types can be ignored with the following command:

    $ mix sobelow -i XSS