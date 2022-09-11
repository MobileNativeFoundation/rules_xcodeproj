- [Bazel configs](#bazel-configs)
  - [`rules_xcodeproj`](#rules_xcodeproj)
  - [`rules_xcodeproj_generator`](#rules_xcodeproj_generator)
  - [`rules_xcodeproj_indexbuild`](#rules_xcodeproj_indexbuild)
  - [`rules_xcodeproj_swiftuipreviews`](#rules_xcodeproj_swiftuipreviews)
  - [Project-level configs](#project-level-configs)
  - [Extra config flags](#extra-config-flags)
  - [`.bazelrc` files](#bazelrc-files)

# Bazel configs

The way your project is generated, and the way Bazel builds it inside of Xcode,
can be customized with configs in `.bazelrc` files.

### `rules_xcodeproj`

The `rules_xcodeproj` config is used when building the project normally inside
of Xcode. It is also inherited by all of the other `rules_xcodeproj_*` configs.

> **Warning**
>
> Build affecting flags need to be the same between all `rules_xcodeproj{_*}`
> configs, so it's usually better to adjust this config (`rules_xcodeproj`) over
> the other ones, unless you actually need to target them specifically.

### `rules_xcodeproj_generator`

The `rules_xcodeproj_generator` config is used when generating the project (i.e.
when you use `bazel run //:xcodeproj`).

The types of things you might want to adjust on this config are non-build
affecting, like adjusting build log output.

### `rules_xcodeproj_indexbuild`

The `rules_xcodeproj_indexbuild` config is used when Xcode performs an Index
Build (also known as "Index Prebuilding"), where it builds the project in the
background to a separate output directory, to ensure that it has the required
artifacts to perform per-file indexing based compiles.

Since Index Build runs in the background quite frequently, sometimes once per
target in the project, and then once per saving of a file, the types of things
you might want to adjust on this config are probably log output or telemetry
related (and the default config disables BES upload for this reason).

### `rules_xcodeproj_swiftuipreviews`

The `rules_xcodeproj_swiftuipreviews` config is used when Xcode performs a
SwiftUI Preview build.

You shouldn't need to adjust this config. The default config applies the needed
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
the `--@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:extra_*_flags`
family of build flags. These flags apply changes to the configs after all other
sources, and work when calling `bazel run` to generate the project. If using
project-level configs, these flags adjust those instead of the base configs.

- `extra_common_flags`: Applied to the parent config (i.e. `rules_xcodeproj`)
- `extra_generator_flags`: Applied to the generator config (i.e.
  `rules_xcodeproj_generator`)
- `extra_generator_flags`: Applied to the Index Build config (i.e.
  `rules_xcodeproj_indexbuild`)
- `extra_generator_flags`: Applied to the SwiftUI Previews build config (i.e.
  `rules_xcodeproj_swiftuipreviews`)

## `.bazelrc` files

### Project `xcodeproj.bazelrc`

A project `xcodeproj.bazelrc` file is loaded before the workspace `.bazelrc`.
It's created from a
[template](../xcodeproj/internal/xcodeproj.template.bazelrc), which contains the
default configs mentioned above, and will also contain stubs for the
project-level configs if they are used.

### Workspace `xcodeproj.bazelrc`

At the end of the project `xcodeproj.bazelrc` file is a conditional import of a
workspace level `xcodeproj.bazelrc` file. Since startup flags (e.g.
`--output_base`) can't be applied to configs, they can instead be set in this
file, and they will only apply to rules_xcodeproj `bazel` invocations. If you
have to generate all or part of your rules_xcodeproj configs, this is a
convenient file to use for that.

### Workspace `.bazelrc`

Next the normal workspace `.bazelrc` file is imported. Here you can adjust the
configs further.

### Project `xcodeproj_extra_flags.bazelrc`

Finally, if any
`--@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:extra_*_flags` build
flags were used during project generation, then those adjustments are made in
a project `xcodeproj_extra_flags.bazelrc` file, which is loaded after the
workspace `.bazelrc` file. This ensures that they override any flags set
earlier, mimicking the behavior of command-line set flags taking precedence.
