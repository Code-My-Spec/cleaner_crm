# Wallaby.Browser

The Browser module is the entrypoint for interacting with a real browser.

By default, action only work with elements that are visible to a real user.

## Actions

Actions are used to interact with form elements. All actions work with the
query interface:

```html
<label for="first_name">
  First Name
</label>
<input id="user_first_name" type="text" name="first_name">
```

```
fill_in(page, Query.text_field("First Name"), with: "Grace")
fill_in(page, Query.text_field("first_name"), with: "Grace")
fill_in(page, Query.text_field("user_first_name"), with: "Grace")
```

These queries work with any of the available actions.

```
fill_in(page, Query.text_field("First Name"), with: "Chris")
clear(page, Query.text_field("user_email"))
click(page, Query.radio_button("Radio Button 1"))
click(page, Query.checkbox("Checkbox"))
click(page, Query.checkbox("Checkbox"))
click(page, Query.option("Option 1"))
click(page, Query.button("Some Button"))
attach_file(page, Query.file_field("Avatar"), path: "test/fixtures/avatar.jpg")
```

Actions return their parent element so that they can be chained together:

```
page
|> find(Query.css(".signup-form"), fn(form) ->
  form
  |> fill_in(Query.text_field("Name"), with: "Grace Hopper")
  |> fill_in(Query.text_field("Email"), with: "grace@hopper.com")
  |> click(Query.button("Submit"))
end)
```

## Scoping

Finders provide scoping like so:

```
session
|> visit("/page.html")
|> find(Query.css(".users"))
|> find(Query.css(".user", count: 3))
|> List.first
|> find(Query.css(".user-name"))
```

If a callback is passed to find then the scoping will only apply to the callback
and the parent will be passed to the next action in the chain:

```
page
|> find(Query.css(".todo-form"), fn(form) ->
  form
  |> fill_in(Query.text_field("What needs doing?"), with: "Write Wallaby Documentation")
  |> click(Query.button("Save"))
end)
|> find(Query.css(".success-notification"), fn(notification) ->
  assert notification
  |> has_text?("Todo created successfully!")
end)
```

This allows you to create a test that is logically grouped together in a single pipeline.
It also means that its easy to create re-usable helper functions without having to worry about
chaining. You could re-write the above example like this:

```
def create_todo(page, todo) do
  find(Query.css(".todo-form"), & fill_in_and_save_todo(&1, todo))
end

def fill_in_and_save_todo(form, todo) do
  form
  |> fill_in(Query.text_field("What needs doing?"), with: todo)
  |> click(Query.button("Save"))
end

def todo_was_created?(page) do
  find Query.css(page, ".success-notification"), fn(notification) ->
    assert notification
    |> has_text?("Todo created successfully!")
  end
end

assert page
|> create_todo("Write Wallaby Documentation")
|> todo_was_created?
```

## retry/2

Attempts to synchronize with the browser. This is most often used to
execute queries repeatedly until it either exceeds the time limit or
returns a success.

## Note

It is possible that this function never halts. Whenever we experience a stale
reference error we retry the query without checking to see if we've run over
our time. In practice we should eventually be able to query the DOM in a stable
state. However, if this error does continue to occur it will cause wallaby to
loop forever (or until the test is killed by exunit).

## fill_in/3

Fills in an element identified by `query` with `value`.

All inputs previously present in the input field will be overridden.

### Examples

    page
    |> fill_in(Query.text_field("name"), with: "Chris")
    |> fill_in(Query.css("#password_field"), with: "secret42")

### Note

