# Wallaby.Query



## css/2

Literally queries for the CSS selector you provide.

## xpath/2

Literally queries for the xpath selector you provide.

## text/2

This function can be used in one of two ways.

The first is by providing a selector and possible options. This generates a
query that checks if the provided text is contained anywhere.

## Example

  ```
  Query.text("Submit", count: 1)
  ```

The second is by providing an existing query and a value to set as the `text`
option.

Note that the text you're querying for must appear in a single element.
To assert on text that appears in multiple (potentially nested) elements,
rather than using `assert_has/2` in combination with `Query.text/2`, use
`assert_text/{2,3}` directly.

## Examples

### Querying the text of a specific element

  ```
  submit_button = Query.css("#submit-button")

  update_button = submit_button |> Query.text("Update")
  create_button = submit_button |> Query.text("Create")
  ```

### Asserting on the text of a single element

    ```
    submit_button = Query.css("#submit-button")
    assert_has(session, Query.text(submit_button, "Create"))
    ```

### Asserting on the text of nested elements

HTML:

    ```
    <div id="unread-notifications">
      Unread messages:
      <strong>1 message</strong>
    </div>
    ```

Test:

    ```
    assert_text(session, "Unread messages: 1 message")

    notifications_block = Query.css("#unread-notifications")
    # It would *not* work to query as: Query.text(notifications_block, "Unread messages: 1 message")
    assert_has(session, Query.text(notifications_block, "Unread messages:"))
    ```

## value/2

Checks if the provided value is contained anywhere.

## data/3

Checks if the data attribute is contained anywhere.

## attribute/3

Checks if the provided attribute, value pair is contained anywhere.

## text_field/2

See `Wallaby.Query.fillable_field/2`.

## fillable_field/2

Looks for a text input field where the provided selector is the id, name or
placeholder of the text field itself or alternatively the id or the text of
the label.

## radio_button/2

Looks for a radio button where the provided selector is the id, name or
placeholder of the radio button itself or alternatively the id or the text of
the label.

## checkbox/2

Looks for a checkbox where the provided selector is the id, name or
placeholder of the checkbox itself or alternatively the id or the text of
the label.

## select/2

Looks for a select box where the provided selector is the id or name of the
select box itself or alternatively the id or the text of the label.

## option/2

Looks for an option that contains the given text.

## button/2

Looks for a button (literal button or input type button, submit, image or
reset) where the provided selector is the id, name, value, alt or title of the
button.

## link/2

Looks for a link where the selector is the id, link text, title of the link
itself or the alt of an image child node.

## file_field/2

Looks for a file input where the selector is the id or name of the file input
itself or the id or text of the label.

## visible/2

Updates a query's visibility (visible if `true`, hidden if `false`).

## Examples

  ```
  Query.css("#modal")
  |> Query.visible(true)

  Query.css("#modal")
  |> Query.visible(false)
  ```

## selected/2

Updates a query's `selected` option.

## Examples

  ```
  Query.css("#select-dropdown")
  |> Query.selected(true)

  Query.css("#select-dropdown")
  |> Query.selected(false)
  ```

## count/2

Updates a query's `count`.

The `count` specifies how many elements you expect to be present within the scope
of the query and can be any number greater than zero or `:any`.

## Example

```elixir
# Exactly 2 elements
Query.css(".names > li")
|> Query.count(2)

# Any number of elements
Query.css(".names > li")
|> Query.count(:any)
```

## at/2

Updates a query's `at` option.

## Example

  ```
  Query.css(".names")
  |> Query.at(3)
  ```

## compile/1

Compiles a query into CSS or xpath so its ready to be sent to the driver

    iex> Wallaby.Query.compile Wallaby.Query.text("my text")
    {:xpath, ".//*[contains(normalize-space(text()), \"my text\")]"}
    iex> Wallaby.Query.compile Wallaby.Query.css("#some-id")
    {:css, "#some-id"}