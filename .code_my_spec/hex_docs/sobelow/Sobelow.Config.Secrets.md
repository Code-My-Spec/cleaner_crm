# Sobelow.Config.Secrets

# Hard-coded Secrets

In the event of a source-code disclosure via file read
vulnerability, accidental commit, etc, hard-coded secrets
may be exposed to an attacker. This may result in
database access, cookie forgery, and other issues.

Sobelow detects missing hard-coded secrets by checking the prod
configuration.

Hard-coded secrets checks can be ignored with the following command:

    $ mix sobelow -i Config.Secrets