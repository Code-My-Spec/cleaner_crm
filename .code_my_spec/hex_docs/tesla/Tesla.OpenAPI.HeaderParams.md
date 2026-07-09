# Tesla.OpenAPI.HeaderParams

A collection of header parameter definitions.

`Tesla.OpenAPI.HeaderParams` keeps static header parameter metadata separate
from per-request values. Since header parameter definitions usually come from
a static operation specification, prefer defining the collection in a module
attribute and passing only dynamic values when creating request headers.

    defmodule MyApi.Operation.GetItem.Header do
      alias Tesla.OpenAPI.{HeaderParam, HeaderParams}

      @header_params HeaderParams.new!([
                       HeaderParam.new!("X-Request-ID")
                     ])

      def to_headers(values) do
        HeaderParams.to_headers(@header_params, values)
      end
    end