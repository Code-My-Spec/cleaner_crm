# Phoenix.LiveView.JS



## push/1

Pushes an event to the server.

  * `event` - The string event name to push.

## Options

  * `:target` - A selector or component ID to push to. This value will
    overwrite any `phx-target` attribute present on the element.
  * `:loading` - A selector to apply the phx loading classes to,
    such as `phx-click-loading` in case the event was triggered by
    `phx-click`. The element will be locked from server updates
    until the push is acknowledged by the server.
  * `:page_loading` - Boolean to trigger the phx:page-loading-start and
    phx:page-loading-stop events for this push. Defaults to `false`.
  * `:value` - A map of values to send to the server. These values will be
    merged over any `phx-value-*` attributes that are present on the element.
    All keys will be treated as strings when merging. When used on a form event
    like `phx-change` or `phx-submit`, the precedence is
    `JS.push value > phx-value-* > input value`.

## Examples

```heex
<button phx-click={JS.push("clicked")}>click me!</button>
<button phx-click={JS.push("clicked", value: %{id: @id})}>click me!</button>
<button phx-click={JS.push("clicked", page_loading: true)}>click me!</button>
```

## push/2

See `push/1`.

## push/3

See `push/1`.

## dispatch/2

Dispatches an event to the DOM.

  * `event` - The string event name to dispatch.

