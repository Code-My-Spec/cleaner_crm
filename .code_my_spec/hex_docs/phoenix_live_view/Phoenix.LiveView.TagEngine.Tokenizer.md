# Phoenix.LiveView.TagEngine.Tokenizer



## init/4

Initiate the Tokenizer state.

### Params

* `indentation` - An integer that indicates the current indentation.
* `file` - Can be either a file or a string "nofile".
* `source` - The contents of the file as binary to be tokenized.
* `tag_handler` - Tag handler to classify the tags. See `Phoenix.LiveView.TagEngine`
  behaviour.

## tokenize/5

Tokenize the given text according to the given params.

### Params

* `text` - The content to be tokenized.
* `meta` - A keyword list with `:line` and `:column`. Both must be integers.
* `tokens` - A list of tokens.
* `cont` - An atom that is `:text`, `:style`, or `:script`, or a tuple
  {:comment, line, column}.
* `state` - The tokenizer state that must be initiated by `Tokenizer.init/4`

### Examples

    iex> alias Phoenix.LiveView.Tokenizer

    iex> state =
      Tokenizer.init(indent, file, [text: "<section><div/></section>"], HTMLEngine)

    iex> Tokenizer.tokenize(state)
    {[
       {:close, :tag, "section", %{column: 16, line: 1}},
       {:tag, "div", [], %{column: 10, line: 1, closing: :self}},
       {:tag, "section", [], %{column: 1, line: 1}}
     ], {:text, :enabled}}