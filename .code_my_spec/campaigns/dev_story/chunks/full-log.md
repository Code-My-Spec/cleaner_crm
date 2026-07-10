# Git Log: cleaner_crm full build (2026-07-09 .. 2026-07-10)

Commits: 18

## 21e1564 - Initial commit: Cleaner CRM — full owner/cleaner/customer build

Date: 2026-07-09 10:19:24 -0400

Requirements-driven build via CodeMySpec: 21 stories across three
personas (cleaning business owner, cleaner, cleaning client), all
browser-QA passed. 143 BDD specs, 262 tests incl. 5 Wallaby journeys.

Owner: clients/properties with access details, recurring plans with
series-wide conflict detection, weekly dispatch board, quotes + rate
card, invoicing with Stripe (card-on-file + payment links), automated
reminders with SMS fallback, timesheets/payroll export, quality review
with photo proof and scorecards, append-only audit trail, review inbox.

Cleaner (/field): day view with entry briefs, room-by-room checklists
with photo proof, clock in/out with live earnings incl. tips,
acknowledged schedule-change alerts with escalation, incident reports.

Customer: public instant-quote calculator (/book), online acceptance
with card capture and policy agreement, magic-link client portal
(visits, proof-of-work, policy-gated reschedule/cancel, pay + tip),
post-visit review collection via Oban.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01NTAk369erSweBXFki6AtiC



 .code_my_spec/AGENTS.md                            |  164 ++
 .../.proposal_pre_existed_at_session_start         |    1 +
 .code_my_spec/architecture/decisions.md            |   32 +
 .../architecture/decisions/audit-logging.md        |   23 +
 .../architecture/decisions/background-jobs-oban.md |   23 +
 .../architecture/decisions/bdd-testing.md          |   13 +
 .code_my_spec/architecture/decisions/daisyui.md    |   13 +
 .code_my_spec/architecture/decisions/dotenvy.md    |   13 +
 .code_my_spec/architecture/decisions/elixir.md     |   13 +
 .../architecture/decisions/field-app-approach.md   |   23 +
 .../architecture/decisions/file-storage.md         |   23 +
 .../architecture/decisions/hetzner-deployment.md   |   13 +
 .code_my_spec/architecture/decisions/liveview.md   |   13 +
 .../architecture/decisions/money-handling.md       |   22 +
 .../architecture/decisions/payments-stripe.md      |   23 +
 .code_my_spec/architecture/decisions/phoenix.md    |   13 +
 .../architecture/decisions/phx-gen-auth.md         |   13 +
 .../decisions/pow-assent-integrations.md           |   13 +
 .../decisions/recurrence-and-timezones.md          |   23 +
 .../architecture/decisions/req_cassette.md         |   13 +
 .code_my_spec/architecture/decisions/resend.md     |   13 +
 .../architecture/decisions/sms-delivery.md         |   23 +
 .code_my_spec/architecture/decisions/tailwind.md   |   13 +
 .code_my_spec/architecture/decisions/wallaby.md    |   13 +
 .code_my_spec/architecture/proposal.md             |  253 +++
 .code_my_spec/credo_checks/framework/checks.exs    |    8 +
 .../framework/no_control_flow_in_tests.ex          |   87 +
 .../framework/no_direct_send_in_spex.ex            |   54 +
 .../credo_checks/framework/spex_denied_calls.ex    |  147 ++
 .code_my_spec/credo_checks/local/checks.exs        |    4 +
 .../credo_checks/local/cleaner_crm_spex_denies.ex  |  102 ++
 .../hex_docs/assent/Assent.HTTPAdapter.Finch.md    |   10 +
 .../assent/Assent.HTTPAdapter.HTTPResponse.md      |    3 +
 .../hex_docs/assent/Assent.HTTPAdapter.Httpc.md    |   15 +
 .../hex_docs/assent/Assent.HTTPAdapter.Req.md      |    9 +
 .../hex_docs/assent/Assent.HTTPAdapter.md          |   43 +
 .../hex_docs/assent/Assent.JWTAdapter.AssentJWT.md |    9 +
 .../hex_docs/assent/Assent.JWTAdapter.JOSE.md      |    9 +
 .code_my_spec/hex_docs/assent/Assent.JWTAdapter.md |   40 +
 .../hex_docs/assent/Assent.Strategy.Apple.md       |   47 +
 .../hex_docs/assent/Assent.Strategy.Auth0.md       |   18 +
 .../hex_docs/assent/Assent.Strategy.AzureAD.md     |   35 +
 .../hex_docs/assent/Assent.Strategy.Basecamp.md    |   19 +
 .../hex_docs/assent/Assent.Strategy.Bitbucket.md   |   17 +
 .../assent/Assent.Strategy.DigitalOcean.md         |   13 +
 .../hex_docs/assent/Assent.Strategy.Discord.md     |   13 +
 .../hex_docs/assent/Assent.Strategy.Facebook.md    |   66 +
 .../hex_docs/assent/Assent.Strategy.Github.md      |   19 +
 .../hex_docs/assent/Assent.Strategy.Gitlab.md      |   13 +
 .../hex_docs/assent/Assent.Strategy.Google.md      |   29 +
 .../hex_docs/assent/Assent.Strategy.Instagram.md   |   16 +
 .../hex_docs/assent/Assent.Strategy.LINE.md        |   13 +
 .../hex_docs/assent/Assent.Strategy.Linkedin.md    |   17 +
 .../hex_docs/assent/Assent.Strategy.OAuth.Base.md  |   37 +
 .../hex_docs/assent/Assent.Strategy.OAuth.md       |  109 ++
 .../hex_docs/assent/Assent.Strategy.OAuth2.Base.md |   32 +
 .../hex_docs/assent/Assent.Strategy.OAuth2.md      |  151 ++
 .../hex_docs/assent/Assent.Strategy.OIDC.Base.md   |   17 +
 .../hex_docs/assent/Assent.Strategy.OIDC.md        |  169 ++
 .../hex_docs/assent/Assent.Strategy.Slack.md       |   35 +
 .../hex_docs/assent/Assent.Strategy.Spotify.md     |   13 +
 .../hex_docs/assent/Assent.Strategy.Strava.md      |   16 +
 .../hex_docs/assent/Assent.Strategy.Stripe.md      |   29 +
 .../hex_docs/assent/Assent.Strategy.Telegram.md    |   84 +
 .../hex_docs/assent/Assent.Strategy.Twitch.md      |    5 +
 .../hex_docs/assent/Assent.Strategy.Twitter.md     |   16 +
 .../hex_docs/assent/Assent.Strategy.VK.md          |   21 +
 .../hex_docs/assent/Assent.Strategy.Zitadel.md     |   17 +
 .code_my_spec/hex_docs/assent/Assent.Strategy.md   |   60 +
 .code_my_spec/hex_docs/assent/Assent.md            |   15 +
 .code_my_spec/hex_docs/bandit/Bandit.Clock.md      |   10 +
 .../hex_docs/bandit/Bandit.HTTP2.Settings.md       |    3 +
 .../hex_docs/bandit/Bandit.PhoenixAdapter.md       |   74 +
 .../bandit/Bandit.PrimitiveOps.WebSocket.md        |    7 +
 .code_my_spec/hex_docs/bandit/Bandit.Telemetry.md  |  152 ++
 .code_my_spec/hex_docs/bandit/Bandit.Trace.md      |   50 +
 .code_my_spec/hex_docs/bandit/Bandit.md            |    8 +
 .../hex_docs/bcrypt_elixir/Bcrypt.Base.md          |   31 +
 .../hex_docs/bcrypt_elixir/Bcrypt.Stats.md         |   42 +
 .code_my_spec/hex_docs/bcrypt_elixir/Bcrypt.md     |   89 +
 .../boundary/Boundary.Mix.CompilerState.md         |   25 +
 .code_my_spec/hex_docs/boundary/Boundary.md        |  596 +++++++
 .../boundary/Mix.Tasks.Boundary.ExDocGroups.md     |   34 +
 .../Mix.Tasks.Boundary.FindExternalDeps.md         |    5 +
 .../hex_docs/boundary/Mix.Tasks.Boundary.Spec.md   |    3 +
 .../boundary/Mix.Tasks.Boundary.Visualize.md       |    3 +
 .../boundary/Mix.Tasks.Compile.Boundary.md         |   76 +
 .code_my_spec/hex_docs/bunt/Bunt.ANSI.md           |   16 +
 .code_my_spec/hex_docs/bunt/Bunt.md                |  107 ++
 .../CCPrecompiler.UniversalBinary.md               |    9 +
 .../hex_docs/cc_precompiler/CCPrecompiler.md       |    3 +
 .../client_utils/ClientUtils.CloudflareTunnel.md   |   64 +
 .../client_utils/ClientUtils.DiagnosticsFormat.md  |   11 +
 .../ClientUtils.TestFormatter.JsonFormatter.md     |   39 +
 .../ClientUtils.TestFormatter.TestCache.md         |   66 +
 .../client_utils/ClientUtils.TestFormatter.md      |    6 +
 .../hex_docs/client_utils/Mix.Tasks.AgentTest.md   |   16 +
 .../Mix.Tasks.ClientUtils.Gen.ChatWidget.md        |   38 +
 .../Mix.Tasks.ClientUtils.Gen.CmsUsers.md          |   32 +
 .../client_utils/Mix.Tasks.Compile.Diagnostics.md  |   40 +
 .code_my_spec/hex_docs/cloak/Cloak.Cipher.md       |   56 +
 .../hex_docs/cloak/Cloak.Ciphers.AES.CTR.md        |   48 +
 .../hex_docs/cloak/Cloak.Ciphers.AES.GCM.md        |   40 +
 .../cloak/Cloak.Ciphers.Deprecated.AES.CTR.md      |   20 +
 .../cloak/Cloak.Ciphers.Deprecated.AES.GCM.md      |   20 +
 .../hex_docs/cloak/Cloak.InvalidConfig.md          |    3 +
 .../hex_docs/cloak/Cloak.MissingCipher.md          |    3 +
 .code_my_spec/hex_docs/cloak/Cloak.Vault.md        |  123 ++
 .../hex_docs/cloak/Cloak.VaultNotStarted.md        |   14 +
 .code_my_spec/hex_docs/cloak/Cloak.md              |    9 +
 .../hex_docs/cloak_ecto/Cloak.Ecto.Binary.md       |   23 +
 .../hex_docs/cloak_ecto/Cloak.Ecto.CustomCursor.md |   43 +
 .../hex_docs/cloak_ecto/Cloak.Ecto.Date.md         |   23 +
 .../hex_docs/cloak_ecto/Cloak.Ecto.DateTime.md     |   23 +
 .../hex_docs/cloak_ecto/Cloak.Ecto.Decimal.md      |   26 +
 .../hex_docs/cloak_ecto/Cloak.Ecto.Float.md        |   24 +
 .../hex_docs/cloak_ecto/Cloak.Ecto.HMAC.md         |   93 +
 .../hex_docs/cloak_ecto/Cloak.Ecto.Integer.md      |   23 +
 .../hex_docs/cloak_ecto/Cloak.Ecto.IntegerList.md  |   30 +
 .../hex_docs/cloak_ecto/Cloak.Ecto.Map.md          |   44 +
 .../cloak_ecto/Cloak.Ecto.NaiveDateTime.md         |   23 +
 .../hex_docs/cloak_ecto/Cloak.Ecto.PBKDF2.md       |  110 ++
 .../hex_docs/cloak_ecto/Cloak.Ecto.SHA256.md       |   42 +
 .../hex_docs/cloak_ecto/Cloak.Ecto.StringList.md   |   34 +
 .../hex_docs/cloak_ecto/Cloak.Ecto.Time.md         |   23 +
 .../cloak_ecto/Mix.Tasks.Cloak.Migrate.Ecto.md     |  103 ++
 .../CodeMySpecGenerators.Generator.md              |   64 +
 .../CodeMySpecGenerators.Injector.md               |   45 +
 .../CodeMySpecGenerators.md                        |   10 +
 .../Mix.Tasks.CmsGen.Accounts.md                   |   40 +
 .../Mix.Tasks.CmsGen.FeedbackWidget.md             |   25 +
 .../Mix.Tasks.CmsGen.IntegrationProvider.md        |   23 +
 .../Mix.Tasks.CmsGen.Integrations.md               |   29 +
 .../comeonin/Comeonin.BehaviourTestHelper.md       |   35 +
 .../hex_docs/comeonin/Comeonin.PasswordHash.md     |    3 +
 .code_my_spec/hex_docs/comeonin/Comeonin.md        |   11 +
 .../credo/Credo.CLI.Command.Diff.Output.Default.md |   11 +
 .../Credo.CLI.Command.Explain.Output.Default.md    |   11 +
 .../credo/Credo.CLI.Command.List.Output.Default.md |   11 +
 .../Credo.CLI.Command.Suggest.Output.Default.md    |   11 +
 .code_my_spec/hex_docs/credo/Credo.CLI.Command.md  |   43 +
 .code_my_spec/hex_docs/credo/Credo.CLI.Filename.md |   42 +
 .code_my_spec/hex_docs/credo/Credo.CLI.Options.md  |    9 +
 .../credo/Credo.CLI.Output.FormatDelegator.md      |   12 +
 .../hex_docs/credo/Credo.CLI.Output.Shell.md       |   11 +
 .../hex_docs/credo/Credo.CLI.Output.UI.md          |   32 +
 .code_my_spec/hex_docs/credo/Credo.CLI.Output.md   |   49 +
 .code_my_spec/hex_docs/credo/Credo.CLI.md          |    9 +
 .../hex_docs/credo/Credo.Check.ConfigComment.md    |   18 +
 .../credo/Credo.Check.Consistency.Collector.md     |   68 +
 ...Consistency.SpaceAroundOperators.SpaceHelper.md |   17 +
 .../credo/Credo.Check.Design.DuplicatedCode.md     |   24 +
 .code_my_spec/hex_docs/credo/Credo.Check.Params.md |   21 +
 .../hex_docs/credo/Credo.Check.Refactor.ABCSize.md |   16 +
 .../Credo.Check.Refactor.CyclomaticComplexity.md   |   16 +
 .../Credo.Check.Refactor.PerceivedComplexity.md    |   16 +
 .code_my_spec/hex_docs/credo/Credo.Check.Runner.md |    7 +
 .code_my_spec/hex_docs/credo/Credo.Check.md        |   86 +
 .code_my_spec/hex_docs/credo/Credo.Code.Block.md   |   80 +
 .../hex_docs/credo/Credo.Code.Charlists.md         |    8 +
 .../hex_docs/credo/Credo.Code.Heredocs.md          |    8 +
 .code_my_spec/hex_docs/credo/Credo.Code.Module.md  |   48 +
 .code_my_spec/hex_docs/credo/Credo.Code.Name.md    |    4 +
 .../hex_docs/credo/Credo.Code.Parameters.md        |   12 +
 .../hex_docs/credo/Credo.Code.ParserError.md       |    4 +
 .code_my_spec/hex_docs/credo/Credo.Code.Scope.md   |   25 +
 .code_my_spec/hex_docs/credo/Credo.Code.Sigils.md  |    8 +
 .code_my_spec/hex_docs/credo/Credo.Code.Strings.md |    8 +
 .code_my_spec/hex_docs/credo/Credo.Code.Token.md   |   13 +
 .code_my_spec/hex_docs/credo/Credo.Code.md         |   56 +
 .code_my_spec/hex_docs/credo/Credo.ConfigFile.md   |   40 +
 .../credo/Credo.Execution.ExecutionIssues.md       |   23 +
 .../credo/Credo.Execution.ExecutionTiming.md       |   58 +
 .../hex_docs/credo/Credo.Execution.Task.md         |   12 +
 .code_my_spec/hex_docs/credo/Credo.Execution.md    |  183 ++
 .code_my_spec/hex_docs/credo/Credo.Issue.md        |    7 +
 .code_my_spec/hex_docs/credo/Credo.IssueMeta.md    |   17 +
 .code_my_spec/hex_docs/credo/Credo.Plugin.md       |  136 ++
 .code_my_spec/hex_docs/credo/Credo.Priority.md     |    7 +
 .code_my_spec/hex_docs/credo/Credo.SourceFile.md   |   41 +
 .code_my_spec/hex_docs/credo/Credo.Sources.md      |   25 +
 .code_my_spec/hex_docs/credo/Credo.Test.Case.md    |  279 +++
 .code_my_spec/hex_docs/credo/Credo.md              |   19 +
 .../db_connection/DBConnection.ConnectionError.md  |    6 +
 .../db_connection/DBConnection.ConnectionPool.md   |    8 +
 .../db_connection/DBConnection.LogEntry.md         |    5 +
 .../db_connection/DBConnection.Ownership.md        |   62 +
 .../db_connection/DBConnection.OwnershipError.md   |    3 +
 .../DBConnection.TelemetryListener.md              |   63 +
 .../hex_docs/db_connection/DBConnection.Util.md    |   18 +
 .../hex_docs/db_connection/DBConnection.md         |  697 ++++++++
 .code_my_spec/hex_docs/decimal/Decimal.Context.md  |   90 +
 .code_my_spec/hex_docs/decimal/Decimal.Error.md    |   14 +
 .code_my_spec/hex_docs/decimal/Decimal.md          |  728 ++++++++
 .code_my_spec/hex_docs/dns_cluster/DNSCluster.md   |   35 +
 .../hex_docs/ecto/Ecto.Adapter.Queryable.md        |   20 +
 .code_my_spec/hex_docs/ecto/Ecto.Adapter.Schema.md |    3 +
 .../hex_docs/ecto/Ecto.Adapter.Storage.md          |    3 +
 .../hex_docs/ecto/Ecto.Adapter.Transaction.md      |    3 +
 .code_my_spec/hex_docs/ecto/Ecto.Adapter.md        |   13 +
 .../hex_docs/ecto/Ecto.Association.BelongsTo.md    |   16 +
 .../hex_docs/ecto/Ecto.Association.Has.md          |   18 +
 .../hex_docs/ecto/Ecto.Association.HasThrough.md   |   12 +
 .../hex_docs/ecto/Ecto.Association.ManyToMany.md   |   21 +
 .../hex_docs/ecto/Ecto.Association.NotLoaded.md    |    9 +
 .code_my_spec/hex_docs/ecto/Ecto.Association.md    |   90 +
 .code_my_spec/hex_docs/ecto/Ecto.CastError.md      |    3 +
 .../hex_docs/ecto/Ecto.Changeset.Relation.md       |   37 +
 .code_my_spec/hex_docs/ecto/Ecto.Changeset.md      | 1835 +++++++++++++++++++
 .code_my_spec/hex_docs/ecto/Ecto.Embedded.md       |   12 +
 .code_my_spec/hex_docs/ecto/Ecto.Enum.md           |  202 +++
 .../hex_docs/ecto/Ecto.InvalidChangesetError.md    |    4 +
 .code_my_spec/hex_docs/ecto/Ecto.Multi.md          |  529 ++++++
 .../hex_docs/ecto/Ecto.NoPrimaryKeyFieldError.md   |    4 +
 .../hex_docs/ecto/Ecto.NoPrimaryKeyValueError.md   |    4 +
 .../hex_docs/ecto/Ecto.ParameterizedType.md        |   87 +
 .code_my_spec/hex_docs/ecto/Ecto.Query.API.md      |  947 ++++++++++
 .../hex_docs/ecto/Ecto.Query.Builder.CTE.md        |   22 +
 .../ecto/Ecto.Query.Builder.Combination.md         |   15 +
 .../hex_docs/ecto/Ecto.Query.Builder.Distinct.md   |   31 +
 .../hex_docs/ecto/Ecto.Query.Builder.Dynamic.md    |   19 +
 .../hex_docs/ecto/Ecto.Query.Builder.Filter.md     |   37 +
 .../hex_docs/ecto/Ecto.Query.Builder.From.md       |   49 +
 .../hex_docs/ecto/Ecto.Query.Builder.GroupBy.md    |   38 +
 .../hex_docs/ecto/Ecto.Query.Builder.Join.md       |   67 +
 .../ecto/Ecto.Query.Builder.LimitOffset.md         |   23 +
 .../hex_docs/ecto/Ecto.Query.Builder.Lock.md       |   22 +
 .../hex_docs/ecto/Ecto.Query.Builder.OrderBy.md    |   71 +
 .../hex_docs/ecto/Ecto.Query.Builder.Preload.md    |   98 ++
 .../hex_docs/ecto/Ecto.Query.Builder.Select.md     |   49 +
 .../hex_docs/ecto/Ecto.Query.Builder.Update.md     |   40 +
 .../hex_docs/ecto/Ecto.Query.Builder.Windows.md    |   28 +
 .code_my_spec/hex_docs/ecto/Ecto.Query.Builder.md  |  200 +++
 .../hex_docs/ecto/Ecto.Query.CastError.md          |    3 +
 .../hex_docs/ecto/Ecto.Query.CompileError.md       |    3 +
 .code_my_spec/hex_docs/ecto/Ecto.Query.Planner.md  |   83 +
 .../hex_docs/ecto/Ecto.Query.WindowAPI.md          |  202 +++
 .code_my_spec/hex_docs/ecto/Ecto.Query.md          | 1842 ++++++++++++++++++++
 .code_my_spec/hex_docs/ecto/Ecto.QueryError.md     |    3 +
 .code_my_spec/hex_docs/ecto/Ecto.Repo.Assoc.md     |    8 +
 .code_my_spec/hex_docs/ecto/Ecto.Repo.Preloader.md |   12 +
 .code_my_spec/hex_docs/ecto/Ecto.Repo.Queryable.md |    7 +
 .code_my_spec/hex_docs/ecto/Ecto.Repo.Schema.md    |   39 +
 .../hex_docs/ecto/Ecto.Repo.Supervisor.md          |   23 +
 .code_my_spec/hex_docs/ecto/Ecto.Repo.md           |  227 +++
 .code_my_spec/hex_docs/ecto/Ecto.Schema.Loader.md  |   25 +
 .../hex_docs/ecto/Ecto.Schema.Metadata.md          |   34 +
 .code_my_spec/hex_docs/ecto/Ecto.Schema.md         |  129 ++
 .code_my_spec/hex_docs/ecto/Ecto.SubQuery.md       |    9 +
 .code_my_spec/hex_docs/ecto/Ecto.SubQueryError.md  |    3 +
 .code_my_spec/hex_docs/ecto/Ecto.Type.md           |  468 +++++
 .code_my_spec/hex_docs/ecto/Ecto.UUID.md           |  114 ++
 .code_my_spec/hex_docs/ecto/Ecto.md                |  181 ++
 .code_my_spec/hex_docs/ecto/Mix.Ecto.md            |   46 +
 .../hex_docs/ecto/Mix.Tasks.Ecto.Create.md         |   27 +
 .code_my_spec/hex_docs/ecto/Mix.Tasks.Ecto.Drop.md |   28 +
 .../hex_docs/ecto/Mix.Tasks.Ecto.Gen.Repo.md       |   17 +
 .code_my_spec/hex_docs/ecto/Mix.Tasks.Ecto.md      |    5 +
 .../hex_docs/ecto_sql/Ecto.Adapter.Migration.md    |    3 +
 .../hex_docs/ecto_sql/Ecto.Adapter.Structure.md    |    3 +
 .../hex_docs/ecto_sql/Ecto.Adapters.MyXQL.md       |  196 +++
 .../hex_docs/ecto_sql/Ecto.Adapters.Postgres.md    |  163 ++
 .../ecto_sql/Ecto.Adapters.SQL.Connection.md       |    3 +
 .../hex_docs/ecto_sql/Ecto.Adapters.SQL.Sandbox.md |  113 ++
 .../hex_docs/ecto_sql/Ecto.Adapters.SQL.md         |   45 +
 .../hex_docs/ecto_sql/Ecto.Adapters.Tds.md         |  133 ++
 .../hex_docs/ecto_sql/Ecto.Migration.Command.md    |    8 +
 .../hex_docs/ecto_sql/Ecto.Migration.Constraint.md |    5 +
 .../hex_docs/ecto_sql/Ecto.Migration.Index.md      |    5 +
 .../hex_docs/ecto_sql/Ecto.Migration.Reference.md  |    5 +
 .../hex_docs/ecto_sql/Ecto.Migration.Runner.md     |   66 +
 .../hex_docs/ecto_sql/Ecto.Migration.Table.md      |    5 +
 .code_my_spec/hex_docs/ecto_sql/Ecto.Migration.md  |  940 ++++++++++
 .code_my_spec/hex_docs/ecto_sql/Ecto.Migrator.md   |  247 +++
 .code_my_spec/hex_docs/ecto_sql/Mix.EctoSQL.md     |   11 +
 .../hex_docs/ecto_sql/Mix.Tasks.Ecto.Dump.md       |   36 +
 .../ecto_sql/Mix.Tasks.Ecto.Gen.Migration.md       |   37 +
 .../hex_docs/ecto_sql/Mix.Tasks.Ecto.Load.md       |   31 +
 .../hex_docs/ecto_sql/Mix.Tasks.Ecto.Migrate.md    |   83 +
 .../hex_docs/ecto_sql/Mix.Tasks.Ecto.Migrations.md |   38 +
 .../hex_docs/ecto_sql/Mix.Tasks.Ecto.Rollback.md   |   80 +
 .code_my_spec/hex_docs/ecto_sql/Tds.Ecto.UUID.md   |   31 +
 .../hex_docs/ecto_sql/Tds.Ecto.VarChar.md          |   31 +
 .../hex_docs/elixir_make/ElixirMake.Artefact.md    |   43 +
 .../hex_docs/elixir_make/ElixirMake.Downloader.md  |    3 +
 .../hex_docs/elixir_make/ElixirMake.Precompiler.md |    7 +
 .../elixir_make/Mix.Tasks.Compile.ElixirMake.md    |  119 ++
 .../elixir_make/Mix.Tasks.ElixirMake.Checksum.md   |   16 +
 .../elixir_make/Mix.Tasks.ElixirMake.Precompile.md |   10 +
 .code_my_spec/hex_docs/esbuild/Esbuild.md          |   48 +
 .../hex_docs/esbuild/Mix.Tasks.Esbuild.md          |   25 +
 .../hex_docs/expo/Expo.MO.InvalidFileError.md      |    5 +
 .../expo/Expo.MO.UnsupportedVersionError.md        |    5 +
 .code_my_spec/hex_docs/expo/Expo.MO.md             |  108 ++
 .code_my_spec/hex_docs/expo/Expo.Message.Plural.md |   78 +
 .../hex_docs/expo/Expo.Message.Singular.md         |   77 +
 .code_my_spec/hex_docs/expo/Expo.Message.md        |  112 ++
 .code_my_spec/hex_docs/expo/Expo.Messages.md       |   58 +
 .../expo/Expo.PO.DuplicateMessagesError.md         |    3 +
 .code_my_spec/hex_docs/expo/Expo.PO.SyntaxError.md |    4 +
 .code_my_spec/hex_docs/expo/Expo.PO.Tokenizer.md   |   19 +
 .code_my_spec/hex_docs/expo/Expo.PO.md             |   89 +
 .../hex_docs/expo/Expo.PluralForms.SyntaxError.md  |    3 +
 .code_my_spec/hex_docs/expo/Expo.PluralForms.md    |   62 +
 .../hex_docs/expo/Mix.Tasks.Expo.Msgfmt.md         |   13 +
 .../hex_docs/expo/Mix.Tasks.Expo.Msguniq.md        |   17 +
 .../hex_docs/file_system/FileSystem.Backend.md     |   15 +
 .../file_system/FileSystem.Backends.FSInotify.md   |   31 +
 .../file_system/FileSystem.Backends.FSMac.md       |   48 +
 .../file_system/FileSystem.Backends.FSPoll.md      |   14 +
 .../file_system/FileSystem.Backends.FSWindows.md   |   33 +
 .../hex_docs/file_system/FileSystem.Worker.md      |    4 +
 .code_my_spec/hex_docs/file_system/FileSystem.md   |   50 +
 .code_my_spec/hex_docs/finch/Finch.Error.md        |    6 +
 .../hex_docs/finch/Finch.HTTP1.PoolMetrics.md      |   20 +
 .../hex_docs/finch/Finch.HTTP2.PoolMetrics.md      |   18 +
 .code_my_spec/hex_docs/finch/Finch.HTTPError.md    |    3 +
 .../hex_docs/finch/Finch.Pool.Strategy.Hash.md     |   25 +
 .../hex_docs/finch/Finch.Pool.Strategy.Random.md   |    6 +
 .../finch/Finch.Pool.Strategy.RoundRobin.md        |   14 +
 .../hex_docs/finch/Finch.Pool.Strategy.md          |   47 +
 .code_my_spec/hex_docs/finch/Finch.Pool.md         |   73 +
 .code_my_spec/hex_docs/finch/Finch.PoolMetrics.md  |   38 +
 .code_my_spec/hex_docs/finch/Finch.Request.md      |    9 +
 .code_my_spec/hex_docs/finch/Finch.Response.md     |    3 +
 .code_my_spec/hex_docs/finch/Finch.Telemetry.md    |  243 +++
 .../hex_docs/finch/Finch.TransportError.md         |    3 +
 .code_my_spec/hex_docs/finch/Finch.md              |  420 +++++
 .code_my_spec/hex_docs/fine/Fine.md                |    7 +
 .code_my_spec/hex_docs/gettext/Gettext.Backend.md  |   23 +
 .code_my_spec/hex_docs/gettext/Gettext.Compiler.md |   14 +
 .code_my_spec/hex_docs/gettext/Gettext.Error.md    |    3 +
 .../hex_docs/gettext/Gettext.Extractor.md          |   34 +
 .code_my_spec/hex_docs/gettext/Gettext.Fuzzy.md    |   35 +
 .../gettext/Gettext.Interpolation.Default.md       |   59 +
 .../hex_docs/gettext/Gettext.Interpolation.md      |    5 +
 .code_my_spec/hex_docs/gettext/Gettext.Macros.md   |  284 +++
 .code_my_spec/hex_docs/gettext/Gettext.Merger.md   |   50 +
 .../gettext/Gettext.MissingBindingsError.md        |    3 +
 .../gettext/Gettext.Plural.UnknownLocaleError.md   |    7 +
 .code_my_spec/hex_docs/gettext/Gettext.Plural.md   |  150 ++
 .../hex_docs/gettext/Gettext.PluralFormError.md    |    3 +
 .code_my_spec/hex_docs/gettext/Gettext.md          |  343 ++++
 .../hex_docs/gettext/Mix.Tasks.Gettext.Extract.md  |   51 +
 .../hex_docs/gettext/Mix.Tasks.Gettext.Merge.md    |  112 ++
 .code_my_spec/hex_docs/hpax/HPAX.Table.md          |   71 +
 .code_my_spec/hex_docs/hpax/HPAX.md                |   86 +
 .code_my_spec/hex_docs/httpoison/HTTPoison.Base.md |   71 +
 .../httpoison/HTTPoison.Handlers.Multipart.md      |   39 +
 .../hex_docs/httpoison/HTTPoison.MaybeRedirect.md  |    9 +
 .../hex_docs/httpoison/HTTPoison.Request.md        |   62 +
 .code_my_spec/hex_docs/httpoison/HTTPoison.md      |   20 +
 .code_my_spec/hex_docs/jason/Jason.Encode.md       |    9 +
 .code_my_spec/hex_docs/jason/Jason.Helpers.md      |    3 +
 .../hex_docs/jason/Jason.OrderedObject.md          |   13 +
 .code_my_spec/hex_docs/jason/Jason.md              |  153 ++
 .code_my_spec/hex_docs/lazy_html/LazyHTML.Tree.md  |   29 +
 .code_my_spec/hex_docs/lazy_html/LazyHTML.md       |  233 +++
 .../logger_file_backend/LoggerFileBackend.md       |    3 +
 .code_my_spec/hex_docs/mime/MIME.md                |   81 +
 .code_my_spec/hex_docs/mint/Mint.HTTP.md           |  946 ++++++++++
 .code_my_spec/hex_docs/mint/Mint.HTTP1.md          |  124 ++
 .code_my_spec/hex_docs/mint/Mint.HTTP2.Frame.md    |   13 +
 .code_my_spec/hex_docs/mint/Mint.HTTP2.md          |  470 +++++
 .code_my_spec/hex_docs/mint/Mint.HTTPError.md      |   42 +
 .code_my_spec/hex_docs/mint/Mint.TransportError.md |   38 +
 .code_my_spec/hex_docs/mint/Mint.Types.md          |    3 +
 .../NimbleOptions.ValidationError.md               |   22 +
 .../hex_docs/nimble_options/NimbleOptions.md       |   71 +
 .code_my_spec/hex_docs/nimble_pool/NimblePool.md   |   79 +
 .code_my_spec/hex_docs/oban/Oban.Backoff.md        |   65 +
 .code_my_spec/hex_docs/oban/Oban.Config.md         |   52 +
 .code_my_spec/hex_docs/oban/Oban.CrashError.md     |    3 +
 .../hex_docs/oban/Oban.Cron.Expression.md          |   65 +
 .code_my_spec/hex_docs/oban/Oban.Engine.md         |   23 +
 .code_my_spec/hex_docs/oban/Oban.Engines.Basic.md  |    9 +
 .../hex_docs/oban/Oban.Engines.Dolphin.md          |   13 +
 .code_my_spec/hex_docs/oban/Oban.Engines.Inline.md |    9 +
 .code_my_spec/hex_docs/oban/Oban.Engines.Lite.md   |   13 +
 .code_my_spec/hex_docs/oban/Oban.Job.md            |  219 +++
 .code_my_spec/hex_docs/oban/Oban.Migration.md      |  169 ++
 .code_my_spec/hex_docs/oban/Oban.Notifier.md       |  184 ++
 .code_my_spec/hex_docs/oban/Oban.Notifiers.PG.md   |   36 +
 .../hex_docs/oban/Oban.Notifiers.Postgres.md       |   36 +
 .code_my_spec/hex_docs/oban/Oban.Peer.md           |   92 +
 .code_my_spec/hex_docs/oban/Oban.Peers.Database.md |   20 +
 .code_my_spec/hex_docs/oban/Oban.Peers.Global.md   |   14 +
 .code_my_spec/hex_docs/oban/Oban.PerformError.md   |    6 +
 .code_my_spec/hex_docs/oban/Oban.Period.md         |   32 +
 .code_my_spec/hex_docs/oban/Oban.Plugin.md         |   38 +
 .code_my_spec/hex_docs/oban/Oban.Plugins.Cron.md   |   97 ++
 .../hex_docs/oban/Oban.Plugins.Lifeline.md         |   49 +
 .code_my_spec/hex_docs/oban/Oban.Plugins.Pruner.md |   47 +
 .../hex_docs/oban/Oban.Plugins.Reindexer.md        |   39 +
 .code_my_spec/hex_docs/oban/Oban.Registry.md       |   81 +
 .code_my_spec/hex_docs/oban/Oban.Repo.md           |  121 ++
 .code_my_spec/hex_docs/oban/Oban.Telemetry.md      |  426 +++++
 .code_my_spec/hex_docs/oban/Oban.Testing.md        |  291 ++++
 .code_my_spec/hex_docs/oban/Oban.TimeoutError.md   |    3 +
 .code_my_spec/hex_docs/oban/Oban.Worker.md         |  417 +++++
 .code_my_spec/hex_docs/oban/Oban.md                |  965 ++++++++++
 .../hex_docs/phoenix/Mix.Phoenix.Schema.md         |   43 +
 .../hex_docs/phoenix/Mix.Phoenix.Scope.md          |   40 +
 .code_my_spec/hex_docs/phoenix/Mix.Phoenix.md      |  127 ++
 .../hex_docs/phoenix/Mix.Tasks.Phx.Digest.Clean.md |   29 +
 .../hex_docs/phoenix/Mix.Tasks.Phx.Digest.md       |   45 +
 .../phoenix/Mix.Tasks.Phx.Gen.Auth.Injector.md     |   47 +
 .../hex_docs/phoenix/Mix.Tasks.Phx.Gen.Auth.md     |  148 ++
 .../hex_docs/phoenix/Mix.Tasks.Phx.Gen.Channel.md  |   19 +
 .../hex_docs/phoenix/Mix.Tasks.Phx.Gen.Context.md  |   82 +
 .../hex_docs/phoenix/Mix.Tasks.Phx.Gen.Html.md     |  111 ++
 .../hex_docs/phoenix/Mix.Tasks.Phx.Gen.Json.md     |  111 ++
 .../hex_docs/phoenix/Mix.Tasks.Phx.Gen.Live.md     |  115 ++
 .../hex_docs/phoenix/Mix.Tasks.Phx.Gen.Notifier.md |   18 +
 .../hex_docs/phoenix/Mix.Tasks.Phx.Gen.Presence.md |   12 +
 .../hex_docs/phoenix/Mix.Tasks.Phx.Gen.Release.md  |   70 +
 .../hex_docs/phoenix/Mix.Tasks.Phx.Gen.Secret.md   |    9 +
 .../hex_docs/phoenix/Mix.Tasks.Phx.Gen.Socket.md   |   21 +
 .../hex_docs/phoenix/Mix.Tasks.Phx.Gen.md          |   42 +
 .../hex_docs/phoenix/Mix.Tasks.Phx.Routes.md       |   56 +
 .../hex_docs/phoenix/Mix.Tasks.Phx.Server.md       |   26 +
 .code_my_spec/hex_docs/phoenix/Mix.Tasks.Phx.md    |    9 +
 .../hex_docs/phoenix/Phoenix.Channel.Server.md     |   78 +
 .code_my_spec/hex_docs/phoenix/Phoenix.Channel.md  |  147 ++
 .../hex_docs/phoenix/Phoenix.ChannelTest.md        |  417 +++++
 .../phoenix/Phoenix.CodeReloader.MixListener.md    |    9 +
 .../hex_docs/phoenix/Phoenix.CodeReloader.md       |   57 +
 .code_my_spec/hex_docs/phoenix/Phoenix.Config.md   |   53 +
 .code_my_spec/hex_docs/phoenix/Phoenix.ConnTest.md |  379 ++++
 .../phoenix/Phoenix.Controller.Pipeline.md         |   12 +
 .../hex_docs/phoenix/Phoenix.Controller.md         |  903 ++++++++++
 .code_my_spec/hex_docs/phoenix/Phoenix.Debug.md    |   99 ++
 .code_my_spec/hex_docs/phoenix/Phoenix.Digester.md |   27 +
 .../phoenix/Phoenix.Endpoint.Cowboy2Adapter.md     |   46 +
 .../phoenix/Phoenix.Endpoint.Supervisor.md         |   31 +
 .code_my_spec/hex_docs/phoenix/Phoenix.Endpoint.md |  278 +++
 .code_my_spec/hex_docs/phoenix/Phoenix.Flash.md    |   14 +
 .../hex_docs/phoenix/Phoenix.MissingParamError.md  |   12 +
 .code_my_spec/hex_docs/phoenix/Phoenix.Naming.md   |   75 +
 .../hex_docs/phoenix/Phoenix.NotAcceptableError.md |   12 +
 .code_my_spec/hex_docs/phoenix/Phoenix.Presence.md |  207 +++
 .../phoenix/Phoenix.Router.ConsoleFormatter.md     |    7 +
 .../hex_docs/phoenix/Phoenix.Router.Helpers.md     |   21 +
 .../phoenix/Phoenix.Router.MalformedURIError.md    |    3 +
 .../phoenix/Phoenix.Router.NoRouteError.md         |    3 +
 .../hex_docs/phoenix/Phoenix.Router.Resource.md    |    7 +
 .../hex_docs/phoenix/Phoenix.Router.Route.md       |   24 +
 .../hex_docs/phoenix/Phoenix.Router.Scope.md       |   39 +
 .code_my_spec/hex_docs/phoenix/Phoenix.Router.md   |  616 +++++++
 .../hex_docs/phoenix/Phoenix.Socket.Broadcast.md   |    9 +
 .../phoenix/Phoenix.Socket.InvalidMessageError.md  |    3 +
 .../hex_docs/phoenix/Phoenix.Socket.Message.md     |   18 +
 .../hex_docs/phoenix/Phoenix.Socket.Reply.md       |   11 +
 .../hex_docs/phoenix/Phoenix.Socket.Serializer.md  |    8 +
 .../hex_docs/phoenix/Phoenix.Socket.Transport.md   |  161 ++
 .code_my_spec/hex_docs/phoenix/Phoenix.Socket.md   |   62 +
 .code_my_spec/hex_docs/phoenix/Phoenix.Token.md    |  206 +++
 .../hex_docs/phoenix/Phoenix.VerifiedRoutes.md     |  100 ++
 .code_my_spec/hex_docs/phoenix/Phoenix.md          |   37 +
 .../phoenix_ecto/Phoenix.Ecto.CheckRepoStatus.md   |   14 +
 .../phoenix_ecto/Phoenix.Ecto.SQL.Sandbox.md       |  219 +++
 .../hex_docs/phoenix_ecto/Phoenix.Ecto.md          |    6 +
 .../hex_docs/phoenix_html/Phoenix.HTML.Engine.md   |    7 +
 .../hex_docs/phoenix_html/Phoenix.HTML.Form.md     |  179 ++
 .../phoenix_html/Phoenix.HTML.FormField.md         |   15 +
 .../hex_docs/phoenix_html/Phoenix.HTML.md          |  142 ++
 .../Phoenix.LiveDashboard.Assets.md                |    7 +
 .../Phoenix.LiveDashboard.Helpers.md               |   49 +
 .../Phoenix.LiveDashboard.PageBuilder.md           |  343 ++++
 .../Phoenix.LiveDashboard.ReingoldTilford.md       |   24 +
 .../Phoenix.LiveDashboard.RequestLogger.md         |    5 +
 .../Phoenix.LiveDashboard.Router.md                |   86 +
 .../Phoenix.LiveDashboard.Web.md                   |    7 +
 .../Phoenix.LiveReloader.Channel.md                |    3 +
 .../Phoenix.LiveReloader.Socket.md                 |    3 +
 .../phoenix_live_reload/Phoenix.LiveReloader.md    |   95 +
 .../Mix.Tasks.Compile.PhoenixLiveView.md           |   10 +
 .../Phoenix.Component.MacroComponent.md            |   22 +
 .../phoenix_live_view/Phoenix.Component.md         |  979 +++++++++++
 .../phoenix_live_view/Phoenix.LiveComponent.CID.md |    6 +
 .../phoenix_live_view/Phoenix.LiveComponent.md     |   14 +
 .../Phoenix.LiveView.AsyncResult.md                |   97 ++
 .../Phoenix.LiveView.ColocatedAssets.md            |   20 +
 .../Phoenix.LiveView.ColocatedCSS.md               |   63 +
 .../Phoenix.LiveView.Component.md                  |    7 +
 .../Phoenix.LiveView.Comprehension.md              |    3 +
 .../Phoenix.LiveView.Controller.md                 |   32 +
 .../phoenix_live_view/Phoenix.LiveView.Debug.md    |   94 +
 .../phoenix_live_view/Phoenix.LiveView.Diff.md     |   72 +
 .../Phoenix.LiveView.HTMLEngine.md                 |    6 +
 .../Phoenix.LiveView.HTMLFormatter.TagFormatter.md |    3 +
 .../Phoenix.LiveView.HTMLFormatter.md              |  277 +++
 .../phoenix_live_view/Phoenix.LiveView.Helpers.md  |   12 +
 .../phoenix_live_view/Phoenix.LiveView.JS.md       |  411 +++++
 .../Phoenix.LiveView.Lifecycle.md                  |    7 +
 .../phoenix_live_view/Phoenix.LiveView.Logger.md   |   37 +
 .../phoenix_live_view/Phoenix.LiveView.Rendered.md |    6 +
 .../phoenix_live_view/Phoenix.LiveView.Renderer.md |    7 +
 .../phoenix_live_view/Phoenix.LiveView.Route.md    |   16 +
 .../phoenix_live_view/Phoenix.LiveView.Router.md   |  126 ++
 .../phoenix_live_view/Phoenix.LiveView.Session.md  |   20 +
 .../phoenix_live_view/Phoenix.LiveView.Socket.md   |   31 +
 .../phoenix_live_view/Phoenix.LiveView.Static.md   |   39 +
 .../Phoenix.LiveView.TagEngine.Compiler.md         |   16 +
 .../Phoenix.LiveView.TagEngine.Tokenizer.md        |   42 +
 .../Phoenix.LiveView.TagEngine.md                  |   66 +
 .../phoenix_live_view/Phoenix.LiveView.Upload.md   |   77 +
 .../Phoenix.LiveView.UploadConfig.md               |    3 +
 .../Phoenix.LiveView.UploadEntry.md                |    3 +
 .../phoenix_live_view/Phoenix.LiveView.Utils.md    |  142 ++
 .../hex_docs/phoenix_live_view/Phoenix.LiveView.md |  715 ++++++++
 .../Phoenix.LiveViewTest.ClientProxy.md            |   29 +
 .../phoenix_live_view/Phoenix.LiveViewTest.DOM.md  |   27 +
 .../Phoenix.LiveViewTest.Element.md                |   10 +
 .../Phoenix.LiveViewTest.TreeDOM.md                |   81 +
 .../Phoenix.LiveViewTest.Upload.md                 |   10 +
 .../phoenix_live_view/Phoenix.LiveViewTest.View.md |   13 +
 .../phoenix_live_view/Phoenix.LiveViewTest.md      |  869 +++++++++
 .../phoenix_pubsub/Phoenix.PubSub.Adapter.md       |    3 +
 .../hex_docs/phoenix_pubsub/Phoenix.PubSub.PG2.md  |    5 +
 .../hex_docs/phoenix_pubsub/Phoenix.PubSub.md      |  247 +++
 .../phoenix_pubsub/Phoenix.Tracker.Clock.md        |   35 +
 .../Phoenix.Tracker.DeltaGeneration.md             |   13 +
 .../phoenix_pubsub/Phoenix.Tracker.Replica.md      |   11 +
 .../phoenix_pubsub/Phoenix.Tracker.State.md        |  115 ++
 .../hex_docs/phoenix_pubsub/Phoenix.Tracker.md     |  141 ++
 .../phoenix_template/Phoenix.Template.EExEngine.md |    3 +
 .../phoenix_template/Phoenix.Template.Engine.md    |   11 +
 .../phoenix_template/Phoenix.Template.ExsEngine.md |    3 +
 .../hex_docs/phoenix_template/Phoenix.Template.md  |  185 ++
 .../hex_docs/plug/Plug.BadRequestError.md          |    3 +
 .code_my_spec/hex_docs/plug/Plug.BasicAuth.md      |  124 ++
 .code_my_spec/hex_docs/plug/Plug.Builder.md        |  182 ++
 .../Plug.CSRFProtection.InvalidCSRFTokenError.md   |    3 +
 ...SRFProtection.InvalidCrossOriginRequestError.md |    3 +
 .code_my_spec/hex_docs/plug/Plug.CSRFProtection.md |  173 ++
 .code_my_spec/hex_docs/plug/Plug.Conn.Adapter.md   |   18 +
 .../hex_docs/plug/Plug.Conn.AlreadySentError.md    |    3 +
 .../hex_docs/plug/Plug.Conn.CookieOverflowError.md |    3 +
 .code_my_spec/hex_docs/plug/Plug.Conn.Cookies.md   |   26 +
 .../hex_docs/plug/Plug.Conn.InvalidQueryError.md   |    6 +
 .../hex_docs/plug/Plug.Conn.NotSentError.md        |    3 +
 .code_my_spec/hex_docs/plug/Plug.Conn.Query.md     |  149 ++
 .code_my_spec/hex_docs/plug/Plug.Conn.Status.md    |    9 +
 .code_my_spec/hex_docs/plug/Plug.Conn.Unfetched.md |    9 +
 .code_my_spec/hex_docs/plug/Plug.Conn.Utils.md     |   28 +
 .../hex_docs/plug/Plug.Conn.WrapperError.md        |   10 +
 .code_my_spec/hex_docs/plug/Plug.Conn.md           |  877 ++++++++++
 .code_my_spec/hex_docs/plug/Plug.Debugger.md       |   98 ++
 .code_my_spec/hex_docs/plug/Plug.ErrorHandler.md   |   49 +
 .code_my_spec/hex_docs/plug/Plug.HTML.md           |    3 +
 .code_my_spec/hex_docs/plug/Plug.Head.md           |    7 +
 .code_my_spec/hex_docs/plug/Plug.Logger.md         |   17 +
 .code_my_spec/hex_docs/plug/Plug.MethodOverride.md |   37 +
 .../hex_docs/plug/Plug.Parsers.BadEncodingError.md |    3 +
 .code_my_spec/hex_docs/plug/Plug.Parsers.JSON.md   |   26 +
 .../hex_docs/plug/Plug.Parsers.MULTIPART.md        |   85 +
 .../hex_docs/plug/Plug.Parsers.ParseError.md       |    3 +
 .../plug/Plug.Parsers.RequestTooLargeError.md      |    3 +
 .../hex_docs/plug/Plug.Parsers.URLENCODED.md       |   18 +
 .../plug/Plug.Parsers.UnsupportedMediaTypeError.md |    3 +
 .code_my_spec/hex_docs/plug/Plug.Parsers.md        |  186 ++
 .code_my_spec/hex_docs/plug/Plug.RequestId.md      |   66 +
 .code_my_spec/hex_docs/plug/Plug.RewriteOn.md      |   33 +
 .code_my_spec/hex_docs/plug/Plug.Router.Utils.md   |   73 +
 .code_my_spec/hex_docs/plug/Plug.Router.md         |  124 ++
 .code_my_spec/hex_docs/plug/Plug.SSL.md            |  131 ++
 .code_my_spec/hex_docs/plug/Plug.Session.COOKIE.md |   62 +
 .code_my_spec/hex_docs/plug/Plug.Session.ETS.md    |   43 +
 .code_my_spec/hex_docs/plug/Plug.Session.Store.md  |   13 +
 .code_my_spec/hex_docs/plug/Plug.Session.md        |   43 +
 .code_my_spec/hex_docs/plug/Plug.Static.md         |  133 ++
 .code_my_spec/hex_docs/plug/Plug.Telemetry.md      |   49 +
 .code_my_spec/hex_docs/plug/Plug.Test.md           |  150 ++
 .code_my_spec/hex_docs/plug/Plug.TimeoutError.md   |    3 +
 .code_my_spec/hex_docs/plug/Plug.Upload.md         |   48 +
 .code_my_spec/hex_docs/plug/Plug.md                |  111 ++
 .../plug_crypto/Plug.Crypto.KeyGenerator.md        |   27 +
 .../plug_crypto/Plug.Crypto.MessageEncryptor.md    |   17 +
 .../plug_crypto/Plug.Crypto.MessageVerifier.md     |   22 +
 .code_my_spec/hex_docs/plug_crypto/Plug.Crypto.md  |  159 ++
 .code_my_spec/hex_docs/postgrex/Postgrex.Box.md    |    8 +
 .code_my_spec/hex_docs/postgrex/Postgrex.Circle.md |    8 +
 .../hex_docs/postgrex/Postgrex.Extension.md        |   68 +
 .code_my_spec/hex_docs/postgrex/Postgrex.INET.md   |    8 +
 .../hex_docs/postgrex/Postgrex.Interval.md         |   10 +
 .code_my_spec/hex_docs/postgrex/Postgrex.Lexeme.md |    8 +
 .code_my_spec/hex_docs/postgrex/Postgrex.Line.md   |   12 +
 .../hex_docs/postgrex/Postgrex.LineSegment.md      |    8 +
 .../hex_docs/postgrex/Postgrex.MACADDR.md          |    7 +
 .../hex_docs/postgrex/Postgrex.Multirange.md       |    7 +
 .../hex_docs/postgrex/Postgrex.Notifications.md    |   40 +
 .code_my_spec/hex_docs/postgrex/Postgrex.Path.md   |    8 +
 .code_my_spec/hex_docs/postgrex/Postgrex.Point.md  |    8 +
 .../hex_docs/postgrex/Postgrex.Polygon.md          |    7 +
 .code_my_spec/hex_docs/postgrex/Postgrex.Query.md  |   20 +
 .code_my_spec/hex_docs/postgrex/Postgrex.Range.md  |   15 +
 .../postgrex/Postgrex.ReplicationConnection.md     |   74 +
 .code_my_spec/hex_docs/postgrex/Postgrex.Result.md |   13 +
 .../postgrex/Postgrex.SCRAM.LockedCache.md         |   12 +
 .../hex_docs/postgrex/Postgrex.SimpleConnection.md |   45 +
 .code_my_spec/hex_docs/postgrex/Postgrex.Stream.md |    5 +
 .../hex_docs/postgrex/Postgrex.TypeInfo.md         |   20 +
 .../hex_docs/postgrex/Postgrex.TypeModule.md       |   48 +
 .../hex_docs/postgrex/Postgrex.TypeServer.md       |   22 +
 .../hex_docs/postgrex/Postgrex.TypeSupervisor.md   |   12 +
 .code_my_spec/hex_docs/postgrex/Postgrex.Types.md  |   85 +
 .code_my_spec/hex_docs/postgrex/Postgrex.Utils.md  |   36 +
 .code_my_spec/hex_docs/postgrex/Postgrex.md        |   66 +
 .code_my_spec/hex_docs/req/Req.ArchiveError.md     |    3 +
 .../hex_docs/req/Req.ChecksumMismatchError.md      |    3 +
 .code_my_spec/hex_docs/req/Req.DecompressError.md  |    3 +
 .code_my_spec/hex_docs/req/Req.Fields.md           |   33 +
 .code_my_spec/hex_docs/req/Req.Finch.md            |   11 +
 .code_my_spec/hex_docs/req/Req.HTTPError.md        |    8 +
 .code_my_spec/hex_docs/req/Req.Request.md          |  436 +++++
 .code_my_spec/hex_docs/req/Req.Response.Async.md   |   27 +
 .code_my_spec/hex_docs/req/Req.Response.md         |  154 ++
 .code_my_spec/hex_docs/req/Req.Steps.md            |  794 +++++++++
 .code_my_spec/hex_docs/req/Req.Tar.md              |   12 +
 .code_my_spec/hex_docs/req/Req.Test.md             |  324 ++++
 .../hex_docs/req/Req.TooManyRedirectsError.md      |    3 +
 .code_my_spec/hex_docs/req/Req.TransportError.md   |    8 +
 .code_my_spec/hex_docs/req/Req.Utils.md            |  111 ++
 .code_my_spec/hex_docs/req/Req.ZIP.md              |    9 +
 .code_my_spec/hex_docs/req/Req.md                  |  666 +++++++
 .../hex_docs/sexy_spex/Mix.Tasks.Compile.Spex.md   |   68 +
 .code_my_spec/hex_docs/sexy_spex/Mix.Tasks.Spex.md |   73 +
 .code_my_spec/hex_docs/sexy_spex/SexySpex.DSL.md   |  168 ++
 .../sexy_spex/SexySpex.ErrorCapture.Handler.md     |    7 +
 .../hex_docs/sexy_spex/SexySpex.ErrorCapture.md    |   56 +
 .../hex_docs/sexy_spex/SexySpex.Givens.md          |   41 +
 .../hex_docs/sexy_spex/SexySpex.Helpers.md         |   43 +
 .../hex_docs/sexy_spex/SexySpex.Reporter.md        |   44 +
 .../hex_docs/sexy_spex/SexySpex.StepExecutor.md    |   40 +
 .code_my_spec/hex_docs/sexy_spex/SexySpex.md       |  200 +++
 .../hex_docs/sobelow/Mix.Tasks.Sobelow.md          |   82 +
 .code_my_spec/hex_docs/sobelow/Sobelow.CI.OS.md    |   12 +
 .../hex_docs/sobelow/Sobelow.CI.System.md          |   12 +
 .code_my_spec/hex_docs/sobelow/Sobelow.CI.md       |   22 +
 .../hex_docs/sobelow/Sobelow.Config.CSP.md         |   28 +
 .../hex_docs/sobelow/Sobelow.Config.CSRF.md        |   18 +
 .../hex_docs/sobelow/Sobelow.Config.CSRFRoute.md   |   23 +
 .../hex_docs/sobelow/Sobelow.Config.CSWH.md        |   14 +
 .../hex_docs/sobelow/Sobelow.Config.HSTS.md        |   11 +
 .../hex_docs/sobelow/Sobelow.Config.HTTPS.md       |   13 +
 .../hex_docs/sobelow/Sobelow.Config.Headers.md     |   16 +
 .../hex_docs/sobelow/Sobelow.Config.Secrets.md     |   15 +
 .code_my_spec/hex_docs/sobelow/Sobelow.Config.md   |   28 +
 .../hex_docs/sobelow/Sobelow.DOS.BinToAtom.md      |   12 +
 .../hex_docs/sobelow/Sobelow.DOS.ListToAtom.md     |   12 +
 .../hex_docs/sobelow/Sobelow.DOS.StringToAtom.md   |   12 +
 .code_my_spec/hex_docs/sobelow/Sobelow.DOS.md      |   23 +
 .code_my_spec/hex_docs/sobelow/Sobelow.IO.md       |    4 +
 .../hex_docs/sobelow/Sobelow.Misc.BinToTerm.md     |   12 +
 .code_my_spec/hex_docs/sobelow/Sobelow.Misc.md     |   18 +
 .../hex_docs/sobelow/Sobelow.RCE.CodeModule.md     |   16 +
 .code_my_spec/hex_docs/sobelow/Sobelow.RCE.EEx.md  |   11 +
 .code_my_spec/hex_docs/sobelow/Sobelow.RCE.md      |   19 +
 .../hex_docs/sobelow/Sobelow.SQL.Query.md          |   13 +
 .../hex_docs/sobelow/Sobelow.SQL.Stream.md         |   12 +
 .code_my_spec/hex_docs/sobelow/Sobelow.SQL.md      |   22 +
 .../sobelow/Sobelow.Traversal.FileModule.md        |   12 +
 .../sobelow/Sobelow.Traversal.SendDownload.md      |   12 +
 .../hex_docs/sobelow/Sobelow.Traversal.SendFile.md |   12 +
 .../hex_docs/sobelow/Sobelow.Traversal.md          |   23 +
 .../hex_docs/sobelow/Sobelow.Vuln.Coherence.md     |   10 +
 .../hex_docs/sobelow/Sobelow.Vuln.CookieRCE.md     |   10 +
 .../hex_docs/sobelow/Sobelow.Vuln.Ecto.md          |   10 +
 .../hex_docs/sobelow/Sobelow.Vuln.HeaderInject.md  |   10 +
 .../hex_docs/sobelow/Sobelow.Vuln.PlugNull.md      |   10 +
 .../hex_docs/sobelow/Sobelow.Vuln.Redirect.md      |   10 +
 .code_my_spec/hex_docs/sobelow/Sobelow.Vuln.md     |   21 +
 .../hex_docs/sobelow/Sobelow.XSS.ContentType.md    |   22 +
 .code_my_spec/hex_docs/sobelow/Sobelow.XSS.HTML.md |   10 +
 .code_my_spec/hex_docs/sobelow/Sobelow.XSS.Raw.md  |   10 +
 .../hex_docs/sobelow/Sobelow.XSS.SendResp.md       |   10 +
 .code_my_spec/hex_docs/sobelow/Sobelow.XSS.md      |   24 +
 .code_my_spec/hex_docs/sobelow/Sobelow.md          |    4 +
 .../swoosh/Mix.Tasks.Swoosh.Mailbox.Server.md      |   14 +
 .../hex_docs/swoosh/Plug.Swoosh.MailboxPreview.md  |   18 +
 .code_my_spec/hex_docs/swoosh/Swoosh.Adapter.md    |   10 +
 .../hex_docs/swoosh/Swoosh.Adapters.Gmail.md       |   41 +
 .../swoosh/Swoosh.Adapters.Local.Storage.Memory.md |   11 +
 .../swoosh/Swoosh.Adapters.Mua.MultihostError.md   |   17 +
 .../hex_docs/swoosh/Swoosh.Adapters.Mua.md         |  101 ++
 .../hex_docs/swoosh/Swoosh.Adapters.Sandbox.md     |   15 +
 .../hex_docs/swoosh/Swoosh.Adapters.XML.Helpers.md |    7 +
 .../hex_docs/swoosh/Swoosh.Adapters.ZeptoMail.md   |   92 +
 .../hex_docs/swoosh/Swoosh.ApiClient.Finch.md      |   23 +
 .../hex_docs/swoosh/Swoosh.ApiClient.Hackney.md    |    3 +
 .../hex_docs/swoosh/Swoosh.ApiClient.Req.md        |   11 +
 .code_my_spec/hex_docs/swoosh/Swoosh.ApiClient.md  |   14 +
 .code_my_spec/hex_docs/swoosh/Swoosh.Email.md      |  200 +++
 .code_my_spec/hex_docs/swoosh/Swoosh.Mailer.md     |   12 +
 .../hex_docs/swoosh/Swoosh.TestAssertions.md       |   28 +
 .../hex_docs/swoosh/Swoosh.X.TestAssertions.md     |   32 +
 .../hex_docs/tailwind/Mix.Tasks.Tailwind.md        |   28 +
 .code_my_spec/hex_docs/tailwind/Tailwind.md        |   77 +
 .../Telemetry.Metrics.ConsoleReporter.md           |   37 +
 .../telemetry_metrics/Telemetry.Metrics.Counter.md |    3 +
 .../Telemetry.Metrics.Distribution.md              |    3 +
 .../Telemetry.Metrics.LastValue.md                 |    3 +
 .../telemetry_metrics/Telemetry.Metrics.Sum.md     |    3 +
 .../telemetry_metrics/Telemetry.Metrics.Summary.md |    3 +
 .../telemetry_metrics/Telemetry.Metrics.md         |  479 +++++
 .../hex_docs/tesla/Tesla.Adapter.Finch.md          |   68 +
 .code_my_spec/hex_docs/tesla/Tesla.Adapter.Gun.md  |  114 ++
 .../hex_docs/tesla/Tesla.Adapter.Hackney.md        |   32 +
 .../hex_docs/tesla/Tesla.Adapter.Httpc.md          |    8 +
 .../hex_docs/tesla/Tesla.Adapter.Ibrowse.md        |   25 +
 .code_my_spec/hex_docs/tesla/Tesla.Adapter.Mint.md |   50 +
 .code_my_spec/hex_docs/tesla/Tesla.Adapter.md      |   70 +
 .code_my_spec/hex_docs/tesla/Tesla.Builder.md      |   37 +
 .code_my_spec/hex_docs/tesla/Tesla.Env.md          |    3 +
 .../hex_docs/tesla/Tesla.Middleware.BaseUrl.md     |   67 +
 .../hex_docs/tesla/Tesla.Middleware.BasicAuth.md   |   23 +
 .../hex_docs/tesla/Tesla.Middleware.BearerAuth.md  |   21 +
 .../tesla/Tesla.Middleware.CompressRequest.md      |    5 +
 .../tesla/Tesla.Middleware.Compression.Error.md    |   11 +
 .../hex_docs/tesla/Tesla.Middleware.Compression.md |   50 +
 .../hex_docs/tesla/Tesla.Middleware.DecodeJson.md  |    6 +
 .../hex_docs/tesla/Tesla.Middleware.DecodeRels.md  |   20 +
 .../tesla/Tesla.Middleware.DecompressResponse.md   |    6 +
 .../hex_docs/tesla/Tesla.Middleware.DigestAuth.md  |   27 +
 .../hex_docs/tesla/Tesla.Middleware.EncodeJson.md  |    3 +
 .../tesla/Tesla.Middleware.FollowRedirects.md      |   20 +
 .../tesla/Tesla.Middleware.FormUrlencoded.md       |  201 +++
 .../hex_docs/tesla/Tesla.Middleware.Fuse.md        |   54 +
 .../hex_docs/tesla/Tesla.Middleware.Headers.md     |   15 +
 .../hex_docs/tesla/Tesla.Middleware.JSON.md        |   67 +
 .../hex_docs/tesla/Tesla.Middleware.KeepRequest.md |   39 +
 .../hex_docs/tesla/Tesla.Middleware.MessagePack.md |   49 +
 .../tesla/Tesla.Middleware.MethodOverride.md       |   20 +
 .../hex_docs/tesla/Tesla.Middleware.Opts.md        |   15 +
 .../hex_docs/tesla/Tesla.Middleware.PathParams.md  |   81 +
 .../hex_docs/tesla/Tesla.Middleware.Query.md       |   51 +
 .../hex_docs/tesla/Tesla.Middleware.Retry.md       |   58 +
 .../hex_docs/tesla/Tesla.Middleware.SSE.md         |   20 +
 .../hex_docs/tesla/Tesla.Middleware.Telemetry.md   |   89 +
 .../hex_docs/tesla/Tesla.Middleware.Timeout.md     |   39 +
 .code_my_spec/hex_docs/tesla/Tesla.Middleware.md   |   44 +
 .code_my_spec/hex_docs/tesla/Tesla.Mock.md         |  146 ++
 .code_my_spec/hex_docs/tesla/Tesla.Multipart.md    |   58 +
 .../hex_docs/tesla/Tesla.OpenAPI.CookieParam.md    |   59 +
 .../hex_docs/tesla/Tesla.OpenAPI.CookieParams.md   |   21 +
 .../hex_docs/tesla/Tesla.OpenAPI.HeaderParam.md    |   44 +
 .../hex_docs/tesla/Tesla.OpenAPI.HeaderParams.md   |   20 +
 .../hex_docs/tesla/Tesla.OpenAPI.PathParam.md      |   69 +
 .../hex_docs/tesla/Tesla.OpenAPI.PathParams.md     |   43 +
 .../hex_docs/tesla/Tesla.OpenAPI.PathTemplate.md   |   44 +
 .../hex_docs/tesla/Tesla.OpenAPI.QueryParam.md     |   79 +
 .../hex_docs/tesla/Tesla.OpenAPI.QueryParams.md    |   47 +
 .../hex_docs/tesla/Tesla.OpenAPI.QueryString.md    |   28 +
 .../tesla/Tesla.OpenAPI.QueryStringError.md        |    3 +
 .../hex_docs/tesla/Tesla.OpenAPI.Response.md       |   10 +
 .code_my_spec/hex_docs/tesla/Tesla.OpenAPI.md      |   80 +
 .code_my_spec/hex_docs/tesla/Tesla.Test.md         |  134 ++
 .code_my_spec/hex_docs/tesla/Tesla.md              |  285 +++
 .../thousand_island/ThousandIsland.Handler.md      |  203 +++
 .../ThousandIsland.HandlerConfig.md                |   10 +
 .../thousand_island/ThousandIsland.Logger.md       |   20 +
 .../thousand_island/ThousandIsland.ServerConfig.md |    5 +
 .../thousand_island/ThousandIsland.Socket.md       |   95 +
 .../thousand_island/ThousandIsland.Telemetry.md    |  276 +++
 .../thousand_island/ThousandIsland.Transport.md    |    8 +
 .../ThousandIsland.Transports.SSL.md               |   37 +
 .../ThousandIsland.Transports.TCP.md               |   35 +
 .../hex_docs/thousand_island/ThousandIsland.md     |  120 ++
 .../hex_docs/wallaby/PartitionSupervisor.md        |  109 ++
 .code_my_spec/hex_docs/wallaby/Wallaby.Browser.md  |  715 ++++++++
 .code_my_spec/hex_docs/wallaby/Wallaby.Chrome.md   |  103 ++
 .code_my_spec/hex_docs/wallaby/Wallaby.DSL.md      |   26 +
 .../hex_docs/wallaby/Wallaby.Driver.LogStore.md    |    7 +
 .code_my_spec/hex_docs/wallaby/Wallaby.Element.md  |   96 +
 .code_my_spec/hex_docs/wallaby/Wallaby.Feature.md  |   74 +
 .../hex_docs/wallaby/Wallaby.HTTPClient.md         |    8 +
 .../hex_docs/wallaby/Wallaby.Helpers.KeyCodes.md   |   47 +
 .code_my_spec/hex_docs/wallaby/Wallaby.Metadata.md |    7 +
 .../hex_docs/wallaby/Wallaby.Query.ErrorMessage.md |   28 +
 .../hex_docs/wallaby/Wallaby.Query.XPath.md        |   48 +
 .code_my_spec/hex_docs/wallaby/Wallaby.Query.md    |  197 +++
 .code_my_spec/hex_docs/wallaby/Wallaby.Selenium.md |   72 +
 .code_my_spec/hex_docs/wallaby/Wallaby.Session.md  |    3 +
 .../hex_docs/wallaby/Wallaby.WebdriverClient.md    |  224 +++
 .code_my_spec/hex_docs/wallaby/Wallaby.md          |   50 +
 .../web_driver_client/WebDriverClient.Config.md    |    7 +
 .../WebDriverClient.ConnectionError.md             |    4 +
 .../web_driver_client/WebDriverClient.Cookie.md    |    3 +
 .../web_driver_client/WebDriverClient.Element.md   |    3 +
 .../WebDriverClient.JSONWireProtocolClient.md      |  180 ++
 .../web_driver_client/WebDriverClient.LogEntry.md  |    3 +
 .../WebDriverClient.ProtocolMismatchError.md       |    4 +
 .../WebDriverClient.ServerStatus.md                |    3 +
 .../web_driver_client/WebDriverClient.Session.md   |   11 +
 .../web_driver_client/WebDriverClient.Size.md      |    3 +
 .../WebDriverClient.UnexpectedResponseError.md     |    4 +
 .../WebDriverClient.W3CWireProtocolClient.md       |  175 ++
 .../WebDriverClient.WebDriverError.md              |    3 +
 .../hex_docs/web_driver_client/WebDriverClient.md  |  148 ++
 .../WebSockAdapter.UpgradeValidation.md            |   28 +
 .../hex_docs/websock_adapter/WebSockAdapter.md     |   49 +
 .code_my_spec/integrations/codemyspec.md           |   25 +
 .code_my_spec/integrations/index.md                |   33 +
 .code_my_spec/integrations/object_storage.md       |   23 +
 .code_my_spec/integrations/resend.md               |   19 +
 .code_my_spec/integrations/stripe.md               |   20 +
 .code_my_spec/integrations/twilio.md               |   21 +
 .code_my_spec/knowledge/bdd/spex/index.md          |   66 +
 .code_my_spec/personas/cleaner/sources.md          |   14 +
 .code_my_spec/personas/cleaner/summary.md          |   35 +
 .../personas/cleaning-business-owner/sources.md    |   17 +
 .../personas/cleaning-business-owner/summary.md    |   34 +
 .code_my_spec/personas/cleaning-client/sources.md  |   24 +
 .code_my_spec/personas/cleaning-client/summary.md  |   38 +
 .code_my_spec/qa/832/brief.md                      |  159 ++
 .code_my_spec/qa/833/brief.md                      |   54 +
 .code_my_spec/qa/834/brief.md                      |   68 +
 .../834_ben_own_schedule_shows_reassigned_job.png  |  Bin 0 -> 513685 bytes
 .../qa/834/screenshots/834_conflict_blocked.png    |  Bin 0 -> 519996 bytes
 .../834_dispatch_unassigned_success.png            |  Bin 0 -> 515145 bytes
 .../834_reassign_ana_to_ben_success.png            |  Bin 0 -> 511658 bytes
 .../screenshots/834_weekly_board_all_cleaners.png  |  Bin 0 -> 32449 bytes
 .code_my_spec/qa/835/brief.md                      |   72 +
 .code_my_spec/qa/836/brief.md                      |  134 ++
 .code_my_spec/qa/837/brief.md                      |  114 ++
 .code_my_spec/qa/838/brief.md                      |   79 +
 .code_my_spec/qa/839/brief.md                      |   58 +
 .code_my_spec/qa/839/result.md                     |   97 ++
 .code_my_spec/qa/840/brief.md                      |   86 +
 .code_my_spec/qa/842/brief.md                      |   44 +
 .code_my_spec/qa/843/brief.md                      |   43 +
 .code_my_spec/qa/844/brief.md                      |   38 +
 .code_my_spec/qa/845/brief.md                      |   31 +
 .code_my_spec/qa/846/brief.md                      |   32 +
 .code_my_spec/qa/848/brief.md                      |   48 +
 .code_my_spec/qa/849/brief.md                      |   42 +
 .code_my_spec/qa/850/brief.md                      |   40 +
 .code_my_spec/qa/851/brief.md                      |   40 +
 .code_my_spec/qa/852/brief.md                      |   42 +
 .code_my_spec/qa/853/brief.md                      |   35 +
 .code_my_spec/qa/journey_plan.md                   |   86 +
 .code_my_spec/qa/journey_result.md                 |   72 +
 .code_my_spec/qa/plan.md                           |   40 +
 .code_my_spec/qa/scripts/authenticated_curl.sh     |   32 +
 .../qa/scripts/exchange_codemyspec_token.sh        |   19 +
 .code_my_spec/qa/scripts/verify_codemyspec.sh      |   14 +
 .code_my_spec/qa/scripts/verify_object_storage.sh  |   38 +
 .code_my_spec/qa/scripts/verify_resend.sh          |   19 +
 .code_my_spec/qa/scripts/verify_stripe.sh          |   19 +
 .code_my_spec/qa/scripts/verify_twilio.sh          |   22 +
 .code_my_spec/qa/stories_summary.md                |  176 ++
 .code_my_spec/rules/collaboration_guidelines.md    |   12 +
 .code_my_spec/rules/context_design.md              |   16 +
 .code_my_spec/rules/documentation_writing.md       |  129 ++
 .code_my_spec/rules/elixir.md                      |   43 +
 .code_my_spec/rules/elixir_design.md               |   21 +
 .code_my_spec/rules/elixir_test.md                 |   18 +
 .code_my_spec/rules/feature_page_writing.md        |   51 +
 .code_my_spec/rules/live_context_design.md         |   21 +
 .code_my_spec/rules/liveview.md                    |   57 +
 .code_my_spec/rules/liveview_component_design.md   |   41 +
 .code_my_spec/rules/liveview_design.md             |   47 +
 .code_my_spec/rules/liveview_forms.md              |   37 +
 .code_my_spec/rules/repository.md                  |   10 +
 .code_my_spec/rules/repository_design.md           |   79 +
 .code_my_spec/rules/repository_test.md             |  100 ++
 .code_my_spec/rules/schema.md                      |   16 +
 .code_my_spec/rules/schema_design.md               |   13 +
 .code_my_spec/rules/tool_design.md                 |  107 ++
 .code_my_spec/rules/tools.md                       |    6 +
 .code_my_spec/spec/cleaner_crm/audit.spec.md       |    7 +
 .../spec/cleaner_crm/audit/audit_entry.spec.md     |    7 +
 .../spec/cleaner_crm/audit/recorder.spec.md        |    7 +
 .code_my_spec/spec/cleaner_crm/billing.spec.md     |   14 +
 .../spec/cleaner_crm/billing/invoice.spec.md       |    7 +
 .../spec/cleaner_crm/billing/payment.spec.md       |    7 +
 .../cleaner_crm/billing/stripe_gateway.spec.md     |    7 +
 .code_my_spec/spec/cleaner_crm/booking.spec.md     |   15 +
 .../spec/cleaner_crm/booking/lead.spec.md          |    7 +
 .code_my_spec/spec/cleaner_crm/clients.spec.md     |   12 +
 .../spec/cleaner_crm/clients/access_detail.spec.md |    7 +
 .../spec/cleaner_crm/clients/client.spec.md        |    7 +
 .../spec/cleaner_crm/clients/property.spec.md      |    7 +
 .../spec/cleaner_crm/notifications.spec.md         |   14 +
 .../cleaner_crm/notifications/delivery.spec.md     |    7 +
 .../cleaner_crm/notifications/notification.spec.md |    7 +
 .../notifications/reminder_scheduler.spec.md       |    7 +
 .code_my_spec/spec/cleaner_crm/portal.spec.md      |   15 +
 .../cleaner_crm/portal/cancellation_policy.spec.md |    7 +
 .../spec/cleaner_crm/portal/portal_session.spec.md |    7 +
 .code_my_spec/spec/cleaner_crm/portal/tip.spec.md  |    7 +
 .code_my_spec/spec/cleaner_crm/quality.spec.md     |   12 +
 .../spec/cleaner_crm/quality/checklist.spec.md     |    7 +
 .../cleaner_crm/quality/checklist_item.spec.md     |    7 +
 .../cleaner_crm/quality/checklist_template.spec.md |    7 +
 .../cleaner_crm/quality/incident_report.spec.md    |    7 +
 .../spec/cleaner_crm/quality/photo.spec.md         |    7 +
 .../spec/cleaner_crm/quality/scorecard.spec.md     |    7 +
 .code_my_spec/spec/cleaner_crm/quoting.spec.md     |   12 +
 .../spec/cleaner_crm/quoting/pricing.spec.md       |    7 +
 .../spec/cleaner_crm/quoting/quote.spec.md         |    7 +
 .../spec/cleaner_crm/quoting/quote_item.spec.md    |    7 +
 .../spec/cleaner_crm/quoting/rate_card.spec.md     |    7 +
 .code_my_spec/spec/cleaner_crm/reviews.spec.md     |   12 +
 .../spec/cleaner_crm/reviews/review.spec.md        |    7 +
 .../reviews/review_request_worker.spec.md          |    7 +
 .code_my_spec/spec/cleaner_crm/scheduling.spec.md  |   14 +
 .../scheduling/availability_block.spec.md          |    7 +
 .../scheduling/conflict_detector.spec.md           |    7 +
 .../spec/cleaner_crm/scheduling/job.spec.md        |    7 +
 .../spec/cleaner_crm/scheduling/recurrence.spec.md |    7 +
 .../cleaner_crm/scheduling/recurring_plan.spec.md  |    7 +
 .../spec/cleaner_crm/time_tracking.spec.md         |   13 +
 .../cleaner_crm/time_tracking/earnings.spec.md     |    7 +
 .../cleaner_crm/time_tracking/pay_rate.spec.md     |    7 +
 .../time_tracking/payroll_export.spec.md           |    7 +
 .../cleaner_crm/time_tracking/time_entry.spec.md   |    7 +
 .../spec/cleaner_crm_web/audit_live.spec.md        |   11 +
 .../spec/cleaner_crm_web/booking_live.spec.md      |   11 +
 .../cleaner_crm_web/booking_live/accept.spec.md    |    7 +
 .../cleaner_crm_web/booking_live/quote.spec.md     |    7 +
 .../spec/cleaner_crm_web/client_live.spec.md       |   11 +
 .../client_live/form_component.spec.md             |    7 +
 .../spec/cleaner_crm_web/client_live/index.spec.md |    7 +
 .../client_live/property_form_component.spec.md    |    7 +
 .../spec/cleaner_crm_web/client_live/show.spec.md  |    7 +
 .../spec/cleaner_crm_web/field_live.spec.md        |   14 +
 .../field_live/checklist_component.spec.md         |    7 +
 .../field_live/earnings_component.spec.md          |    7 +
 .../field_live/incident_form_component.spec.md     |    7 +
 .../spec/cleaner_crm_web/field_live/job.spec.md    |    7 +
 .../spec/cleaner_crm_web/field_live/today.spec.md  |    7 +
 .../spec/cleaner_crm_web/invoice_live.spec.md      |   11 +
 .../cleaner_crm_web/invoice_live/index.spec.md     |    7 +
 .../spec/cleaner_crm_web/invoice_live/show.spec.md |    7 +
 .../cleaner_crm_web/payment_controller.spec.md     |   11 +
 .../spec/cleaner_crm_web/portal_live.spec.md       |   11 +
 .../spec/cleaner_crm_web/portal_live/home.spec.md  |    7 +
 .../cleaner_crm_web/portal_live/invoices.spec.md   |    7 +
 .../spec/cleaner_crm_web/portal_live/visit.spec.md |    7 +
 .../spec/cleaner_crm_web/quality_live.spec.md      |   11 +
 .../cleaner_crm_web/quality_live/review.spec.md    |    7 +
 .../quality_live/scorecards.spec.md                |    7 +
 .../spec/cleaner_crm_web/quote_live.spec.md        |   12 +
 .../cleaner_crm_web/quote_live/builder.spec.md     |    7 +
 .../spec/cleaner_crm_web/quote_live/index.spec.md  |    7 +
 .../cleaner_crm_web/reminder_controller.spec.md    |   11 +
 .../spec/cleaner_crm_web/reminder_live.spec.md     |   11 +
 .../spec/cleaner_crm_web/review_live.spec.md       |   11 +
 .../spec/cleaner_crm_web/review_live/index.spec.md |    7 +
 .../cleaner_crm_web/review_live/public.spec.md     |    7 +
 .../spec/cleaner_crm_web/schedule_live.spec.md     |   12 +
 .../cleaner_crm_web/schedule_live/board.spec.md    |    7 +
 .../schedule_live/job_form_component.spec.md       |    7 +
 .../schedule_live/plan_form_component.spec.md      |    7 +
 .../spec/cleaner_crm_web/timesheet_live.spec.md    |   11 +
 .code_my_spec/tasks/code_generation.sh             |   20 +
 .credo.exs                                         |   36 +
 .formatter.exs                                     |    6 +
 .gitignore                                         |   46 +
 .tool-versions                                     |    2 +
 AGENTS.md                                          |  510 ++++++
 CLAUDE.md                                          |   40 +
 README.md                                          |   18 +
 assets/css/app.css                                 |  108 ++
 assets/js/app.js                                   |   84 +
 assets/js/screenshot.js                            |   36 +
 assets/package-lock.json                           |   18 +
 assets/package.json                                |    5 +
 assets/tsconfig.json                               |   32 +
 assets/vendor/daisyui-theme.js                     |  124 ++
 assets/vendor/daisyui.js                           | 1057 +++++++++++
 assets/vendor/heroicons.js                         |   43 +
 assets/vendor/topbar.js                            |  138 ++
 config/config.exs                                  |  123 ++
 config/dev.exs                                     |  105 ++
 config/prod.exs                                    |   33 +
 config/runtime.exs                                 |  163 ++
 config/test.exs                                    |   73 +
 docs/STATUS.md                                     |   90 +
 docs/research/cleaner-pain-points.md               |  138 ++
 docs/research/customer-side.md                     |  147 ++
 docs/research/housecall-pro.md                     |   82 +
 docs/research/jobber.md                            |  130 ++
 docs/research/maidily-and-cleaning-specific.md     |  132 ++
 lib/cleaner_crm.ex                                 |   82 +
 lib/cleaner_crm/accounts.ex                        |  271 +++
 lib/cleaner_crm/accounts/account.ex                |   78 +
 lib/cleaner_crm/accounts/accounts_repository.ex    |   43 +
 lib/cleaner_crm/accounts/invitation.ex             |  119 ++
 lib/cleaner_crm/accounts/invitation_notifier.ex    |   67 +
 lib/cleaner_crm/accounts/invitation_repository.ex  |   96 +
 lib/cleaner_crm/accounts/member.ex                 |   83 +
 lib/cleaner_crm/accounts/members_repository.ex     |  111 ++
 lib/cleaner_crm/audit.ex                           |  100 ++
 lib/cleaner_crm/audit/audit_entry.ex               |   55 +
 lib/cleaner_crm/audit/recorder.ex                  |   86 +
 lib/cleaner_crm/authorization.ex                   |   32 +
 lib/cleaner_crm/billing.ex                         |  284 +++
 lib/cleaner_crm/billing/invoice.ex                 |   77 +
 lib/cleaner_crm/billing/payment.ex                 |   49 +
 lib/cleaner_crm/billing/receipt_notifier.ex        |   29 +
 lib/cleaner_crm/billing/stripe_gateway.ex          |   39 +
 lib/cleaner_crm/billing/stripe_gateway/live.ex     |  128 ++
 lib/cleaner_crm/billing/stripe_gateway/test.ex     |   20 +
 lib/cleaner_crm/booking.ex                         |  351 ++++
 lib/cleaner_crm/booking/lead.ex                    |  229 +++
 lib/cleaner_crm/booking/notifier.ex                |   44 +
 lib/cleaner_crm/booking/pricing.ex                 |  127 ++
 lib/cleaner_crm/clients.ex                         |  171 ++
 lib/cleaner_crm/clients/client.ex                  |   47 +
 lib/cleaner_crm/clients/property.ex                |   73 +
 lib/cleaner_crm/codemyspec/client.ex               |  145 ++
 lib/cleaner_crm/encrypted/binary.ex                |    3 +
 lib/cleaner_crm/integrations.ex                    |   81 +
 lib/cleaner_crm/integrations/integration.ex        |   61 +
 .../integrations/integration_repository.ex         |   69 +
 lib/cleaner_crm/integrations/o_auth_state_store.ex |   44 +
 .../integrations/providers/behaviour.ex            |    7 +
 .../integrations/providers/codemyspec.ex           |   56 +
 lib/cleaner_crm/mailer.ex                          |    3 +
 lib/cleaner_crm/money.ex                           |   40 +
 lib/cleaner_crm/notifications.ex                   |  309 ++++
 lib/cleaner_crm/notifications/delivery.ex          |   21 +
 lib/cleaner_crm/notifications/delivery/test.ex     |   16 +
 lib/cleaner_crm/notifications/delivery/twilio.ex   |   53 +
 lib/cleaner_crm/notifications/notification.ex      |   96 +
 lib/cleaner_crm/notifications/reminder_notifier.ex |   39 +
 .../notifications/reminder_scheduler.ex            |  138 ++
 lib/cleaner_crm/notifications/reminder_settings.ex |   35 +
 lib/cleaner_crm/portal.ex                          |  404 +++++
 lib/cleaner_crm/portal/cancellation_policy.ex      |   46 +
 lib/cleaner_crm/portal/portal_session.ex           |   92 +
 lib/cleaner_crm/portal/tip.ex                      |   44 +
 lib/cleaner_crm/quality.ex                         |  418 +++++
 lib/cleaner_crm/quality/checklist.ex               |   56 +
 lib/cleaner_crm/quality/checklist_item.ex          |   68 +
 lib/cleaner_crm/quality/checklist_template.ex      |   85 +
 lib/cleaner_crm/quality/incident_report.ex         |   72 +
 lib/cleaner_crm/quality/photo.ex                   |   81 +
 lib/cleaner_crm/quality/scorecard.ex               |   60 +
 lib/cleaner_crm/quoting.ex                         |  129 ++
 lib/cleaner_crm/quoting/pricing.ex                 |  103 ++
 lib/cleaner_crm/quoting/quote.ex                   |   79 +
 lib/cleaner_crm/quoting/quote_item.ex              |   49 +
 lib/cleaner_crm/quoting/rate_card.ex               |   95 +
 lib/cleaner_crm/repo.ex                            |    5 +
 lib/cleaner_crm/reviews.ex                         |   72 +
 lib/cleaner_crm/reviews/review.ex                  |   78 +
 lib/cleaner_crm/reviews/review_notifier.ex         |   58 +
 lib/cleaner_crm/reviews/review_request_worker.ex   |  115 ++
 lib/cleaner_crm/scheduling.ex                      |  490 ++++++
 lib/cleaner_crm/scheduling/availability_block.ex   |   55 +
 lib/cleaner_crm/scheduling/conflict_detector.ex    |  132 ++
 lib/cleaner_crm/scheduling/job.ex                  |  138 ++
 lib/cleaner_crm/scheduling/recurrence.ex           |   62 +
 lib/cleaner_crm/scheduling/recurring_plan.ex       |  100 ++
 lib/cleaner_crm/time_tracking.ex                   |  304 ++++
 lib/cleaner_crm/time_tracking/earnings.ex          |   51 +
 lib/cleaner_crm/time_tracking/pay_rate.ex          |   44 +
 lib/cleaner_crm/time_tracking/payroll_export.ex    |   49 +
 lib/cleaner_crm/time_tracking/time_entry.ex        |   64 +
 lib/cleaner_crm/users.ex                           |  297 ++++
 lib/cleaner_crm/users/scope.ex                     |   35 +
 lib/cleaner_crm/users/user.ex                      |  138 ++
 lib/cleaner_crm/users/user_notifier.ex             |   84 +
 lib/cleaner_crm/users/user_token.ex                |  156 ++
 lib/cleaner_crm/vault.ex                           |    3 +
 lib/cleaner_crm_web.ex                             |  116 ++
 lib/cleaner_crm_web/application.ex                 |   37 +
 lib/cleaner_crm_web/cache_body_reader.ex           |   20 +
 lib/cleaner_crm_web/components/core_components.ex  |  585 +++++++
 lib/cleaner_crm_web/components/layouts.ex          |  175 ++
 .../components/layouts/root.html.heex              |   71 +
 lib/cleaner_crm_web/controllers/error_html.ex      |   24 +
 lib/cleaner_crm_web/controllers/error_json.ex      |   21 +
 .../controllers/integrations_controller.ex         |  102 ++
 lib/cleaner_crm_web/controllers/page_controller.ex |    7 +
 lib/cleaner_crm_web/controllers/page_html.ex       |   10 +
 .../controllers/page_html/home.html.heex           |  199 +++
 .../controllers/payment_controller.ex              |   59 +
 lib/cleaner_crm_web/controllers/payment_html.ex    |   10 +
 .../controllers/payment_html/declined.html.heex    |    5 +
 .../controllers/payment_html/not_found.html.heex   |    5 +
 .../controllers/payment_html/paid.html.heex        |    6 +
 .../controllers/payment_html/show.html.heex        |   13 +
 .../controllers/portal_controller.ex               |   28 +
 lib/cleaner_crm_web/controllers/portal_html.ex     |   11 +
 .../controllers/portal_html/invalid.html.heex      |    7 +
 .../controllers/reminder_controller.ex             |   25 +
 lib/cleaner_crm_web/controllers/reminder_html.ex   |   11 +
 .../controllers/reminder_html/confirm.html.heex    |    4 +
 .../controllers/reminder_html/not_found.html.heex  |    4 +
 .../controllers/reminder_html/reschedule.html.heex |    4 +
 .../controllers/stripe_webhook_controller.ex       |   51 +
 .../controllers/timesheet_export_controller.ex     |   40 +
 .../controllers/twilio_webhook_controller.ex       |   16 +
 .../controllers/user_session_controller.ex         |   67 +
 lib/cleaner_crm_web/date_param.ex                  |   11 +
 lib/cleaner_crm_web/endpoint.ex                    |   64 +
 lib/cleaner_crm_web/gettext.ex                     |   25 +
 .../account_live/components/accounts_breadcrumb.ex |   41 +
 .../live/account_live/components/members_list.ex   |  141 ++
 .../live/account_live/components/navigation.ex     |   44 +
 lib/cleaner_crm_web/live/account_live/form.ex      |  115 ++
 lib/cleaner_crm_web/live/account_live/index.ex     |  150 ++
 .../live/account_live/invitations.ex               |  178 ++
 lib/cleaner_crm_web/live/account_live/manage.ex    |  139 ++
 lib/cleaner_crm_web/live/account_live/members.ex   |  209 +++
 lib/cleaner_crm_web/live/account_live/picker.ex    |   82 +
 lib/cleaner_crm_web/live/audit_live.ex             |  237 +++
 lib/cleaner_crm_web/live/booking_live/accept.ex    |  205 +++
 lib/cleaner_crm_web/live/booking_live/quote.ex     |  279 +++
 .../live/client_live/form_component.ex             |  100 ++
 lib/cleaner_crm_web/live/client_live/index.ex      |   71 +
 .../live/client_live/property_form_component.ex    |  212 +++
 lib/cleaner_crm_web/live/client_live/show.ex       |  321 ++++
 lib/cleaner_crm_web/live/feedback_widget.ex        |  267 +++
 .../live/field_live/checklist_component.ex         |  219 +++
 .../live/field_live/checklist_item_component.ex    |  253 +++
 .../live/field_live/earnings_component.ex          |   74 +
 .../live/field_live/incident_form_component.ex     |  172 ++
 lib/cleaner_crm_web/live/field_live/job.ex         |  256 +++
 lib/cleaner_crm_web/live/field_live/today.ex       |  236 +++
 lib/cleaner_crm_web/live/integration_live/index.ex |  106 ++
 .../live/invitations_live/accept.ex                |  214 +++
 .../components/pending_invitations.ex              |   70 +
 lib/cleaner_crm_web/live/invitations_live/form.ex  |   88 +
 lib/cleaner_crm_web/live/invoice_live/index.ex     |   57 +
 lib/cleaner_crm_web/live/invoice_live/show.ex      |  163 ++
 lib/cleaner_crm_web/live/portal_live/home.ex       |  155 ++
 lib/cleaner_crm_web/live/portal_live/invoices.ex   |  118 ++
 lib/cleaner_crm_web/live/portal_live/visit.ex      |  201 +++
 lib/cleaner_crm_web/live/quality_live/review.ex    |  196 +++
 .../live/quality_live/scorecards.ex                |   99 ++
 .../live/quality_live/template_form_component.ex   |  157 ++
 lib/cleaner_crm_web/live/quality_live/templates.ex |  121 ++
 lib/cleaner_crm_web/live/quote_live/builder.ex     |  312 ++++
 lib/cleaner_crm_web/live/quote_live/index.ex       |   70 +
 lib/cleaner_crm_web/live/quote_live/rate_card.ex   |  380 ++++
 lib/cleaner_crm_web/live/reminder_live.ex          |   90 +
 lib/cleaner_crm_web/live/review_live/index.ex      |   75 +
 lib/cleaner_crm_web/live/review_live/public.ex     |  117 ++
 .../live/schedule_live/availability_live.ex        |   81 +
 .../live/schedule_live/cleaner_live.ex             |  133 ++
 lib/cleaner_crm_web/live/schedule_live/index.ex    |  388 +++++
 .../live/schedule_live/job_form_component.ex       |  465 +++++
 lib/cleaner_crm_web/live/schedule_live/job_live.ex |   86 +
 .../live/schedule_live/plan_form_component.ex      |  214 +++
 .../live/schedule_live/plan_live.ex                |   48 +
 .../live/schedule_live/schedule_notifier.ex        |   67 +
 .../live/settings_live/booking_policy.ex           |  218 +++
 lib/cleaner_crm_web/live/timesheet_live.ex         |  147 ++
 lib/cleaner_crm_web/live/user_live/confirmation.ex |   94 +
 lib/cleaner_crm_web/live/user_live/login.ex        |  134 ++
 lib/cleaner_crm_web/live/user_live/registration.ex |   89 +
 lib/cleaner_crm_web/live/user_live/settings.ex     |  160 ++
 lib/cleaner_crm_web/portal_auth.ex                 |   36 +
 lib/cleaner_crm_web/require_office_role.ex         |   77 +
 lib/cleaner_crm_web/router.ex                      |  265 +++
 lib/cleaner_crm_web/telemetry.ex                   |   93 +
 lib/cleaner_crm_web/user_auth.ex                   |  304 ++++
 mix.exs                                            |  112 ++
 mix.lock                                           |   71 +
 priv/gettext/en/LC_MESSAGES/errors.po              |  112 ++
 priv/gettext/errors.pot                            |  109 ++
 priv/repo/migrations/.formatter.exs                |    4 +
 .../20260707171323_create_users_auth_tables.exs    |   30 +
 .../20260707171341_create_accounts_tables.exs      |   49 +
 .../20260707171540_create_integrations_tables.exs  |   20 +
 .../20260707180000_create_clients_tables.exs       |   42 +
 .../20260707180010_create_audit_entries_table.exs  |   37 +
 .../20260707190000_add_name_to_users.exs           |   15 +
 .../20260707190010_create_scheduling_tables.exs    |   75 +
 .../20260707200000_add_contact_info_to_clients.exs |   13 +
 .../20260707200001_create_quality_tables.exs       |  118 ++
 ...20260707200005_add_time_tracking_pay_fields.exs |   19 +
 .../20260707200010_create_billing_tables.exs       |   46 +
 .../20260707200012_create_time_tracking_tables.exs |   40 +
 .../20260707200099_create_quoting_tables.exs       |   58 +
 ...0707200200_add_preferred_channel_to_clients.exs |   11 +
 .../20260707200210_create_notifications_tables.exs |   54 +
 .../20260707200220_add_oban_jobs_table.exs         |   13 +
 .../20260707200300_update_oban_to_v14.exs          |    8 +
 ...200310_add_client_preferences_to_properties.exs |    9 +
 .../20260707200320_add_push_enabled_to_users.exs   |   13 +
 ...0_add_agreed_price_cents_to_recurring_plans.exs |    9 +
 ...20260708200110_create_portal_sessions_table.exs |   24 +
 ...08200120_create_cancellation_policies_table.exs |   21 +
 .../20260708200130_create_tips_table.exs           |   25 +
 ...8210001_add_frequency_pricing_to_rate_cards.exs |   12 +
 .../20260708210002_create_leads_table.exs          |   46 +
 .../20260708220001_create_reviews_table.exs        |   31 +
 priv/repo/qa_seeds.exs                             |   60 +
 priv/repo/qa_seeds_834.exs                         |  219 +++
 priv/repo/qa_seeds_836.exs                         |   99 ++
 priv/repo/qa_seeds_837.exs                         |  158 ++
 priv/repo/seeds.exs                                |   11 +
 priv/static/favicon.ico                            |  Bin 0 -> 152 bytes
 priv/static/images/logo.svg                        |    6 +
 priv/static/robots.txt                             |    5 +
 screenshots/tmp/debug_screenshot.png               |  Bin 0 -> 37520 bytes
 test/cleaner_crm/billing/stripe_gateway_test.exs   |   48 +
 test/cleaner_crm/billing_test.exs                  |   77 +
 test/cleaner_crm/booking_test.exs                  |  157 ++
 .../notifications/delivery/twilio_test.exs         |   44 +
 .../notifications/reminder_scheduler_test.exs      |   76 +
 .../portal/cancellation_policy_test.exs            |   52 +
 test/cleaner_crm/portal/portal_session_test.exs    |   70 +
 test/cleaner_crm/portal/tip_test.exs               |   48 +
 test/cleaner_crm/portal_cross_client_test.exs      |   36 +
 test/cleaner_crm/portal_test.exs                   |  326 ++++
 .../reviews/review_request_worker_test.exs         |  110 ++
 test/cleaner_crm/reviews/review_test.exs           |   60 +
 test/cleaner_crm/reviews_test.exs                  |  172 ++
 test/cleaner_crm/scheduling/recurrence_test.exs    |   48 +
 test/cleaner_crm/time_tracking/earnings_test.exs   |   65 +
 test/cleaner_crm/time_tracking_test.exs            |  163 ++
 test/cleaner_crm/users_test.exs                    |  397 +++++
 .../controllers/error_html_test.exs                |   14 +
 .../controllers/error_json_test.exs                |   12 +
 .../controllers/page_controller_test.exs           |    8 +
 .../controllers/user_session_controller_test.exs   |  147 ++
 .../live/booking_live/accept_test.exs              |   90 +
 .../client_live/property_form_component_test.exs   |  252 +++
 .../live/field_live/checklist_component_test.exs   |   60 +
 .../cleaner_crm_web/live/portal_live/home_test.exs |  100 ++
 .../live/portal_live/invoices_test.exs             |  112 ++
 .../live/portal_live/visit_test.exs                |  141 ++
 .../live/quality_live/templates_test.exs           |  178 ++
 .../live/quote_live/rate_card_test.exs             |  143 ++
 .../live/review_live/index_test.exs                |   63 +
 .../live/review_live/public_test.exs               |   78 +
 .../live/schedule_live/job_form_component_test.exs |  446 +++++
 .../schedule_live/plan_form_component_test.exs     |  252 +++
 .../live/settings_live/booking_policy_test.exs     |  102 ++
 .../live/user_live/confirmation_test.exs           |  118 ++
 test/cleaner_crm_web/live/user_live/login_test.exs |  109 ++
 .../live/user_live/registration_test.exs           |   82 +
 .../live/user_live/settings_test.exs               |  212 +++
 test/cleaner_crm_web/user_auth_test.exs            |  390 +++++
 test/journeys/cleaner_day_test.exs                 |  114 ++
 test/journeys/new_client_to_paid_invoice_test.exs  |  164 ++
 test/journeys/payroll_close_test.exs               |  118 ++
 .../journeys/preferred_cleaner_continuity_test.exs |   98 ++
 test/journeys/schedule_chaos_test.exs              |  137 ++
 ...dd_a_property_under_an_existing_client_spex.exs |   76 +
 ..._7108_reject_a_property_with_no_client_spex.exs |   49 +
 ..._property_with_a_valid_service_address_spex.exs |   63 +
 ...reject_a_property_with_a_blank_address_spex.exs |   68 +
 ...brief_inherits_property_access_details_spex.exs |  103 ++
 ...updated_code_propagates_to_future_jobs_spex.exs |  106 ++
 ...erion_7115_entry_code_change_is_logged_spex.exs |   84 +
 ...deactivate_a_client_with_upcoming_jobs_spex.exs |  114 ++
 ..._delete_of_a_client_with_upcoming_jobs_spex.exs |  113 ++
 ..._weekly_plan_generates_the_full_series_spex.exs |  110 ++
 ...lict_on_a_later_occurrence_is_detected_spex.exs |  135 ++
 ...48_clean_series_saves_without_warnings_spex.exs |  114 ++
 ...a_cleaner_within_their_available_hours_spex.exs |  122 ++
 ...ock_assignment_during_a_time-off_block_spex.exs |  143 ++
 ...51_block_an_overlapping_double-booking_spex.exs |  125 ++
 ...eviews_conflicting_dates_before_saving_spex.exs |  132 ++
 ...on_7167_see_the_whole_week_at_a_glance_spex.exs |   93 +
 ...7170_reassign_a_job_to_another_cleaner_spex.exs |   87 +
 ...ck_reassigning_onto_a_conflicting_slot_spex.exs |   95 +
 ...patch_an_unassigned_job_from_the_board_spex.exs |   87 +
 ...signment_reaches_the_cleaners_schedule_spex.exs |   90 +
 ...ion_7112_owner_builds_a_per-room_quote_spex.exs |   53 +
 ...g_model_clears_the_other_models_inputs_spex.exs |   56 +
 ...foot_total_computes_from_the_rate_card_spex.exs |   53 +
 ...one_lead_without_visiting_the_property_spex.exs |   70 +
 ..._on_the_chosen_model_blocks_finalizing_spex.exs |   53 +
 ...e_does_not_alter_an_already-sent_quote_spex.exs |   68 +
 ...completing_a_job_generates_its_invoice_spex.exs |   60 +
 ...rion_7154_auto-charge_the_card_on_file_spex.exs |   70 +
 ..._no_card_on_file_pays_via_payment_link_spex.exs |   71 +
 ...6_invoice_shows_the_jobs_proof-of-work_spex.exs |   50 +
 ...n_7157_card-on-file_charge_is_declined_spex.exs |   79 +
 ...e_marked_paid_on_provider_confirmation_spex.exs |   74 +
 ...nder_fires_at_the_configured_lead_time_spex.exs |   75 +
 ...t_who_prefers_sms_gets_a_text_reminder_spex.exs |   80 +
 ...ncludes_confirm_and_reschedule_actions_spex.exs |   73 +
 ...n_7187_client_confirms_the_appointment_spex.exs |   58 +
 ...rion_7188_client_requests_a_reschedule_spex.exs |   59 +
 ..._undeliverable_and_falls_back_to_email_spex.exs |   82 +
 ...r_clocks_in_and_out_of_an_assigned_job_spex.exs |   79 +
 ...clock_in_on_a_job_not_assigned_to_them_spex.exs |   75 +
 ...ourly_job_pays_rate_times_worked_hours_spex.exs |   71 +
 ...pays_a_fixed_amount_regardless_of_time_spex.exs |   70 +
 ...y-period_total_builds_as_jobs_complete_spex.exs |   95 +
 ..._exports_a_completed_pay_period_to_csv_spex.exs |  125 ++
 ...rion_7137_cleaner_forgets_to_clock_out_spex.exs |  120 ++
 ...while_an_unresolved_time_entry_remains_spex.exs |   83 +
 ...s_a_job_with_a_fully_checked_checklist_spex.exs |   81 +
 ...complete_with_unchecked_required_tasks_spex.exs |   85 +
 ..._after_photos_attached_with_timestamps_spex.exs |  107 ++
 ...168_completed_job_gets_a_quality_score_spex.exs |   49 +
 ...reviews_a_cleaners_scorecard_over_time_spex.exs |   62 +
 ...ls_up_job_proof_to_answer_a_chargeback_spex.exs |   50 +
 ...en_offline_uploads_when_signal_returns_spex.exs |   97 ++
 ...aff_reschedules_a_job_and_it_is_logged_spex.exs |  109 ++
 ...price_change_records_old_and_new_value_spex.exs |   88 +
 ...ody_can_alter_or_delete_an_audit_entry_spex.exs |   92 +
 ...ters_the_trail_to_find_who_moved_a_job_spex.exs |   93 +
 ...generation_is_attributed_to_the_system_spex.exs |  113 ++
 ...r_sees_todays_jobs_in_start-time_order_spex.exs |  119 ++
 ...27_another_cleaners_jobs_are_not_shown_spex.exs |   92 +
 ...ess_code_appears_on_the_day_of_the_job_spex.exs |   90 +
 ..._code_stays_hidden_before_the_job_date_spex.exs |   97 ++
 ...d_shows_the_full_get-in-the-door_brief_spex.exs |  112 ++
 ...ional_detail_shows_a_clear_placeholder_spex.exs |   93 +
 ...lockbox_code_propagates_to_future_jobs_spex.exs |  135 ++
 ..._7145_day_off_shows_an_empty-day_state_spex.exs |   58 +
 ...n_7159_checklist_opens_grouped_by_room_spex.exs |   99 ++
 ...-of-scope_task_is_not_on_the_checklist_spex.exs |   63 +
 ..._7162_checking_tasks_advances_progress_spex.exs |   67 +
 ...fore_and_after_photos_attach_to_a_task_spex.exs |   81 +
 ...letes_when_all_required_items_are_done_spex.exs |   70 +
 ...blocked_with_a_required_task_unchecked_spex.exs |   75 +
 ...en_offline_uploads_when_signal_returns_spex.exs |   93 +
 ...on_7190_moved_job_notifies_the_cleaner_spex.exs |   69 +
 ...191_cancelled_job_notifies_the_cleaner_spex.exs |   66 +
 ...cknowledging_clears_the_pending_change_spex.exs |   87 +
 ..._unacknowledged_change_keeps_prompting_spex.exs |   79 +
 ...7_office_sees_who_has_not_acknowledged_spex.exs |  104 ++
 ...acknowledged_same-day_change_escalates_spex.exs |   98 ++
 ...on_7203_push_failure_falls_back_to_sms_spex.exs |   87 +
 ...leaner_clocks_in_to_their_assigned_job_spex.exs |   63 +
 ...k_in_to_a_job_assigned_to_someone_else_spex.exs |   71 +
 ..._a_second_job_while_already_clocked_in_spex.exs |   85 +
 ...lock_out_then_clock_in_to_the_next_job_spex.exs |   91 +
 ...ob_earnings_computed_from_clocked_time_spex.exs |   76 +
 ...rate_job_shows_its_fixed_rate_up_front_spex.exs |   64 +
 ...ay-period_total_grows_as_jobs_complete_spex.exs |   80 +
 ..._drive-time_policy_with_their_earnings_spex.exs |   50 +
 ...es_a_damage_report_from_the_job_screen_spex.exs |   80 +
 ..._filing_time_and_cleaner_automatically_spex.exs |   89 +
 ...180_submitted_report_cannot_be_altered_spex.exs |   88 +
 ...mage_report_without_a_photo_is_blocked_spex.exs |   73 +
 ...on_report_can_be_filed_without_a_photo_spex.exs |   71 +
 ...ice_is_notified_when_a_report_is_filed_spex.exs |   78 +
 ..._preferred_cleaner_on_a_recurring_plan_spex.exs |  128 ++
 ..._pre-assigned_to_the_preferred_cleaner_spex.exs |  130 ++
 ...igning_away_from_the_preferred_cleaner_spex.exs |  143 ++
 ...ves_the_plans_preferred_cleaner_intact_spex.exs |  144 ++
 ...when_the_plan_has_no_preferred_cleaner_spex.exs |  143 ++
 ...nts_shows_a_price_with_no_contact_info_spex.exs |   52 +
 ..._square_footage_instead_of_room_counts_spex.exs |   45 +
 ...ng_any_input_recomputes_the_total_live_spex.exs |   56 +
 ...equency_applies_the_recurring_discount_spex.exs |   61 +
 ...ng_add-ons_increases_the_running_total_spex.exs |   57 +
 ...ows_a_message_instead_of_a_wrong_price_spex.exs |   55 +
 ...ice_matches_the_later_acceptance_total_spex.exs |   60 +
 ...ts_an_open_slot_and_proceeds_to_review_spex.exs |   51 +
 ...ecomes_unavailable_before_confirmation_spex.exs |   64 +
 ..._cancellation_policy_before_confirming_spex.exs |   55 +
 ..._without_cancellation_policy_agreement_spex.exs |   54 +
 ..._a_valid_card_and_the_booking_confirms_spex.exs |   77 +
 ...7234_payment_gateway_declines_the_card_spex.exs |   77 +
 ...authorized_for_the_exact_quoted_amount_spex.exs |   71 +
 ...client_and_business_with_portal_access_spex.exs |   87 +
 ...pens_the_portal_via_a_valid_magic_link_spex.exs |   44 +
 ...ed_or_invalid_magic_link_denies_access_spex.exs |   45 +
 ...s_the_assigned_cleaners_name_and_photo_spex.exs |   52 +
 ...e_cleaner_updates_what_the_client_sees_spex.exs |   80 +
 ...ned_upcoming_visit_shows_a_placeholder_spex.exs |   48 +
 ...shows_checklist_and_beforeafter_photos_spex.exs |   53 +
 ...-of-work_matches_the_invoices_evidence_spex.exs |   68 +
 ...nt_reschedules_a_visit_from_the_portal_spex.exs |   61 +
 ...ncellation_shows_fee_before_confirming_spex.exs |   71 +
 ...n_7224_on-time_cancellation_has_no_fee_spex.exs |   79 +
 ...reschedule_notifies_office_and_cleaner_spex.exs |   96 +
 ...6_reschedule_preserves_price_and_scope_spex.exs |   76 +
 ...n_7227_cannot_modify_a_completed_visit_spex.exs |   48 +
 ...y_cancellation_charges_the_maximum_fee_spex.exs |   80 +
 ...iterion_7237_client_views_invoice_list_spex.exs |   95 +
 ...client_pays_an_invoice_with_a_new_card_spex.exs |   74 +
 ...ce_marked_paid_on_webhook_confirmation_spex.exs |   72 +
 ...40_declined_card_leaves_invoice_unpaid_spex.exs |   75 +
 ...erion_7241_client_saves_a_card_on_file_spex.exs |   63 +
 ...rion_7242_client_adds_a_tip_at_payment_spex.exs |   84 +
 ...erion_7243_client_pays_without_tipping_spex.exs |   88 +
 ..._7244_thank-you_sent_on_job_completion_spex.exs |   62 +
 ...view_request_sent_24h_after_completion_spex.exs |   66 +
 ...erion_7246_no_duplicate_review_request_spex.exs |   50 +
 ...ion_7247_high_rating_routes_to_publish_spex.exs |   57 +
 ...low_rating_routes_to_private_complaint_spex.exs |   59 +
 ..._7249_owner_receives_private_complaint_spex.exs |   73 +
 ..._no_review_prompt_for_incomplete_visit_spex.exs |   52 +
 test/support/cleaner_crm_spex.ex                   |    3 +
 test/support/cleaner_crm_spex_case.ex              |   29 +
 test/support/cleaner_crm_test_boundary.ex          |    3 +
 test/support/conn_case.ex                          |   79 +
 test/support/data_case.ex                          |   58 +
 test/support/feature_case.ex                       |   32 +
 test/support/fixtures/cleaner_crm_spex_fixtures.ex |  460 +++++
 test/support/fixtures/clients_fixtures.ex          |   29 +
 test/support/fixtures/files/test_photo.png         |  Bin 0 -> 68 bytes
 test/support/fixtures/journey_fixtures.ex          |  138 ++
 test/support/fixtures/scheduling_fixtures.ex       |   66 +
 test/support/fixtures/users_fixtures.ex            |  104 ++
 test/support/shared_givens.ex                      |   47 +
 test/test_helper.exs                               |    5 +
 1404 files changed, 103875 insertions(+)
