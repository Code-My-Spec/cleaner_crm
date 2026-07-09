# Sobelow.SQL.Query

# SQL Injection in Query

This submodule of the `SQL` module checks for SQL injection
vulnerabilities through usage of the `Ecto.Adapters.SQL.query`
and `Ecto.Adapters.SQL.query!`.

Ensure that the query is parameterized and not user-controlled.

SQLi Query checks can be ignored with the following command:

    $ mix sobelow -i SQL.Query