# Gettext.Fuzzy



## matcher/1

Returns a matcher function that takes two message keys and checks if they
match.

`String.jaro_distance/2` (which calculates the Jaro distance) is used to
measure the distance between the two messages. `threshold` is the minimum
distance that means a match. `{:match, distance}` is returned in case of a
match, `:nomatch` otherwise.

## jaro_distance/2

Finds the Jaro distance between the msgids of two messages.

To mimic the behaviour of the `msgmerge` tool, this function only calculates
the Jaro distance of the msgids of the two messages, even if one (or both)
of them is a plural message.

As per `msgmerge`, the msgctxt of a message is completely ignored when
calculating the distance.

## merge/2

Merges a message with the corresponding fuzzy match.

`new` is the newest message and `existing` is the existing message
that we use to populate the msgstr of the newest message.

Note that if `new` is a regular message, then the result will be a regular
message; if `new` is a plural message, then the result will be a
plural message.