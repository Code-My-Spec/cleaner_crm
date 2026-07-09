# Assent.HTTPAdapter.Finch

HTTP adapter module for making http requests with Finch.

The Finch adapter must be configured with the supervisor by passing it as an
option:

    http_adapter: {Assent.HTTPAdapter.Finch, [supervisor: MyFinch]}

See `Assent.HTTPAdapter` for more.