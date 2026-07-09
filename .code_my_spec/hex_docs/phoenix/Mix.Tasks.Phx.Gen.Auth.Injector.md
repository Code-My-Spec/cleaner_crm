# Mix.Tasks.Phx.Gen.Auth.Injector



## mix_dependency_inject/2

Injects a dependency into the contents of mix.exs

## config_inject/2

Injects configuration into `file`.

## test_config_inject/2

Injects configuration for test environment into `file`.

## test_config_help_text/2

Instructions to provide the user when `test_config_inject/2` fails.

## router_plug_inject/2

Injects the fetch_current_scope_for_<schema> plug into router's browser pipeline

## router_plug_help_text/2

Instructions to provide the user when `inject_router_plug/2` fails.

## app_layout_menu_inject/2

Injects a menu in the application layout

## app_layout_menu_help_text/2

Instructions to provide the user when `app_layout_menu_inject/2` fails.

## app_layout_menu_code_to_inject/3

Menu code to inject into the application layout template.

## inject_unless_contains/3

Injects code unless the existing code already contains `code_to_inject`

## inject_before_final_end/2

Injects snippet before the final end in a file