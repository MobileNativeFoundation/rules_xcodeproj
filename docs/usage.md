- [Bazel configs](#bazel-configs)
  - [`rules_xcodeproj`](#rules_xcodeproj)
  - [`rules_xcodeproj_generator`](#rules_xcodeproj_generator)
  - [`rules_xcodeproj_indexbuild`](#rules_xcodeproj_indexbuild)
  - [`rules_xcodeproj_swiftuipreviews`](#rules_xcodeproj_swiftuipreviews)
  - [Project-level configs](#project-level-configs)
  - [Extra config flags](#extra-config-flags)
  - [`.bazelrc` files](#bazelrc-files)
- [Command-line API](#command-line-api)
  - [Commands](#commands)
  - [Options](#options)
  - [Substitutions](#substitutions)

# Bazel configs

The way your project is generated, and the way Bazel builds it inside of Xcode,
can be customized with configs in `.bazelrc` files.

### `rules_xcodeproj`

The `rules_xcodeproj` config is used when building the project inside of Xcode.
It’s also inherited by all of the other `rules_xcodeproj_*` configs.

> **Warning**
>
> Build affecting flags need to be the same between all `rules_xcodeproj{_*}`
> configs, so it’s usually better to adjust this config (`rules_xcodeproj`) over
> the other ones, unless you actually need to target them specifically.

### `rules_xcodeproj_generator`

The `rules_xcodeproj_generator` config is used when generating the project (i.e.
when you run `bazel run //:xcodeproj`).

The types of things you might want to adjust on this config are non-build
affecting, like adjusting build log output.

### `rules_xcodeproj_indexbuild`

The `rules_xcodeproj_indexbuild` config is used when Xcode performs an Index
Build (also known as “Prepare for Indexing”), where it builds the project in the
background to a separate output directory, to ensure that it has the required
artifacts to perform per-file indexing based compiles.

Since Index Build runs in the background quite frequently, sometimes once per
target in the project, and then once per saving of a file, the types of things
you might want to adjust on this config are probably log output or telemetry
related (and the default config disables BES upload for this reason). For
example, if you set `--profile` globally or on the `rules_xcodeproj` config,
you will want to set `--profile=` (clearing the value) on
`rules_xcodeproj_indexbuild` to prevent Index Builds from overwriting the
profile:

```
build:rules_xcodeproj --profile=/tmp/profile.gz
build:rules_xcodeproj_indexbuild --profile=
```

### `rules_xcodeproj_swiftuipreviews`

The `rules_xcodeproj_swiftuipreviews` config is used when Xcode performs a
SwiftUI Preview build.

You shouldn’t need to adjust this config. The default config applies the needed
build adjusting flags.

## Project-level configs

Each `xcodeproj` can specify a set of configs which inherit from the
`rules_xcodeproj` family of configs. You can specify the base config with the
`config` attribute. For example, if you set `config = "projectx_xcodeproj"`,
then the `projectx_xcodeproj`, `projectx_xcodeproj_generator`,
`projectx_xcodeproj_indexbuild`, and `projectx_xcodeproj_swiftuipreviews`
configs are available to adjust, and they all inherit from their respective
`rules_xcodeproj{_*}` configs.

Using this feature adds a layer of indirection, and should only be used if you
have project-specific configurations you need to apply.

## Extra config flags

Finally, there is one last way to adjust the Bazel configs, through the use of
the `--@rules_xcodeproj//xcodeproj:extra_*_flags`
family of build flags. These flags apply changes to the configs after all other
sources, and work when calling `bazel run` to generate the project. If using
project-level configs, these flags adjust those instead of the base configs.

- `extra_common_flags`: Applied to the parent config (i.e. `rules_xcodeproj`)
- `extra_generator_flags`: Applied to the generator config (i.e.
  `rules_xcodeproj_generator`)
- `extra_indexbuild_flags`: Applied to the Index Build config (i.e.
  `rules_xcodeproj_indexbuild`)
- `extra_swiftuipreviews_flags`: Applied to the SwiftUI Previews build config
  (i.e. `rules_xcodeproj_swiftuipreviews`)

## `.bazelrc` files

### Project `xcodeproj.bazelrc`

A project `xcodeproj.bazelrc` file is loaded before the workspace `.bazelrc`.
It’s created from a
[template](../xcodeproj/internal/xcodeproj.template.bazelrc), which contains the
default configs mentioned above, and will also contain stubs for the
project-level configs if they are used.

### Workspace `xcodeproj.bazelrc`

At the end of the project `xcodeproj.bazelrc` file is a conditional import of a
workspace level `xcodeproj.bazelrc` file. Since startup flags (e.g.
`--host_jvm_args`) can’t be applied to configs, they can instead be set in this
file, and they will only apply to rules_xcodeproj `bazel` invocations. If you
have to generate all or part of your rules_xcodeproj configs, this is a
convenient file to use for that.

> **Note**
>
> `--output_base` is set by rules_xcodeproj in order to nest the output base
> inside of the primary output base (see the
> [command-line API section](#command-line-api) for more details). Thus, setting
> `startup --output_base` in `xcodeproj.bazelrc` will have no effect.

### Workspace `.bazelrc`

Next the normal workspace `.bazelrc` file is imported. Here you can adjust the
configs further.

### Project `xcodeproj_extra_flags.bazelrc`

Finally, if any
`--@rules_xcodeproj//xcodeproj:extra_*_flags` build
flags were used during project generation, then those adjustments are made in
a project `xcodeproj_extra_flags.bazelrc` file, which is loaded after the
workspace `.bazelrc` file. This ensures that they override any flags set
earlier, mimicking the behavior of command-line set flags taking precedence.

# Command-line API

rules_xcodeproj builds targets in its own
[output base](https://docs.bazel.build/versions/main/guide.html#choosing-the-output-base).
It does this to ensure that the
[analysis cache](https://sluongng.hashnode.dev/bazel-caching-explained-pt-2-bazel-in-memory-cache#heading-in-memory-caching)
isn’t affected by other Bazel commands, including project generation itself.
In addition, rules_xcodeproj sets one of the project’s
[Bazel configs](#bazel-configs). Because of this, normal Bazel commands, such
as `bazel build` or `bazel clean`, won’t be the same as what is performed in
Xcode.

To enable you to perform Bazel commands in the same “environment” that
rules_xcodeproj itself uses, we provide a command-line API. Assuming your
`xcodeproj` target is defined at `//:xcodeproj`, this is how you can call this
API:

```
bazel run //:xcodeproj -- [option ...] command_string
```

For example, this will call `bazel info output_path` in the rules_xcodeproj
environment:

```
bazel run //:xcodeproj -- 'info output_path'
```

This will build all targets in the project the same way as SwiftUI Previews
does:

```
bazel run //:xcodeproj -- --config=swiftuipreviews --generator_output_groups=all_targets build
```

## Commands

The API supports all the
[commands](https://bazel.build/reference/command-line-reference#commands)
`bazel` supports. It does not support providing
[startup options](https://bazel.build/reference/command-line-reference#startup-options),
though you can specify those in the
[`xcodeproj.bazelrc`](#workspace-xcodeprojbazelrc) file.

Below are notes about various commands.

### `build`

To build targets the same way as rules_xcodeproj requires more than just using
this API, because the `xcodeproj` rule applies a
[configuration transition](https://bazel.build/extending/config#user-defined-transitions)
to targets. That means that building targets by specifying their labels will
build potentially different versions of those targets, and minimally versions
that have different cache keys.

rules_xcodeproj uses
[output groups](https://bazel.build/extending/rules#requesting_output_files)
to “address” these correctly configured targets. It uses a set of private
output groups, but it also exposes some [public ones](#output-groups).

To build these output groups with this API you would have to craft a call like
this (**note:** this is not the recommended way to do this, and might break in
the future, continue reading after the example for the recommended way):

```
bazel run //:xcodeproj -- 'build --remote_download_minimal --output_groups=all_targets //:xcodeproj.generator'
```

This requires knowing the internal name of the generator target
(`//:xcodeproj.generator` in this example), and it also doesn’t apply some flags
that Xcode `bazel build` command applies (e.g.
`--experimental_remote_download_regex`). Instead, it’s recommended that you use
the [`--generator_output_groups` option](#--generator_output_groups):

```
bazel run //:xcodeproj -- --generator_output_groups=all_targets 'build --remote_download_minimal'
```

### `clean`

When you run `bazel clean` normally (i.e. not using this API), it won’t affect
the rules_xcodeproj output base the way you expect. `bazel clean --expunge`
will though, as it will blow away both environments. To clean the
rules_xcodeproj output base use the API instead:

```
bazel run //:xcodeproj -- clean
```

### `query`/`cquery`/`aquery`

Depending on how you have your [rules_xcodeproj Bazel configs](#bazel-configs)
set up, you might be able to run `bazel query` without using the API. I
recommend using the API instead though, to prevent fetching external
dependencies in the primary output base. The other queries, `cquery` and
`aquery`, should always be performed through the API, to ensure the targets
are properly configured:

```
bazel run //:xcodeproj -- 'aquery "set(//some:target)"'
```

## Options

You can specify some options before the Bazel command:

### `-v`/`--verbose`

Prints the command that was executed.

Without `-v`:

```
$ bazel run --config=cache //:xcodeproj -- clean
INFO: Invocation ID: e4be5bb9-1823-4ca9-a3fd-6066f936460a
INFO: Analyzed target //:xcodeproj (0 packages loaded, 0 targets configured).
INFO: Found 1 target...
Target //:xcodeproj up-to-date:
  /Users/brentley/Developer/rules_xcodeproj/bazel-output-base/execroot/rules_xcodeproj/bazel-out/darwin_arm64-fastbuild/bin/xcodeproj-runner.sh
INFO: Elapsed time: 0.285s, Critical Path: 0.00s
INFO: 1 process: 1 internal.
INFO: Running command line: /Users/brentley/Developer/rules_xcodeproj/bazel-output-base/execroot/rules_xcodeproj/bazel-out/darwin_arm64-fastbuild/bin/xcodeproj-runner.sh -v clean
INFO: Build completed successfully, 1 total action

INFO: Invocation ID: 84c53471-73a4-4267-9289-0ad076ee94fb
INFO: Starting clean.
```

With `-v`:

```
$ bazel run --config=cache //:xcodeproj -- -v clean
INFO: Invocation ID: e4be5bb9-1823-4ca9-a3fd-6066f936460a
INFO: Analyzed target //:xcodeproj (0 packages loaded, 0 targets configured).
INFO: Found 1 target...
Target //:xcodeproj up-to-date:
  /Users/brentley/Developer/rules_xcodeproj/bazel-output-base/execroot/rules_xcodeproj/bazel-out/darwin_arm64-fastbuild/bin/xcodeproj-runner.sh
INFO: Elapsed time: 0.285s, Critical Path: 0.00s
INFO: 1 process: 1 internal.
INFO: Running command line: /Users/brentley/Developer/rules_xcodeproj/bazel-output-base/execroot/rules_xcodeproj/bazel-out/darwin_arm64-fastbuild/bin/xcodeproj-runner.sh -v clean
INFO: Build completed successfully, 1 total action

Running Bazel command:
+ env PATH=/usr/bin:/bin /Users/brentley/Library/Caches/bazelisk/downloads/bazelbuild/bazel-5.3.0-darwin-arm64/bin/bazel --host_jvm_args=-Xdock:name=/Applications/Xcode-14.0.1.app/Contents/Developer --noworkspace_rc --bazelrc=/Users/brentley/Developer/rules_xcodeproj/bazel-output-base/execroot/rules_xcodeproj/bazel-out/darwin_arm64-fastbuild/bin/xcodeproj-runner.sh.runfiles/rules_xcodeproj/xcodeproj.bazelrc --bazelrc=.bazelrc --bazelrc=/Users/brentley/Developer/rules_xcodeproj/bazel-output-base/execroot/rules_xcodeproj/bazel-out/darwin_arm64-fastbuild/bin/xcodeproj-runner.sh.runfiles/rules_xcodeproj/xcodeproj-extra-flags.bazelrc --output_base /Users/brentley/Developer/rules_xcodeproj/bazel-output-base/execroot/_rules_xcodeproj/build_output_base clean --repo_env=DEVELOPER_DIR=/Applications/Xcode-14.0.1.app/Contents/Developer --repo_env=USE_CLANG_CL=14A400 --config=_rules_xcodeproj_build
INFO: Invocation ID: 84c53471-73a4-4267-9289-0ad076ee94fb
INFO: Starting clean.
```

### `--config`

Changes the [Bazel config](#bazel-configs) that is used. Valid values are:

- `build`: [`rules_xcodeproj`](#rules_xcodeproj) or the project-level
  equivalent. This is the default if `--config` isn’t specified.
- `indexbuild`: [`rules_xcodeproj_indexbuild`](#rules_xcodeproj_indexbuild) or
  the project-level equivalent.
- `swiftuipreviews`: [`rules_xcodeproj_swiftuipreviews`](#rules_xcodeproj_swiftuipreviews)
  or the project-level equivalent.

For example, this will build all targets in the project the same way as
SwiftUI Previews does:

```
bazel run //:xcodeproj -- --config=swiftuipreviews --generator_output_groups=all_targets build
```

### `--generator_output_groups`

If the Bazel command is `build`, then this builds the specified generator
outputs groups, potentially adding additional flags to match the behavior of
Xcode’s `bazel build` (e.g. `--experimental_remote_download_regex`).

<a id="output-groups"></a>
These are the available output groups to use:

- `all_targets`: This will build every target specified by `top_level_targets`.
  This is useful to build in “cache warming” jobs.

For example, this will build all targets the same way that Xcode does:

```
bazel run //:xcodeproj -- --generator_output_groups=all_targets build
```

### `--collect_specs`

To aid in debugging an issue, we may request that you provide us with the specs
that were used to generate your project. The specs are intermediate JSON files
used to communicate information from the analysis (Starlark) half of the
generator to the execution (Swift) half of the generator. They contain file
paths and build settings.

Since the location and number of these files can be hard to determine, we’ve
added a command to be able to easily collect them:

```
bazel run //:xcodeproj -- --collect_specs=/path/to/specs.tar.gz
```

The path passed to `--collect_specs` is where a `.tar.gz` archive containing the
specs will be written.

## Substitutions

In your command, any reference to these variables will be expanded:

- `$_GENERATOR_LABEL_`: The label of the generator target (e.g.
  `@@_main~internal~rules_xcodeproj_generated//generator/xcodeproj`). Useful for
  certain `aquery` commands:

  ```
  $bazel run //:xcodeproj -- 'aquery $_GENERATOR_LABEL_'
  ...
  INFO: Invocation ID: ca31d4b4-0df5-49de-a020-c70a922521af
  INFO: Streaming build results to: https://app.buildbuddy.io/invocation/ca31d4b4-0df5-49de-a020-c70a922521af
  INFO: Analyzed target @_main~internal~rules_xcodeproj_generated//generator/tools/generator/xcodeproj:xcodeproj (1 packages loaded, 2 targets configured).
  INFO: Found 1 target...
  action 'Writing file external/_main~internal~rules_xcodeproj_generated/generator/xcodeproj/xcodeproj-xcode_generated_paths.json'
    Mnemonic: FileWrite
    Target: @rules_xcodeproj_generated//generator/xcodeproj:xcodeproj
    Configuration: darwin_arm64-dbg
    Execution platform: @local_config_platform//:host
    ActionKey: f0332c573c0b3ae2ebe525959057fd901d6ce582948b19f7b8e2fdee3f43f045
    Inputs: []
    Outputs: [bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/xcodeproj/xcodeproj-xcode_generated_paths.json]
  ...
  ```
