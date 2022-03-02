"""Functions for creating `XcodeProjInfo` providers."""

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleBundleInfo",
    "AppleResourceBundleInfo",
    "IosXcTestBundleInfo",
)
load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:sets.bzl", "sets")
load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj/internal:build_settings.bzl",
    "get_product_module_name",
    "get_targeted_device_family",
    "set_if_true",
)
load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj/internal:opts.bzl",
    "process_opts",
)
load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj/internal:platform.bzl",
    "process_platform",
)

XcodeProjInfo = provider(
    "Provides information needed to generate an Xcode project.",
    fields = {
        "all_inputs": """\
A `depset` of all the files in the project.
""",
        "extra_files": """\
A `depset` of files that should be added to the Xcode project, but not
associated with any targets.
""",
        "required_links": """\
A `depset` of all static library files that are linked into top-level targets
besides their primary top-level targets.
""",
        "potential_target_merges": """\
A `depset` of structs with 'src' and 'dest' fields. The 'src' field is the id of
the target that can be merged into the target with the id of the 'dest' field.
""",
        "target": """\
A `struct` that contains information about the current target that is
potentially needed by the dependent targets.
""",
        "unbound_srcs": """\
A `depset` of files that should be added to the Compile Sources phase of
the next eligible target.
""",
        "xcode_targets": """\
A `depset` of partial json `dict` strings (e.g. a single '"Key": "Value"'
without the enclosing braces), which potentially will become targets in the
Xcode project.
""",
    },
)

# Inputs

def _input_files(*, ctx, transitive_infos):
    """Gathers files needed for creating an `XcodeProjInfo` provider.

    Args:
        ctx: The aspect context.
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of `Target`.

    Returns:
        A `struct` containing the following fields:

        *   `all_inputs`: A `depset` of all input files gathered from `Target`
            and its transitive dependencies.
        *   `extra_files`: A `depset` of all non-source files gathered from
            `Target` and its transitive dependencies.
        *   `unbound_srcs`: A `depset` of source files gathered from `Target`
            and any non-processed transitive dependencies (see
            `_should_process_target()`).
    """
    srcs = []
    extra_files = []
    for attr in dir(ctx.rule.files):
        if attr in ["data", "hdrs", "structured_resources", "resources"]:
            extra_files.extend(getattr(ctx.rule.files, attr, []))
        elif attr == "srcs" or attr == "non_arc_srcs":
            # TODO: account for non-arc in Xcode properly
            srcs.extend(getattr(ctx.rule.files, attr, []))
    all_inputs = extra_files + srcs

    return struct(
        unbound_srcs = depset(
            srcs,
            transitive = [info.unbound_srcs for info in transitive_infos],
        ),
        extra_files = depset(
            extra_files,
            transitive = [info.extra_files for info in transitive_infos],
        ),
        all_inputs = depset(
            all_inputs,
            transitive = [info.all_inputs for info in transitive_infos],
        ),
    )

# Configuration

def _calculate_configuration(*, bin_dir_path):
    """Calculates a configuration string from `ctx.bin_dir`.

    Args:
        bin_dir_path: `ctx.bin_dir.path`.

    Returns:
        A string that represents a configuration.
    """
    path_components = bin_dir_path.split("/")
    if len(path_components) > 2:
        return path_components[1]
    return ""

def _get_configuration(ctx):
    """Generates a configuration identifier for a target.

    `ConfiguredTarget.getConfigurationKey()` isn't exposed to Starlark, so we
    are using the output directory as a proxy.

    Args:
        ctx: The aspect context.

    Returns:
        A string that uniquely identifies the configuration of a target.
    """
    return _calculate_configuration(bin_dir_path = ctx.bin_dir.path)

# Target ID

def _get_id(*, label, configuration):
    """Generates a unique identifier for a target.

    Args:
        label: The `Label` of the `Target`.
        configuration: The configuration as returned by `_get_configuration()`.

    Returns:
        An opaque string that uniquely identifies the target.
    """
    return "{} {}".format(label, configuration)

