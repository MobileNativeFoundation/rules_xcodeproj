"""Macro wrapper for the `xcodeproj` rule."""

load("@bazel_skylib//lib:sets.bzl", "sets")
load(":bazel_labels.bzl", "bazel_labels")
load(":collections.bzl", "flatten")
load(":logging.bzl", "warn")
load(":top_level_target.bzl", "top_level_target")
load(":xcode_schemes.bzl", "focus_schemes", "unfocus_schemes")
load(":xcodeproj_rule.bzl", _xcodeproj = "xcodeproj")
load(":xcodeproj_runner.bzl", "xcodeproj_runner")

def xcodeproj(
        *,
        name,
        archived_bundles_allowed = None,
        associated_extra_files = {},
        bazel_path = "bazel",
        build_mode = "bazel",
        config = "rules_xcodeproj",
        extra_files = [],
        focused_targets = [],
        ios_device_cpus = "arm64",
        ios_simulator_cpus = None,
        post_build = None,
        pre_build = None,
        project_name = None,
        scheme_autogeneration_mode = "auto",
        schemes = [],
        top_level_targets,
        tvos_device_cpus = "arm64",
        tvos_simulator_cpus = None,
        unfocused_targets = [],
        watchos_device_cpus = "arm64_32",
        watchos_simulator_cpus = None,
        **kwargs):
    """Creates an `.xcodeproj` file in the workspace when run.

    This is a wrapper macro for the
    [actual `xcodeproj` rule](../xcodeproj/internal/xcodeproj_rule.bzl), which
    can't be used directly. All public API is documented below. The `kwargs`
    argument will pass forward values for globally available attributes (e.g.
    `visibility`, `features`, etc.) to the underlying rule.

    **EXAMPLE**

    ```starlark
    xcodeproj(
        name = "xcodeproj",
        project_name = "App",
        tags = ["manual"],
        top_level_targets = [
            top_level_target(":App", target_environments = ["device", "simulator"]),
            ":Tests",
        ],
    )
    ```

    Args:
        name: A unique name for this target.
        archived_bundles_allowed: This argument is deprecated and is now a
            no-op. It will be removed in a future release. Adjust the setting of
            `--define=apple.experimental.tree_artifact_outputs` on
            `build:rules_xcodeproj` in your `.bazelrc` or `xcodeproj.bazelrc`
            file.
        associated_extra_files: Optional. A `dict` of files to be added to the
            project. The key is a `string` value representing the label of the
            target the files should be associated with, and the value is a
            `list` of `File`s. These files won't be added to the project if the
            target is unfocused.
        bazel_path: Optional. The path the `bazel` binary or wrapper script. If
            the path is relative it will be resolved using the `PATH`
            environment variable (which is set to
            `/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin` in
            Xcode). If you want to specify a path to a workspace-relative
            binary, you must prepend the path with `./` (e.g. `"./bazelw"`).
        build_mode: Optional. The build mode the generated project should use.

            If this is set to `"xcode"`, the project will use the Xcode build
            system to build targets. Generated files and unfocused targets (see
            the `focused_targets` and `unfocused_targets` arguments) will be
            built with Bazel.

            If this is set to `"bazel"`, the project will use Bazel to build
            targets, inside of Xcode. The Xcode build system still unavoidably
            orchestrates some things at a high level.
        config: Optional. The Bazel config to use when generating the project or
            invoking `bazel` inside of Xcode. This is the basename of multiple
            configs. For example, if this is set to `"projectx_xcodeproj"`, then
            the following configs will be available for you to adjust in your
            `.bazelrc` file: `projectx_xcodeproj`,
            `projectx_xcodeproj_generator`, `projectx_xcodeproj_indexbuild`, and
            `projectx_xcodeproj_swiftuipreviews`.

            See the [usage guide](usage.md#bazel-configs) for more information
            on adjusting Bazel configs.
        extra_files: Optional. A `list` of extra `File`s to be added to the
            project.
        focused_targets: Optional. A `list` of target labels as `string` values.
            If specified, only these targets will be included in the generated
            project; all other targets will be excluded, as if they were
            listed explicitly in the `unfocused_targets` argument. The labels
            must match transitive dependencies of the targets specified in the
            `top_level_targets` argument.
        ios_device_cpus: Optional. The value to use for `--ios_multi_cpus` when
            building the transitive dependencies of the targets specified in the
            `top_level_targets` argument with the `"device"`
            `target_environment`.

            **Warning:** Changing this value will affect the Starlark transition
            hash of all transitive dependencies of the targets specified in the
            `top_level_targets` argument with the `"device"`
            `target_environment`, even if they aren't iOS targets.
        ios_simulator_cpus: Optional. The value to use for `--ios_multi_cpus`
            when building the transitive dependencies of the targets specified
            in the `top_level_targets` argument with the `"simulator"`
            `target_environment`.

            If no value is specified, it defaults to the simulator cpu that goes
            with `--host_cpu` (i.e. `sim_arm64` on Apple Silicon and `x86_64` on
            Intel).

            **Warning:** Changing this value will affect the Starlark transition
            hash of all transitive dependencies of the targets specified in the
            `top_level_targets` argument with the `"simulator"`
            `target_environment`, even if they aren't iOS targets.
        post_build: The text of a script that will be run after the build. For
            example: `./post-build.sh`, `"$PROJECT_DIR/post-build.sh"`.
        pre_build: The text of a script that will be run before the build. For
            example: `./pre-build.sh`, `"$PROJECT_DIR/pre-build.sh"`.
        project_name: Optional. The name to use for the `.xcodeproj` file. If
            not specified, the value of the `name` argument is used.
        scheme_autogeneration_mode: Optional. Specifies how Xcode schemes are
            automatically generated.
        schemes: Optional. A `list` of values returned by
            `xcode_schemes.scheme`. Target labels listed in the schemes need to
            be from the transitive dependencies of the targets specified in the
            `top_level_targets` argument. This and the
            `scheme_autogeneration_mode` argument together customize how
            schemes for those targets are generated.
        top_level_targets: A `list` of a list of top-level targets. Each target
            can be specified as either a `Label` (or label-like `string`), a
            value returned by `top_level_target`, or a value returned by
            `top_level_targets`.
        tvos_device_cpus: Optional. The value to use for `--tvos_cpus` when
            building the transitive dependencies of the targets specified in the
            `top_level_targets` argument with the `"device"`
            `target_environment`.

            **Warning:** Changing this value will affect the Starlark transition
            hash of all transitive dependencies of the targets specified in the
            `top_level_targets` argument with the `"device"`
            `target_environment`, even if they aren't tvOS targets.
        tvos_simulator_cpus: Optional. The value to use for `--tvos_cpus` when
            building the transitive dependencies of the targets specified in the
            `top_level_targets` argument with the `"simulator"`
            `target_environment`.

            If no value is specified, it defaults to the simulator cpu that goes
            with `--host_cpu` (i.e. `sim_arm64` on Apple Silicon and `x86_64` on
            Intel).

            **Warning:** Changing this value will affect the Starlark transition
            hash of all transitive dependencies of the targets specified in the
            `top_level_targets` argument with the `"simulator"`
            `target_environment`, even if they aren't tvOS targets.
        unfocused_targets: Optional. A `list` of target labels as `string`
            values. Any targets in the transitive dependencies of the targets
            specified in the `top_level_targets` argument with a matching
            label will be excluded from the generated project. This overrides
            any targets specified in the `focused_targets` argument.
        watchos_device_cpus: Optional. The value to use for `--watchos_cpus`
            when building the transitive dependencies of the targets specified
            in the `top_level_targets` argument with the `"device"`
            `target_environment`.

            **Warning:** Changing this value will affect the Starlark transition
            hash of all transitive dependencies of the targets specified in the
            `top_level_targets` argument with the `"device"`
            `target_environment`, even if they aren't watchOS targets.
        watchos_simulator_cpus: Optional. The value to use for `--watchos_cpus`
            when building the transitive dependencies of the targets specified
            in the `top_level_targets` argument with the `"simulator"`
            `target_environment`.

            If no value is specified, it defaults to the simulator cpu that goes
            with `--host_cpu` (i.e. `arm64` on Apple Silicon and `x86_64` on
            Intel).

            **Warning:** Changing this value will affect the Starlark transition
            hash of all transitive dependencies of the targets specified in the
            `top_level_targets` argument with the `"simulator"`
            `target_environment`, even if they aren't watchOS targets.
        **kwargs: Additional arguments to pass to the underlying `xcodeproj`
            rule specified by `xcodeproj_rule`.
    """
    testonly = kwargs.pop("testonly", True)

    if archived_bundles_allowed != None:
        warn("""\
`archived_bundles_allowed` is deprecated and is now a no-op. It will be \
removed in a future release. Adjust the setting of \
`--define=apple.experimental.tree_artifact_outputs` on `build:rules_xcodeproj` \
in your `.bazelrc` or `xcodeproj.bazelrc` file.""")

    # Apply defaults
    if not bazel_path:
        bazel_path = "bazel"
    if not build_mode:
        build_mode = "xcode"
    if not project_name:
        project_name = name

    if not top_level_targets:
        fail("`top_level_targets` cannot be empty.")

    actual_top_level_targets = []
    for target in top_level_targets:
        if type(target) == "string":
            actual_top_level_targets.append(top_level_target(target))
        elif type(target) == "list":
            actual_top_level_targets.extend(target)
        else:
            actual_top_level_targets.append(target)

    top_level_device_targets = [
        top_level_target.label
        for top_level_target in actual_top_level_targets
        if sets.contains(top_level_target.target_environments, "device")
    ]
    top_level_simulator_targets = [
        top_level_target.label
        for top_level_target in actual_top_level_targets
        if sets.contains(top_level_target.target_environments, "simulator")
    ]

    focused_targets = [
        bazel_labels.normalize(t)
        for t in focused_targets
    ]
    unfocused_targets = [
        bazel_labels.normalize(t)
        for t in unfocused_targets
    ]

    owned_extra_files = {}
    for label, files in associated_extra_files.items():
        for f in files:
            owned_extra_files[f] = bazel_labels.normalize(label)

    schemes_json = None
    if schemes:
        if unfocused_targets:
            schemes = unfocus_schemes(
                schemes = schemes,
                unfocused_targets = unfocused_targets,
            )
        if focused_targets:
            schemes = focus_schemes(
                schemes = schemes,
                focused_targets = focused_targets,
            )
        schemes_json = json.encode(schemes)

    generator_name = "{}.generator".format(name)

    xcodeproj_rule = kwargs.pop("xcodeproj_rule", _xcodeproj)

    tags = kwargs.pop("tags", [])

    # The generator should always have its config applied, so add `manual` to
    # the tag to prevent accidental building with `//...`
    generator_tags = list(tags)
    if "manual" not in generator_tags:
        generator_tags.append("manual")

    xcodeproj_rule(
        name = generator_name,
        build_mode = build_mode,
        bazel_path = bazel_path,
        config = config,
        focused_targets = focused_targets,
        ios_device_cpus = ios_device_cpus,
        ios_simulator_cpus = ios_simulator_cpus,
        owned_extra_files = owned_extra_files,
        post_build = post_build,
        pre_build = pre_build,
        project_name = project_name,
        scheme_autogeneration_mode = scheme_autogeneration_mode,
        schemes_json = schemes_json,
        tags = generator_tags,
        testonly = testonly,
        top_level_device_targets = top_level_device_targets,
        top_level_simulator_targets = top_level_simulator_targets,
        tvos_device_cpus = tvos_device_cpus,
        tvos_simulator_cpus = tvos_simulator_cpus,
        unfocused_targets = unfocused_targets,
        unowned_extra_files = extra_files,
        watchos_device_cpus = watchos_device_cpus,
        watchos_simulator_cpus = watchos_simulator_cpus,
        **kwargs
    )

    xcodeproj_runner(
        name = name,
        bazel_path = bazel_path,
        config = config,
        project_name = project_name,
        tags = tags,
        testonly = testonly,
        xcodeproj_target = bazel_labels.normalize(generator_name),
        visibility = kwargs.get("visibility"),
    )
