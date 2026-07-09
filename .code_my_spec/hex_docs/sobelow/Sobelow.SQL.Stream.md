# Sobelow.SQL.Stream

# SQL Injection in Stream

This submodule of the `SQL` module checks for SQL injection
vulnerabilities through usage of the `Ecto.Adapters.SQL.stream`.

Ensure that the query is parameterized and not user-controlled.

SQLi Stream checks can be ignored with the following command:

    $ mix sobelow -i SQL.Stream