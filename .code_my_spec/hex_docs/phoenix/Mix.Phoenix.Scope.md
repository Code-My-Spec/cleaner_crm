# Mix.Phoenix.Scope



## new!/2

Creates a new scope struct.

## scopes_from_config/1

Returns a `%{name: scope}` map of configured scopes.

## default_scope/1

Returns the default scope.

## scope_from_opts/3

Returns the configured scope for the given --scope parameter.

Returns `nil` for `--no-scope` and raises if a specific scope is not configured.

## route_prefix/2

Generates a route prefix string with placeholders for the access path.

Takes a scope_key (what to use for accessing the scope) and a schema with scope information.
If the schema doesn't have a scope with route_prefix, returns an empty string.
Otherwise, it processes the route_prefix, replacing param segments with dynamic path elements.

## Examples

    route_prefix("socket.assigns.current_scope", schema_with_scope)
    # => "/orgs/#{socket.assigns.current_scope.organization.slug}"

    route_prefix("@current_scope", schema_with_scope)
    # => "/orgs/#{@current_scope.organization.slug}"

    route_prefix("scope", schema_with_scope)
    # => "/orgs/#{scope.organization.slug}"