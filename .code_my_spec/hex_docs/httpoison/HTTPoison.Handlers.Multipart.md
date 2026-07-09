# HTTPoison.Handlers.Multipart

Provides a set of functions to handle multipart requests/responses

`HTTPoison.Handlers.Multipart` defines the following list of functions:

    # Used to parse a multipart response body
    # @type body :: binary | {:form, [{atom, any}]} | {:file, binary}
    # @spec decode_body(Response.t()) :: body
    # def decode_body(response)

## decode_body/1

Parses a multipart response body.

It uses `:hackney_headers` to understand if the content type of the response
is multipart, in which case it uses `:hackney_multipart` to decode the body of
the response.

For example, if we have the following `multipart` response body:

    --123
    Content-type: application/json
    {"1": "first"}
    --123
    Content-type: application/json
    {"2": "second"}
    --123--

We can parse the body of the response to its various parts:

    HTTPoison.Handlers.Multipart.decode_body(response)
    #=> will decode a multipart body, e.g. yielding
    # [
    #   {[{"Content-Type", "application/json"}], "{"1": "first"}"},
    #   {[{"Content-Type", "application/json"}], "{"2": "second"}"}
    # ]

In case the content type is not multipart, the original body is returned.