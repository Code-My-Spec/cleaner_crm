# Ecto.Adapter

Specifies the minimal API required from adapters.

## lookup_meta/1

Returns the adapter metadata from its `c:init/1` callback.

It expects a process name of a repository. The name is either
an atom or a PID. For a given repository, you often want to
call this function based on the repository dynamic repo:

    Ecto.Adapter.lookup_meta(repo.get_dynamic_repo())