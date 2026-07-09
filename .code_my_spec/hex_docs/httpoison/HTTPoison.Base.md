# HTTPoison.Base

Provides a default implementation for HTTPoison functions.

This module is meant to be `use`'d in custom modules in order to wrap the
functionalities provided by HTTPoison. For example, this is very useful to
build API clients around HTTPoison:

    defmodule GitHub do
      use HTTPoison.Base

      @endpoint "https://api.github.com"

      def process_request_url(url) do
        @endpoint <> url
      end
    end

The example above shows how the `GitHub` module can wrap HTTPoison
functionalities to work with the GitHub API in particular; this way, for
example, all requests done through the `GitHub` module will be done to the
GitHub API:

    GitHub.get("/users/octocat/orgs")
    #=> will issue a GET request at https://api.github.com/users/octocat/orgs

## Overriding functions

`HTTPoison.Base` defines the following list of functions, all of which can be
overridden (by redefining them). The following list also shows the typespecs
for these functions and a short description.

    # Called in order to process the url passed to any request method before
    # actually issuing the request.
    @spec process_request_url(binary) :: binary
    def process_request_url(url)

    # Called to arbitrarily process the request body before sending it with the
    # request.
    @spec process_request_body(term) :: binary
    def process_request_body(body)

    # Called to arbitrarily process the request headers before sending them
    # with the request.
    @spec process_request_headers(term) :: [{binary, term}]
    def process_request_headers(headers)

    # Called to arbitrarily process the request options before sending them
    # with the request.
    @spec process_request_options(keyword) :: keyword
    def process_request_options(options)

    # Called before returning the response body returned by a request to the
    # caller.
    @spec process_response_body(binary) :: term
    def process_response_body(body)

    # Used when an async request is made; it's called on each chunk that gets
    # streamed before returning it to the streaming destination.
    @spec process_response_chunk(binary) :: term
    def process_response_chunk(chunk)

    # Called to process the response headers before returning them to the
    # caller.
    @spec process_headers([{binary, term}]) :: term
    def process_headers(headers)

    # Used to arbitrarily process the status code of a response before
    # returning it to the caller.
    @spec process_response_status_code(integer) :: term
    def process_response_status_code(status_code)