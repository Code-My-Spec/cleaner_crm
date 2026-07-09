# Req.Fields



## merge/2

Merges `fields1` and `fields2`.

## Examples

    iex> Req.Fields.merge(%{"a" => ["1"]}, %{"a" => ["2"], "b" => ["2"]})
    %{"a" => ["2"], "b" => ["2"]}

## get_values/2

Returns field values.

## put/3

Adds a new field `name` with the given `value` if not present,
otherwise replaces previous value with `value`.

## put_new/3

Adds a field `name` unless already present.

## delete/2

Deletes the field given by `name`.

## get_list/1

Returns fields as list.