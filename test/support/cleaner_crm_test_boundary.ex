defmodule CleanerCrmTest do
  use Boundary, top_level?: true, deps: [CleanerCrm], exports: [ConnCase, DataCase]
end
