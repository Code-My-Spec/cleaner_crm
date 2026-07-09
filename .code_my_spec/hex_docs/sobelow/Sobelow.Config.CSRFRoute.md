# Sobelow.Config.CSRFRoute

# Cross-Site Request Forgery

In a Cross-Site Request Forgery (CSRF) attack, an untrusted
application can cause a user's browser to submit requests or perform
actions on the user's behalf.

Read more about CSRF here:
https://www.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)

This type of CSRF is flagged by `sobelow` when state-changing
routes share an action with GET-based routes. For example:

    get "/users", UserController, :new
    post "/users", UserController, :new

In this instance, it may be possible to trigger the POST
functionality with a GET request and query parameters.

CSRF checks can be ignored with the following command:

    $ mix sobelow -i Config.CSRFRoute