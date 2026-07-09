# HTTPoison.MaybeRedirect

Deprecated as of the hackney 4.0 upgrade.

Earlier versions returned this struct in place of a `HTTPoison.Response` when
a redirect could not be followed automatically, so the caller could re-request
the `redirect_url` itself. As of hackney 4.0 redirects are resolved inside
hackney and the final response is returned, so this struct is no longer
produced. It is retained only for backward compatibility.