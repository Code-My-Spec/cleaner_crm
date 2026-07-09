# Phoenix.LiveViewTest



## put_connect_params/2

Puts connect params to be used on LiveView connections.

See `Phoenix.LiveView.get_connect_params/1`.

## live/3

Spawns a connected LiveView process.

If a `path` is given, then a regular `get(conn, path)`
is done and the page is upgraded to a LiveView. If
no path is given, it assumes a previously rendered
`%Plug.Conn{}` is given, which will be converted to
a LiveView immediately.

## Options

  * `:on_error` - Can be either `:raise` or `:warn` to control whether
     detected errors like duplicate IDs or live components fail the test or just log
     a warning. Defaults to `:raise`.

## Examples

    {:ok, view, html} = live(conn, "/path")
    assert view.module == MyLive
    assert html =~ "the count is 3"

    assert {:error, {:redirect, %{to: "/somewhere"}}} = live(conn, "/path")

## live_isolated/3

Spawns a connected LiveView process mounted in isolation as the sole rendered element.

Useful for testing LiveViews that are not directly routable, such as those
built as small components to be re-used in multiple parents. Testing routable
LiveViews is still recommended whenever possible since features such as
live navigation require routable LiveViews.

## Options

  * `:session` - the session to be given to the LiveView
  * `:on_error` - Can be either `:raise` or `:warn` to control whether
     detected errors like duplicate IDs or live components fail the test or just log
     a warning. Defaults to `:raise`.

All other options are forwarded to the LiveView for rendering. Refer to
`Phoenix.Component.live_render/3` for a list of supported render
options.

## Examples

    {:ok, view, html} =
      live_isolated(conn, MyAppWeb.ClockLive, session: %{"tz" => "EST"})

Use `put_connect_params/2` to put connect params for a call to
`Phoenix.LiveView.get_connect_params/1` in `c:Phoenix.LiveView.mount/3`:

    {:ok, view, html} =
      conn
      |> put_connect_params(%{"param" => "value"})
      |> live_isolated(AppWeb.ClockLive, session: %{"tz" => "EST"})

## render_component/3

Renders a component.

The first argument may either be a function component, as an
anonymous function:

    assert render_component(&Weather.city/1, name: "Kraków") =~
             "some markup in component"

Or a stateful component as a module. In this case, this function
will mount, update, and render the component. The `:id` option is
a required argument:

    assert render_component(MyComponent, id: 123, user: %User{}) =~
             "some markup in component"

If your component is using the router, you can pass it as argument:

    assert render_component(MyComponent, %{id: 123, user: %User{}}, router: SomeRouter) =~
             "some markup in component"

## render_click/2

Sends a click event given by `element` and returns the rendered result.

The `element` is created with `element/3` and must point to a single
element on the page with a `phx-click` attribute in it. The event name
given set on `phx-click` is then sent to the appropriate LiveView
(or component if `phx-target` is set accordingly). All `phx-value-*`
entries in the element are sent as values. Extra values can be given
with the `value` argument.

If the element does not have a `phx-click` attribute but it is
a link (the `<a>` tag), the link will be followed accordingly:

  * if the link is a `patch`, the current view will be patched
  * if the link is a `navigate`, this function will return
    `{:error, {:live_redirect, %{to: url}}}`, which can be followed
    with `follow_redirect/2`
  * if the link is a regular link, this function will return
    `{:error, {:redirect, %{to: url}}}`, which can be followed
    with `follow_redirect/2`

It returns the contents of the whole LiveView or an `{:error, redirect}`
tuple.

## Examples

    {:ok, view, html} = live(conn, "/thermo")

    assert view
           |> element("button", "Increment")
           |> render_click() =~ "The temperature is: 30℉"

## render_click/3

Sends a click `event` to the `view` with `value` and returns the rendered result.

It returns the contents of the whole LiveView or an `{:error, redirect}`
tuple.

## Examples

    {:ok, view, html} = live(conn, "/thermo")
    assert html =~ "The temperature is: 30℉"
    assert render_click(view, :inc) =~ "The temperature is: 31℉"

## put_submitter/2

Puts the submitter `element_or_selector` on the given `form` element.

