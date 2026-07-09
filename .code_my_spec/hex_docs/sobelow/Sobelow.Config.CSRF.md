# Sobelow.Config.CSRF

# Cross-Site Request Forgery

In a Cross-Site Request Forgery (CSRF) attack, an untrusted
application can cause a user's browser to submit requests or perform
actions on the user's behalf.

Read more about CSRF here:
https://owasp.org/www-community/attacks/csrf

Cross-Site Request Forgery is flagged by `sobelow` when
a pipeline fetches a session, but does not implement the
`:protect_from_forgery` plug.

CSRF checks can be ignored with the following command:

    $ mix sobelow -i Config.CSRF