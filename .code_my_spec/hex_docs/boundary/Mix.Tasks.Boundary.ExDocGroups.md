# Mix.Tasks.Boundary.ExDocGroups

Creates a `boundary.exs` holding ex_doc module group defintions.

## Integration with ExDoc

The `boundary.exs` file can be integrated with ex_doc in your mix.exs:

      def project do
        [
          …,
          aliases: aliases(),
          docs: docs()
        ]
      end

      defp aliases do
        [
          …,
          docs: ["boundary.ex_doc_groups", "docs"]
        ]
      end

      defp docs do
        [
          …,
          groups_for_modules: groups_for_modules()
        ]
      end

      defp groups_for_modules do
        {list, _} = Code.eval_file("boundary.exs")
        list
      end