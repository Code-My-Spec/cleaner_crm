# HTTPoison.MaybeRedirect

If the option `:follow_redirect` is given to a request, HTTP redirects are automatically follow if
the method is set to `:get` or `:head` and the response's `status_code` is `301`, `302` or `307`.

If the method is set to `:post`, then the only `status_code` that get's automatically
followed is `303`.

If any other method or `status_code` is returned, then this struct is returned in place of a
`HTTPoison.Response` or `HTTPoison.AsyncResponse`, containing the `redirect_url` to allow you
to optionally re-request with the method set to `:get`.