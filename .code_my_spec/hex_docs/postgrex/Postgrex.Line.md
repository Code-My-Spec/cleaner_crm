# Postgrex.Line

Struct for PostgreSQL `line`.

Note, lines are stored in PostgreSQL in the form `{a, b, c}`, which
parameterizes a line as `a*x + b*y + c = 0`.

## Fields

  * `a`
  * `b`
  * `c`