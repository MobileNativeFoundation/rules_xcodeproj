"""Macro wrapper for the `xcodeproj` rule."""

load(
    "//xcodeproj/internal/xcschemes:xcscheme_labels.bzl",
    "xcscheme_labels",
)
load(":bazel_labels.bzl", "bazel_labels")
load(":logging.bzl", "warn")
load(":project_options.bzl", _default_project_options = "project_options")
load(":top_level_target.bzl", "top_level_target")
load(":xcode_schemes.bzl", "focus_schemes", "unfocus_schemes")
load(":xcodeproj_runner.bzl", "xcodeproj_runner")

def _normalize_build_setting(flag):
    if flag.startswith("//command_line_option:"):
        return flag
    return bazel_labels.normalize_string(flag)

def xcodeproj(
        *,
        name,
        adjust_schemes_for_swiftui_previews = True,
        associated_extra_files = {},
        bazel_path = "bazel",
        bazel_env = {"PATH": "/bin:/usr/bin"},
        build_mode = "bazel",
        config = "rules_xcodeproj",
        default_xcode_configuration = None,
        extra_files = [],
        fail_for_invalid_extra_files_targets = True,
        focused_targets = [],
        generation_mode = "legacy",
        install_directory = None,
        ios_device_cpus = "arm64",
        ios_simulator_cpus = None,
        minimum_xcode_version = None,
        post_build = None,
        pre_build = None,
        project_name = None,
        project_options = None,
        scheme_autogeneration_mode = "auto",
        schemes = [],
        target_name_mode = "auto",
        top_level_targets,
        tvos_device_cpus = "arm64",
        tvos_simulator_cpus = None,
        unfocused_targets = [],
        visionos_device_cpus = "arm64",
        visionos_simulator_cpus = "sim_arm64",
        watchos_device_cpus = "arm64_32",
        watchos_simulator_cpus = None,
        xcode_configurations = {"Debug": {}},
        xcschemes = [],
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
        adjust_schemes_for_swiftui_previews: Optional. Whether to adjust schemes
            in BwB mode to explicitly include transitive dependencies that are
            able to run Xcode Previews.

            For example, this changes a scheme for an single application target
            to also include any app clip, app extension, framework, or watchOS
            app dependencies.
        associated_extra_files: Optional. A `dict` of files to be added to the
            project.

            The key is a `string` value representing the label of the target the
            files should be associated with, and the value is a `list` of
            `File`s. These files won't be added to the project if the target is
            unfocused.
        bazel_env: Optional. A `dict` of environment variables to set when
            invoking `bazel_path`.

            This is useful for setting environment variables that are required
            for Bazel actions to run successfully, such as `JAVA_HOME` or
            `ANDROID_HOME`. It's also useful if `bazel_path` itself (if it's a
            wrapper) needs certain environment variables.

            The keys are the names of the environment variables, and the values
            are the values of the environment variables. If a value
            is `None`, the environment variable will be resolved from the
            current environment as the project is generated. If a value
            references environment variables, those will be resolved from the
            current environment as the project is generated. If you want to use
            a literal `$` in a value, you must escape it with two backslashes.

            If project generation succeeds, but building inside of Xcode fails
            because of missing environment variables, you probably have to set
            them here.

            If `PATH` is not specified, it will default to `/bin:/usr/bin`, so
            you don't have to specify it unless you want to use a different
            value.
        bazel_path: Optional. The path the `bazel` binary or wrapper script.

            If the path is relative it will be resolved using the `PATH`
            environment variable that is set when generating the project. If you
            want to specify a path to a workspace-relative binary, you must
            prepend the path with `./` (e.g. `"./bazelw"`).
        build_mode: Optional. The build mode the generated project should use.

            If this is set to `"xcode"`, the project will use the Xcode build
            system to build targets. Generated files and unfocused targets (see
            the `focused_targets` and `unfocused_targets` arguments) will be
            built with Bazel.

            If this is set to `"bazel"`, the project will use Bazel to build
            targets, inside of Xcode. The Xcode build system still unavoidably
            orchestrates some things at a high level.
        config: Optional. The Bazel config to use when generating the project or
            invoking `bazel` inside of Xcode.

            This is the basename of multiple configs. For example, if this is
            set to `"projectx_xcodeproj"`, then the following configs will be
            available for you to adjust in your `.bazelrc` file:

            <ul>
            <li>`projectx_xcodeproj`</li>
            <li>`projectx_xcodeproj_generator`</li>
            <li>`projectx_xcodeproj_indexbuild`</li>
            <li>`projectx_xcodeproj_swiftuipreviews`</li>
            </ul>

            See the [usage guide](usage.md#bazel-configs) for more information
            on adjusting Bazel configs.
        default_xcode_configuration: Optional. The name of the the Xcode
            configuration to use when building, if not overridden by custom
            schemes.

            If not set, the first Xcode configuration alphabetically will be
            used. Use [`xcode_configurations`](#xcodeproj-xcode_configurations)
            to adjust Xcode configurations.
        extra_files: Optional. A `list` of extra `File`s to be added to the
            project.
        fail_for_invalid_extra_files_targets: Optional. Determines wether, when
            processing targets, invalid extra files without labels will fail or
            just emit a warning.
        focused_targets: Optional. A `list` of target labels as `string` values.

            If specified, only these targets will be included in the generated
            project; all other targets will be excluded, as if they were
            listed explicitly in the `unfocused_targets` argument. The labels
            must match transitive dependencies of the targets specified in the
            `top_level_targets` argument.
        generation_mode: Optional. Determines how the project is generated.

            <ul>
            <li>
              `incremental`: The project is generated in pieces by multiple
              Bazel actions and then combined together. This allows for
              incremental generation where some of those pieces can be reused
              in subsequent project generations.

              The way information is collected and processed has also changed
              compared to legacy generation mode. This has resulted in some bug
              fixes and improvements that don't exist in legacy generation mode.

              **Note:** Only `build_mode = "bazel"` is supported in this mode.

              **Note:** The [`xcschemes`](#xcodeproj-xcschemes) attribute is
              used instead of [`schemes`](#xcodeproj-schemes) in this mode.
            </li>
            <li>
              `legacy`: The project is generated by a monolith Bazel action.

              This mode is deprecated and will be removed in a future version of
              **rules_xcodeproj**.
            </li>
            </ul>
        install_directory: Optional. The directory where the generated project
            will be written to.

            The path is relative to the workspace root.

            Defaults to the directory that the `xcodeproj` target is declared
            in (e.g. if the `xcodeproj` target is declared in `//foo/bar:BUILD`
            then the default value is `"foo/bar"`). Use `""` to have the project
            generated in the workspace root.
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
        minimum_xcode_version: Optional. The minimum Xcode version that the
            generated project supports.

            Newer Xcode versions can support newer features, so setting this to
            the highest value you can will enable the most features. The value
            is the dot separated version number
            (e.g. "13.4.1", "14", "14.1").

            Defaults to whichever version of Xcode that Bazel uses during
            project generation.
        post_build: The text of a script that will be run after the build.

            For example: `./post-build.sh`, `"$SRCROOT/post-build.sh"`.

            The script will be run in Bazel's execution root, so you probably
            want to change to the `$SRCROOT` directory in the script.

            Currently this script will be run as part of Index Build. If you
            don't want that (which is probably the case), you should add a check
            to ensure `$ACTION == build`.
        pre_build: The text of a script that will be run before the build.

            For example: `./pre-build.sh`, `"$SRCROOT/pre-build.sh"`.

            The script will be run in Bazel's execution root, so you probably
            want to change to the `$SRCROOT` directory in the script.

            Currently this script will be run as part of Index Build. If you
            don't want that (which is probably the case), you should add a check
            to ensure `$ACTION == build`.
        project_name: Optional. The name to use for the `.xcodeproj` file.

            If not specified, the value of the `name` argument is used.
        project_options: Optional. A value returned by `project_options`.
        scheme_autogeneration_mode: Optional. Specifies how Xcode schemes are
            automatically generated:

            <ul>
            <li>
              `auto`: If no custom schemes are specified, via `schemes`, an
              Xcode scheme will be created for every buildable target. If custom
              schemes are provided, no autogenerated schemes will be created.
            </li>
            <li>
              `none`: No schemes are automatically generated.
            </li>
            <li>
              `all`: A scheme is generated for every buildable target even if
              custom schemes are provided.
            </li>
            </ul>
        schemes: Optional. A `list` of values returned by
            `xcode_schemes.scheme`.

            This and the `scheme_autogeneration_mode` argument together
            customize how schemes for targets are generated, when using
            `generation_mode = "legacy"`.

            Target labels listed in the schemes need to be from the transitive
            dependencies of the targets specified in the `top_level_targets`
            argument.
        target_name_mode: Optional. Specifies how Xcode targets names are
            represented:

            <ul>
            <li>
              `auto`: Use the product name if it is available and there is no collision.
               Otherwise select the target name from the label.
               And if there is a collision, use the full label.
            </li>
            <li>
              `label`: Always use full label for Xcode targets names.
            </li>
            </ul>
        top_level_targets: A `list` of a list of top-level targets.

            Each target can be specified as either a `Label` (or label-like
            `string`), a value returned by `top_level_target`, or a value
            returned by `top_level_targets`.
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
            values.

            Any targets in the transitive dependencies of the targets specified
            in the `top_level_targets` argument with a matching label will be
            excluded from the generated project. This overrides any targets
            specified in the `focused_targets` argument.
        visionos_device_cpus: Optional. The value to use for `--visionos_cpus`
            when building the transitive dependencies of the targets specified
            in the `top_level_targets` argument with the `"device"`
            `target_environment`.

            **Warning:** Changing this value will affect the Starlark transition
            hash of all transitive dependencies of the targets specified in the
            `top_level_targets` argument with the `"device"`
            `target_environment`, even if they aren't visionOS targets.
        visionos_simulator_cpus: Optional. The value to use for `--visionos_cpus`
            when building the transitive dependencies of the targets specified
            in the `top_level_targets` argument with the `"simulator"`
            `target_environment`.

            **Warning:** Changing this value will affect the Starlark transition
            hash of all transitive dependencies of the targets specified in the
            `top_level_targets` argument with the `"simulator"`
            `target_environment`, even if they aren't visionOS targets.
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
        xcode_configurations: Optional. A `dict` mapping Xcode configuration
            names to transition settings dictionaries. For example:

            ```starlark
            {
                "Dev": {
                    "//command_line_option:compilation_mode": "dbg",
                },
                "AppStore": {
                    "//command_line_option:compilation_mode": "opt",
                },
            }
            ```

            would create the "Dev" and "AppStore" configurations, setting
            `--compilation_mode` to `dbg` and `opt` respectively.

            Refer to the
            [bazel documentation](https://bazel.build/extending/config#defining)
            on how to define the transition settings dictionary.
        xcschemes: Optional. A `list` of values returned by
            `xcschemes.scheme`.

            This and the `scheme_autogeneration_mode` argument together
            customize how schemes for targets are generated, when using
            `generation_mode = "incremental"`.
        **kwargs: Additional arguments to pass to the underlying `xcodeproj`
            rule specified by `xcodeproj_rule`.
    """
    is_fixture = kwargs.pop("is_fixture", False)
    testonly = kwargs.pop("testonly", True)
    generation_shard_count = kwargs.pop("generation_shard_count", 10)

    # Apply defaults
    if not bazel_path:
        bazel_path = "bazel"
    bazel_env = dict(bazel_env) if bazel_env else {}
    if "PATH" not in bazel_env:
        bazel_env["PATH"] = "/bin:/usr/bin"
    if not generation_mode:
        generation_mode = "legacy"
    if not build_mode:
        build_mode = "bazel"
    if install_directory == None:
        install_directory = native.package_name()
    if not project_name:
        project_name = name
    if not project_options:
        project_options = _default_project_options()
    if not xcode_configurations:
        xcode_configurations = {"Debug": {}}

    # Collect `BAZEL_REAL` and `BAZELISK_SKIP_WRAPPER` from runner's env if it
    # exists
    bazel_env["BAZEL_REAL"] = None
    bazel_env["BAZELISK_SKIP_WRAPPER"] = None

    bazel_env = {
        # Null character is used to represent `None`, since `attr.string_dict`
        # requires non-`None` values.
        key: "\0" if value == None else value
        for key, value in sorted(bazel_env.items())
    }

    if default_xcode_configuration and default_xcode_configuration not in xcode_configurations:
        keys = sorted(xcode_configurations.keys())
        fail("""
{target}: `default_xcode_configuration` ("{configuration}") must be one of the \
keys in `xcode_configurations` ({keys}), or `None` to select the first \
configuration alphabetically ("{default}").
""".format(
            configuration = default_xcode_configuration,
            default = keys[0],
            keys = keys,
            target = bazel_labels.normalize_string(name),
        ))

    if not top_level_targets:
        fail("""
{target}: `top_level_targets` cannot be empty.
""".format(target = bazel_labels.normalize_string(name)))

    actual_top_level_targets = []
    for target in top_level_targets:
        if type(target) == "string":
            actual_top_level_targets.append(top_level_target(target))
        elif type(target) == "list":
            actual_top_level_targets.extend(target)
        else:
            actual_top_level_targets.append(target)

    top_level_device_targets = [
        bazel_labels.normalize_string(top_level_target.label)
        for top_level_target in actual_top_level_targets
        if "device" in top_level_target.target_environments
    ]
    top_level_simulator_targets = [
        bazel_labels.normalize_string(top_level_target.label)
        for top_level_target in actual_top_level_targets
        if "simulator" in top_level_target.target_environments
    ]

    focused_labels = [
        bazel_labels.normalize_string(t)
        for t in focused_targets
    ]
    unfocused_labels = [
        bazel_labels.normalize_string(t)
        for t in unfocused_targets
    ]

    owned_extra_files = {}
    for label, files in associated_extra_files.items():
        for f in files:
            owned_extra_files[bazel_labels.normalize_string(f)] = (
                bazel_labels.normalize_string(label)
            )

    unowned_extra_files = [
        bazel_labels.normalize_string(f)
        for f in extra_files
    ]

    schemes_json = None
    xcschemes_json = "[]"
    if generation_mode == "incremental":
        if build_mode == "xcode":
            fail("""
{target}: `xcodeproj.generation_mode = "incremental"` does not work with \
`xcodeproj.build_mode = "xcode"`.
""".format(
                target = bazel_labels.normalize_string(name),
            ))

        xcschemes = xcschemes or []
        if type(xcschemes) != "list":
            fail("""
{target}: `xcodeproj.xcschemes` must be a list.
""".format(
                target = bazel_labels.normalize_string(name),
            ))

        if schemes and len(schemes) != len(xcschemes):
            warn("""\
{target}: `xcodeproj.generation_mode = "incremental"` and `xcodeproj.schemes` \
({schemes_len}) are set, but `xcodeproj.xcschemes` ({xcschemes_len}) doesn't \
have the same number of elements. Your schemes will not be the same as when \
`xcodeproj.generation_mode = "legacy"` is set.\
""".format(
                schemes_len = len(schemes),
                target = bazel_labels.normalize_string(name),
                xcschemes_len = len(xcschemes),
            ))

        xcschemes_json = json.encode(
            xcscheme_labels.resolve_labels(xcschemes),
        )
    elif schemes:
        if unfocused_labels:
            schemes = unfocus_schemes(
                schemes = schemes,
                unfocused_labels = unfocused_labels,
            )
        if focused_labels:
            schemes = focus_schemes(
                schemes = schemes,
                focused_labels = focused_labels,
            )
        schemes_json = json.encode(schemes)

    normalized_xcode_configurations = {}
    xcode_configuration_inverse_map = {}
    xcode_configuration_flags = None
    for configuration, flags in xcode_configurations.items():
        if type(flags) != "dict":
            fail("""
{target}: All values in `xcode_configurations` must be transition settings \
dictionaries. Please refer to https://bazel.build/extending/config#defining) \
on how to set them.
""".format(target = bazel_labels.normalize_string(name)))

        # Make sure Starlark build settings work with bzlmod (need to resolve
        # the labels before it reaches the generated BUILD file)
        flags = {
            _normalize_build_setting(flag): value
            for flag, value in flags.items()
        }
        normalized_xcode_configurations[configuration] = flags

        keys = sorted(flags.keys())
        if xcode_configuration_flags == None:
            xcode_configuration_flags = keys
        elif xcode_configuration_flags != keys:
            fail("""
{target}: Keys of the `xcode_configurations` transition settings dictionary \
for {configuration} ({new_keys}) do not match keys of other configurations \
({old_keys}). All transition settings dictionaries must have the same keys.
""".format(
                configuration = configuration,
                new_keys = keys,
                old_keys = xcode_configuration_flags,
                target = bazel_labels.normalize_string(name),
            ))
        xcode_configuration_inverse_map.setdefault(str(flags), []).append(
            configuration,
        )

    # Bazel bugs out if multiple splits have the same dictionary, so we dedupe
    # them, but maintain a mapping so that we can recreate the them in the rule
    dedupped_xcode_configurations = {}
    xcode_configuration_map = {}
    for configurations in xcode_configuration_inverse_map.values():
        configurations = sorted(configurations)
        configuration = configurations[0]
        xcode_configuration_map[configuration] = configurations
        dedupped_xcode_configurations[configuration] = (
            normalized_xcode_configurations[configuration]
        )

    xcodeproj_runner(
        name = name,
        adjust_schemes_for_swiftui_previews = (
            adjust_schemes_for_swiftui_previews
        ),
        build_mode = build_mode,
        bazel_path = bazel_path,
        bazel_env = bazel_env,
        config = config,
        default_xcode_configuration = default_xcode_configuration,
        fail_for_invalid_extra_files_targets = fail_for_invalid_extra_files_targets,
        focused_labels = focused_labels,
        generation_mode = generation_mode,
        generation_shard_count = generation_shard_count,
        install_directory = install_directory,
        ios_device_cpus = ios_device_cpus,
        ios_simulator_cpus = ios_simulator_cpus,
        is_fixture = is_fixture,
        minimum_xcode_version = minimum_xcode_version,
        owned_extra_files = owned_extra_files,
        post_build = post_build,
        pre_build = pre_build,
        project_name = project_name,
        project_options = project_options,
        scheme_autogeneration_mode = scheme_autogeneration_mode,
        schemes_json = schemes_json,
        target_name_mode = target_name_mode,
        testonly = testonly,
        top_level_device_targets = top_level_device_targets,
        top_level_simulator_targets = top_level_simulator_targets,
        tvos_device_cpus = tvos_device_cpus,
        tvos_simulator_cpus = tvos_simulator_cpus,
        unfocused_labels = unfocused_labels,
        unowned_extra_files = unowned_extra_files,
        visionos_device_cpus = visionos_device_cpus,
        visionos_simulator_cpus = visionos_simulator_cpus,
        watchos_device_cpus = watchos_device_cpus,
        watchos_simulator_cpus = watchos_simulator_cpus,
        xcode_configuration_flags = xcode_configuration_flags,
        xcode_configuration_map = xcode_configuration_map,
        xcode_configurations = str(dedupped_xcode_configurations),
        xcschemes_json = xcschemes_json,
        **kwargs
    )