A submitter is an element that initiates the form's submit event on the client. When a submitter
is put on an element created with `form/3` and then the form is submitted via `render_submit/2`,
the name/value pair of the submitter will be included in the submit event payload.

The given element or selector must exist within the form and match one of the following:

- A `button` or `input` element with `type="submit"`.

- A `button` element without a `type` attribute.

## Examples

    form = view |> form("#my-form")

    assert form
           |> put_submitter("button[name=example]")
           |> render_submit() =~ "Submitted example"

## render_submit/3

Sends a form submit event to the view and returns the rendered result.

It returns the contents of the whole LiveView or an `{:error, redirect}`
tuple.

## Examples

    {:ok, view, html} = live(conn, "/thermo")
    assert html =~ "The temp is: 30℉"
    assert render_submit(view, :refresh, %{deg: 32}) =~ "The temp is: 32℉"

## render_change/2

Sends a form change event given by `element` and returns the rendered result.

The `element` is created with `element/3` and must point to a single
element on the page with a `phx-change` attribute in it. The event name
given set on `phx-change` is then sent to the appropriate LiveView
(or component if `phx-target` is set accordingly). All `phx-value-*`
entries in the element are sent as values.

If you need to pass any extra values or metadata, such as the "_target"
parameter, you can do so by giving a map under the `value` argument.

It returns the contents of the whole LiveView or an `{:error, redirect}`
tuple.

## Examples

    {:ok, view, html} = live(conn, "/thermo")

    assert view
           |> element("form")
           |> render_change(%{deg: 123}) =~ "123 exceeds limits"

    # Passing metadata
    {:ok, view, html} = live(conn, "/thermo")

    assert view
           |> element("form")
           |> render_change(%{_target: ["deg"], deg: 123}) =~ "123 exceeds limits"

As with `render_submit/2`, hidden input field values can be provided like so:

    refute view
          |> form("#term", user: %{name: "hello"})
          |> render_change(%{user: %{"hidden_field" => "example"}}) =~ "can't be blank"

## render_change/3

Sends a form change event to the view and returns the rendered result.

It returns the contents of the whole LiveView or an `{:error, redirect}`
tuple.

## Examples

    {:ok, view, html} = live(conn, "/thermo")
    assert html =~ "The temp is: 30℉"
    assert render_change(view, :validate, %{deg: 123}) =~ "123 exceeds limits"

## render_keydown/2

Sends a keydown event given by `element` and returns the rendered result.

The `element` is created with `element/3` and must point to a single element
on the page with a `phx-keydown` or `phx-window-keydown` attribute in it.
The event name given set on `phx-keydown` is then sent to the appropriate
LiveView (or component if `phx-target` is set accordingly). All `phx-value-*`
entries in the element are sent as values. Extra values can be given with
the `value` argument.

It returns the contents of the whole LiveView or an `{:error, redirect}`
tuple.

## Examples

    {:ok, view, html} = live(conn, "/thermo")
    assert html =~ "The temp is: 30℉"
    assert view |> element("#inc") |> render_keydown() =~ "The temp is: 31℉"

## render_keydown/3

Sends a keydown event to the view and returns the rendered result.

It returns the contents of the whole LiveView or an `{:error, redirect}`
tuple.

## Examples

    {:ok, view, html} = live(conn, "/thermo")
    assert html =~ "The temp is: 30℉"
    assert render_keydown(view, :inc) =~ "The temp is: 31℉"

## render_keyup/2

Sends a keyup event given by `element` and returns the rendered result.

The `element` is created with `element/3` and must point to a single
element on the page with a `phx-keyup` or `phx-window-keyup` attribute
in it. The event name given set on `phx-keyup` is then sent to the
appropriate LiveView (or component if `phx-target` is set accordingly).
All `phx-value-*` entries in the element are sent as values. Extra values
can be given with the `value` argument.

It returns the contents of the whole LiveView or an `{:error, redirect}`
tuple.

## Examples

    {:ok, view, html} = live(conn, "/thermo")
    assert html =~ "The temp is: 30℉"
    assert view |> element("#inc") |> render_keyup() =~ "The temp is: 31℉"

