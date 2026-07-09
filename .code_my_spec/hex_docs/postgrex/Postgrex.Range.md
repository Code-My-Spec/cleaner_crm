# Postgrex.Range

Struct for PostgreSQL `range`.

Note that PostgreSQL itself does not return ranges exactly as stored:
`SELECT '(1,5)'::int4range` returns `[2,5)`, which is equivalent in terms
of the values included in the range ([PostgreSQL docs](https://www.postgresql.org/docs/current/rangetypes.html#RANGETYPES-IO)).
When selecting data, this struct simply reflects what PostgreSQL returns.

## Fields

  * `lower`
  * `upper`
  * `lower_inclusive`
  * `upper_inclusive`