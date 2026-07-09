# PartitionSupervisor



## start_link/1

Starts a partition supervisor with the given options.

This function is typically not invoked directly, instead it is invoked
when using a `PartitionSupervisor` as a child of another supervisor:

    children = [
      {PartitionSupervisor, child_spec: SomeChild, name: MyPartitionSupervisor}
    ]

If the supervisor is successfully spawned, this function returns
`{:ok, pid}`, where `pid` is the PID of the supervisor. If the given name
for the partition supervisor is already assigned to a process,
the function returns `{:error, {:already_started, pid}}`, where `pid`
is the PID of that process.

Note that a supervisor started with this function is linked to the parent
process and exits not only on crashes but also if the parent process exits
with `:normal` reason.

## Options

  * `:name` - an atom or via tuple representing the name of the partition
    supervisor (see `t:name/0`).

  * `:partitions` - a positive integer with the number of partitions.
    Defaults to `System.schedulers_online()` (typically the number of cores).

  * `:strategy` - the restart strategy option, defaults to `:one_for_one`.
    You can learn more about strategies in the `Supervisor` module docs.

  * `:max_restarts` - the maximum number of restarts allowed in
    a time frame. Defaults to `3`.

  * `:max_seconds` - the time frame in which `:max_restarts` applies.
    Defaults to `5`.

  * `:with_arguments` - a two-argument anonymous function that allows
    the partition to be given to the child starting function. See the
    `:with_arguments` section below.

## `:with_arguments`

Sometimes you want each partition to know their partition assigned number.
This can be done with the `:with_arguments` option. This function receives
the list of arguments of the child specification and the partition. It
must return a new list of arguments that will be passed to the child specification
of children.

For example, most processes are started by calling `start_link(opts)`,
where `opts` is a keyword list. You could inject the partition into the
options given to the child:

    with_arguments: fn [opts], partition ->
      [Keyword.put(opts, :partition, partition)]
    end

## partitions/1

Returns the number of partitions for the partition supervisor.

## which_children/1

Returns a list with information about all children.

This function returns a list of tuples containing:

  * `id` - the partition number

  * `child` - the PID of the corresponding child process or the
    atom `:restarting` if the process is about to be restarted

  * `type` - `:worker` or `:supervisor` as defined in the child
    specification

  * `modules` - as defined in the child specification

## count_children/1

Returns a map containing count values for the supervisor.

The map contains the following keys:

  * `:specs` - the number of partitions (children processes)

  * `:active` - the count of all actively running child processes managed by
    this supervisor

  * `:supervisors` - the count of all supervisors whether or not the child
    process is still alive

  * `:workers` - the count of all workers, whether or not the child process
    is still alive

## stop/3

Synchronously stops the given partition supervisor with the given `reason`.

It returns `:ok` if the supervisor terminates with the given
reason. If it terminates with another reason, the call exits.

This function keeps OTP semantics regarding error reporting.
If the reason is any other than `:normal`, `:shutdown` or
`{:shutdown, _}`, an error report is logged.