## render_keyup/3

Sends a keyup event to the view and returns the rendered result.

It returns the contents of the whole LiveView or an `{:error, redirect}`
tuple.

## Examples

    {:ok, view, html} = live(conn, "/thermo")
    assert html =~ "The temp is: 30℉"
    assert render_keyup(view, :inc) =~ "The temp is: 31℉"

## render_blur/2

Sends a blur event given by `element` and returns the rendered result.

The `element` is created with `element/3` and must point to a single
element on the page with a `phx-blur` attribute in it. The event name
given set on `phx-blur` is then sent to the appropriate LiveView
(or component if `phx-target` is set accordingly). All `phx-value-*`
entries in the element are sent as values. Extra values can be given
with the `value` argument.

It returns the contents of the whole LiveView or an `{:error, redirect}`
tuple.

## Examples

    {:ok, view, html} = live(conn, "/thermo")

    assert view
           |> element("#inactive")
           |> render_blur() =~ "Tap to wake"

## render_blur/3

Sends a blur event to the view and returns the rendered result.

It returns the contents of the whole LiveView or an `{:error, redirect}`
tuple.

## Examples

    {:ok, view, html} = live(conn, "/thermo")
    assert html =~ "The temp is: 30℉"
    assert render_blur(view, :inactive) =~ "Tap to wake"

## render_focus/2

Sends a focus event given by `element` and returns the rendered result.

The `element` is created with `element/3` and must point to a single
element on the page with a `phx-focus` attribute in it. The event name
given set on `phx-focus` is then sent to the appropriate LiveView
(or component if `phx-target` is set accordingly). All `phx-value-*`
entries in the element are sent as values. Extra values can be given
with the `value` argument.

It returns the contents of the whole LiveView or an `{:error, redirect}`
tuple.

## Examples

    {:ok, view, html} = live(conn, "/thermo")

    assert view
           |> element("#inactive")
           |> render_focus() =~ "Tap to wake"

## render_focus/3

Sends a focus event to the view and returns the rendered result.

It returns the contents of the whole LiveView or an `{:error, redirect}`
tuple.

## Examples

    {:ok, view, html} = live(conn, "/thermo")
    assert html =~ "The temp is: 30℉"
    assert render_focus(view, :inactive) =~ "Tap to wake"

## render_hook/3

Sends a hook event to the view or an element and returns the rendered result.

It returns the contents of the whole LiveView or an `{:error, redirect}`
tuple.

## Examples

    {:ok, view, html} = live(conn, "/thermo")
    assert html =~ "The temp is: 30℉"
    assert render_hook(view, :refresh, %{deg: 32}) =~ "The temp is: 32℉"

If you are pushing events from a hook to a component, then you must pass
an `element`, created with `element/3`, as first argument and it must point
to a single element on the page with a `phx-target` attribute in it:

    {:ok, view, _html} = live(conn, "/thermo")
    assert view
           |> element("#thermo-component")
           |> render_hook(:refresh, %{deg: 32}) =~ "The temp is: 32℉"

## render_async/2

Awaits all current `assign_async`, `stream_async` and `start_async` tasks
for a given LiveView or element.

