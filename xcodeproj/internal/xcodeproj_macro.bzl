"""Macro wrapper for the `xcodeproj` rule."""

load("@bazel_skylib//lib:sets.bzl", "sets")
load(":bazel_labels.bzl", "bazel_labels")
load(":logging.bzl", "warn")
load(":xcode_schemes.bzl", "xcode_schemes")
load(":xcodeproj_rule.bzl", _xcodeproj = "xcodeproj")
load(":xcodeproj_runner.bzl", "xcodeproj_runner")

def xcodeproj(
        *,
        name,
        archived_bundles_allowed = None,
        bazel_path = "bazel",
        build_mode = "bazel",
        config = "rules_xcodeproj",
        focused_targets = [],
        ios_device_cpus = "arm64",
        ios_simulator_cpus = None,
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

    Args:
        name: A unique name for this target.
        archived_bundles_allowed: This argument is deprecated and is now a
            no-op. It will be removed in a future release. Adjust the setting of
            `--define=apple.experimental.tree_artifact_outputs` on
            `build:rules_xcodeproj` in your `.bazelrc` or `xcodeproj.bazelrc`
            file.
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
            `projectx_xcodeproj_generator`, `rules_xcodeproj_indexbuild`, and
            `rules_xcodeproj_swiftuipreviews`.

            See the [usage guide](usage.md#bazel-configs) for more
            information about adjusting Bazel configs.
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
            can be specified as either a `Label` (or label-like `string`), or a
            value returned by `top_level_target`.
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

    top_level_targets = [
        top_level_target(target) if type(target) == "string" else target
        for target in top_level_targets
    ]
    top_level_device_targets = [
        top_level_target.label
        for top_level_target in top_level_targets
        if sets.contains(top_level_target.target_environments, "device")
    ]
    top_level_simulator_targets = [
        top_level_target.label
        for top_level_target in top_level_targets
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

    schemes_json = None
    if schemes:
        if unfocused_targets:
            schemes = xcode_schemes.unfocus_schemes(
                schemes = schemes,
                unfocused_targets = unfocused_targets,
            )
        if focused_targets:
            schemes = xcode_schemes.focus_schemes(
                schemes = schemes,
                focused_targets = focused_targets,
            )
        schemes_json = json.encode(schemes)

    generator_name = "{}.generator".format(name)

    xcodeproj_rule = kwargs.pop("xcodeproj_rule", _xcodeproj)

    tags = kwargs.pop("tags", [])

    # The runner needs to ensure that the
    # `rules_xcodeproj_top_level_cache_buster` repository is properly created,
    # so don't allow people to accidentally try to build the generator.
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

_VALID_TARGET_ENVIRONMENTS = sets.make(["device", "simulator"])

def top_level_target(label, *, target_environments = ["simulator"]):
    """Constructs a top-level target for use in `xcodeproj.top_level_targets`.

    Args:
        label: A `Label` or label-like string for the target.
        target_environments: Optional. A `list` of target environment strings
            (see `@build_bazel_apple_support//constraints:target_environment`;
            `"catalyst"` is not currently supported). The target will be
            configured for each environment.

            If multiple environments are specified, then a single combined Xcode
            target will be created if possible. If the configured targets are
            the same for each environment (e.g. macOS for
            `["device", "simulator"]`), they will appear as separate but similar
            Xcode targets. If no environments are specified, the `"simulator"`
            environment will be used.

    Returns:
        A `struct` containing fields for the provided arguments.
    """
    if not target_environments:
        target_environments = ["simulator"]

    target_environments = sets.make(target_environments)

    invalid_target_environments = sets.to_list(
        sets.difference(target_environments, _VALID_TARGET_ENVIRONMENTS),
    )
    if invalid_target_environments:
        fail("`target_environments` contains invalid elements: {}".format(
            invalid_target_environments,
        ))

    return struct(
        label = label,
        target_environments = target_environments,
    )
