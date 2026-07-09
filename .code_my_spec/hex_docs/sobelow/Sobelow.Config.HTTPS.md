# Sobelow.Config.HTTPS

# HTTPS

Without HTTPS, attackers in a privileged network position can
intercept and modify traffic.

Sobelow detects missing HTTPS by checking the prod
configuration.

HTTPS checks can be ignored with the following command:

    $ mix sobelow -i Config.HTTPS