# Tesla.OpenAPI.CookieParams

A collection of cookie parameter definitions.

`Tesla.OpenAPI.CookieParams` keeps static cookie parameter metadata separate
from per-request values. Since cookie parameter definitions usually come from
a static operation specification, prefer defining the collection in a module
attribute and passing only dynamic values when creating request headers.

    defmodule MyApi.Operation.GetItem.Cookie do
      alias Tesla.OpenAPI.{CookieParam, CookieParams}

      @cookie_params CookieParams.new!([
                       CookieParam.new!("session_id"),
                       CookieParam.new!("theme")
                     ])

      def to_headers(values) do
        CookieParams.to_headers(@cookie_params, values)
      end
    end