*Note*: All events dispatched are of a type
[CustomEvent](https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent),
with the exception of `"click"`. For a `"click"`, a
[MouseEvent](https://developer.mozilla.org/en-US/docs/Web/API/MouseEvent)
is dispatched to properly simulate a UI click.

For emitted `CustomEvent`'s, the event detail will contain a `dispatcher`,
which references the DOM node that dispatched the JS event to the target
element.

## Options

  * `:to` - An optional DOM selector to dispatch the event to.
    Defaults to the interacted element. See the `DOM selectors`
    section for details.
  * `:detail` - An optional detail map to dispatch along
    with the client event. The details will be available in the
    `event.detail` attribute for event listeners.
  * `:bubbles` – A boolean flag to bubble the event or not. Defaults to `true`.
  * `:blocking` - A boolean flag to block the UI until the event handler calls `event.detail.done()`.
    The done function is injected by LiveView and *must* be called eventually to unblock the UI.
    This is useful to integrate with third party JavaScript based animation libraries.

## Examples

```javascript
window.addEventListener("click", e => console.log("clicked!", e.detail))
```

```heex
<button phx-click={JS.dispatch("click", to: ".nav")}>Click me!</button>
```

## dispatch/3

See `dispatch/2`.

## toggle/2

See `toggle/1`.

## show/2

See `show/1`.

## hide/2

See `hide/1`.

## add_class/2

See `add_class/1`.

## add_class/3

See `add_class/1`.

## remove_class/2

See `remove_class/1`.

## remove_class/3

See `remove_class/1`.

## transition/2

See `transition/1`.

## transition/3

See `transition/1`.

## set_attribute/1

Sets an attribute on elements.

Accepts a tuple containing the string attribute name/value pair.

## Options

  * `:to` - An optional DOM selector to add attributes to.
    Defaults to the interacted element. See the `DOM selectors`
    section for details.

## Examples

```heex
<button phx-click={JS.set_attribute({"aria-expanded", "true"}, to: "#dropdown")}>
  show
</button>
```

> #### A note on properties {: .warning}
>
> `JS.set_attribute/1` cannot be used to set DOM properties such as the [`value` of an input](https://jakearchibald.com/2024/attributes-vs-properties/#value-on-input-fields).
> So if you find yourself wanting to do `JS.set_attribute({"value", "..."})` on an input, and
> see that updated value reflected in a form event, you should use `JS.dispatch/2`
> instead:
>
> Instead of
>
> ```heex
> <.button phx-click={JS.set_attribute({"value", ""}, to: "#my_input")}>...</.button>
> ```
>
> do
>
> ```heex
> <script :type={Phoenix.LiveView.ColocatedJS} name="clear_input">
>   window.addEventListener("input:clear", (e) => {
>     e.target.value = ""
>     e.target.dispatchEvent(new Event("input", {bubbles: true}))
>   })
> </script>
> <.button phx-click={JS.dispatch("input:clear", to: "#my_input")}>...</.button>
> ```
>
> While the example above uses `Phoenix.LiveView.ColocatedJS`, you can also
> define the event listener directly inside your `app.js` instead.

## set_attribute/2

See `set_attribute/1`.

## set_attribute/3

See `set_attribute/1`.

## remove_attribute/1

Removes an attribute from elements.

  * `attr` - The string attribute name to remove.

## Options

  * `:to` - An optional DOM selector to remove attributes from.
    Defaults to the interacted element. See the `DOM selectors`
    section for details.

## Examples

```heex
<button phx-click={JS.remove_attribute("aria-expanded", to: "#dropdown")}>
  hide
</button>
```

## remove_attribute/2

See `remove_attribute/1`.

## remove_attribute/3

See `remove_attribute/1`.

## toggle_attribute/1

Sets or removes element attribute based on attribute presence.

Accepts a two or three-element tuple:

* `{attr, val}` - Sets the attribute to the given value or removes it
* `{attr, val1, val2}` - Toggles the attribute between `val1` and `val2`

## Options

  * `:to` - An optional DOM selector to set or remove attributes from.
    Defaults to the interacted element. See the `DOM selectors`
    section for details.

## Examples

```heex
<button phx-click={JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "#dropdown")}>
  toggle
</button>

<button phx-click={JS.toggle_attribute({"open", "true"}, to: "#dialog")}>
  toggle
</button>
```

## toggle_attribute/2

See `toggle_attribute/1`.

## toggle_attribute/3

See `toggle_attribute/1`.

## ignore_attributes/1

Mark attributes as ignored, skipping them when patching the DOM.

Accepts a single attribute name or a list of attribute names.
An asterisk `*` can be used as a wildcard.

Once set, the given attributes will not be patched across LiveView updates.
This includes attributes that are removed by the server.

If you need to "unmark" an attribute, you need to call `ignore_attributes/1` again
with an updated list of attributes.

This is mostly useful in combination with the `phx-mounted` binding, for example:

```heex
<dialog phx-mounted={JS.ignore_attributes("open")}>
  ...
</dialog>
```

> #### A note on the behavior of phx-mounted {: .info}
>
> The `phx-mounted` binding executes when the LiveView is mounted.
> This means that you cannot use `ignore_attributes/1` to retain attributes
> that are set on the client during the disconnected render.
> `JS.ignore_attributes/1` will only ever ignore future changes from the server.

## Options

  * `:to` - An optional DOM selector to select the target element.
    Defaults to the interacted element. See the `DOM selectors`
    section for details.

## Examples

    JS.ignore_attributes(["open", "data-*"], to: "#my-dialog")

## focus/1

Sends focus to a selector.

## Options

  * `:to` - An optional DOM selector to send focus to.
    Defaults to the interacted element. See the `DOM selectors`
    section for details.

## Examples

    JS.focus(to: "main")

## focus/2

See `focus/1`.

## focus_first/1

Sends focus to the first focusable child in selector.

## Options

  * `:to` - An optional DOM selector to focus.
    Defaults to the interacted element. See the `DOM selectors`
    section for details.

## Examples

    JS.focus_first(to: "#modal")

## focus_first/2

See `focus_first/1`.

## push_focus/1

Pushes focus from the source element to be later popped.

## Options

  * `:to` - An optional DOM selector to push focus to.
    Defaults to the interacted element. See the `DOM selectors`
    section for details.

## Examples

    JS.push_focus()
    JS.push_focus(to: "#my-button")

## push_focus/2

See `push_focus/1`.

## pop_focus/1

Focuses the last pushed element.

## Examples

    JS.pop_focus()

## navigate/1

Sends a navigation event to the server and updates the browser's pushState history.

## Options

  * `:replace` - Whether to replace the browser's pushState history. Defaults to `false`.

## Examples

    JS.navigate("/my-path")

## navigate/2

See `navigate/1`.

## navigate/3

See `navigate/1`.

## patch/1

Sends a patch event to the server and updates the browser's pushState history.

## Options

  * `:replace` - Whether to replace the browser's pushState history. Defaults to `false`.

## Examples

    JS.patch("/my-path")

## patch/2

See `patch/1`.

## patch/3

See `patch/1`.

## exec/1

Executes JS commands located in an element's attribute.

  * `attr` - The string attribute where the JS command is specified

## Options

  * `:to` - An optional DOM selector to fetch the attribute from.
    Defaults to the interacted element. See the `DOM selectors`
    section for details.

## Examples

```heex
<div id="modal" phx-remove={JS.hide()}>...</div>
<button phx-click={JS.exec("phx-remove", to: "#modal")}>close</button>
```

## exec/2

See `exec/1`.

## exec/3

See `exec/1`.

## concat/2

Combines two JS commands, appending the second to the first.