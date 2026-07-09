# Credo.Check.ConfigComment

`ConfigComment` structs represent comments which control Credo's behaviour.

The following comments are supported:

    # credo:disable-for-this-file
    # credo:disable-for-next-line
    # credo:disable-for-previous-line
    # credo:disable-for-lines:<number>

## new/3

Returns a `ConfigComment` struct based on the given parameters.

## ignores_issue?/2

Returns `true` if the given `issue` should be ignored based on the given `config_comment`