# SexySpex.DSL

Domain-specific language for writing executable specifications.

Provides macros for structuring specifications in a readable, executable format
following the Given-When-Then pattern.

## Step return contract

Every step block must return `{:ok, context}`. There is no implicit
pass-through and no map-merge magic — the value you return becomes the
context for the next step.

    given_ "user is logged in", context do
      user = create_user()
      {:ok, Map.put(context, :user, user)}
    end

    then_ "user can see dashboard", context do
      assert context.user.role == :member
      {:ok, context}
    end

## Reusable givens

Register a reusable given inside a spex module:

    defmodule MyApp.UserSpex do
      use SexySpex

      register_given :logged_in_user, context do
        user = create_user()
        {:ok, Map.put(context, :user, user)}
      end

      spex "user dashboard" do
        scenario "logged-in user sees dashboard" do
          given_ :logged_in_user

          then_ "user is set", context do
            assert context.user
            {:ok, context}
          end
        end
      end
    end

Share givens across modules with a normal Elixir `import`:

    defmodule MyApp.SharedGivens do
      use SexySpex.Givens

      register_given :logged_in_user, context do
        {:ok, Map.put(context, :user, create_user())}
      end
    end

    defmodule MyApp.ProfileSpex do
      use SexySpex
      import MyApp.SharedGivens

      spex "profile" do
        scenario "..." do
          given_ :logged_in_user
        end
      end
    end

## register_given/3

Registers a reusable given by name.

Generates a public function `def name(context)` whose body is the block.
The block must return `{:ok, context}`.

## Examples

    register_given :valid_user, context do
      {:ok, Map.put(context, :user, %{name: "Test"})}
    end

    register_given :reset_database, context do
      MyApp.Repo.delete_all(MyApp.User)
      {:ok, context}
    end

## spex/3

Defines a specification.

## Example

    spex "user can login", tags: [:authentication] do
      scenario "with valid credentials" do
        # test implementation
      end
    end

## Options

  * `:description` - Human-readable description of the specification
  * `:tags` - List of atoms for categorizing the specification
  * `:context` - Map of additional context information
  * `:fail_on_error_logs` - Fail the test if any error logs are emitted (default: true)

## Error Log Detection

By default, spex will fail if any error-level logs are emitted during test execution,
even if no assertion failed. This catches crashes and errors that might go unnoticed.

To disable for a specific spex:

    spex "my test", fail_on_error_logs: false do
      # This test won't fail on error logs
    end

## scenario/2

Defines a scenario within a specification.

Scenarios group related Given-When-Then steps together.
Context from ExUnit setup/setup_all is implicitly available as `context`.

## Example

    scenario "user workflow" do
      given_ "a user", context do
        user = create_user()
        {:ok, Map.put(context, :user, user)}
      end

      when_ "they login", context do
        session = login(context.user)
        {:ok, Map.put(context, :session, session)}
      end

      then_ "they see dashboard", context do
        assert context.session.valid?
        {:ok, context}
      end
    end

## given_/1

Defines preconditions for a scenario.

Two forms:

    # Invoke a registered given by atom
    given_ :logged_in_user

    # Inline given — block must return {:ok, context}
    given_ "user signs up", context do
      user = sign_up()
      {:ok, Map.put(context, :user, user)}
    end

## when_/3

Defines the action being tested. Block must return `{:ok, context}`.

## then_/3

Defines the expected outcome. Block must return `{:ok, context}`.

## and_/3

Defines additional context or cleanup. Block must return `{:ok, context}`.