## 5a1f1bf - Add role-aware app shell, navigation, and real landing page

Date: 2026-07-09 10:48:51 -0400

Replace the stock Phoenix header and welcome page with a product shell:

- Owner/admin nav: Schedule, Clients, Quotes, Invoices, Timesheets,
  Quality, Reviews direct links; More (Reminders, Audit) and Settings
  (Rate card, Booking policy, Accounts, Integrations, User settings)
  dropdowns; Field view link; user menu. Collapses to a hamburger
  below lg.
- Cleaner nav: My Day plus the user menu — no office links.
- Landing page (/): instant-quote CTA, client-portal and business
  log-in links, "Go to app" when signed in (office -> /schedule,
  cleaner -> /field).
- Portal pages get a minimal portal nav; public/token pages (booking,
  reviews, payment, reminder confirm) get a branding-only header.
- Remove every phoenixframework.org link and stock page.

266 tests, 143 BDD specs green.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01NTAk369erSweBXFki6AtiC



 lib/cleaner_crm_web/components/layouts.ex          | 217 +++++++++++++++++---
 .../components/layouts/root.html.heex              |  22 +-
 .../controllers/page_html/home.html.heex           | 227 +++------------------
 .../controllers/payment_html/declined.html.heex    |   2 +-
 .../controllers/payment_html/not_found.html.heex   |   2 +-
 .../controllers/payment_html/paid.html.heex        |   2 +-
 .../controllers/payment_html/show.html.heex        |   2 +-
 .../controllers/portal_html/invalid.html.heex      |  16 +-
 .../controllers/reminder_html/confirm.html.heex    |  10 +-
 .../controllers/reminder_html/not_found.html.heex  |  10 +-
 .../controllers/reminder_html/reschedule.html.heex |  10 +-
 lib/cleaner_crm_web/live/booking_live/accept.ex    |   2 +-
 lib/cleaner_crm_web/live/booking_live/quote.ex     |   2 +-
 lib/cleaner_crm_web/live/portal_live/home.ex       |   2 +-
 lib/cleaner_crm_web/live/portal_live/invoices.ex   |   2 +-
 lib/cleaner_crm_web/live/portal_live/visit.ex      |   2 +-
 lib/cleaner_crm_web/live/review_live/public.ex     |   2 +-
 test/cleaner_crm_web/components/layouts_test.exs   |  55 +++++
 .../controllers/page_controller_test.exs           |  22 +-
 .../controllers/user_session_controller_test.exs   |  18 +-
 test/support/fixtures/journey_fixtures.ex          |   9 +-
 21 files changed, 352 insertions(+), 284 deletions(-)
