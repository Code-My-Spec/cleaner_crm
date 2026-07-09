# CodeMySpecGenerators.Injector



## inject_routes/2

Injects route blocks into the router file.

Finds the specified anchor point and injects the routes after it.
Returns `{:ok, new_content}`, `:already_injected`, or `{:error, :unable_to_inject}`.

## inject_into_live_session/3

Injects route blocks after a specific live_session anchor in the router.

Searches for `live_session :authenticated` or similar patterns and injects
routes inside the existing live_session block.

## inject_scope_fields/2

Injects fields into an existing Scope struct's defstruct call.

Finds `defstruct` in the Scope module and adds new fields.

## inject_supervision_child/2

Injects a child spec into the Application supervision tree.

Finds the `children = [` list and adds the new child.

## inject_deps_instructions/1

Prints instructions for deps to add to mix.exs.

## inject_into_file/3

Injects code into a file if not already present.

Reads the file, checks if the marker is already present,
and if not, calls the injection function and writes the result.
Returns `:ok` on success, `:already_injected`, or raises on error.

## inject_before_final_end/2

Injects code before the final `end` in the content.