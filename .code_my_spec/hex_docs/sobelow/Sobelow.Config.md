# Sobelow.Config

# Configuration

Submodules contained within this vulnerability type
are related to common insecurities found in how
Phoenix applications are configured.

This can include things like missing headers,
insecure cookies, and more.

If you wish to learn more about the specific vulnerabilities
found within the Configuration category, you may run the
following commands to find out more:

          $ mix sobelow -d Config.CSP
          $ mix sobelow -d Config.CSRF
          $ mix sobelow -d Config.CSRFRoute
          $ mix sobelow -d Config.CSWH
          $ mix sobelow -d Config.Headers
          $ mix sobelow -d Config.Secrets
          $ mix sobelow -d Config.HTTPS
          $ mix sobelow -d Config.HSTS

Configuration checks of all types can be ignored with the
following command:

    $ mix sobelow -i Config