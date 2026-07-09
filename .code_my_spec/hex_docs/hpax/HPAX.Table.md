# HPAX.Table



## new/2

Creates a new HPACK table with the given maximum size.

The maximum size is not the maximum number of entries but rather the maximum size as defined in
http://httpwg.org/specs/rfc7541.html#maximum.table.size.

## add/3

Adds the given header to the given table.

If the new entry does not fit within the max table size then the oldest entries will be evicted.

Header names should be lowercase when added to the HPACK table
as per the [HTTP/2 spec](https://http2.github.io/http2-spec/#rfc.section.8.1.2):

> header field names MUST be converted to lowercase prior to their encoding in HTTP/2

## lookup_by_index/2

Looks up a header by index `index` in the given `table`.

Returns `{:ok, {name, value}}` if a header is found at the given `index`, otherwise returns
`:error`. `value` can be a binary in case both the header name and value are present in the
table, or `nil` if only the name is present (this can only happen in the static table).

## lookup_by_header/3

Looks up the index of a header by its name and value.

It returns:

  * `{:full, index}` if the full header (name and value) are present in the table at `index`

  * `{:name, index}` if `name` is present in the table but with a different value than `value`

  * `:not_found` if the header name is not in the table at all

Header names should be lowercase when looked up in the HPACK table
as per the [HTTP/2 spec](https://http2.github.io/http2-spec/#rfc.section.8.1.2):

> header field names MUST be converted to lowercase prior to their encoding in HTTP/2

## resize/2

Changes the table's protocol negotiated maximum size, possibly evicting entries as needed to satisfy.

If the indicated size is less than the table's current max size, entries
will be evicted as needed to fit within the specified size, and the table's
maximum size will be decreased to the specified value. An will also be
set which will enqueue a 'dynamic table size update' command to be prefixed
to the next block encoded with this table, per RFC9113§4.3.1.

If the indicated size is greater than or equal to the table's current max size, no entries are evicted
and the table's maximum size changes to the specified value.

In all cases, the table's `:protocol_max_table_size` is updated accordingly

## pop_pending_resizes/1

Returns (and clears) any pending resize events on the table which will need to be signalled to
the decoder via dynamic table size update messages. Intended to be called at the start of any
block encode to prepend such dynamic table size update(s) as needed. The value of
`pending_minimum_resize` indicates the smallest maximum size of this table which has not yet
been signalled to the decoder, and is always included in the list returned if it is set.
Additionally, if the current max table size is larger than this value, it is also included int
the list, per https://www.rfc-editor.org/rfc/rfc7541#section-4.2