Currently, ChromeDriver only supports [BMP Unicode](http://www.unicode.org/roadmaps/bmp/) characters. Emojis are [SMP](https://www.unicode.org/roadmaps/smp/) characters and will be ignored by ChromeDriver.

Using JavaScript is a known workaround for filling in fields with Emojis and other non-BMP characters.

## attach_file/3

Attaches a file to a file input. Input elements are looked up by id, label text,
or name.

When dealing with Selenium server (especially a remote instance), the file
must be uploaded to Selenium via `send_keys` recognizing a local file,
else attaching a file fails.

## take_screenshot/2

Takes a screenshot of the current window.
Screenshots are saved to a "screenshots" directory in the same directory the
tests are run in.

Pass `[{:name, "some_name"}]` to specify the file name. Defaults to a timestamp.
Pass `[{:log, true}]` to log the location of the screenshot to stdout. Defaults to false.

## window_handle/1

Gets the window handle of the current window.

The window is either an instance of a browser tab or another operating system window.
Getting the current window handle makes it easy to return to the window in case you
need to switch between them.

## Usage

```elixir
feature "can open a new tab and switch back to the original tab", %{session: session} do
  handle =
    session
    |> visit("/home")
    |> window_handle()

  path =
    session
    # click a link that takes you to a new tab
    |> click(Query.link("External Page"))
    |> assert_text("Some text")
    |> focus_window(handle)
    |> current_path()

  assert "/home" == path
end
```

## window_handles/1

Gets the window handles of all available windows.

The window is either an instance of a browser tab or another operating system window.

## Usage

```elixir
feature "can open new tabs for external links", %{session: session} do
  handles =
    session
    |> visit("/home")
    |> click(Query.link("External Page"))
    |> click(Query.link("Another External Page"))
    |> window_handles()

  assert 3 == length(path)
end
```

## focus_window/2

Focuses the window identified by the given handle.

The window is either an instance of a browser tab or another operating system window.

## Usage

```elixir
feature "can switch between different tabs", %{session: session} do
  handle =
    session
    |> visit("/home")
    |> window_handle()

  path =
    session
    # click a link that takes you to a new tab
    |> click(Query.link("External Page"))
    |> assert_text("Some text")
    |> focus_window(handle)
    |> current_path()

  assert "/home" == path
end
```

## close_window/1

Closes the current window.

The window is either an instance of a browser tab or another operating system window.

## Usage

```elixir
feature "closing a window focuses the previously focused window", %{session: session} do
  original_handle =
    session
    |> visit("/home")
    |> window_handle()

  new_handle =
    session
    # click a link that takes you to a new tab
    |> click(Query.link("External Page"))
    |> close_window()
    |> window_handle()

  assert original_handle == new_handle
end
```

## window_size/1

Gets the size of the current window.

The window is either an instance of a browser tab or another operating system window.

This is useful for debugging responsive designs where the layout changes as the window size changes. The default window size is 1280x800.

## Usage

```elixir
feature "gets the size of the current window", %{session: session} do
  %{"width" => width, "height" => height} =
    session
    |> visit("/home")
    |> window_size()

  assert width == 1280
  assert height == 800
end
```

## resize_window/3

Sets the size of the current window.

The window is either an instance of a browser tab or another operating system window.

## Usage

```elixir
feature "sets the size of the window to mobile dimensions", %{session: session} do
  %{"width" => width, "height" => height} =
    session
    |> visit("/home")
    |> resize_window(375, 667)
    |> window_size()

  assert width == 375
  assert height == 667
end
```

## maximize_window/1

Maximizes the current window.

The window is either an instance of a browser tab or another operating system window.

For most browsers, this requires a graphical window manager to be running.

## Usage

```elixir
feature "maximizes the window to the full size of the display", %{session: session} do
  %{"width" => width, "height" => height} =
    session
    |> visit("/home")
    |> maximize_window()
    |> window_size()

  assert width == 1920
  assert height == 1080
end
```

## window_position/1

Gets the position of the current window.

The window is either an instance of a browser tab or another operating system window.

## Usage

```elixir
feature "gets the current display position of the window", %{session: session} do
  %{"x" => x, "y" => y} =
    session
    |> visit("/home")
    |> window_position()

  assert x == 200
  assert y == 200
end
```

## move_window/3

Sets the position of the current window.

The window is either an instance of a browser tab or another operating system window.

## Usage

```elixir
feature "gets the current display position of the window", %{session: session} do
  %{"x" => x, "y" => y} =
    session
    |> visit("/home")
    |> move_window(500, 500)
    |> window_position()

  assert x == 500
  assert y == 500
end
```

## focus_frame/2

Changes the driver focus to the frame found by query.

## focus_parent_frame/1

Changes the driver focus to the parent frame.

## focus_default_frame/1

Changes the driver focus to the default (top level) frame.

## current_url/1

Gets the current url of the session

## current_path/1

Gets the current path of the session

## page_title/1

Gets the title for the current page

## execute_script/2

Executes JavaScript synchronously, taking as arguments the script to execute,
an optional list of arguments available in the script via `arguments`, and an
optional callback function with the result of script execution as a parameter.

## execute_script_async/2

Executes asynchronous JavaScript, taking as arguments the script to execute,
an optional list of arguments available in the script via `arguments`, and an
optional callback function with the result of script execution as a parameter.

## send_keys/3

Sends a list of key strokes to active element. If strings are included
then they are sent as individual keys. Special keys should be provided as a
list of atoms, which are automatically converted into the corresponding key
codes.

For a list of available key codes see `Wallaby.Helpers.KeyCodes`.

## Example

    iex> Wallaby.Browser.send_keys(session, ["Example Text", :enter])
    iex> Wallaby.Browser.send_keys(session, [:enter])
    iex> Wallaby.Browser.send_keys(session, [:shift, :enter])

### Note

Currently, ChromeDriver only supports [BMP Unicode](http://www.unicode.org/roadmaps/bmp/) characters. Emojis are [SMP](https://www.unicode.org/roadmaps/smp/) characters and will be ignored by ChromeDriver.

Using JavaScript is a known workaround for filling in fields with Emojis and other non-BMP characters.

## page_source/1

Retrieves the source of the current page.

## set_value/3

Sets the value of an element. The allowed type for the value depends on the
type of the element. The value may be:
* a string of characters for a text element
* :selected for a radio button, checkbox or select list option
* :unselected for a checkbox

## click/2

Clicks the mouse on the element returned by the query or at the current mouse cursor position.

## double_click/1

Double-clicks left mouse button at the current mouse coordinates.

## button_down/2

Clicks and holds the given mouse button at the current mouse coordinates.

## button_up/2

Releases given previously held mouse button.

## hover/2

Hovers over an element.

## move_mouse_by/3

Moves mouse by an offset relative to current cursor position.

## touch_down/3

Touches the screen at the given position.

## touch_down/4

Touches and holds the element on its top-left corner plus an optional offset.

## touch_up/1

Stops touching the screen.

## tap/2

Taps the element.

## touch_move/3

Moves the touch pointer (finger, stylus etc.) on the screen to the point determined by the given coordinates.

## touch_scroll/4

Scroll on the screen from the given element by the given offset using touch events.

## text/2

Gets the Element's text value.

If the element is not visible, the return value will be `""`.

## attr/3

Gets the value of the elements attribute.

## selected?/2

Checks if the element has been selected. Alias for checked?(element)

## visible?/2

Checks if the element is visible on the page

## find/2

Finds and returns one or more DOM element(s) on the page based on the given query.

The query is scoped by the first argument, which is either the `%Session{}` or an
`%Element{}`.

## Example

```elixir
session
|> find(Query.css("#login-button"))
|> assert_text("Login")

buttons =
  session
  |> find(Query.css(".login-button", count: 2, text: "Login"))
```

## Notes

- Blocks until it finds the element(s) or the max time is reached.
- By default only 1 element is expected to match the query. If more elements are present then a count can be
  specified. Use `count: :any` to allow any number of elements to be present.
- By default only elements that would be visible to a real user on the page are returned.

## find/3

Same as `find/2`, but takes a callback to enact side effects on the found element(s).

## Example

```elixir
session
|> find(Query.css("#login-button"), fn button ->
  assert_text(button, "Login")
end)

session
|> find(Query.css(".login-button", count: 2, text: "Login"), fn buttons ->
  assert 2 == length(buttons)
end)

```

## Notes

- Returns the first argument to make the function pipe-able.

## all/2

Finds all of the DOM elements that match the CSS selector. If no elements are
found then an empty list is immediately returned. This is equivalent to calling
`find(session, css("element", count: nil, minimum: 0))`.

## has?/2

Validates that the query returns a result. This can be used to define other
types of matchers.

## has_value?/3

Matches the Element's value with the provided value.

## has_text?/3

Matches the parent's content with the provided text.

Returns a boolean that indicates if the text was found.

## Examples

```
session
|> visit("/")
|> has_text?("Login")
```

Example providing query:

```
session
|> visit("/")
|> has_text?(Query.css(".login-button"), "Login")
```

## assert_text/3

Matches the Element's content with the provided text and raises if not found.

Returns the given `parent` if the assertion is correct so that it is easily
pipeable.

## Examples

```
session
|> visit("/")
|> assert_text("Login")
```

Example providing query:

```
session
|> visit("/")
|> assert_text(Query.css(".login-button"), "Login")
```

## assert_has/2

Checks if `query` is present within `parent` and raises if not found.

Returns the given `parent` if the assertion is correct so that it is easily
pipeable.

## Examples

    session
    |> visit("/")
    |> assert_has(Query.css(".login-button"))

## refute_has/2

Checks if `query` is not present within `parent` and raises if it is found.

Returns the given `parent` if the query is not found so that it is easily
pipeable.

## Examples

    session
    |> visit("/")
    |> refute_has(Query.css(".secret-admin-content"))

## has_css?/3

Searches for CSS on the page.

## has_no_css?/3

Searches for CSS that should not be on the page

## visit/2

Changes the current page to the provided route.
Relative paths are appended to the provided base_url.
Absolute paths do not use the base_url.

## accept_alert/2

Accepts one alert dialog, which must be triggered within the specified `fun`.
Returns the message that was presented to the user. For example:

```
message = accept_alert session, fn(s) ->
  click(s, Query.link("Trigger alert"))
end
```

## accept_confirm/2

Accepts one confirmation dialog, which must be triggered within the specified
`fun`. Returns the message that was presented to the user. For example:

```
message = accept_confirm session, fn(s) ->
  click(s, Query.link("Trigger confirm"))
end
```

## dismiss_confirm/2

Dismisses one confirmation dialog, which must be triggered within the
specified `fun`. Returns the message that was presented to the user. For
example:

```
message = dismiss_confirm session, fn(s) ->
  click(s, Query.link("Trigger confirm"))
end
```

## accept_prompt/2

Accepts one prompt, which must be triggered within the specified `fun`. The
`[with: value]` option allows to simulate user input for the prompt. If no
value is provided, the default value that was passed to `window.prompt` will
be used instead. Returns the message that was presented to the user. For
example:

```
message = accept_prompt session, fn(s) ->
  click(s, Query.link("Trigger prompt"))
end
```

Example providing user input:

```
message = accept_prompt session, [with: "User input"], fn(s) ->
  click(s, Query.link("Trigger prompt"))
end
```

## dismiss_prompt/2

Dismisses one prompt, which must be triggered within the specified `fun`.
Returns the message that was presented to the user. For example:

```
message = dismiss_prompt session, fn(s) ->
  click(s, Query.link("Trigger prompt"))
end
```