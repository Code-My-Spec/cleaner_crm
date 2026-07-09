# Ecto.Changeset.Relation



## empty/1

Returns empty container for relation.

## empty?/2

Checks if the container can be considered empty.

## filter_empty/1

Filter empty changes

## apply_changes/2

Applies related changeset changes

## load!/2

Loads the relation with the given struct.

Loading will fail if the association is not loaded but the struct is.

## cast/5

Casts related according to the `on_cast` function.

## change/3

Wraps related structs in changesets.

## on_replace/2

Handles the changeset or struct when being replaced.