# Product

def _get_static_library(*, label, cc_info):
    for input in cc_info.linking_context.linker_inputs.to_list():
        if input.owner != label:
            continue
        for library in input.libraries:
            return library.static_library.path
    return None

def _process_product(
    target,
    product_name,
    product_type,
    bundle_path,
    build_settings):
    """Generates information about the target's product.

    Args:
        target: The `Target` the product information is gathered from.
        product_name: The name of the product (i.e. the "PRODUCT_NAME" build
            setting).
        product_type: A PBXProductType string. See
            https://github.com/tuist/XcodeProj/blob/main/Sources/XcodeProj/Objects/Targets/PBXProductType.swift
            for examples.
        bundle_path: If the product is a bundle, this is the the path to the
            bundle, otherwise `None`.
        build_settings: A mutable `dict` that will be updated with Xcode build
            settings.
    """
    if bundle_path:
        path = bundle_path
    elif CcInfo in target or SwiftInfo in target:
        path = _get_static_library(
            label = target.label,
            cc_info = target[CcInfo],
        )
    else:
        path = target[DefaultInfo].files_to_run.executable.path

    if not path:
        fail("Could not find product for target {}".format(target.label))

    build_settings["PRODUCT_NAME"] = product_name

    return {
        "name": product_name,
        "type": product_type,
        "path": path,
    }

# Outputs

def _process_outputs(target):
    """Generates information about the target's outputs.

    Args:
        target: The `Target` the output information is gathered from.

    Returns:
        A `dict` containing the targets output information. See `Output` in
        `//tools/generator/src:DTO.swift` for what it transforms into.
    """
    outputs = {}
    if OutputGroupInfo in target:
        if "dsyms" in target[OutputGroupInfo]:
            outputs["dsyms"] = [
                file.path for file in target[OutputGroupInfo].dsyms.to_list()
            ]
    if SwiftInfo in target:
        outputs["swift_module"] = _swift_module_output([
            module
            for module in target[SwiftInfo].direct_modules
            if module.swift
        ][0])
    return outputs

def _swift_module_output(module):
    """Generates information about the target's Swift module.

    Args:
        module: A `struct` as returned from `swift_common.create_module()`. See
            https://github.com/bazelbuild/rules_swift/blob/master/doc/api.md#swift_commoncreate_module.

    Returns:
        A `dict` containing the Swift module's output information. See
        `Output.SwiftModule` in `//tools/generator/src:DTO.swift` for what it
        transforms into.
    """
    swift = module.swift

    output = {
        "name": module.name + '.swiftmodule',
        "swiftdoc": swift.swiftdoc.path,
        "swiftmodule": swift.swiftmodule.path,
    }
    if swift.swiftsourceinfo:
        output["swiftsourceinfo"] = swift.swiftsourceinfo.path
    if swift.swiftinterface:
        output["swiftinterface"] = swift.swiftinterface.path

    return output

# Xcode target

