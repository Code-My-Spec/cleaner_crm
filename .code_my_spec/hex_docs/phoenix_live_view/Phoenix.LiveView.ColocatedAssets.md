# Phoenix.LiveView.ColocatedAssets



## extract/5

Extracts content into the colocated directory.

Returns an opaque struct that is stored as macro component data
for manifest generation.

The flow is:

  1. MacroComponent transform callback is called.
  2. The transform callback invokes ColocatedAssets.extract/5,
     which writes the content to the target directory.
  3. LiveView compiler invokes ColocatedAssets.compile/0.
  4. ColocatedAssets builds a list of `%ColocatedAssets{}` structs
     grouped by callback module and invokes the callback's
     `build_manifests/1` function.