# Postgrex.Result

Result struct returned from any successful query. Its fields are:

  * `command` - An atom or a list of atoms of the query command, for example:
    `:select`, `:insert`, or `[:rollback, :release]`;
  * `columns` - The column names;
  * `rows` - The result set. A list of lists, each inner list corresponding to a
    row, each element in the inner list corresponds to a column;
  * `num_rows` - The number of fetched or affected rows;
  * `connection_id` - The OS pid of the PostgreSQL backend that executed the query;
  * `messages` - A list of maps of messages, such as hints and notices, sent by the
    driver during the execution of the query.