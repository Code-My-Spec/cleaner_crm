# Jason.OrderedObject



## new/1

Struct implementing a JSON object retaining order of properties.

A wrapper around a keyword (that supports non-atom keys) allowing for
proper protocol implementations.

Implements the `Access` behaviour and `Enumerable` protocol with
complexity similar to keywords/lists.