# Credo.Execution.Task

A Task is a step in a pipeline, which is given an `Credo.Execution` struct and must return one as well.

Tasks in a pipeline are only called if they are not "halted" (see `Credo.Execution.halt/2`).

It implements a `call/1` or `call/2` callback, which is called with the `Credo.Execution` struct
as first parameter (and the Task's options as the second in case of `call/2`).

## __using__/1

Works like `error/1`, but receives the options, which were given during pipeline registration, as second argument.