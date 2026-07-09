# Mix.Tasks.Phx.Gen.Release

Generates release files and optional Dockerfile for release-based deployments.

The following release files are created:

  * `lib/app_name/release.ex` - A release module containing tasks for running
    migrations inside a release

  * `rel/overlays/bin/migrate` - A migrate script for conveniently invoking
    the release system migrations

  * `rel/overlays/bin/server` - A server script for conveniently invoking
    the release system with environment variables to start the phoenix web server

Note, the `rel/overlays` directory is copied into the release build by default when
running `mix release`.

To skip generating the migration-related files, use the `--no-ecto` flag. To
force these migration-related files to be generated, use the `--ecto` flag.

## Docker

When the `--docker` flag is passed, the following docker files are generated:

  * `Dockerfile` - The Dockerfile for use in any standard docker deployment

  * `.dockerignore` - A docker ignore file with standard elixir defaults

By default, the build uses whatever base image matches your development system’s
active versions at generation time. To override those defaults, specify:

* `otp` — the OTP version to use

* `elixir` — the Elixir version to use

For extended release configuration, the `mix release.init` task can be used
in addition to this task. See the `Mix.Release` docs for more details.

If you are using third party JS package managers like `npm` or `yarn`, you will
need to update the generated Dockerfile with an extra step to fetch those packages.
This might look like this:

```dockerfile
...
ARG RUNNER_IMAGE="debian:..."

FROM node:20 as node
COPY assets assets
RUN cd assets && npm ci

FROM ${BUILDER_IMAGE} as builder

...

COPY assets assets
COPY --from=node assets/node_modules assets/node_modules
...
```

If you are using esbuild through Node.js or other JavaScript build tools, the approach
above can also be modified to invoke those in the node stage, for example:

```dockerfile
FROM node:20 as node
COPY assets assets
RUN cd assets && npm ci && node build.js --deploy
```

Note that you may need to adjust the `assets.deploy` task to not invoke Node.js again.