def _xcode_target(
    *,
    id,
    name,
    label,
    configuration,
    platform,
    product,
    test_host,
    build_settings,
    srcs,
    links,
    dependencies,
    outputs):
    """Generates the partial json string representation of an Xcode target.

    Args:
        id: A unique identifier. No two `_xcode_target` will have the same `id`.
            This won't be user facing, the generator will use other fields to
            generate a unique name for a target.
        name: The base name that the Xcode target should use. Multiple
            `_xcode_target`s can have the same name; the generator will
            disambiguate them.
        label: The `Label` of the `Target`.
        configuration: The configuration of the `Target`.
        platform: The platform `dict` as returned by `process_platform()`.
        product: The product `dict` as returned by `_process_product()`.
        test_host: The `id` of the target that is the test host for this
            target, or `None` if this target does not have a test host.
        build_settings: A `dict` of Xcode build settings for the target.
        srcs: A `list` of source file paths for `target`.
        links: A `list` of file paths for libraries that the target links
            against.
        dependencies: A `list` of `id`s of targets that this target depends on.
        outputs: The outputs `dict` as returned by `_process_outputs()`.

    Returns:
        An element of a json array string. This should be wrapped with `"[{}]"`
        to create a json array string, possibly joining multiples of these
        strings with `","`.
    """
    target = json.encode(struct(
        name = name,
        label = str(label),
        configuration = configuration,
        platform = platform,
        product = product,
        test_host = test_host,
        build_settings = build_settings,
        srcs = srcs,
        links = links,
        dependencies = dependencies,
        outputs = outputs,
    ))

    # Since we use a custom dictionary key type in
    # `//tools/generator/src:DTO.swift`, we need to use alternating keys and
    # values to get the correct dictionary representation.
    return '"{id}",{target}'.format(id = id, target = target)

# Top-level targets

def _process_top_level_properties(
    *,
    target_name,
    files,
    bundle_info,
    tree_artifact_enabled,
    build_settings):
    if bundle_info:
        product_name = bundle_info.bundle_name
        product_type = bundle_info.product_type
        minimum_deployment_version = bundle_info.minimum_deployment_os_version

        if tree_artifact_enabled:
            bundle_path = bundle_info.archive.path
        else:
            bundle_extension = bundle_info.bundle_extension
            bundle = "{}{}".format(bundle_info.bundle_name, bundle_extension)
            if bundle_extension == ".app":
                bundle_path = paths.join(
                    bundle_info.archive_root, "Payload", bundle,
                )
            else:
                bundle_path = paths.join(bundle_info.archive_root, bundle)

        build_settings["GENERATE_INFOPLIST_FILE"] = True
        build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = bundle_info.bundle_id
    else:
        product_name = target_name
        minimum_deployment_version = None

        xctest = None
        for file in files:
            if ".xctest/" in file.short_path:
                xctest = file.short_path
                break
        if xctest:
            # This is something like `swift_test`: it creates an xctest bundle
            product_type = "com.apple.product-type.bundle.unit-test"
            build_settings["GENERATE_INFOPLIST_FILE"] = True
            # "some/test.xctest/binary" -> "some/test.xctest"
            bundle_path = xctest[:-(len(xctest.split(".xctest/")[1]) + 1)]
        else:
            product_type = "com.apple.product-type.tool"
            bundle_path = None

    build_settings["PRODUCT_MODULE_NAME"] = "_{}_".format(product_name)

    return struct(
        bundle_path = bundle_path,
        minimum_deployment_os_version = minimum_deployment_version,
        product_name = product_name,
        product_type = product_type,
    )

def _process_libraries(
    *,
    product_type,
    test_host_libraries,
    links,
    required_links):
    if (test_host_libraries and
        product_type == "com.apple.product-type.bundle.unit-test"):
        # Unit tests have their test host as a bundle loader. So the
        # test host and its dependencies should be removed from the
        # unit test's links.
        avoid_links = [
            file.path for file in test_host_libraries.to_list()
        ]

        def remove_avoided(links):
            return sets.to_list(
                sets.difference(sets.make(links), sets.make(avoid_links))
            )

        links = [file for file in remove_avoided(links)]
        required_links = [file for file in remove_avoided(required_links)]

    return links, required_links

def _process_test_host(test_host, *, dependencies):
    if test_host:
        test_host_target = test_host[XcodeProjInfo].target
        dependencies = dependencies + [test_host_target.id]
    else:
        test_host_target = None

    return test_host_target, dependencies

