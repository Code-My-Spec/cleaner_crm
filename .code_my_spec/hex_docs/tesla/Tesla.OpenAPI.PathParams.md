# Tesla.OpenAPI.PathParams

A collection of path parameter definitions for `Tesla.Middleware.PathParams`.

`Tesla.OpenAPI.PathParams` keeps static path parameter metadata separate from
per-request values. Since path parameter definitions usually come from a
static operation specification, prefer defining the collection in a module
attribute, storing it in `t:Tesla.Env.private/0`, and passing only the dynamic
values through `opts[:path_params]`.

    defmodule MyApi.Operation.GetItem do
      alias Tesla.OpenAPI.{PathParam, PathParams}

      @path_params PathParams.new!([
                     PathParam.new!("id"),
                     PathParam.new!("coords", style: :matrix, explode: true)
                   ])

      @private PathParams.put_private(@path_params)

      def request(client) do
        Tesla.get(client, "/items/{id}{coords}",
          opts: [path_params: %{"id" => 5, "coords" => ["blue", "black"]}],
          private: @private
        )
      end
    end

## put_private/1

Adds path parameter definitions to `t:Tesla.Env.private/0`.

    defmodule MyApi.Operation.GetItem do
      @path_params Tesla.OpenAPI.PathParams.new!([Tesla.OpenAPI.PathParam.new!("id")])
      @private Tesla.OpenAPI.PathParams.put_private(@path_params)

      def request(client) do
        Tesla.get(client, "/items/{id}",
          opts: [path_params: %{"id" => 42}],
          private: @private
        )
      end
    end