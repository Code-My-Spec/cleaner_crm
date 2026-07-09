%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "test/"],
        excluded: [~r"/_build/", ~r"/deps/", ~r"/node_modules/"]
      },
      plugins: [],
      requires: [
        ".code_my_spec/credo_checks/framework/**/*.ex",
        ".code_my_spec/credo_checks/local/**/*.ex"
      ],
      strict: false,
      parse_timeout: 5000,
      color: true,
      checks: %{
        # _spex.exs is the CodeMySpec-mandated BDD spec suffix; this stock
        # check would demand _test.exs for anything using a *.Case template.
        disabled: [
          {Credo.Check.Warning.WrongTestFileExtension, []},
          {Credo.Check.Warning.WrongTestFilename, []}
        ],
        extra:
          if(File.exists?(".code_my_spec/credo_checks/framework/checks.exs"),
            do: elem(Code.eval_file(".code_my_spec/credo_checks/framework/checks.exs"), 0),
            else: []
          ) ++
            if(File.exists?(".code_my_spec/credo_checks/local/checks.exs"),
              do: elem(Code.eval_file(".code_my_spec/credo_checks/local/checks.exs"), 0),
              else: []
            )
      }
    }
  ]
}
