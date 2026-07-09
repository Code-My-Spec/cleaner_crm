# Tesla.OpenAPI.QueryParams

A collection of query parameter definitions for `Tesla.Middleware.Query`.

`Tesla.OpenAPI.QueryParams` keeps static query parameter metadata separate from
per-request values. Since query parameter definitions usually come from a
static operation specification, prefer defining the collection in a module
attribute, storing it in `t:Tesla.Env.private/0`, and passing only dynamic values
through `env.query`.

    defmodule MyApi.Operation.ListItems do
      alias Tesla.OpenAPI.{QueryParam, QueryParams}

      @query_params QueryParams.new!([
                      QueryParam.new!("filter"),
                      QueryParam.new!("ids", style: :pipe_delimited)
                    ])

      @private QueryParams.put_private(@query_params)

      def request(client) do
        Tesla.get(client, "/items",
          query: %{
            "filter" => [status: "open", owner: "yordis"],
            "ids" => [10, 20],
            "debug" => true
          },
          private: @private
        )
      end
    end

## put_private/1

Adds query parameter definitions to `t:Tesla.Env.private/0`.

    defmodule MyApi.Operation.ListItems do
      @query_params Tesla.OpenAPI.QueryParams.new!([Tesla.OpenAPI.QueryParam.new!("page")])
      @private Tesla.OpenAPI.QueryParams.put_private(@query_params)

      def request(client) do
        Tesla.get(client, "/items",
          query: %{"page" => 2},
          private: @private
        )
      end
    end