It renders the LiveView or Element once complete and returns the result.
The default `timeout` is [ExUnit](https://ex-unit.hexdocs.pm/ExUnit.html#configure/1)'s
`assert_receive_timeout` (100 ms).

## Examples

    {:ok, lv, html} = live(conn, "/path")
    assert html =~ "loading data..."
    assert render_async(lv) =~ "data loaded!"

## render_patch/2

Simulates a `push_patch` to the given `path` and returns the rendered result.

## live_children/1

Returns the current list of LiveView children for the `parent` LiveView.

Children are returned in the order they appear in the rendered HTML.

## Examples

    {:ok, view, _html} = live(conn, "/thermo")
    assert [clock_view] = live_children(view)
    assert render_click(clock_view, :snooze) =~ "snoozing"

## find_live_child/2

Gets the nested LiveView child by `child_id` from the `parent` LiveView.

## Examples

    {:ok, view, _html} = live(conn, "/thermo")
    assert clock_view = find_live_child(view, "clock")
    assert render_click(clock_view, :snooze) =~ "snoozing"

## has_element?/1

Checks if the given element exists on the page.

## Examples

    assert view |> element("#some-element") |> has_element?()

## has_element?/3

Checks if the given `selector` with `text_filter` is on `view`.

See `element/3` for more information.

## Examples

    assert has_element?(view, "#some-element")

## render/1

Returns the HTML string of the rendered view or element.

If a view is provided, the entire LiveView is rendered.
If a view after calling `with_target/2` or an element
are given, only that particular context is returned.

## Examples

    {:ok, view, _html} = live(conn, "/thermo")
    assert render(view) =~ ~s|<button id="alarm">Snooze</div>|

    assert view
           |> element("#alarm")
           |> render() == "Snooze"

## with_target/2

Sets the target of the view for events.

This emulates `phx-target` directly in tests, without
having to dispatch the event to a specific element.
This can be useful for invoking events to one or
multiple components at the same time:

    view
    |> with_target("#user-1,#user-2")
    |> render_click("Hide", %{})

## element/3

Returns an element to scope a function to.

It expects the current LiveView, a query selector, and a text filter.

An optional text filter may be given to filter the results by the query
selector. If the text filter is a string or a regex, it will match any
element that contains the string (including as a substring) or matches the
regex.

So a link containing the text "unopened" will match `element("a", "opened")`.
To prevent this, a regex could specify that "opened" appear without the prefix "un".
For example, `element("a", ~r{(?<!un)opened})`.
But it may be clearer to add an HTML attribute to make the element easier to
select.

After the text filter is applied, only one element must remain, otherwise an
error is raised.

If no text filter is given, then the query selector itself must return
a single element.

    assert view
          |> element("#term > :first-child", "Increment")
          |> render() =~ "Increment</a>"

Attribute selectors are also supported, and may be used on special cases
like ids which contain periods:

    assert view
           |> element(~s{[href="/foo"][id="foo.bar.baz"]})
           |> render() =~ "Increment</a>"

## form/3

Returns a form element to scope a function to.

It expects the current LiveView, a query selector, and the form data.
The query selector must return a single element.

The form data will be validated directly against the form markup and
make sure the data you are changing/submitting actually exists, failing
otherwise.

## Examples

    assert view
          |> form("#term", user: %{name: "hello"})
          |> render_submit() =~ "Name updated"

This function is meant to mimic what the user can actually do, so you cannot
 set hidden input values. However, hidden values can be given when calling
 `render_submit/2` or `render_change/2`, see their docs for examples.

## file_input/4

Builds a file input for testing uploads within a form.

Given the form DOM selector, the upload name, and a list of maps of client metadata
for the upload, the returned file input can be passed to `render_upload/2`.

Client metadata takes the following form:

  * `:last_modified` - the last modified timestamp
  * `:name` - the name of the file
  * `:content` - the binary content of the file
  * `:size` - the byte size of the content
  * `:type` - the MIME type of the file
  * `:relative_path` - for simulating webkitdirectory metadata
  * `:meta` - optional metadata sent by the client

## Examples

    avatar = file_input(lv, "#my-form-id", :avatar, [%{
      last_modified: 1_594_171_879_000,
      name: "myfile.jpeg",
      content: File.read!("myfile.jpg"),
      size: 1_396_009,
      type: "image/jpeg"
    }])

    assert render_upload(avatar, "myfile.jpeg") =~ "100%"

## page_title/1

Returns the most recent title that was updated via a `page_title` assign.

## Examples

    render_click(view, :event_that_triggers_page_title_update)
    assert page_title(view) =~ "my title"

## assert_patch/2

Asserts a live patch will happen within `timeout` milliseconds.
The default `timeout` is [ExUnit](https://ex-unit.hexdocs.pm/ExUnit.html#configure/1)'s
`assert_receive_timeout` (100 ms).

It returns the new path.

To assert on the flash message, you can assert on the result of the
rendered LiveView.

## Examples

    render_click(view, :event_that_triggers_patch)
    assert_patch view

    render_click(view, :event_that_triggers_patch)
    assert_patch view, 30

    render_click(view, :event_that_triggers_patch)
    path = assert_patch view
    assert path =~ ~r/path/+/

## assert_patch/3

Asserts a live patch will happen to a given path within `timeout`
milliseconds.

The default `timeout` is [ExUnit](https://ex-unit.hexdocs.pm/ExUnit.html#configure/1)'s
`assert_receive_timeout` (100 ms).

It returns the new path.

To assert on the flash message, you can assert on the result of the
rendered LiveView.

## Examples
    render_click(view, :event_that_triggers_patch)
    assert_patch view, "/path"

    render_click(view, :event_that_triggers_patch)
    assert_patch view, "/path", 30

## assert_patched/2

Asserts a live patch was performed, and returns the new path.

To assert on the flash message, you can assert on the result of
the rendered LiveView.

## Examples

    render_click(view, :event_that_triggers_redirect)
    assert_patched view, "/path"

## refute_patched/1

Refutes a live patch to a given path was performed.

It returns `:ok` if the specified patch isn't already in the mailbox.

## Examples

    render_click(view, :event_that_triggers_patch_to_path)
    :ok = refute_patched view, "/wrong_path"

## assert_redirect/3

Asserts a redirect will happen to a given path within `timeout` milliseconds.

The default `timeout` is [ExUnit](https://ex-unit.hexdocs.pm/ExUnit.html#configure/1)'s
`assert_receive_timeout` (100 ms).

It returns the flash messages from said redirect, if any.
Note the flash will contain string keys.

## Examples

    render_click(view, :event_that_triggers_redirect)
    flash = assert_redirect view, "/path"
    assert flash["info"] == "Welcome"

    render_click(view, :event_that_triggers_redirect)
    assert_redirect view, "/path", 30

## assert_redirected/2

Asserts a redirect was performed.

It returns the flash messages from said redirect, if any. Note the
flash will contain string keys.

## Examples

    render_click(view, :event_that_triggers_redirect)
    flash = assert_redirected view, "/path"
    assert flash["info"] == "Welcome"

## refute_redirected/1

Refutes a redirect to a given path was performed.

It returns :ok if the specified redirect isn't already in the mailbox.

If no path is specified, refutes any redirection on the given view.

## Examples

    render_click(view, :event_that_triggers_redirect_to_path)
    :ok = refute_redirected view, "/wrong_path"

## open_browser/2

Open the default browser to display current HTML of `view_or_element`.

## Examples

    view
    |> element("#term > :first-child", "Increment")
    |> open_browser()

    assert view
           |> form("#term", user: %{name: "hello"})
           |> open_browser()
           |> render_submit() =~ "Name updated"

## assert_push_event/4

Asserts an event will be pushed within `timeout`.
The default `timeout` is [ExUnit](https://ex-unit.hexdocs.pm/ExUnit.html#configure/1)'s
`assert_receive_timeout` (100 ms).

## Examples

    assert_push_event view, "scores", %{points: 100, user: "josé"}

## refute_push_event/4

Refutes an event will be pushed within timeout.

The default `timeout` is [ExUnit](https://ex-unit.hexdocs.pm/ExUnit.html#configure/1)'s
`refute_receive_timeout` (100 ms).

## Examples

    refute_push_event view, "scores", %{points: _, user: "josé"}

## assert_reply/3

Asserts a hook reply was returned from a `handle_event` callback.

The default `timeout` is [ExUnit](https://ex-unit.hexdocs.pm/ExUnit.html#configure/1)'s
`assert_receive_timeout` (100 ms).

## Examples

    assert_reply view, %{result: "ok", transaction_id: _}

## follow_redirect/3

Follows the redirect from a `render_*` action or an `{:error, redirect}`
tuple.

Imagine you have a LiveView that redirects on a `render_click`
event. You can make sure it immediately redirects after the
`render_click` action by calling `follow_redirect/3`:

    live_view
    |> render_click("redirect")
    |> follow_redirect(conn)

Or in the case of an error tuple:

    assert {:error, {:live_redirect, %{to: "/somewhere"}}} = result = live(conn, "my-path")
    {:ok, view, html} = follow_redirect(result, conn)

`follow_redirect/3` expects a connection as second argument.
This is the connection that will be used to perform the underlying
request.

If the LiveView redirects with a live redirect, this macro returns
`{:ok, live_view, disconnected_html}` with the content of the new
LiveView, the same as the `live/3` macro. If the LiveView redirects
with a regular redirect, this macro returns `{:ok, conn}` with the
rendered redirected page. In any other case, this macro raises.

Finally, note that you can optionally assert on the path you are
being redirected to by passing a third argument:

    live_view
    |> render_click("redirect")
    |> follow_redirect(conn, "/redirected/page")

## live_redirect/2

Performs a live redirect from one LiveView to another.

When redirecting between two LiveViews of the same `live_session`,
mounts the new LiveView and shuts down the previous one, which
mimics general browser live navigation behaviour.

When attempting to navigate from a LiveView of a different
`live_session`, an error redirect condition is returned indicating
a failed `push_navigate` from the client.

## Examples

    assert {:ok, page_live, _html} = live(conn, "/page/1")
    assert {:ok, page2_live, _html} = live(conn, "/page/2")

    assert {:error, {:redirect, _}} = live_redirect(page2_live, to: "/admin")

## follow_trigger_action/2

Receives a `form_element` and asserts that `phx-trigger-action` has been
set to true, following up on that request.

Imagine you have a LiveView that sends an HTTP form submission. Say that it
sets the `phx-trigger-action` to true, as a response to a submit event.
You can follow the trigger action like this:

    form = form(live_view, selector, %{"form" => "data"})

    # First we submit the form. Optionally verify that phx-trigger-action
    # is now part of the form.
    assert render_submit(form) =~ ~r/phx-trigger-action/

    # Now follow the request made by the form
    conn = follow_trigger_action(form, conn)
    assert conn.method == "POST"
    assert conn.params == %{"form" => "data"}

## submit_form/2

Receives a form element and submits the HTTP request through the plug pipeline.

Imagine you have a LiveView that validates form data, but submits the form to
a controller via the normal form `action` attribute. This is especially useful
in scenarios where the result of a form submit needs to write to the plug session.

You can submit the form with the `%Plug.Conn{}`, like this:

    form = form(live_view, selector, %{"form" => "data"})

    # Now submit the LiveView form to the plug pipeline
    conn = submit_form(form, conn)
    assert conn.method == "POST"
    assert conn.params == %{"form" => "data"}

## render_upload/3

Performs an upload of a file input and renders the result.

See `file_input/4` for details on building a file input.

## Examples

Given the following LiveView template:

```heex
<%= for entry <- @uploads.avatar.entries do %>
  {entry.name}: {entry.progress}%
<% end %>
```

Your test case can assert the uploaded content:

    avatar = file_input(lv, "#my-form-id", :avatar, [
      %{
        last_modified: 1_594_171_879_000,
        name: "myfile.jpeg",
        content: File.read!("myfile.jpg"),
        size: 1_396_009,
        type: "image/jpeg"
      }
    ])

    assert render_upload(avatar, "myfile.jpeg") =~ "100%"

By default, the entire file is chunked to the server, but an optional
percentage to chunk can be passed to test chunk-by-chunk uploads:

    assert render_upload(avatar, "myfile.jpeg", 49) =~ "49%"
    assert render_upload(avatar, "myfile.jpeg", 51) =~ "100%"

Before making assertions about how the upload is consumed server-side,
you will need to call `render_submit/1`.

In the case where an upload progress callback issues a navigate, patch, or
redirect, the following will be returned:

  * for a patch, the current view will be patched
  * for a navigate, this function will return
    `{:error, {:live_redirect, %{to: url}}}`, which can be followed
    with `follow_redirect/2`
  * for a regular redirect, this function will return
    `{:error, {:redirect, %{to: url}}}`, which can be followed
    with `follow_redirect/2`

## preflight_upload/1

Performs a preflight upload request.

Useful for testing external uploaders to retrieve the `:external` entry metadata.

## Examples

    avatar = file_input(lv, "#my-form-id", :avatar, [%{name: ..., ...}, ...])
    assert {:ok, %{ref: _ref, config: %{chunk_size: _}}} = preflight_upload(avatar)