def _process_top_level_target(*, ctx, target, bundle_info):
    """Gathers information about a top-level target.

    Args:
        ctx: The aspect context.
        target: The `Target` to process.
        bundle_info: The `AppleBundleInfo` provider for `target`, or `None`.

    Returns:
        A `struct` containing the following fields:

        *   `potential_target_merges`: A list of `struct`s that will be in the
            `XcodeProjInfo.potential_target_merges` `depset`.
        *   `required_links`: An array of file paths that will be in the
            `XcodeProjInfo.required_links` `depset`.
        *   `target`: The `XcodeProjInfo.target` struct.
        *   `xcode_target`: A string that will be in the
            `XcodeProjInfo.xcode_targets` `depset`.
    """
    configuration = _get_configuration(ctx)
    id = _get_id(label = target.label, configuration = configuration)

    if len(ctx.rule.attr.deps) > 1:
        fail("xcodeproj requires {} rules to have a single dep. {} has {}"
          .format(ctx.rule.kind, target.label, len(ctx.rule.attr.deps)))
    merged_target = ctx.rule.attr.deps[0][XcodeProjInfo].target
    libraries = merged_target.libraries
    potential_target_merges = [struct(src = merged_target.id, dest = id)]

    build_settings = process_opts(ctx = ctx, target = target)

    tree_artifact_enabled = (
        ctx.var.get("apple.experimental.tree_artifact_outputs", "").lower()
          in ("true", "yes", "1")
    )
    props = _process_top_level_properties(
        target_name = ctx.rule.attr.name,
        # The common case is to have a `bundle_info`, so this check prevents
        # expanding the `depset` unless needed. Yes, this uses knowledge of what
        # `_process_top_level_properties()` does internally.
        files = [] if bundle_info else target.files.to_list(),
        bundle_info = bundle_info,
        tree_artifact_enabled = tree_artifact_enabled,
        build_settings = build_settings,
    )

    test_host_target, dependencies = _process_test_host(
        getattr(ctx.rule.attr, "test_host", None),
        dependencies = [merged_target.id],
    )

    libraries_list = libraries.to_list()
    links, required_links = _process_libraries(
        product_type = props.product_type,
        test_host_libraries = (
            test_host_target.libraries if test_host_target else None
        ),
        links = [
            library.path
            for library in libraries_list
        ],
        required_links = [
            library.path
            for library in libraries_list
            if library.owner != merged_target.label
        ],
    )

    build_settings["OTHER_LDFLAGS"] = ["-ObjC"] + build_settings.get(
        "OTHER_LDFLAGS", [],
    )

    set_if_true(
        build_settings,
        "TARGETED_DEVICE_FAMILY",
        get_targeted_device_family(getattr(ctx.rule.attr, "families", [])),
    )

    platform = process_platform(
        ctx = ctx,
        minimum_deployment_os_version = props.minimum_deployment_os_version,
        build_settings = build_settings,
    )

    return struct(
        potential_target_merges = potential_target_merges,
        required_links = required_links,
        target = struct(
            id = id,
            label = target.label,
            build_settings = build_settings,
            srcs = [],
            libraries = libraries,
            dependencies = dependencies,
        ),
        xcode_target = _xcode_target(
            id = id,
            name = props.product_name,
            label = str(target.label),
            configuration = configuration,
            platform = platform,
            product = _process_product(
                target,
                props.product_name,
                props.product_type,
                props.bundle_path,
                build_settings
            ),
            test_host = test_host_target.id if test_host_target else None,
            build_settings = build_settings,
            srcs = [],
            links = links,
            dependencies = dependencies,
            outputs = _process_outputs(target),
        ),
    )

# Library targets

