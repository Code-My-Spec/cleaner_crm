# Mix.Tasks.Gettext.Extract

Extracts messages by recompiling the Elixir source code.

```bash
mix gettext.extract [OPTIONS]
```

messages are extracted into POT (Portable Object Template) files with a
`.pot` extension. The location of these files is determined by the `:otp_app`
and `:priv` options given by Gettext modules when they call `use Gettext`. One
POT file is generated for each message domain.

All automatically-extracted messages are assigned the `elixir-autogen` flag.
If a message from the POT is no longer present and has the `elixir-autogen`
flag, the message is removed.

Before `v0.19.0`, the `elixir-format` flag was used to detect automatically
extracted messages. This has been deprecated in `v0.19.0`. When extracting
with the newest version, the new `elixir-autogen` flag is added to all
automatically extracted messages.

All messages are assigned a format flag. When using the default
interpolation module, that flag is `elixir-format`. With other interpolation
modules, the flag name is defined by that implementation (see
`c:Gettext.Interpolation.message_format/0`).

If you would like to verify that your POT files are up to date with the
current state of the codebase, you can provide the `--check-up-to-date`
flag. This is particularly useful for automated checks and in CI systems.
This validation will fail even when the same calls to Gettext
only change location in the codebase:

```bash
mix gettext.extract --check-up-to-date
```

It is possible to pass the `--merge` option to perform merging
for every Gettext backend updated during merge:

```bash
mix gettext.extract --merge
```

All other options passed to `gettext.extract` are forwarded to the
`gettext.merge` task (`Mix.Tasks.Gettext.Merge`), which is called internally
by this task. For example:

```bash
mix gettext.extract --merge --no-fuzzy
```