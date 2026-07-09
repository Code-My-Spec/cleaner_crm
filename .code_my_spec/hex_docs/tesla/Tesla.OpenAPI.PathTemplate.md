# Tesla.OpenAPI.PathTemplate

A precompiled OpenAPI Path Templating path.

`Tesla.OpenAPI.PathTemplate` keeps the request path as a string while carrying a
compiled representation that `Tesla.Middleware.PathParams` can use to avoid
parsing the same path template on every request.

    alias Tesla.OpenAPI.PathTemplate

    template = PathTemplate.new!("/items/{id}")
    path_params = Tesla.OpenAPI.PathParams.new!([Tesla.OpenAPI.PathParam.new!("id")])

    private =
      %{}
      |> PathTemplate.put_private(template)
      |> Tesla.OpenAPI.PathParams.put_private(path_params)

    Tesla.get(client, template.path,
      opts: [path_params: %{"id" => id}],
      private: private
    )

Path templates follow the [OpenAPI Path Templating][oas-path-templating]
syntax for `{name}` template expressions.

[oas-path-templating]: https://spec.openapis.org/oas/latest.html#path-templating

## put_private/1

Adds the compiled path template to `t:Tesla.Env.private/0`.

    template = Tesla.OpenAPI.PathTemplate.new!("/items/{id}")
    path_params = Tesla.OpenAPI.PathParams.new!([Tesla.OpenAPI.PathParam.new!("id")])

    private =
      %{}
      |> Tesla.OpenAPI.PathTemplate.put_private(template)
      |> Tesla.OpenAPI.PathParams.put_private(path_params)

    Tesla.get(client, template.path,
      opts: [path_params: %{"id" => id}],
      private: private
    )