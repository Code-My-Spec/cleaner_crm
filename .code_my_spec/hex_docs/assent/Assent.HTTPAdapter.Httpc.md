# Assent.HTTPAdapter.Httpc

HTTP adapter module for making http requests with `:httpc`.

SSL support will automatically be enabled if the `:certifi` and
`:ssl_verify_fun` libraries exists in your project. You can also override
the `:httpc` options by updating the configuration:

    http_adapter: {Assent.HTTPAdapter.Httpc, [...]}

For releases please make sure you have included `:inets` in your application:

    extra_applications: [:inets]

See `Assent.HTTPAdapter` for more.