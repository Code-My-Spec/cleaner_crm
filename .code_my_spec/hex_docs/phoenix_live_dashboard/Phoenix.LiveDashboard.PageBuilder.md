# Phoenix.LiveDashboard.PageBuilder

Page builder is the default mechanism for building custom dashboard pages.

Each dashboard page is a LiveView with additional callbacks for
customizing the menu appearance and the automatic refresh.

A simple and straight-forward example of a custom page is the
`Phoenix.LiveDashboard.EtsPage` that ships with the dashboard:

    defmodule Phoenix.LiveDashboard.EtsPage do
      @moduledoc false
      use Phoenix.LiveDashboard.PageBuilder

      @impl true
      def menu_link(_, _) do
        {:ok, "ETS"}
      end

      @impl true
      def render(assigns) do
        ~H"""
        <.live_table
          id="ets-table"
          dom_id="ets-table"
          page={@page}
          title="ETS"
          row_fetcher={&fetch_ets/2}
          row_attrs={&row_attrs/1}
          rows_name="tables"
        >
          <:col field={:name} header="Name or module" />
          <:col field={:protection} />
          <:col field={:type} />
          <:col field={:size} text_align="right" sortable={:desc} />
          <:col field={:memory} text_align="right" sortable={:desc} :let={ets}>
            <%= format_words(ets[:memory]) %>
          </:col>
          <:col field={:owner} :let={ets} >
            <%= encode_pid(ets[:owner]) %>
          </:col>
        </.live_table>
        """
      end

      defp fetch_ets(params, node) do
        %{search: search, sort_by: sort_by, sort_dir: sort_dir, limit: limit} = params

        # Here goes the code that goes through all ETS tables, searches
        # (if not nil), sorts, and limits them.
        #
        # It must return a tuple where the first element is list with
        # the current entries (up to limit) and an integer with the
        # total amount of entries.
        # ...
      end

      defp row_attrs(table) do
        [
          {"phx-click", "show_info"},
          {"phx-value-info", encode_ets(table[:id])},
          {"phx-page-loading", true}
        ]
      end
    end

Once a page is defined, it must be declared in your `live_dashboard`
route as follows:

    live_dashboard "/dashboard",
      additional_pages: [
        route_name: MyAppWeb.MyCustomPage
      ]

Or alternatively:

    live_dashboard "/dashboard",
      additional_pages: [
        route_name: {MyAppWeb.MyCustomPage, some_option: ...}
      ]

The second argument of the tuple will be given to the `c:init/1`
callback. If not tuple is given, `c:init/1` will receive an empty
list.

## Options for the use macro

The following options can be given when using the `PageBuilder` module:

* `refresher?` - Boolean to enable or disable the automatic refresh in the page.

## Components

A page can return any valid HEEx template in the `render/1` callback,
and it can use the components listed with this page too.

We currently support `card/1`, `fields_card/1`, `row/1`,
`shared_usage_card/1`, and `usage_card/1`;
and the live components `live_layered_graph/1`, `live_nav_bar/1`,
and `live_table/1`.

## Helpers

Some helpers are available for page building. The supported
helpers are: `live_dashboard_path/2`, `live_dashboard_path/3`,
`encode_app/1`, `encode_ets/1`, `encode_pid/1`, `encode_port/1`,
and `encode_socket/1`.

## Custom Hooks

If your page needs to register custom hooks, you can use the `register_after_opening_head_tag/2`
function. Because the hooks need to be available on the dead render in the layout, before the
LiveView's LiveSocket is configured, your need to do this inside an `on_mount` hook:

```elixir
defmodule MyAppWeb.MyLiveDashboardHooks do
  import Phoenix.LiveView
  import Phoenix.Component

  alias Phoenix.LiveDashboard.PageBuilder

  def on_mount(:default, _params, _session, socket) do
    {:cont, PageBuilder.register_after_opening_head_tag(socket, &after_opening_head_tag/1)}
  end

  defp after_opening_head_tag(assigns) do
    ~H"""
    <script nonce={@csp_nonces[:script]}>
      window.LiveDashboard.registerCustomHooks({
        MyHook: {
          mounted() {
            // do something
          }
        }
      })
    </script>
    """
  end
end

defmodule MyAppWeb.MyCustomPage do
  ...
end
```

And then add it to the list of `on_mount` hooks in the `live_dashboard` router configuration:

```elixir
live_dashboard "/dashboard",
  additional_pages: [
    route_name: MyAppWeb.MyCustomPage
  ],
  on_mount: [
    MyAppWeb.MyLiveDashboardHooks
  ]
```

The LiveDashboard provides a function `window.LiveDashboard.registerCustomHooks({ ... })` that you can call
with an object of hook declarations.

Note that in order to use external libraries, you will either need to include them from
a CDN, or bundle them yourself and include them from your app's static paths.

> #### A note on CSPs and libraries {: .info}
>
> Phoenix LiveDashboard supports CSP nonces for its own assets, configurable using the
> `Phoenix.LiveDashboard.Router.live_dashboard/2` macro by setting the `:csp_nonce_assign_key`
> option. If you are building a library, ensure that you render those CSP nonces on any scripts,
> styles or images of your page. The nonces are passed to your custom page under the `:csp_nonces` assign
> and also available in  the `after_opening_head_tag` component.
>
> You should use those when including scripts or styles like this:
>
> ```heex
> <script nonce={@csp_nonces.script}>...</script>
> <script nonce={@csp_nonces.script} src="..."></script>
> <style nonce={@csp_nonces.style}>...</style>
> <link rel="stylesheet" href="..." nonce={@csp_nonces.style}>
> ```
>
> This ensures that your custom page can be used when a CSP is in place using the mechanism
> supported by Phoenix LiveDashboard.
>
> If your custom page needs a different CSP policy, for example due to inline styles set by scripts,
> please consider documenting these requirements.

## live_table/1

Table live component.

You can see it in use the applications, processes, sockets pages and many others.

## live_nav_bar/1

Nav bar live component.

You can see it in use the Metrics and Ecto info pages.

## hint/1

Hint pop-up text component

## card_title/1

Card title component.

## card/1

Card component.

You can see it in use the Home and OS Data pages.

## fields_card/1

Fields card component.

You can see it in use the Home page in the Environment section.

## row/1

Row component.

You can see it in use the Home page and OS Data pages.

## usage_card/1

Usage card component.

You can see it in use the Home page and OS Data pages.

## shared_usage_card/1

Shared usage card component.

You can see it in use the Home page and OS Data pages.

## live_layered_graph/1

A component for drawing layered graphs.

This is useful to represent pipelines like we have on
[BroadwayDashboard](https://hexdocs.pm/broadway_dashboard) where
each layer points to nodes of the layer below.
It draws the layers from top to bottom.

The calculation of layers and positions is done automatically
based on options.

[INSERT LVATTRDOCS]

## Examples

    iex> layers = [
    ...>   [
    ...>     %{
    ...>       id: "a1",
    ...>       data: "a1",
    ...>       children: ["b1"]
    ...>     }
    ...>   ],
    ...>   [
    ...>     %{
    ...>       id: "b1"
    ...>       data: %{
    ...>         detail: 0,
    ...>         label: "b1"
    ...>       },
    ...>       children: []
    ...>      }
    ...>    ]
    ...> ]

## label_value_list/1

List of label value.

You can see it in use in the modal in Ports or Processes page.

## encode_socket/1

Encodes Sockets for URLs.

## Example

This function can be used to encode `@socket` for an event value:

    <button phx-click="show-info" phx-value-info=<%= encode_socket(@socket) %>/>

## encode_ets/1

Encodes ETSs references for URLs.

## Example

This function can be used to encode an ETS reference for an event value:

    <button phx-click="show-info" phx-value-info=<%= encode_ets(@reference) %>/>

## encode_pid/1

Encodes PIDs for URLs.

## Example

This function can be used to encode a PID for an event value:

    <button phx-click="show-info" phx-value-info=<%= encode_pid(@pid) %>/>

## encode_port/1

Encodes Port for URLs.

## Example

This function can be used to encode a Port for an event value:

    <button phx-click="show-info" phx-value-info=<%= encode_port(@port) %>/>

## encode_app/1

Encodes an application for URLs.

## Example

This function can be used to encode an application for an event value:

    <button phx-click="show-info" phx-value-info=<%= encode_app(@my_app) %>/>

## live_dashboard_path/2

Computes a router path to the current page.

## live_dashboard_path/3

Computes a router path to the current page with merged params.

## register_after_opening_head_tag/2

Registers a component to be rendered after the opening head tag in the layout.

## register_before_closing_head_tag/2

Registers a component to be rendered before the closing head tag in the layout.