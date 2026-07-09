# Phoenix.Component



## live_render/3

Renders a LiveView within a template.

This is useful in two situations:

* When rendering a child LiveView inside a LiveView.

* When rendering a LiveView inside a regular (non-live) controller/view.

Most other cases for shared functionality, including state management and user interactions, can be
[achieved with function components or LiveComponents](welcome.md#compartmentalize-state-markup-and-events-in-liveview)

## Options

* `:session` - a map of binary keys with extra session data to be serialized and sent
to the client. All session data currently in the connection is automatically available
in LiveViews. You can use this option to provide extra data. Remember all session data is
serialized and sent to the client, so you should always keep the data in the session
to a minimum. For example, instead of storing a User struct, you should store the "user_id"
and load the User when the LiveView mounts.

* `:container` - an optional tuple for the HTML tag and DOM attributes to be used for the
LiveView container. For example: `{:li, style: "color: blue;"}`. By default it uses the module
definition container. See the "Containers" section below for more information.

* `:id` - both the DOM ID and the ID to uniquely identify a LiveView. An `:id` is
automatically generated when rendering root LiveViews but it is a required option when
rendering a child LiveView.

* `:sticky` - an optional flag to maintain the LiveView across live redirects, even if it is
nested within another LiveView. Note that this only works for LiveViews that are in the same
[live_session](`Phoenix.LiveView.Router.live_session/3`).
If you are rendering the sticky view within another LiveView, make sure that the sticky view
itself does not use the same layout. You can do so by returning `{:ok, socket, layout: false}`
from mount.

## Examples

When rendering from a controller/view, you can call:

```heex
{live_render(@conn, MyApp.ThermostatLive)}
```

Or:

```heex
{live_render(@conn, MyApp.ThermostatLive, session: %{"home_id" => @home.id})}
```

Within another LiveView, you must pass the `:id` option:

```heex
{live_render(@socket, MyApp.ThermostatLive, id: "thermostat")}
```

## Containers

When a LiveView is rendered, its contents are wrapped in a container. By default,
the container is a `div` tag with a handful of LiveView-specific attributes.

The container can be customized in different ways:

* You can change the default `container` on `use Phoenix.LiveView`:

      use Phoenix.LiveView, container: {:tr, id: "foo-bar"}

* You can override the container tag and pass extra attributes when calling `live_render`
(as well as on your `live` call in your router):

      live_render socket, MyLiveView, container: {:tr, class: "highlight"}

If you don't want the container to affect layout, you can use the CSS property
`display: contents` or a class that applies it, like Tailwind's `.contents`.

Beware if you set this to `:body`, as any content injected inside the body
(such as `Phoenix.LiveReload` features) will be discarded once the LiveView
connects

## Testing

Note that `render_click/1` and other testing functions will send events to the root LiveView, and you will want to
`find_live_child/2` to interact with nested LiveViews in your live tests.

## live_flash/2

Returns the flash message from the LiveView flash assign.

## Examples

```heex
<p class="alert alert-info">{live_flash(@flash, :info)}</p>
<p class="alert alert-danger">{live_flash(@flash, :error)}</p>
```

## upload_errors/1

Returns errors for the upload as a whole.

For errors that apply to a specific upload entry, use `upload_errors/2`.

The output is a list. The following error may be returned:

* `:too_many_files` - The number of selected files exceeds the `:max_entries` constraint

## Examples

    def upload_error_to_string(:too_many_files), do: "You have selected too many files"

```heex
<div :for={err <- upload_errors(@uploads.avatar)} class="alert alert-danger">
  {upload_error_to_string(err)}
</div>
```

## upload_errors/2

Returns errors for the upload entry.

For errors that apply to the upload as a whole, use `upload_errors/1`.

The output is a list. The following errors may be returned:

* `:too_large` - The entry exceeds the `:max_file_size` constraint
* `:not_accepted` - The entry does not match the `:accept` MIME types
* `:external_client_failure` - When external upload fails
* `{:writer_failure, reason}` - When the custom writer fails with `reason`
* `reason` - When the custom validator fails with `reason`

## Examples

```elixir
defp upload_error_to_string(:too_large), do: "The file is too large"
defp upload_error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
defp upload_error_to_string(:external_client_failure), do: "Something went terribly wrong"
defp upload_error_to_string(:custom_validator_error), do: "Custom validation error"
```

```heex
<%= for entry <- @uploads.avatar.entries do %>
  <div :for={err <- upload_errors(@uploads.avatar, entry)} class="alert alert-danger">
    {upload_error_to_string(err)}
  </div>
<% end %>
```

## assign/3

Adds a `key`-`value` pair to `socket_or_assigns`.

The first argument is either a LiveView `socket` or an `assigns` map from function components.

## Examples

    iex> assign(socket, :name, "Elixir")

## assign/2

Adds key-value pairs to assigns.

The first argument is either a LiveView `socket` or an `assigns` map from function components.

When a keyword list or map is provided as the second argument, it will be merged into the existing assigns.
If a function is given, it takes the current assigns as an argument and its return
value will be merged into the current assigns.

## Examples

    iex> assign(socket, name: "Elixir", logo: "💧")
    iex> assign(socket, %{name: "Elixir"})
    iex> assign(socket, fn %{name: name, logo: logo} -> %{title: Enum.join([name, logo], " | ")} end)

## update/3

Updates an existing `key` with `fun` in the given `socket_or_assigns`.

The first argument is either a LiveView `socket` or an `assigns` map from function components.

The update function receives the current key's value and returns the updated value.
Raises if the key does not exist.

The update function may also be of arity 2, in which case it receives the current key's value
as the first argument and the current assigns as the second argument.
Raises if the key does not exist.

## Examples

    iex> update(socket, :count, fn count -> count + 1 end)
    iex> update(socket, :count, &(&1 + 1))
    iex> update(socket, :max_users_this_session, fn current_max, %{users: users} ->
    ...>   max(current_max, length(users))
    ...> end)

## changed?/2

Checks if the given key changed in `socket_or_assigns`.

The first argument is either a LiveView `socket` or an `assigns` map from function components.

## Examples

    iex> changed?(socket, :count)

## to_form/2

Converts a given data structure to a `Phoenix.HTML.Form`.

This is commonly used to convert a map or an Ecto changeset
into a form to be given to the `form/1` component.

## Creating a form from params

If you want to create a form based on `handle_event` parameters,
you could do:

    def handle_event("submitted", params, socket) do
      {:noreply, assign(socket, form: to_form(params))}
    end

When you pass a map to `to_form/1`, it assumes said map contains
the form parameters, which are expected to have string keys.

You can also specify a name to nest the parameters:

    def handle_event("submitted", %{"user" => user_params}, socket) do
      {:noreply, assign(socket, form: to_form(user_params, as: :user))}
    end

## Creating a form from changesets

When using changesets, the underlying data, form parameters, and
errors are retrieved from it. The `:as` option is automatically
computed too. For example, if you have a user schema:

    defmodule MyApp.Users.User do
      use Ecto.Schema

      schema "..." do
        ...
      end
    end

And then you create a changeset that you pass to `to_form`:

    %MyApp.Users.User{}
    |> Ecto.Changeset.change()
    |> to_form()

In this case, once the form is submitted, the parameters will
be available under `%{"user" => user_params}`.

## Options

  * `:as` - the `name` prefix to be used in form inputs
  * `:id` - the `id` prefix to be used in form inputs
  * `:errors` - keyword list of errors (used by maps exclusively)
  * `:action` - The action that was taken against the form. This value can be
    used to distinguish between different operations such as the user typing
    into a form for validation, or submitting a form for a database insert.
    For example: `to_form(changeset, action: :validate)`,
    or `to_form(changeset, action: :save)`. The provided action is passed
    to the underlying `Phoenix.HTML.FormData` implementation options.

The underlying data may accept additional options when
converted to forms. For example, a map accepts `:errors`
to list errors, but such option is not accepted by
changesets. `:errors` is a keyword of tuples in the shape
of `{error_message, options_list}`. Here is an example:

    to_form(%{"search" => nil}, errors: [search: {"Can't be blank", []}])

If an existing `Phoenix.HTML.Form` struct is given, the
options above will override its existing values if given.
Then the remaining options are merged with the existing
form options.

Errors in a form are only displayed if the changeset's `action`
field is set (and it is not set to `:ignore`) and can be filtered
by whether the fields have been used on the client or not. Refer to
[a note on :errors for more information](#form/1-a-note-on-errors).

## used_input?/1

Checks if the input field was used by the client.

Used inputs are only those inputs that have been focused, interacted with, or
submitted by the client. For LiveView, this is used to filter errors from the
`Phoenix.HTML.FormData` implementation to avoid showing "field can't be blank"
in scenarios where the client hasn't yet interacted with specific fields.

Used inputs are tracked internally by the client sending a sibling key
derived from each input name, which indicates the inputs that remain  unused
on the client. For example, a form with email and title fields where only the
title has been modified so far on the client, would send the following payload:

    %{
      "title" => "new title",
      "email" => "",
      "_unused_email" => ""
    }

The `_unused_email` key indicates that the email field has not been used by the
client, which is used to filter errors from the UI.

Nested fields are also supported. For example, a form with a nested datetime field
is considered used if any of the nested parameters are used.

    %{
      "bday" => %{
        "year" => "",
        "month" => "",
        "day" => "",
        "_unused_day" => ""
      }
    }

The `_unused_day` key indicates that the day field has not been used by the client,
but the year and month fields have been used, meaning the birthday field as a whole
was used.

## Examples

For example, imagine in your template you render a title and email input.
On initial load the end-user begins typing the title field. The client will send
the entire form payload to the server with the typed title and an empty email.

The `Phoenix.HTML.FormData` implementation will consider an empty email in
this scenario as invalid, but the user shouldn't see the error because they
haven't yet used the email input. To handle this, `used_input?/1` can be used to
filter errors from the client by referencing param metadata to distinguish between
used and unused input fields. For non-LiveViews, all inputs are considered used.

```heex
<input type="text" name={@form[:title].name} value={@form[:title].value} />

<div :if={used_input?(@form[:title])}>
  <p :for={error <- @form[:title].errors}>{error}</p>
</div>

<input type="text" name={@form[:email].name} value={@form[:email].value} />

<div :if={used_input?(@form[:email])}>
  <p :for={error <- @form[:email].errors}>{error}</p>
</div>
```

## embed_templates/2

Embeds external template files into the module as function components.

## Options

  * `:root` - The root directory to embed files. Defaults to the current
    module's directory (`__DIR__`)
  * `:suffix` - A string value to append to embedded function names. By
    default, function names will be the name of the template file excluding
    the format and engine.

A wildcard pattern may be used to select all files within a directory tree.
For example, imagine a directory listing:

```plain
├── components.ex
├── pages
│   ├── about_page.html.heex
│   └── welcome_page.html.heex
```

Then to embed the page templates in your `components.ex` module:

    defmodule MyAppWeb.Components do
      use Phoenix.Component

      embed_templates "pages/*"
    end

Now, your module will have an `about_page/1` and `welcome_page/1` function
component defined. Embedded templates also support declarative assigns
via bodyless function definitions, for example:

    defmodule MyAppWeb.Components do
      use Phoenix.Component

      embed_templates "pages/*"

      attr :name, :string, required: true
      def welcome_page(assigns)

      slot :header
      def about_page(assigns)
    end

Multiple invocations of `embed_templates` is also supported, which can be
useful if you have more than one template format. For example:

    defmodule MyAppWeb.Emails do
      use Phoenix.Component

      embed_templates "emails/*.html", suffix: "_html"
      embed_templates "emails/*.text", suffix: "_text"
    end

Note: this function is the same as `Phoenix.Template.embed_templates/2`.
It is also provided here for convenience and documentation purposes.
Therefore, if you want to embed templates for other formats, which are
not related to `Phoenix.Component`, prefer to
`import Phoenix.Template, only: [embed_templates: 1]` than this module.

## slot/2

Declares a slot. See `slot/3` for more information.

## live_component/1

A function component for rendering `Phoenix.LiveComponent` within a parent LiveView.

While LiveViews can be nested, each LiveView starts its own process. A LiveComponent provides
similar functionality to LiveView, except they run in the same process as the LiveView,
with its own encapsulated state. That's why they are called stateful components.

## Attributes

* `id` (`:string`) (required) - A unique identifier for the LiveComponent. Note the `id` won't
necessarily be used as the DOM `id`. That is up to the component to decide.

* `module` (`:atom`) (required) - The LiveComponent module to render.

Any additional attributes provided will be passed to the LiveComponent as a map of assigns.
See `Phoenix.LiveComponent` for more information.

## Examples

```heex
<.live_component module={MyApp.WeatherComponent} id="thermostat" city="Kraków" />
```

## live_title/1

Renders a title with automatic prefix/suffix on `@page_title` updates.

[INSERT LVATTRDOCS]

## Examples

```heex
<.live_title default="Welcome" prefix="MyApp · ">
  {assigns[:page_title]}
</.live_title>
```

```heex
<.live_title default="Welcome" suffix=" · MyApp">
  {assigns[:page_title]}
</.live_title>
```

## inputs_for/1

Renders nested form inputs for associations or embeds.

[INSERT LVATTRDOCS]

## Examples

```heex
<.form
  for={@form}
  id="my-form"
  phx-change="change_name"
>
  <.inputs_for :let={f_nested} field={@form[:nested]}>
    <.input type="text" field={f_nested[:name]} />
  </.inputs_for>
</.form>
```

## Dynamically adding and removing inputs

Dynamically adding and removing inputs is supported by rendering named buttons for
inserts and removals. Like inputs, buttons with name/value pairs are serialized with
form data on change and submit events. Libraries such as Ecto, or custom param
filtering can then inspect the parameters and handle the added or removed fields.
This can be combined with `Ecto.Changeset.cast_assoc/3`'s `:sort_param` and `:drop_param`
options. For example, imagine a parent with an `:emails` `has_many` or `embeds_many`
association. To cast the user input from a nested form, one simply needs to configure
the options:

    schema "mailing_lists" do
      field :title, :string

      embeds_many :emails, EmailNotification, on_replace: :delete do
        field :email, :string
        field :name, :string
      end
    end

    def changeset(list, attrs) do
      list
      |> cast(attrs, [:title])
      |> cast_embed(:emails,
        with: &email_changeset/2,
        sort_param: :emails_sort,
        drop_param: :emails_drop
      )
    end

Here we see the `:sort_param` and `:drop_param` options in action.

> ### Note {: .info}
> When using these options, `on_replace: :delete` on the `has_many` and
> `embeds_many` is required.

When Ecto sees the specified sort or drop parameter from the form, it will sort
the children based on the order they appear in the form, add new children it hasn't
seen, or drop children if the parameter instructs it to do so.

The markup for such a schema and association would look like this:

```heex
<.inputs_for :let={ef} field={@form[:emails]}>
  <input type="hidden" name="mailing_list[emails_sort][]" value={ef.index} />
  <.input type="text" field={ef[:email]} placeholder="email" />
  <.input type="text" field={ef[:name]} placeholder="name" />
  <button
    type="button"
    name="mailing_list[emails_drop][]"
    value={ef.index}
    phx-click={JS.dispatch("change")}
  >
    <.icon name="hero-x-mark" class="w-6 h-6 relative top-2" />
  </button>
</.inputs_for>

<input type="hidden" name="mailing_list[emails_drop][]" />

<button type="button" name="mailing_list[emails_sort][]" value="new" phx-click={JS.dispatch("change")}>
  add more
</button>
```

We used `inputs_for` to render inputs for the `:emails` association, which
contains an email address and name input for each child. Within the nested inputs,
we render a hidden `mailing_list[emails_sort][]` input, which is set to the index of the
given child. This tells Ecto's cast operation how to sort existing children, or
where to insert new children. Next, we render the email and name inputs as usual.
Then we render a button containing the "delete" text with the name `mailing_list[emails_drop][]`,
containing the index of the child as its value.

Like before, this tells Ecto to delete the child at this index when the button is
clicked. We use `phx-click={JS.dispatch("change")}` on the button to tell LiveView
to treat this button click as a change event, rather than a submit event on the form,
which invokes our form's `phx-change` binding.

Outside the `inputs_for`, we render an empty `mailing_list[emails_drop][]` input,
to ensure that all children are deleted when saving a form where the user
dropped all entries. This hidden input is required whenever dropping associations.

Finally, we also render another button with the sort param name `mailing_list[emails_sort][]`
and `value="new"` name with accompanied "add more" text. Please note that this button must
have `type="button"` to prevent it from submitting the form.
Ecto will treat unknown sort params as new children and build a new child.
This button is optional and only necessary if you want to dynamically add entries.
You can optionally add a similar button before the `<.inputs_for>`, in the case you want
to prepend entries.

> ### A note on accessing a field's `value` {: .warning}
>
> You may be tempted to access `form[:field].value` or attempt to manipulate
> the form metadata in your templates. However, bear in mind that the `form[:field]`
> value reflects the most recent changes. For example, an `:integer` field may
> either contain integer values, but it may also hold a string, if the form has
> been submitted.
>
> This is particularly noticeable when using `inputs_for`. Accessing the `.value`
> of a nested field may either return a struct, a changeset, or raw parameters
> sent by the client (when using `drop_param`). This makes the `form[:field].value`
> impractical for deriving or computing other properties.
>
> The correct way to approach this problem is by computing any property either in
> your LiveViews, by traversing the relevant changesets and data structures, or by
> moving the logic to the `Ecto.Changeset` itself.
>
> As an example, imagine you are building a time tracking application where:
>
> - users enter the total work time for a day
> - individual activities are tracked as embeds
> - the sum of all activities should match the total time
> - the form should display the remaining time
>
> Instead of trying to calculate the remaining time in your template by
> doing something like `calculate_remaining(@form)` and accessing
> `form[:activities].value`, calculate the remaining time based
> on the changeset in your `handle_event` instead:
>
> ```elixir
> def handle_event("validate", %{"tracked_day" => params}, socket) do
>   changeset = TrackedDay.changeset(socket.assigns.tracked_day, params)
>   remaining = calculate_remaining(changeset)
>   {:noreply, assign(socket, form: to_form(changeset, action: :validate), remaining: remaining)}
> end
>
> # Helper function to calculate remaining time
> defp calculate_remaining(changeset) do
>   total = Ecto.Changeset.get_field(changeset, :total)
>   activities = Ecto.Changeset.get_embed(changeset, :activities)
>
>   Enum.reduce(activities, total, fn activity, acc ->
>     duration =
>       case activity do
>         %{valid?: true} = changeset -> Ecto.Changeset.get_field(changeset, :duration)
>         # if the activity is invalid, we don't include its duration in the calculation
>         _ -> 0
>       end
>
>     acc - length
>   end)
> end
> ```
>
> This logic might also be implemented directly in your schema module and, if you
> often need the `:remaining` value, you could also add it as a `:virtual` field to
> your schema and run the calculation when validating the changeset:
>
> ```elixir
> def changeset(tracked_day, attrs) do
>   tracked_day
>   |> cast(attrs, [:total_duration])
>   |> cast_embed(:activities)
>   |> validate_required([:total_duration])
>   |> validate_number(:total_duration, greater_than: 0)
>   |> validate_and_put_remaining_time()
> end
>
> defp validate_and_put_remaining_time(changeset) do
>   remaining = calculate_remaining(changeset)
>   put_change(changeset, :remaining, remaining)
> end
> ```
>
> By using this approach, you can safely render the remaining time in your template
> using `@form[:remaining].value`, avoiding the pitfalls of directly accessing complex field values.

## link/1

Generates a link to a given route.

It is typically used with one of the three attributes:

  * `patch` - on click, it patches the current LiveView with the given path
  * `navigate` - on click, it navigates to a new LiveView at the given path
  * `href` - on click, it performs traditional browser navigation (as any `<a>` tag)

[INSERT LVATTRDOCS]

## Examples

```heex
<.link href="/">Regular anchor link</.link>
```

```heex
<.link navigate={~p"/"} class="underline">home</.link>
```

```heex
<.link navigate={~p"/?sort=asc"} replace={false}>
  Sort By Price
</.link>
```

```heex
<.link patch={~p"/details"}>view details</.link>
```

```heex
<.link href={URI.parse("https://elixir-lang.org")}>hello</.link>
```

```heex
<.link href="/the_world" method="delete" data-confirm="Really?">delete</.link>
```

## JavaScript dependency

In order to support links where `:method` is not `"get"` or use the above data attributes,
`Phoenix.HTML` relies on JavaScript. You can load `priv/static/phoenix_html.js` into your
build tool.

### Data attributes

Data attributes are added as a keyword list passed to the `data` key. The following data
attributes are supported:

* `data-confirm` - shows a confirmation prompt before generating and submitting the form when
`:method` is not `"get"`.

### Overriding the default confirm behaviour

`phoenix_html.js` does trigger a custom event `phoenix.link.click` on the clicked DOM element
when a click happened. This allows you to intercept the event on its way bubbling up
to `window` and do your own custom logic to enhance or replace how the `data-confirm`
attribute is handled. You could for example replace the browsers `confirm()` behavior with
a custom javascript implementation:

```javascript
// Compared to a javascript window.confirm, the custom dialog does not block
// javascript execution. Therefore to make this work as expected we store
// the successful confirmation as an attribute and re-trigger the click event.
// On the second click, the `data-confirm-resolved` attribute is set and we proceed.
const RESOLVED_ATTRIBUTE = "data-confirm-resolved";
// listen on document.body, so it's executed before the default of
// phoenix_html, which is listening on the window object
document.body.addEventListener('phoenix.link.click', function (e) {
  // Prevent default implementation
  e.stopPropagation();
  // Introduce alternative implementation
  var message = e.target.getAttribute("data-confirm");
  if(!message){ return; }

  // Confirm is resolved execute the click event
  if (e.target?.hasAttribute(RESOLVED_ATTRIBUTE)) {
    e.target.removeAttribute(RESOLVED_ATTRIBUTE);
    return;
  }

  // Confirm is needed, preventDefault and show your modal
  e.preventDefault();
  e.target?.setAttribute(RESOLVED_ATTRIBUTE, "");

  vex.dialog.confirm({
    message: message,
    callback: function (value) {
      if (value == true) {
        // Customer confirmed, re-trigger the click event.
        e.target?.click();
      } else {
        // Customer canceled
        e.target?.removeAttribute(RESOLVED_ATTRIBUTE);
      }
    }
  })
}, false);
```

Or you could attach your own custom behavior.

```javascript
window.addEventListener('phoenix.link.click', function (e) {
  // Introduce custom behaviour
  var message = e.target.getAttribute("data-prompt");
  var answer = e.target.getAttribute("data-prompt-answer");
  if(message && answer && (answer != window.prompt(message))) {
    e.preventDefault();
  }
}, false);
```

The latter could also be bound to any `click` event, but this way you can be sure your custom
code is only executed when the code of `phoenix_html.js` is run.

## CSRF Protection

By default, CSRF tokens are generated through `Plug.CSRFProtection`.

## focus_wrap/1

Wraps tab focus around a container for accessibility.

This is an essential accessibility feature for interfaces such as modals, dialogs, and menus.

[INSERT LVATTRDOCS]

## Examples

Simply render your inner content within this component and focus will be wrapped around the
container as the user tabs through the containers content:

```heex
<.focus_wrap id="my-modal" class="bg-white">
  <div id="modal-content">
    Are you sure?
    <button phx-click="cancel">Cancel</button>
    <button phx-click="confirm">OK</button>
  </div>
</.focus_wrap>
```

## dynamic_tag/1

Generates a dynamically named HTML tag.

Raises an `ArgumentError` if the tag name is found to be unsafe HTML.

[INSERT LVATTRDOCS]

## Examples

```heex
<.dynamic_tag tag_name="input" name="my-input" type="text"/>
```

```html
<input name="my-input" type="text"/>
```

```heex
<.dynamic_tag tag_name="p">content</.dynamic_tag>
```

```html
<p>content</p>
```

## live_file_input/1

Builds a file input tag for a LiveView upload.

[INSERT LVATTRDOCS]

## Customizing the Label

The `id` attribute cannot be overwritten, but you can create a label with a `for` attribute
pointing to the UploadConfig `ref`:

```heex
<label for={@uploads.avatar.ref}>
  <.live_file_input upload={@uploads.avatar} />
</label>
```

## Drag and Drop

Drag and drop is supported by annotating the droppable container with a `phx-drop-target`
attribute pointing to the UploadConfig `ref`, so the following markup is all that is required
for drag and drop support:

```heex
<label for={@uploads.avatar.ref} phx-drop-target={@uploads.avatar.ref}>
  <.live_file_input upload={@uploads.avatar} />
</label>
```

The drop target receives the `phx-drop-target-active` class when it is active. For more information, see the [uploads guide](guides/server/uploads.md).
## Examples

Rendering a file input:

```heex
<.live_file_input upload={@uploads.avatar} />
```

Rendering a file input with a label:

```heex
<label for={@uploads.avatar.ref}>Avatar</label>
<.live_file_input upload={@uploads.avatar} />
```

## intersperse/1

Intersperses separator slot between an enumerable.

Useful when you need to add a separator between items such as when
rendering breadcrumbs for navigation. Provides each item to the
inner block.

## Examples

```heex
<.intersperse :let={item} enum={["home", "profile", "settings"]}>
  <:separator>
    <span class="sep">|</span>
  </:separator>
  {item}
</.intersperse>
```

Renders the following markup:

```html
home <span class="sep">|</span> profile <span class="sep">|</span> settings
```

## async_result/1

Renders a `Phoenix.LiveView.AsyncResult` struct (e.g. from `Phoenix.LiveView.assign_async/4`)
with slots for the different loading states.
The result state takes precedence over subsequent loading and failed
states.

> #### Note {: .info}
>
> The inner block receives the result of the async assign as a `:let`.
> The let is only accessible to the inner block and is not in scope to the
> other slots.

## Examples

```elixir
def mount(%{"slug" => slug}, _, socket) do
  {:ok,
    socket
    |> assign_async(:org, fn -> {:ok, %{org: fetch_org!(slug)}} end)}
end
```

```heex
<.async_result :let={org} assign={@org}>
  <:loading>Loading organization...</:loading>
  <:failed :let={_failure}>there was an error loading the organization</:failed>
  <%= if org do %>
    {org.name}
  <% else %>
    You don't have an organization yet.
  <% end %>
</.async_result>
```

See [Async Operations](`m:Phoenix.LiveView#module-async-operations`) for more information.

To display loading and failed states again on subsequent `assign_async` calls,
reset the assign to a result-free `%AsyncResult{}`:

```elixir
{:noreply,
  socket
  |> assign_async(:page, &reload_data/0)
  |> assign(:page, AsyncResult.loading())}
```

## portal/1

Renders a portal.

A portal is a component that teleports its content to another place in the DOM.
It is useful in cases where you need to render some content in another place, for
example due to overflow or [stacking context](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_positioned_layout/Stacking_context).

A portal consists of two parts:

1. The portal source: the component that should be teleported.
2. The portal target: the DOM element that will render the content of the portal source.

Any element can be a portal target. In most cases, the target would be rendered inside
the layout of your application. Portal sources must be defined with the `.portal` component.

> #### A note on testing {: .info}
>
> Because portals use `<template>` elements under the hood, you cannot query for elements
> inside of a portal when using `Phoenix.LiveViewTest.element/3` and other LiveViewTest functions.
>
> Instead, `Phoenix.LiveViewTest.render/1` the portal element itself to an HTML string and do
> assertions on those:
>
> ```heex
> <.portal id="my-portal" target="body">
>   <div id="something-inside">...</div>
> </.portal>
> ```
>
> ```elixir
> # in your test, instead of
> # assert has_element?(view, "#something-inside")  <-- this won't work
> html = view |> element("#my-portal") |> render()
> assert html =~ "something-inside"
> ```

## Examples

```heex
<.portal id="modal" target="body">
  ...
</.portal>
```