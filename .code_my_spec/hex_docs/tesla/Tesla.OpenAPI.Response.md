# Tesla.OpenAPI.Response

Macro for defining generated-client response wrappers.

Generated clients own their response module and can use this macro to get a
small wrapper around `t:Tesla.Env.t/0`:

    defmodule MyApi.Response do
      use Tesla.OpenAPI.Response
    end