def _process_library_target(*, ctx, target, srcs, transitive_infos):
    """Gathers information about a library target.

    Args:
        ctx: The aspect context.
        target: The `Target` to process.
        srcs: A `list` of source file paths for `target`.
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of `target`.

    Returns:
        A `struct` containing the following fields:

        *   `potential_target_merges`: A list of `struct`s that will be in the
            `XcodeProjInfo.potential_target_merges` `depset`.
        *   `required_links`: An array of file paths that will be in the
            `XcodeProjInfo.required_links` `depset`.
        *   `target`: The `XcodeProjInfo.target` struct.
        *   `xcode_target`: A string that will be in the
            `XcodeProjInfo.xcode_targets` `depset`.
    """
    configuration = _get_configuration(ctx)
    id = _get_id(label = target.label, configuration = configuration)

    build_settings = process_opts(ctx = ctx, target = target)
    product_name = ctx.rule.attr.name
    module_name = get_product_module_name(ctx = ctx, target = target)
    build_settings["PRODUCT_MODULE_NAME"] = module_name
    dependencies = [info.target.id for info in transitive_infos if info.target]
    libraries = target[apple_common.Objc].library

    cpp = ctx.fragments.cpp
    # TODO: Get the value for device builds, even when active config is not for
    # device, as Xcode only uses this value for device builds
    build_settings["ENABLE_BITCODE"] = str(cpp.apple_bitcode_mode) != "none"

    debug_format = "dwarf-with-dsym" if cpp.apple_generate_dsym else "dwarf"
    build_settings["DEBUG_INFORMATION_FORMAT"] = debug_format

    set_if_true(
        build_settings,
        "CLANG_ENABLE_MODULES",
        getattr(ctx.rule.attr, "enable_modules", False),
    )

    set_if_true(
        build_settings,
        "ENABLE_TESTING_SEARCH_PATHS",
        getattr(ctx.rule.attr, "testonly", False),
    )

    platform = process_platform(
        ctx = ctx,
        minimum_deployment_os_version = None,
        build_settings = build_settings,
    )

    return struct(
        potential_target_merges = [],
        required_links = [],
        target = struct(
            id = id,
            label = target.label,
            build_settings = build_settings,
            srcs = srcs,
            libraries = libraries,
            dependencies = dependencies,
        ),
        xcode_target = _xcode_target(
            id = id,
            name = module_name,
            label = str(target.label),
            product = _process_product(
                target,
                product_name,
                "com.apple.product-type.library.static",
                None,
                build_settings,
            ),
            configuration = configuration,
            platform = platform,
            build_settings = build_settings,
            test_host = None,
            srcs = srcs,
            links = [],
            dependencies = dependencies,
            outputs = _process_outputs(target),
        ),
    )

# Creating `XcodeProjInfo`

def _should_process_target(target):
    """Determines if the given target should be included in the Xcode project.

    Args:
        target: The `Target` to check.

    Returns:
        `False` if `target` shouldn't become an actual target in the generated
        Xcode project. Resource bundles are a current example of this, as we
        only include their files in the project, but we don't create targets
        for them.
    """
    return AppleResourceBundleInfo not in target and target.files != depset()

def _should_passthrough_target(*, ctx, target):
    """Determines if the given target should be skipped for target generation.

    There are some rules, like the test runners for iOS tests, that we want to
    ignore. Nothing from those rules are considered.

    Args:
        ctx: The aspect context.
        target: The `Target` to check.

    Returns:
        `True` if `target` should be skipped for target generation.
    """
    # TODO: Find a way to detect TestEnvironment instead
    return (
        IosXcTestBundleInfo in target
        and len(ctx.rule.attr.deps) == 1
        and IosXcTestBundleInfo in ctx.rule.attr.deps[0]
    )

def _target_info_fields(
    *,
    potential_target_merges,
    required_links,
    target,
    xcode_targets):
    """Generates target specific fields for the `XcodeProjInfo`.

    This should be merged with other fields to fully create an `XcodeProjInfo`.

    Args:
        potential_target_merges: Maps to the
            `XcodeProjInfo.potential_target_merges` field.
        required_links: Maps to the `XcodeProjInfo.required_links` field.
        target: Maps to the `XcodeProjInfo.target` field.
        xcode_targets: Maps to the `XcodeProjInfo.xcode_targets` field.

    Returns:
        A `dict` containing the following fields:

        *   `potential_target_merges`
        *   `required_links`
        *   `target`
        *   `xcode_targets`
    """
    return {
        "potential_target_merges": potential_target_merges,
        "required_links": required_links,
        "target": target,
        "xcode_targets": xcode_targets,
    }

