# Telemetry.Metrics.ConsoleReporter

A reporter that prints events and metrics to the terminal.

This is useful for debugging and discovering all available
measurements and metadata in an event.

For example, imagine the given metrics:

    metrics = [
      last_value("vm.memory.binary", unit: :byte),
      counter("vm.memory.total")
    ]

A console reporter can be started as a child of your supervision tree as:

    {Telemetry.Metrics.ConsoleReporter, metrics: metrics}

Now when the "vm.memory" telemetry event is dispatched, we will see
reports like this:

    [Telemetry.Metrics.ConsoleReporter] Got new event!
    Event name: vm.memory
    All measurements: %{binary: 100, total: 200}
    All metadata: %{}

    Metric measurement: :binary (last_value)
    With value: 100 byte
    And tag values: %{}

    Metric measurement: :total (counter)
    With value: 200
    And tag values: %{}

In other words, every time there is an event for any of the registered
metrics, it prints the event measurement and metadata, and then it prints
information about each metric to the user.