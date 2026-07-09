# Sobelow.Vuln

# Known Vulnerable Dependencies

An application with known vulnerabilities is more easily subjected
to automated or targeted attacks.

If you wish to learn more about the specific vulnerabilities
found within the Known Vulnerable Dependencies category, you may run the
following commands to find out more:

          $ mix sobelow -d Vuln.PlugNull
          $ mix sobelow -d Vuln.CookieRCE
          $ mix sobelow -d Vuln.HeaderInject
          $ mix sobelow -d Vuln.Redirect
          $ mix sobelow -d Vuln.Coherence
          $ mix sobelow -d Vuln.Ecto

Known Vulnerable checks of all types can be ignored with the following command:

    $ mix sobelow -i Vuln