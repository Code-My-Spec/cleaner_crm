# Postgrex.Query

Query struct returned from a successfully prepared query.

Its public fields are:

  * `name` - The name of the prepared statement;
  * `statement` - The prepared statement;
  * `columns` - The column names;
  * `ref` - A reference used to identify prepared queries;

## Prepared queries

Once a query is prepared with `Postgrex.prepare/4`, the
returned query will have its `ref` field set to a reference.
When `Postgrex.execute/4` is called with the prepared query,
it always returns a query. If the `ref` field in the query
given to `execute` and the one returned are the same, it
means the cached prepared query was used. If the `ref` field
is not the same, it means the query had to be re-prepared.