## 91f804e - Add UAT deployment: Kamal + GHA + SSM-bootstrap secrets

Date: 2026-07-09 11:27:48 -0400

Fleet-standard deploy pattern (see the devops repo):
- Dockerfile: two-stage multi-arch release image (amd64 prod box,
  arm64 UAT box), tailwind/esbuild via hex, no npm.
- GitHub Actions build.yml: matrix build -> ghcr.io/johns10/cleaner_crm
  multi-arch manifest.
- Kamal config: deploy.yml (prod placeholder) + deploy.uat.yml
  (crm-uat.desertfirstcleaning.com on the Nuremberg box, db_net,
  kamal-proxy TLS); .kamal/secrets-common carries only AWS bootstrap
  creds + registry token.
- SSM-bootstrap secrets: CleanerCrm.Secrets.load!/1 pulls
  /cleaner_crm/<APP_ENV>/* into System env at boot, before runtime.exs
  reads config. Req-backed ExAws HTTP client (hackney 4.x in the tree
  conflicts with ExAws's default).
- CleanerCrm.Release.migrate + rel/overlays bin/server, bin/migrate.
- scripts/deploy-uat: push -> wait for GHA -> kamal deploy -d uat.
- mix.exs: prod compilers drop the dev-only :diagnostics task;
  sexy_spex scoped to test.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01NTAk369erSweBXFki6AtiC



 .code_my_spec/hex_docs/ex_aws/ExAws.Behaviour.md   |   5 ++
 .../hex_docs/ex_aws/ExAws.Config.Defaults.md       |   7 ++
 .code_my_spec/hex_docs/ex_aws/ExAws.Config.md      |  29 ++++++
 .../ex_aws/ExAws.CredentialsIni.Provider.md        |   5 ++
 .code_my_spec/hex_docs/ex_aws/ExAws.Error.md       |   3 +
 .../ex_aws/ExAws.InstanceMetaTokenProvider.md      |   3 +
 .code_my_spec/hex_docs/ex_aws/ExAws.JSON.Codec.md  |  45 ++++++++++
 .../hex_docs/ex_aws/ExAws.Operation.JSON.md        |  18 ++++
 .../hex_docs/ex_aws/ExAws.Operation.Query.md       |   8 ++
 .../hex_docs/ex_aws/ExAws.Operation.S3.md          |   3 +
 .../hex_docs/ex_aws/ExAws.Request.Hackney.md       |  10 +++
 .code_my_spec/hex_docs/ex_aws/ExAws.Request.Req.md |  10 +++
 .code_my_spec/hex_docs/ex_aws/ExAws.Request.Url.md |   7 ++
 .code_my_spec/hex_docs/ex_aws/ExAws.md             |  78 ++++++++++++++++
 .code_my_spec/hex_docs/ex_aws_ssm/ExAws.SSM.md     |  33 +++++++
 .../hex_docs/httpoison/HTTPoison.MaybeRedirect.md  |  14 +--
 .../hex_docs/httpoison/HTTPoison.Request.md        |  16 +---
 .dockerignore                                      |  15 ++++
 .github/workflows/build.yml                        | 100 +++++++++++++++++++++
 .kamal/secrets-common                              |  14 +++
 Dockerfile                                         |  71 +++++++++++++++
 config/deploy.uat.yml                              |  44 +++++++++
 config/deploy.yml                                  |  50 +++++++++++
 config/runtime.exs                                 |  13 +++
 lib/cleaner_crm/release.ex                         |  29 ++++++
 lib/cleaner_crm/secrets.ex                         | 100 +++++++++++++++++++++
 lib/cleaner_crm/secrets/req_client.ex              |  39 ++++++++
 mix.exs                                            |  12 ++-
 mix.lock                                           |  14 +--
 .../favicon-91f37b602a111216f1eef3aa337ad763.ico   | Bin 0 -> 152 bytes
 .../logo-06a11be1f2cdde2c851763d00bdd2e80.svg      |   6 ++
 .../logo-06a11be1f2cdde2c851763d00bdd2e80.svg.gz   | Bin 0 -> 1613 bytes
 priv/static/images/logo.svg.gz                     | Bin 0 -> 1613 bytes
 .../robots-9e2c81b0855bbff2baa8371bc4a78186.txt    |   5 ++
 .../robots-9e2c81b0855bbff2baa8371bc4a78186.txt.gz | Bin 0 -> 164 bytes
 priv/static/robots.txt.gz                          | Bin 0 -> 164 bytes
 rel/overlays/bin/migrate                           |   5 ++
 rel/overlays/bin/server                            |   5 ++
 scripts/deploy-uat                                 |  45 ++++++++++
 39 files changed, 837 insertions(+), 24 deletions(-)
## bab8091 - Move image to the Code-My-Spec org namespace

Date: 2026-07-09 11:40:50 -0400

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01NTAk369erSweBXFki6AtiC



 .github/workflows/build.yml | 2 +-
 config/deploy.uat.yml       | 2 +-
 config/deploy.yml           | 2 +-
 3 files changed, 3 insertions(+), 3 deletions(-)
## 8598cd5 - Dockerfile: install npm deps (html-to-image feedback widget)

Date: 2026-07-09 11:47:52 -0400

The assets pipeline does use npm — package.json/package-lock.json were
already tracked; CI failed on the missing node_modules at esbuild time.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01NTAk369erSweBXFki6AtiC



 Dockerfile | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)
## 7a8d8a6 - Kamal UAT: health-check on / (no /up route)

Date: 2026-07-09 11:58:38 -0400

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01NTAk369erSweBXFki6AtiC



 config/deploy.uat.yml | 2 ++
 1 file changed, 2 insertions(+)
## ae3e9ac - Drop app-level force_ssl — kamal-proxy owns TLS and redirects

Date: 2026-07-09 12:00:37 -0400

The in-app 301 broke kamal-proxy's plain-HTTP health probe; the edge
already redirects http->https. Fleet-consistent.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01NTAk369erSweBXFki6AtiC



 config/prod.exs | 15 ++++-----------
 1 file changed, 4 insertions(+), 11 deletions(-)
## 4520413 - Booking: friendly empty state when no business account exists

Date: 2026-07-09 12:08:26 -0400

A fresh instance (or wiped UAT DB) crashed /book with a
FunctionClauseError — public_scope resolves no account. Render an
'online quotes are not open yet' page instead.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01NTAk369erSweBXFki6AtiC



 lib/cleaner_crm_web/live/booking_live/quote.ex | 33 ++++++++++++++++++++++++--
 1 file changed, 31 insertions(+), 2 deletions(-)
## 2269dd0 - Wire Resend email delivery with configurable sender

Date: 2026-07-09 12:39:23 -0400

- runtime.exs: Swoosh.Adapters.Resend when RESEND_API_KEY is set
  (absent -> Local adapter, boots fine, mails just stay undelivered)
- Sender identity centralized in :mailer_from config (was five
  hardcoded contact@example.com from() calls), overridable via
  MAILER_FROM_NAME / MAILER_FROM_EMAIL

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01NTAk369erSweBXFki6AtiC



 config/config.exs                                  |  5 +++++
 config/runtime.exs                                 | 14 ++++++++++++++
 lib/cleaner_crm/billing/receipt_notifier.ex        |  2 +-
 lib/cleaner_crm/booking/notifier.ex                |  2 +-
 lib/cleaner_crm/notifications/reminder_notifier.ex |  2 +-
 lib/cleaner_crm/reviews/review_notifier.ex         |  4 ++--
 lib/cleaner_crm/users/user_notifier.ex             |  2 +-
 7 files changed, 25 insertions(+), 6 deletions(-)
## db7f478 - Fix fresh-signup onboarding and booking error UX

Date: 2026-07-09 12:53:57 -0400

Found by live UAT testing:
- New RequireAccount on_mount hook: an account-less user (fresh
  signup) crashed /field and /schedule with FunctionClauseError —
  every scoped query guards on active_account_id. Now funneled to
  /accounts/new ("Create your company to get started"); office
  live_session runs it before RequireOfficeRole. signed_in_home
  sends account-less users there too.
- Booking confirm no longer mislabels every failure as "that time
  was just booked by someone else": payment/system errors get an
  honest message and a logged reason. (UAT's actual failure was
  Stripe not_configured.)
- STRIPE_ADAPTER=test runtime switch selects the no-network fake
  gateway — seeded on UAT until real Stripe test keys exist.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01NTAk369erSweBXFki6AtiC



 config/runtime.exs                              |  8 +++++++
 lib/cleaner_crm_web/components/layouts.ex       |  6 +++--
 lib/cleaner_crm_web/live/booking_live/accept.ex | 21 +++++++++++++++--
 lib/cleaner_crm_web/require_account.ex          | 30 +++++++++++++++++++++++++
 lib/cleaner_crm_web/router.ex                   | 14 +++++++++++-
 5 files changed, 74 insertions(+), 5 deletions(-)
## 5b0e657 - Stripe Live: card-only automatic_payment_methods on confirm

Date: 2026-07-09 13:15:57 -0400

Real test-mode Stripe rejects server-side confirm without a return_url
unless redirect-based methods are disabled. Found on UAT sandbox.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01NTAk369erSweBXFki6AtiC



 lib/cleaner_crm/billing/stripe_gateway/live.ex | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)
## ee89221 - Move authenticated app behind /app with drawer+sidebar shell

Date: 2026-07-09 16:07:34 -0400

Mirrors get_ai_traffic's structure: one /app scope with three
live_sessions (authenticated: settings/accounts/integrations;
account-gated: field; office-gated: everything else), and a DaisyUI
drawer + sidebar app layout (mobile hamburger, account breadcrumb to
the picker, role-aware nav, settings group, email + logout footer).
Public, portal, token, webhook, and OAuth-callback routes stay at the
root — the office review inbox at /app/reviews no longer collides
with public /reviews/:token.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01NTAk369erSweBXFki6AtiC



 lib/cleaner_crm/users.ex                           |   2 +-
 lib/cleaner_crm_web/components/layouts.ex          | 304 ++++++++++++---------
 .../controllers/integrations_controller.ex         |  10 +-
 .../controllers/timesheet_export_controller.ex     |   4 +-
 .../controllers/user_session_controller.ex         |   2 +-
 lib/cleaner_crm_web/date_param.ex                  |   2 +-
 .../account_live/components/accounts_breadcrumb.ex |   2 +-
 .../live/account_live/components/navigation.ex     |   6 +-
 lib/cleaner_crm_web/live/account_live/form.ex      |   4 +-
 lib/cleaner_crm_web/live/account_live/index.ex     |   4 +-
 .../live/account_live/invitations.ex               |   2 +-
 lib/cleaner_crm_web/live/account_live/manage.ex    |   4 +-
 lib/cleaner_crm_web/live/account_live/members.ex   |   2 +-
 lib/cleaner_crm_web/live/account_live/picker.ex    |   2 +-
 lib/cleaner_crm_web/live/audit_live.ex             |   2 +-
 .../live/client_live/form_component.ex             |   4 +-
 lib/cleaner_crm_web/live/client_live/index.ex      |   4 +-
 .../live/client_live/property_form_component.ex    |   2 +-
 lib/cleaner_crm_web/live/client_live/show.ex       |  22 +-
 lib/cleaner_crm_web/live/field_live/job.ex         |   6 +-
 lib/cleaner_crm_web/live/field_live/today.ex       |   4 +-
 lib/cleaner_crm_web/live/invoice_live/index.ex     |   2 +-
 lib/cleaner_crm_web/live/quality_live/review.ex    |  10 +-
 .../live/quality_live/scorecards.ex                |   4 +-
 .../live/quality_live/template_form_component.ex   |   4 +-
 lib/cleaner_crm_web/live/quality_live/templates.ex |  10 +-
 lib/cleaner_crm_web/live/quote_live/builder.ex     |   8 +-
 lib/cleaner_crm_web/live/quote_live/index.ex       |   8 +-
 lib/cleaner_crm_web/live/quote_live/rate_card.ex   |   6 +-
 lib/cleaner_crm_web/live/reminder_live.ex          |   2 +-
 lib/cleaner_crm_web/live/review_live/index.ex      |   2 +-
 .../live/schedule_live/availability_live.ex        |   2 +-
 .../live/schedule_live/cleaner_live.ex             |   4 +-
 lib/cleaner_crm_web/live/schedule_live/index.ex    |   2 +-
 .../live/schedule_live/job_form_component.ex       |   2 +-
 .../live/settings_live/booking_policy.ex           |   2 +-
 lib/cleaner_crm_web/live/timesheet_live.ex         |   4 +-
 lib/cleaner_crm_web/live/user_live/settings.ex     |   4 +-
 lib/cleaner_crm_web/require_account.ex             |   4 +-
 lib/cleaner_crm_web/require_office_role.ex         |   8 +-
 lib/cleaner_crm_web/router.ex                      |  60 ++--
 lib/cleaner_crm_web/user_auth.ex                   |   2 +-
 test/cleaner_crm_web/components/layouts_test.exs   |  10 +-
 .../controllers/page_controller_test.exs           |   2 +-
 .../controllers/user_session_controller_test.exs   |  12 +-
 .../live/field_live/checklist_component_test.exs   |   2 +-
 .../live/quality_live/templates_test.exs           |  15 +-
 .../live/quote_live/rate_card_test.exs             |  10 +-
 .../live/review_live/index_test.exs                |   2 +-
 .../live/settings_live/booking_policy_test.exs     |   8 +-
 .../live/user_live/settings_test.exs               |  34 +--
 test/cleaner_crm_web/user_auth_test.exs            |   2 +-
 test/journeys/cleaner_day_test.exs                 |  14 +-
 test/journeys/new_client_to_paid_invoice_test.exs  |  14 +-
 test/journeys/payroll_close_test.exs               |   4 +-
 .../journeys/preferred_cleaner_continuity_test.exs |   8 +-
 test/journeys/schedule_chaos_test.exs              |  12 +-
 ...dd_a_property_under_an_existing_client_spex.exs |   6 +-
 ..._7108_reject_a_property_with_no_client_spex.exs |   2 +-
 ..._property_with_a_valid_service_address_spex.exs |   6 +-
 ...reject_a_property_with_a_blank_address_spex.exs |   6 +-
 ...brief_inherits_property_access_details_spex.exs |  10 +-
 ...updated_code_propagates_to_future_jobs_spex.exs |  16 +-
 ...erion_7115_entry_code_change_is_logged_spex.exs |  10 +-
 ...deactivate_a_client_with_upcoming_jobs_spex.exs |  12 +-
 ..._delete_of_a_client_with_upcoming_jobs_spex.exs |  12 +-
 ..._weekly_plan_generates_the_full_series_spex.exs |  12 +-
 ...lict_on_a_later_occurrence_is_detected_spex.exs |  12 +-
 ...48_clean_series_saves_without_warnings_spex.exs |  14 +-
 ...a_cleaner_within_their_available_hours_spex.exs |  14 +-
 ...ock_assignment_during_a_time-off_block_spex.exs |  14 +-
 ...51_block_an_overlapping_double-booking_spex.exs |  12 +-
 ...eviews_conflicting_dates_before_saving_spex.exs |  12 +-
 ...on_7167_see_the_whole_week_at_a_glance_spex.exs |   4 +-
 ...7170_reassign_a_job_to_another_cleaner_spex.exs |   2 +-
 ...ck_reassigning_onto_a_conflicting_slot_spex.exs |   2 +-
 ...patch_an_unassigned_job_from_the_board_spex.exs |   2 +-
 ...signment_reaches_the_cleaners_schedule_spex.exs |   8 +-
 ...ion_7112_owner_builds_a_per-room_quote_spex.exs |   2 +-
 ...g_model_clears_the_other_models_inputs_spex.exs |   2 +-
 ...foot_total_computes_from_the_rate_card_spex.exs |   2 +-
 ...one_lead_without_visiting_the_property_spex.exs |   2 +-
 ..._on_the_chosen_model_blocks_finalizing_spex.exs |   2 +-
 ...e_does_not_alter_an_already-sent_quote_spex.exs |   4 +-
 ...completing_a_job_generates_its_invoice_spex.exs |   4 +-
 ...rion_7154_auto-charge_the_card_on_file_spex.exs |   2 +-
 ..._no_card_on_file_pays_via_payment_link_spex.exs |   2 +-
 ...6_invoice_shows_the_jobs_proof-of-work_spex.exs |   2 +-
 ...n_7157_card-on-file_charge_is_declined_spex.exs |   4 +-
 ...e_marked_paid_on_provider_confirmation_spex.exs |   4 +-
 ...nder_fires_at_the_configured_lead_time_spex.exs |   2 +-
 ...t_who_prefers_sms_gets_a_text_reminder_spex.exs |   4 +-
 ...ncludes_confirm_and_reschedule_actions_spex.exs |   2 +-
 ...n_7187_client_confirms_the_appointment_spex.exs |   2 +-
 ...rion_7188_client_requests_a_reschedule_spex.exs |   2 +-
 ..._undeliverable_and_falls_back_to_email_spex.exs |   2 +-
 ...r_clocks_in_and_out_of_an_assigned_job_spex.exs |   2 +-
 ...clock_in_on_a_job_not_assigned_to_them_spex.exs |   6 +-
 ...ourly_job_pays_rate_times_worked_hours_spex.exs |   2 +-
 ...pays_a_fixed_amount_regardless_of_time_spex.exs |   2 +-
 ...y-period_total_builds_as_jobs_complete_spex.exs |   4 +-
 ..._exports_a_completed_pay_period_to_csv_spex.exs |   2 +-
 ...rion_7137_cleaner_forgets_to_clock_out_spex.exs |  10 +-
 ...while_an_unresolved_time_entry_remains_spex.exs |   4 +-
 ...s_a_job_with_a_fully_checked_checklist_spex.exs |   4 +-
 ...complete_with_unchecked_required_tasks_spex.exs |   2 +-
 ..._after_photos_attached_with_timestamps_spex.exs |   4 +-
 ...168_completed_job_gets_a_quality_score_spex.exs |   2 +-
 ...reviews_a_cleaners_scorecard_over_time_spex.exs |   2 +-
 ...ls_up_job_proof_to_answer_a_chargeback_spex.exs |   2 +-
 ...en_offline_uploads_when_signal_returns_spex.exs |   2 +-
 ...aff_reschedules_a_job_and_it_is_logged_spex.exs |  10 +-
 ...price_change_records_old_and_new_value_spex.exs |  10 +-
 ...ody_can_alter_or_delete_an_audit_entry_spex.exs |   8 +-
 ...ters_the_trail_to_find_who_moved_a_job_spex.exs |   8 +-
 ...generation_is_attributed_to_the_system_spex.exs |  14 +-
 ...r_sees_todays_jobs_in_start-time_order_spex.exs |   8 +-
 ...27_another_cleaners_jobs_are_not_shown_spex.exs |   8 +-
 ...ess_code_appears_on_the_day_of_the_job_spex.exs |   8 +-
 ..._code_stays_hidden_before_the_job_date_spex.exs |   8 +-
 ...d_shows_the_full_get-in-the-door_brief_spex.exs |   8 +-
 ...ional_detail_shows_a_clear_placeholder_spex.exs |   8 +-
 ...lockbox_code_propagates_to_future_jobs_spex.exs |  15 +-
 ..._7145_day_off_shows_an_empty-day_state_spex.exs |   2 +-
 ...n_7159_checklist_opens_grouped_by_room_spex.exs |   2 +-
 ...-of-scope_task_is_not_on_the_checklist_spex.exs |   2 +-
 ..._7162_checking_tasks_advances_progress_spex.exs |   2 +-
 ...fore_and_after_photos_attach_to_a_task_spex.exs |   2 +-
 ...letes_when_all_required_items_are_done_spex.exs |   2 +-
 ...blocked_with_a_required_task_unchecked_spex.exs |   2 +-
 ...en_offline_uploads_when_signal_returns_spex.exs |   2 +-
 ...on_7190_moved_job_notifies_the_cleaner_spex.exs |   4 +-
 ...191_cancelled_job_notifies_the_cleaner_spex.exs |   4 +-
 ...cknowledging_clears_the_pending_change_spex.exs |   4 +-
 ..._unacknowledged_change_keeps_prompting_spex.exs |   6 +-
 ...7_office_sees_who_has_not_acknowledged_spex.exs |   6 +-
 ...acknowledged_same-day_change_escalates_spex.exs |   2 +-
 ...on_7203_push_failure_falls_back_to_sms_spex.exs |   4 +-
 ...leaner_clocks_in_to_their_assigned_job_spex.exs |   2 +-
 ...k_in_to_a_job_assigned_to_someone_else_spex.exs |   4 +-
 ..._a_second_job_while_already_clocked_in_spex.exs |   5 +-
 ...lock_out_then_clock_in_to_the_next_job_spex.exs |   5 +-
 ...ob_earnings_computed_from_clocked_time_spex.exs |   2 +-
 ...rate_job_shows_its_fixed_rate_up_front_spex.exs |   2 +-
 ...ay-period_total_grows_as_jobs_complete_spex.exs |   2 +-
 ..._drive-time_policy_with_their_earnings_spex.exs |   2 +-
 ...es_a_damage_report_from_the_job_screen_spex.exs |   4 +-
 ..._filing_time_and_cleaner_automatically_spex.exs |   4 +-
 ...180_submitted_report_cannot_be_altered_spex.exs |   6 +-
 ...mage_report_without_a_photo_is_blocked_spex.exs |   4 +-
 ...on_report_can_be_filed_without_a_photo_spex.exs |   4 +-
 ...ice_is_notified_when_a_report_is_filed_spex.exs |   4 +-
 ..._preferred_cleaner_on_a_recurring_plan_spex.exs |  14 +-
 ..._pre-assigned_to_the_preferred_cleaner_spex.exs |  14 +-
 ...igning_away_from_the_preferred_cleaner_spex.exs |  16 +-
 ...ves_the_plans_preferred_cleaner_intact_spex.exs |  16 +-
 ...when_the_plan_has_no_preferred_cleaner_spex.exs |  18 +-
 ...client_and_business_with_portal_access_spex.exs |   2 +-
 ...e_cleaner_updates_what_the_client_sees_spex.exs |   2 +-
 ...-of-work_matches_the_invoices_evidence_spex.exs |   2 +-
 ...reschedule_notifies_office_and_cleaner_spex.exs |   4 +-
 ...rion_7242_client_adds_a_tip_at_payment_spex.exs |   4 +-
 ...erion_7243_client_pays_without_tipping_spex.exs |   2 +-
 ..._7244_thank-you_sent_on_job_completion_spex.exs |   2 +-
 ...view_request_sent_24h_after_completion_spex.exs |   2 +-
 ..._7249_owner_receives_private_complaint_spex.exs |   4 +-
 166 files changed, 672 insertions(+), 616 deletions(-)
## aef6820 - UAT feedback batch: storefront account, quote bounds, price floor, email format, portal request-link

Date: 2026-07-09 18:03:22 -0400

- /book now prices against an explicitly designated storefront account
  (accounts.storefront flag, owner toggle on /app/settings/booking,
  transactionally exclusive) — falls back to the only account when
  exactly one exists, else the unavailable page. Fixes the live
  regression where any new signup's empty company silently stole the
  public funnel.
- Quote inputs bounded (bedrooms/bathrooms 0-20, sqft 200-20,000,
  hours 1-12) and the calculator hides price/contact until valid.
- Rate card gains an owner-set minimum visit price that floors every
  quote ("Includes our minimum visit price.").
- Lead emails validated with the same format rule as user emails.
- New public /portal/request-link: clients get a fresh magic link by
  email (per-client 60s cooldown, no account enumeration); /portal
  without a session and expired-link pages route there.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01NTAk369erSweBXFki6AtiC



 lib/cleaner_crm/accounts.ex                        |  27 ++++
 lib/cleaner_crm/accounts/account.ex                |  10 ++
 lib/cleaner_crm/accounts/accounts_repository.ex    |  12 ++
 lib/cleaner_crm/authorization.ex                   |   8 ++
 lib/cleaner_crm/booking.ex                         |  46 +++++--
 lib/cleaner_crm/booking/lead.ex                    |  19 ++-
 lib/cleaner_crm/booking/pricing.ex                 |  19 ++-
 lib/cleaner_crm/portal.ex                          |  58 ++++++++-
 lib/cleaner_crm/portal/notifier.ex                 |  41 ++++++
 lib/cleaner_crm/quoting/rate_card.ex               |  10 +-
 .../controllers/portal_html/invalid.html.heex      |   2 +-
 lib/cleaner_crm_web/live/booking_live/quote.ex     |  18 ++-
 .../live/portal_live/request_link.ex               |  69 ++++++++++
 lib/cleaner_crm_web/live/quote_live/rate_card.ex   |  21 +++-
 .../live/settings_live/booking_policy.ex           |  68 ++++++++++
 lib/cleaner_crm_web/portal_auth.ex                 |   7 +-
 lib/cleaner_crm_web/router.ex                      |  11 ++
 .../20260709200010_add_storefront_to_accounts.exs  |  18 +++
 ...00020_add_minimum_visit_cents_to_rate_cards.exs |   9 ++
 test/cleaner_crm/booking/lead_test.exs             | 104 +++++++++++++++
 test/cleaner_crm/booking/pricing_test.exs          |  62 +++++++++
 test/cleaner_crm/booking_test.exs                  |  70 +++++++++++
 test/cleaner_crm/portal_test.exs                   |  54 ++++++++
 .../live/booking_live/quote_test.exs               | 140 +++++++++++++++++++++
 .../cleaner_crm_web/live/portal_live/home_test.exs |   4 +-
 .../live/portal_live/request_link_test.exs         |  49 ++++++++
 .../live/quote_live/rate_card_test.exs             |  35 ++++++
 .../live/settings_live/booking_policy_test.exs     |  60 +++++++++
 28 files changed, 1022 insertions(+), 29 deletions(-)
## a38637d - Real Stripe Elements card capture on booking acceptance

Date: 2026-07-09 18:29:33 -0400

With STRIPE_PUBLISHABLE_KEY configured (UAT/prod), the accept page now
mounts a real Stripe Payment Element: the server creates an
unconfirmed PaymentIntent, the client confirms it in the browser, the
signed webhook converts the lead, and a 3s status poll flips the page
live to confirmed/declined. Dev/test (key nil) keep the synchronous
hidden-test-card flow so the BDD suite exercises the same booking
logic unchanged.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01NTAk369erSweBXFki6AtiC



 config/runtime.exs                                 |   9 +
 lib/cleaner_crm/billing/stripe_gateway.ex          |  15 +-
 lib/cleaner_crm/billing/stripe_gateway/live.ex     |  31 ++--
 lib/cleaner_crm/billing/stripe_gateway/test.ex     |   3 +-
 lib/cleaner_crm/booking.ex                         |  93 ++++++++---
 lib/cleaner_crm_web/live/booking_live/accept.ex    | 183 ++++++++++++++++++++-
 test/cleaner_crm/billing/stripe_gateway_test.exs   |  41 +++++
 test/cleaner_crm/booking_test.exs                  |  46 ++++++
 .../live/booking_live/accept_test.exs              |  74 +++++++++
 9 files changed, 448 insertions(+), 47 deletions(-)
## a14c33a - Cassette-backed tests for the real Stripe path + webhook replay guard

Date: 2026-07-09 21:08:57 -0400

The Live gateway had zero coverage — its first real-API bug shipped
to UAT undetected. Now: ReqCassette recordings of real test-mode
Stripe responses (confirmed charge, unconfirmed Elements intent,
declined card, param error — auth headers filtered) replayed offline
through a test-only req-options seam; webhook signature tests; a
Booking.confirm_booking run through the Live adapter; and Elements
render coverage for both publishable-key branches.

Found by that work and fixed here: verify_webhook_event accepted any
correctly-signed payload regardless of age — now rejects outside
Stripe's recommended 5-minute tolerance, closing the replay window.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01NTAk369erSweBXFki6AtiC



 .code_my_spec/hex_docs/req/Req.Steps.md            | 120 +---
 .code_my_spec/hex_docs/req/Req.Tar.md              |  12 -
 .code_my_spec/hex_docs/req/Req.ZIP.md              |   9 -
 .../req_cassette/Mix.Tasks.ReqCassette.Inspect.md  |  39 ++
 .../hex_docs/req_cassette/ReqCassette.BodyType.md  | 221 +++++++
 .../hex_docs/req_cassette/ReqCassette.Cassette.md  | 451 +++++++++++++
 .../hex_docs/req_cassette/ReqCassette.Filter.md    | 408 ++++++++++++
 .../hex_docs/req_cassette/ReqCassette.Plug.md      | 401 ++++++++++++
 .../hex_docs/req_cassette/ReqCassette.Session.md   | 105 +++
 .../req_cassette/ReqCassette.Template.Debug.md     | 148 +++++
 .../req_cassette/ReqCassette.Template.Escape.md    | 148 +++++
 .../req_cassette/ReqCassette.Template.Extractor.md | 186 ++++++
 .../req_cassette/ReqCassette.Template.Matcher.md   |  88 +++
 .../ReqCassette.Template.Normalizer.md             | 184 ++++++
 .../req_cassette/ReqCassette.Template.Presets.md   | 105 +++
 .../req_cassette/ReqCassette.Template.Replacer.md  | 241 +++++++
 .code_my_spec/hex_docs/req_cassette/ReqCassette.md | 723 +++++++++++++++++++++
 lib/cleaner_crm/billing/stripe_gateway/live.ex     |  20 +-
 mix.exs                                            |   3 +-
 mix.lock                                           |   3 +-
 .../stripe/booking_confirm_unconfirmed_intent.json | 171 +++++
 .../create_payment_intent_confirmed_success.json   | 169 +++++
 .../stripe/create_payment_intent_declined.json     | 297 +++++++++
 .../stripe/create_payment_intent_param_error.json  | 108 +++
 .../stripe/create_payment_intent_unconfirmed.json  | 169 +++++
 .../billing/booking_confirm_live_cassette_test.exs | 111 ++++
 .../billing/stripe_elements_render_test.exs        | 128 ++++
 .../billing/stripe_gateway_live_cassette_test.exs  | 148 +++++
 .../stripe_gateway_webhook_signature_test.exs      |  88 +++
 29 files changed, 4896 insertions(+), 108 deletions(-)
## 04df76c - Fix SSM boot crash under req 0.5: keep response decompression on

Date: 2026-07-09 21:16:33 -0400

req_cassette pinned req to 0.5, which requests gzip by default;
ReqClient's raw:true then skipped decompression and ExAws's JSON parse
crashed the container at boot (0x1F gzip magic byte) — caught by the
deploy health check, old container kept serving. Drop raw:true (keep
decode_body:false), thread ExAws's http_opts through so tests can
inject a plug, and pin the gzip case with a regression test — this
boot path had zero coverage.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01NTAk369erSweBXFki6AtiC



 lib/cleaner_crm/secrets/req_client.ex        | 25 ++++++++++-------
 test/cleaner_crm/secrets/req_client_test.exs | 41 ++++++++++++++++++++++++++++
 2 files changed, 56 insertions(+), 10 deletions(-)
## 0d504ec - Add Claude conversation transcripts under .code_my_spec/conversations

Date: 2026-07-10 09:29:31 -0400

Synced from ~/.claude/projects via a pre-commit hook that rsyncs and
stages the latest transcripts on every commit (memory/ excluded).

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>



 .../5c087f36-7410-4765-9540-81bde93623d1.jsonl     |    11 +
 .../b82dc084-1093-4624-b490-31c68a31a4a8.jsonl     | 12811 +++++++++++++++++++
 .../subagents/agent-a188fe2a678c6329b.jsonl        |   180 +
 .../subagents/agent-a188fe2a678c6329b.meta.json    |     1 +
 .../subagents/agent-a1922112a286f7d0a.jsonl        |    37 +
 .../subagents/agent-a1922112a286f7d0a.meta.json    |     1 +
 .../subagents/agent-a3a7c8076f61e3517.jsonl        |   136 +
 .../subagents/agent-a3a7c8076f61e3517.meta.json    |     1 +
 .../subagents/agent-a4333d335dc3ce445.jsonl        |   113 +
 .../subagents/agent-a4333d335dc3ce445.meta.json    |     1 +
 .../subagents/agent-a50a7346f46d39a31.jsonl        |   146 +
 .../subagents/agent-a50a7346f46d39a31.meta.json    |     1 +
 .../subagents/agent-a82c1cac33c7f66f2.jsonl        |    66 +
 .../subagents/agent-a82c1cac33c7f66f2.meta.json    |     1 +
 .../subagents/agent-a961fa3676f086c77.jsonl        |    50 +
 .../subagents/agent-a961fa3676f086c77.meta.json    |     1 +
 .../agent-aamigos-a-1e8ff224f7ac335f.jsonl         |   134 +
 .../agent-aamigos-a-1e8ff224f7ac335f.meta.json     |     1 +
 .../agent-aamigos-a-2-deff0365e6eab58c.jsonl       |   193 +
 .../agent-aamigos-a-2-deff0365e6eab58c.meta.json   |     1 +
 .../agent-aamigos-b-2-1fc11b4fcae96a35.jsonl       |   177 +
 .../agent-aamigos-b-2-1fc11b4fcae96a35.meta.json   |     1 +
 .../agent-aamigos-b-79696cc2f4e3f1a8.jsonl         |   125 +
 .../agent-aamigos-b-79696cc2f4e3f1a8.meta.json     |     1 +
 .../agent-aamigos-c-c3f3a63d4ec89567.jsonl         |   128 +
 .../agent-aamigos-c-c3f3a63d4ec89567.meta.json     |     1 +
 .../agent-aamigos-d-4a2f462fd8763508.jsonl         |   133 +
 .../agent-aamigos-d-4a2f462fd8763508.meta.json     |     1 +
 .../agent-aamigos-e-769f85e831e435d1.jsonl         |   132 +
 .../agent-aamigos-e-769f85e831e435d1.meta.json     |     1 +
 .../subagents/agent-abd597c3982eb8fc9.jsonl        |   174 +
 .../subagents/agent-abd597c3982eb8fc9.meta.json    |     1 +
 .../subagents/agent-ac7fd1222cea49aac.jsonl        |   148 +
 .../subagents/agent-ac7fd1222cea49aac.meta.json    |     1 +
 .../agent-acourier-837-80ec0ce67c4ad038.jsonl      |    89 +
 .../agent-acourier-837-80ec0ce67c4ad038.meta.json  |     1 +
 .../subagents/agent-ad3448906de2d5dea.jsonl        |   310 +
 .../subagents/agent-ad3448906de2d5dea.meta.json    |     1 +
 .../agent-aimpl-appshell2-1495ae192c46dbc0.jsonl   |   191 +
 ...gent-aimpl-appshell2-1495ae192c46dbc0.meta.json |     1 +
 .../agent-aimpl-audit-2ceb780439669dce.jsonl       |   241 +
 .../agent-aimpl-audit-2ceb780439669dce.meta.json   |     1 +
 .../agent-aimpl-audit2-2b1851fb8fef1e80.jsonl      |   145 +
 .../agent-aimpl-audit2-2b1851fb8fef1e80.meta.json  |     1 +
 .../agent-aimpl-authz-cedf19ee40e0a84d.jsonl       |   173 +
 .../agent-aimpl-authz-cedf19ee40e0a84d.meta.json   |     1 +
 .../agent-aimpl-billing-8552dd004bda3aba.jsonl     |   590 +
 .../agent-aimpl-billing-8552dd004bda3aba.meta.json |     1 +
 .../agent-aimpl-billing2-c865920fc69d7994.jsonl    |   286 +
 ...agent-aimpl-billing2-c865920fc69d7994.meta.json |     1 +
 .../agent-aimpl-booking-f94a10ddfc5bc04c.jsonl     |   711 +
 .../agent-aimpl-booking-f94a10ddfc5bc04c.meta.json |     1 +
 .../agent-aimpl-booking2-3054969a8be9c47f.jsonl    |   326 +
 ...agent-aimpl-booking2-3054969a8be9c47f.meta.json |     1 +
 .../agent-aimpl-booking3-0b7b21709a6f1dea.jsonl    |   380 +
 ...agent-aimpl-booking3-0b7b21709a6f1dea.meta.json |     1 +
 .../agent-aimpl-clientlive-c0e6cae0d6725fc2.jsonl  |   243 +
 ...ent-aimpl-clientlive-c0e6cae0d6725fc2.meta.json |     1 +
 .../agent-aimpl-clientlive2-f443487451989895.jsonl |   391 +
 ...nt-aimpl-clientlive2-f443487451989895.meta.json |     1 +
 .../agent-aimpl-elements-3c84e3d44a6e7d8d.jsonl    |   238 +
 ...agent-aimpl-elements-3c84e3d44a6e7d8d.meta.json |     1 +
 .../agent-aimpl-field-3a4b0b67cb3fc882.jsonl       |   597 +
 .../agent-aimpl-field-3a4b0b67cb3fc882.meta.json   |     1 +
 .../agent-aimpl-field2-3c5aa240db90c2b6.jsonl      |   112 +
 .../agent-aimpl-field2-3c5aa240db90c2b6.meta.json  |     1 +
 ...gent-aimpl-notifications-cb6bd1d81bfb34ff.jsonl |   717 ++
 ...-aimpl-notifications-cb6bd1d81bfb34ff.meta.json |     1 +
 .../agent-aimpl-portal-cf3b3307476f596a.jsonl      |   541 +
 .../agent-aimpl-portal-cf3b3307476f596a.meta.json  |     1 +
 .../agent-aimpl-portal2-aedca809e4b015df.jsonl     |    12 +
 .../agent-aimpl-portal2-aedca809e4b015df.meta.json |     1 +
 .../agent-aimpl-portal3-96fab7be36dbe918.jsonl     |   250 +
 .../agent-aimpl-portal3-96fab7be36dbe918.meta.json |     1 +
 .../agent-aimpl-portal4-8bdd0a2f77674fb7.jsonl     |   255 +
 .../agent-aimpl-portal4-8bdd0a2f77674fb7.meta.json |     1 +
 .../agent-aimpl-quality-39f5d9967cc8022a.jsonl     |   490 +
 .../agent-aimpl-quality-39f5d9967cc8022a.meta.json |     1 +
 .../agent-aimpl-quality2-e3a7cdc00a23fd62.jsonl    |   196 +
 ...agent-aimpl-quality2-e3a7cdc00a23fd62.meta.json |     1 +
 .../agent-aimpl-quality3-3ce6a0266266de07.jsonl    |   108 +
 ...agent-aimpl-quality3-3ce6a0266266de07.meta.json |     1 +
 .../agent-aimpl-quoting-6cce313924bbd975.jsonl     |   325 +
 .../agent-aimpl-quoting-6cce313924bbd975.meta.json |     1 +
 .../agent-aimpl-reviews-191498025e86094e.jsonl     |   713 ++
 .../agent-aimpl-reviews-191498025e86094e.meta.json |     1 +
 .../agent-aimpl-sched3-78f0aaba9e7827d9.jsonl      |   114 +
 .../agent-aimpl-sched3-78f0aaba9e7827d9.meta.json  |     1 +
 .../agent-aimpl-sched4-4bdf0b74be71f525.jsonl      |   144 +
 .../agent-aimpl-sched4-4bdf0b74be71f525.meta.json  |     1 +
 .../agent-aimpl-schedule2-8ce07eaba8134ebd.jsonl   |   688 +
 ...gent-aimpl-schedule2-8ce07eaba8134ebd.meta.json |     1 +
 ...agent-aimpl-schedulelive-384ac72c65293071.jsonl |   637 +
 ...t-aimpl-schedulelive-384ac72c65293071.meta.json |     1 +
 .../agent-aimpl-shell-3a7973306c56a6c2.jsonl       |   377 +
 .../agent-aimpl-shell-3a7973306c56a6c2.meta.json   |     1 +
 .../agent-aimpl-stripetest-ebeff3178bb31c0b.jsonl  |   226 +
 ...ent-aimpl-stripetest-ebeff3178bb31c0b.meta.json |     1 +
 ...agent-aimpl-timetracking-061c2838e21221f6.jsonl |   430 +
 ...t-aimpl-timetracking-061c2838e21221f6.meta.json |     1 +
 ...gent-aimpl-timetracking2-a16c474adc94723c.jsonl |   170 +
 ...-aimpl-timetracking2-a16c474adc94723c.meta.json |     1 +
 .../subagents/agent-aqa-832-88004954535a58cc.jsonl |  1189 ++
 .../agent-aqa-832-88004954535a58cc.meta.json       |     1 +
 .../agent-aqa-832b-f9a1e8caef514b28.jsonl          |   269 +
 .../agent-aqa-832b-f9a1e8caef514b28.meta.json      |     1 +
 .../agent-aqa-832c-01da024b4450c77d.jsonl          |    17 +
 .../agent-aqa-832c-01da024b4450c77d.meta.json      |     1 +
 .../subagents/agent-aqa-833-bbde8aea8590ae70.jsonl |  1244 ++
 .../agent-aqa-833-bbde8aea8590ae70.meta.json       |     1 +
 .../subagents/agent-aqa-834-f71935e7c65ad638.jsonl |   657 +
 .../agent-aqa-834-f71935e7c65ad638.meta.json       |     1 +
 .../agent-aqa-836r-4dba7ef1c71c8166.jsonl          |   497 +
 .../agent-aqa-836r-4dba7ef1c71c8166.meta.json      |     1 +
 .../agent-aqa-batch1-15f22f67d8b954f4.jsonl        |    15 +
 .../agent-aqa-batch1-15f22f67d8b954f4.meta.json    |     1 +
 .../agent-aqa-batch2-eed311ba420dc842.jsonl        |   858 ++
 .../agent-aqa-batch2-eed311ba420dc842.meta.json    |     1 +
 .../agent-aqa-batch3-e5d97a51357330be.jsonl        |  1063 ++
 .../agent-aqa-batch3-e5d97a51357330be.meta.json    |     1 +
 .../agent-aqa-batch4-40d49518d0020959.jsonl        |   510 +
 .../agent-aqa-batch4-40d49518d0020959.meta.json    |     1 +
 .../agent-aqa-batch5-a655415f5e04c607.jsonl        |   935 ++
 .../agent-aqa-batch5-a655415f5e04c607.meta.json    |     1 +
 .../agent-aqa-customer-a9b5d9123b962b06.jsonl      |  2152 ++++
 .../agent-aqa-customer-a9b5d9123b962b06.meta.json  |     1 +
 .../agent-aqa-journeys-8fa77df8a05b75f0.jsonl      |  2303 ++++
 .../agent-aqa-journeys-8fa77df8a05b75f0.meta.json  |     1 +
 .../agent-aqa-verify1-f2f6e85bed894d21.jsonl       |   113 +
 .../agent-aqa-verify1-f2f6e85bed894d21.meta.json   |     1 +
 ...agent-aresearch-customer-7d413209643f1f02.jsonl |    67 +
 ...t-aresearch-customer-7d413209643f1f02.meta.json |     1 +
 ...t-aresearch-housecallpro-29ec0258b151822d.jsonl |    32 +
 ...esearch-housecallpro-29ec0258b151822d.meta.json |     1 +
 .../agent-aresearch-jobber-e66b1f380fbb677e.jsonl  |    38 +
 ...ent-aresearch-jobber-e66b1f380fbb677e.meta.json |     1 +
 .../agent-aresearch-matally-f55e301f70b76628.jsonl |    44 +
 ...nt-aresearch-matally-f55e301f70b76628.meta.json |     1 +
 ...ent-aresearch-painpoints-1bb4163e66531c7f.jsonl |    70 +
 ...aresearch-painpoints-1bb4163e66531c7f.meta.json |     1 +
 .../agent-aspex-832-30852792fca9fe87.jsonl         |   197 +
 .../agent-aspex-832-30852792fca9fe87.meta.json     |     1 +
 .../agent-aspex-833-e8a23de9eab6ab82.jsonl         |   248 +
 .../agent-aspex-833-e8a23de9eab6ab82.meta.json     |     1 +
 .../agent-aspex-834-36d86894c453628e.jsonl         |   199 +
 .../agent-aspex-834-36d86894c453628e.meta.json     |     1 +
 .../agent-aspex-835-f9d2f84ac23c5d25.jsonl         |   316 +
 .../agent-aspex-835-f9d2f84ac23c5d25.meta.json     |     1 +
 .../agent-aspex-836-fc127bc3be0e2de8.jsonl         |   203 +
 .../agent-aspex-836-fc127bc3be0e2de8.meta.json     |     1 +
 .../agent-aspex-837-85e0e38a39773a31.jsonl         |   152 +
 .../agent-aspex-837-85e0e38a39773a31.meta.json     |     1 +
 .../agent-aspex-838-6242ce4581fe5dcb.jsonl         |    80 +
 .../agent-aspex-838-6242ce4581fe5dcb.meta.json     |     1 +
 .../agent-aspex-839-baa9c9452f776d3d.jsonl         |    83 +
 .../agent-aspex-839-baa9c9452f776d3d.meta.json     |     1 +
 .../agent-aspex-840-45fe4b7f3ebd2e73.jsonl         |   141 +
 .../agent-aspex-840-45fe4b7f3ebd2e73.meta.json     |     1 +
 .../agent-aspex-841-c55e2d3a367068f9.jsonl         |   150 +
 .../agent-aspex-841-c55e2d3a367068f9.meta.json     |     1 +
 .../agent-aspex-842-5c7c525cf51fa867.jsonl         |    34 +
 .../agent-aspex-842-5c7c525cf51fa867.meta.json     |     1 +
 .../agent-aspex-843-c1cecdecb82ecb68.jsonl         |   153 +
 .../agent-aspex-843-c1cecdecb82ecb68.meta.json     |     1 +
 .../agent-aspex-844-8ed3e951b459139e.jsonl         |   126 +
 .../agent-aspex-844-8ed3e951b459139e.meta.json     |     1 +
 .../agent-aspex-845-b8ca4630ad9dac79.jsonl         |    66 +
 .../agent-aspex-845-b8ca4630ad9dac79.meta.json     |     1 +
 .../agent-aspex-846-e62ad6012f46ddfc.jsonl         |    54 +
 .../agent-aspex-846-e62ad6012f46ddfc.meta.json     |     1 +
 .../subagents/agent-aspex-a-2d6eed9e3cb58598.jsonl |   376 +
 .../agent-aspex-a-2d6eed9e3cb58598.meta.json       |     1 +
 .../subagents/agent-aspex-b-bf2776626a47732d.jsonl |   318 +
 .../agent-aspex-b-bf2776626a47732d.meta.json       |     1 +
 .../tool-results/b5s7xq5ek.txt                     |   790 ++
 .../tool-results/b7eicy1e1.txt                     |    35 +
 .../tool-results/bc2t73aid.txt                     |   154 +
 .../tool-results/bdbtmfjak.txt                     |   250 +
 .../tool-results/bj8tet7i1.txt                     |   786 ++
 .../tool-results/bkvorzzwx.txt                     |   797 ++
 .../tool-results/bl0z2w76h.txt                     |   657 +
 .../tool-results/bm2q5s894.txt                     |   152 +
 .../tool-results/bnjm8o83a.txt                     |   103 +
 .../tool-results/bnu44qhyd.txt                     |  8693 +++++++++++++
 .../tool-results/bojjbahym.txt                     |   152 +
 .../tool-results/bqkqm9c26.txt                     |   150 +
 .../tool-results/btqvqqhnt.txt                     |   789 ++
 .../tool-results/bufum82kk.txt                     |   751 ++
 .../tool-results/bv5ru430o.txt                     |  3311 +++++
 .../tool-results/bys21wqtq.txt                     |   221 +
 .../tool-results/bz9kqwgwb.txt                     |   250 +
 ...yspec_vibium-browser_get_html-1783523754979.txt |  4966 +++++++
 .../e6fb8f79-06b8-4e4b-adbb-ebd169033ebc.jsonl     |    45 +
 .../f7530cd4-c720-4f66-854d-7d06bc48d375.jsonl     |   104 +
 194 files changed, 64521 insertions(+)
## 2fe8160 - Sync latest Claude conversation transcripts

Date: 2026-07-10 09:33:01 -0400

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>



 .../f7530cd4-c720-4f66-854d-7d06bc48d375.jsonl     | 48 ++++++++++++++++++++++
 1 file changed, 48 insertions(+)
