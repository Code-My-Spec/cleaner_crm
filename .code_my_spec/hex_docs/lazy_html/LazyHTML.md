# LazyHTML



## from_document/1

Parses an HTML document.

This function expects a complete document, therefore if either of
`<html>`, `<head>` or `<body>` tags is missing, it will be added,
which matches the usual browser behaviour. To parse a part of an
HTML document, use `from_fragment/1` instead.

## Examples

    iex> LazyHTML.from_document(~S|<html><head></head><body>Hello world!</body></html>|)
    #LazyHTML<
      1 node
      #1
      <html><head></head><body>Hello world!</body></html>
    >

    iex> LazyHTML.from_document(~S|<div>Hello world!</div>|)
    #LazyHTML<
      1 node
      #1
      <html><head></head><body><div>Hello world!</div></body></html>
    >

## from_fragment/1

Parses a segment of an HTML document.

As opposed to `from_document/1`, this function does not expect a full
document and does not add any extra tags.

## Examples

    iex> LazyHTML.from_fragment(~S|<a class="button">Click me</a>|)
    #LazyHTML<
      1 node
      #1
      <a class="button">Click me</a>
    >

    iex> LazyHTML.from_fragment(~S|<span>Hello</span> <span>world</span>|)
    #LazyHTML<
      3 nodes
      #1
      <span>Hello</span>
      #2
      [whitespace]
      #3
      <span>world</span>
    >

## to_tree/2

Builds an Elixir tree data structure representing the `lazy_html`
document.

## Options

  * `:sort_attributes` - when `true`, attributes lists are sorted
    alphabetically by name. Defaults to `false`.

  * `:skip_whitespace_nodes` - when `true`, ignores text nodes that
    consist entirely of whitespace, usually whitespace between tags.
    Defaults to `false`.

## Examples

    iex> lazy_html = LazyHTML.from_document(~S|<html><head><title>Page</title></head><body>Hello world</body></html>|)
    iex> LazyHTML.to_tree(lazy_html)
    [{"html", [], [{"head", [], [{"title", [], ["Page"]}]}, {"body", [], ["Hello world"]}]}]

    iex> lazy_html = LazyHTML.from_fragment(~S|<div><!-- Link --><a href="https://elixir-lang.org">Elixir</a></div>|)
    iex> LazyHTML.to_tree(lazy_html)
    [
      {"div", [], [{:comment, " Link "}, {"a", [{"href", "https://elixir-lang.org"}], ["Elixir"]}]}
    ]

You can get a normalized tree by passing `sort_attributes: true`:

    iex> lazy_html = LazyHTML.from_fragment(~S|<div id="root" class="layout"></div>|)
    iex> LazyHTML.to_tree(lazy_html, sort_attributes: true)
    [{"div", [{"class", "layout"}, {"id", "root"}], []}]

## from_tree/1

Builds a lazy HTML document from an Elixir tree data structure.

## Examples

    iex> tree = [
    ...>   {"html", [], [{"head", [], [{"title", [], ["Page"]}]}, {"body", [], ["Hello world"]}]}
    ...> ]
    iex> LazyHTML.from_tree(tree)
    #LazyHTML<
      1 node
      #1
      <html><head><title>Page</title></head><body>Hello world</body></html>
    >

    iex> tree = [
    ...>   {"div", [], []},
    ...>   {:comment, " Link "},
    ...>   {"a", [{"href", "https://elixir-lang.org"}], ["Elixir"]}
    ...> ]
    iex> LazyHTML.from_tree(tree)
    #LazyHTML<
      3 nodes
      #1
      <div></div>
      #2
      <!-- Link -->
      #3
      <a href="https://elixir-lang.org">Elixir</a>
    >

## child_nodes/1

Returns the child_nodes nodes of the root nodes in `lazy_html`.

## Examples

    iex> lazy_html = LazyHTML.from_fragment(~S|<div><span>Hello</span> <span>world</span></div>|)
    iex> LazyHTML.child_nodes(lazy_html)
    #LazyHTML<
      3 nodes (from selector)
      #1
      <span>Hello</span>
      #2
      [whitespace]
      #3
      <span>world</span>
    >
    iex> LazyHTML.child_nodes(LazyHTML.child_nodes(lazy_html))
    #LazyHTML<
      2 nodes (from selector)
      #1
      Hello
      #2
      world
    >

## parent_node/1

Returns the (unique) parent nodes of the root nodes in `lazy_html`.

## Examples

    iex> lazy_html = LazyHTML.from_fragment(~S|<div><span>Hello</span> <span>world</span></div>|)
    iex> spans = LazyHTML.query(lazy_html, "span")
    iex> LazyHTML.parent_node(spans)
    #LazyHTML<
      1 node (from selector)
      #1
      <div><span>Hello</span> <span>world</span></div>
    >

## nth_child/1

Returns the position among its siblings for every root element in `lazy_html`.

The position numbering is 1-based and only considers siblings that
are elements, as to match the `:nth-child` CSS pseudo-class.

Note that if there are text or comment root nodes, they are ignored,
and they have no corresponding number in the result.

## Examples

    iex> lazy_html = LazyHTML.from_fragment(~S|<div><span>1</span><span>2</span></div>|)
    iex> spans = LazyHTML.query(lazy_html, "span")
    iex> LazyHTML.nth_child(spans)
    [1, 2]

## text/2

Returns the text content of all nodes in `lazy_html`.

## Options

  * `:separator` - a separator used to join the text content from
    individual nodes. Note that the separator is only inserted
    between non-empty nodes. Defaults to no separator.

## Examples

    iex> lazy_html = LazyHTML.from_fragment(~S|<div><span>Hello</span> <span>world</span></div>|)
    iex> LazyHTML.text(lazy_html)
    "Hello world"

    iex> lazy_html = LazyHTML.from_fragment(~S|<div><span>1</span><span>2</span><span>3</span></div>|)
    iex> LazyHTML.text(lazy_html, separator: ", ")
    "1, 2, 3"

    iex> lazy_html = LazyHTML.from_fragment(~S|<div><span>1</span><span></span><span>2</span></div>|)
    iex> LazyHTML.text(lazy_html, separator: ", ")
    "1, 2"

If you want to get the text for each root node separately, you can
use `Enum.map/2`:

    iex> lazy_html = LazyHTML.from_fragment(~S|<div><span>Hello</span> <span>world</span></div>|)
    iex> spans = LazyHTML.query(lazy_html, "span")
    #LazyHTML<
      2 nodes (from selector)
      #1
      <span>Hello</span>
      #2
      <span>world</span>
    >
    iex> Enum.map(spans, &LazyHTML.text/1)
    ["Hello", "world"]

## tag/1

Returns tag name for every root element in `lazy_html`.

Note that if there are text or comment root nodes, they are ignored,
and they have no corresponding list in the result.

## Examples

    iex> lazy_html = LazyHTML.from_fragment(~S|<div><span>Hello</span> <span>world</span></div>|)
    iex> LazyHTML.tag(lazy_html)
    ["div"]

    iex> lazy_html = LazyHTML.from_fragment(~S|<span>Hello</span> <span>world</span>|)
    iex> LazyHTML.tag(lazy_html)
    ["span", "span"]