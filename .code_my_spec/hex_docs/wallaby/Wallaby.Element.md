# Wallaby.Element

Defines an Element Struct and interactions with Elements.

Typically these functions are used in conjunction with a `find`:

```
page
|> find(Query.css(".some-element"), fn(element) -> Element.click(element) end)
```

These functions can be used to create new actions specific to your application:

```
def create_todo(todo_field, todo_text) do
  todo_field
  |> Element.click()
  |> Element.fill_in(with: todo_text)
  |> Element.send_keys([:enter])
end
```

## Retrying

Unlike `Browser` the actions in `Element` do not retry if the element becomes stale. Instead an exception will be raised.

## clear/1

Clears any value set in the element.

## fill_in/2

Fills in the element with the specified value.

## click/2

Clicks the element.

## hover/1

Hovers on the element.

## touch_down/3

Touches and holds the element on its top-left corner plus an optional offset.

## tap/1

Taps the element.

## touch_scroll/3

Scroll on the screen from the given element by the given offset using touch events.

## text/1

Gets the element's text value.

If the element is not visible, the return value will be `""`.

## attr/2

Gets the value of the element's attribute.

## selected?/1

Returns a boolean based on whether or not the element is selected.

## Note
This only really makes sense for options, checkboxes, and radio buttons.
Everything else will simply return false because they have no notion of
"selected".

## visible?/1

Returns a boolean based on whether or not the element is visible.

## set_value/2

Sets the value of the element.

## send_keys/2

Sends keys to the element.

## value/1

Returns the Element's value.

## size/1

Returns a tuple `{width, height}` with the size of the given element.

## location/1

Returns a tuple `{x, y}` with the coordinates of the left-top corner of given element.