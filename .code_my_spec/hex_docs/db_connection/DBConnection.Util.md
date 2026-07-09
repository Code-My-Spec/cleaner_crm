# DBConnection.Util



## inspect_pid/1

Inspect a pid, including the process label if possible.

## set_label/1

Set a process label if `Process.set_label/1` is available.

## pool_label/1

Get the pool label from a pid's process label.

Returns the label if found, or `nil` otherwise.
Process labels set as `{module, label}` tuples have the label extracted.