def _passthrough_target(*, transitive_infos):
    """Passes through existing target info fields, not collecting new ones.

    Merges `XcodeProjInfo`s for the dependencies of the current target, and
    forwards them on, not collecting any information for the current target.

    Args:
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of `target`.

    Returns:
        The return value of `_target_info_fields()`, with values merged from
        `transitive_infos`.
    """
    return _target_info_fields(
        potential_target_merges = depset(
            transitive = [
                info.potential_target_merges for info in transitive_infos
            ],
        ),
        required_links = depset(
            transitive = [info.required_links for info in transitive_infos],
        ),
        target = None,
        xcode_targets = depset(
            transitive = [info.xcode_targets for info in transitive_infos],
        ),
    )

def _process_target(*, ctx, target, srcs, transitive_infos):
    """Creates the target portion of an `XcodeProjInfo` for a `Target`.

    Args:
        ctx: The aspect context.
        target: The `Target` to process.
        srcs: A `list` of source file paths for `target`.
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of `target`.

    Returns:
        A `dict` of fields to be merged into the `XcodeProjInfo`. See
        `_target_info_fields()`.
    """
    if AppleBundleInfo in target:
        processed_target = _process_top_level_target(
            ctx = ctx,
            target = target,
            bundle_info = target[AppleBundleInfo],
        )
    elif target[DefaultInfo].files_to_run.executable:
        processed_target = _process_top_level_target(
            ctx = ctx,
            target = target,
            bundle_info = None,
        )
    else:
        processed_target = _process_library_target(
            ctx = ctx,
            target = target,
            srcs = srcs,
            transitive_infos = transitive_infos,
        )

    return _target_info_fields(
        potential_target_merges = depset(
            processed_target.potential_target_merges,
            transitive = [
                info.potential_target_merges for info in transitive_infos
            ],
        ),
        required_links = depset(
            processed_target.required_links,
            transitive = [info.required_links for info in transitive_infos],
        ),
        target = processed_target.target,
        xcode_targets = depset(
            [processed_target.xcode_target],
            transitive = [info.xcode_targets for info in transitive_infos],
        ),
    )

# API

def process_target(*, ctx, target, transitive_infos):
    """Creates an `XcodeProjInfo` for the given target.

    Args:
        ctx: The aspect context.
        target: The `Target` to process.
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of `target`.

    Returns:
        An `XcodeProjInfo` populated with information from `target` and
        `transitive_infos`.
    """
    inputs = _input_files(ctx = ctx, transitive_infos = transitive_infos)

    if not _should_process_target(target):
        return XcodeProjInfo(
            all_inputs = inputs.all_inputs,
            potential_target_merges = depset(),
            extra_files = inputs.extra_files,
            required_links = depset(),
            target = None,
            unbound_srcs = inputs.unbound_srcs,
            xcode_targets = depset(),
        )

    if _should_passthrough_target(ctx = ctx, target = target):
        info_fields = _passthrough_target(
            transitive_infos = transitive_infos,
        )
    else:
        info_fields = _process_target(
            ctx = ctx,
            target = target,
            srcs = [file.path for file in inputs.unbound_srcs.to_list()],
            transitive_infos = transitive_infos,
        )

    return XcodeProjInfo(
        all_inputs = inputs.all_inputs,
        extra_files = inputs.extra_files,
        unbound_srcs = depset(),
        **info_fields
    )

# These functions are exposed only for access in unit tests.
testable = struct(
    calculate_configuration = _calculate_configuration,
    process_libraries = _process_libraries,
    process_top_level_properties = _process_top_level_properties,
)
