# Sobelow.Config.CSWH

# Cross-Site Websocket Hijacking

Websocket connections are not bound by the same-origin policy.
Connections that do not validate the origin may leak information
to an attacker.

More information can be found here: https://www.christian-schneider.net/CrossSiteWebSocketHijacking.html

Cross-Site Websocket Hijacking checks can be disabled with
the following command:

    $ mix sobelow -i Config.CSWH