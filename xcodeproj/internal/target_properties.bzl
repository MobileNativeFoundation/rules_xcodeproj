"""Functions for processing target properties"""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("@bazel_skylib//lib:collections.bzl", "collections")
load(":collections.bzl", "set_if_true", "uniq")
load(
    ":files.bzl",
    "file_path",
)

def should_bundle_resources(ctx):
    """Determines whether resources should be bundled in the generated project.

    Args:
        ctx: The aspect context.

    Returns:
        `True` if resources should be bundled, `False` otherwise.
    """
    return ctx.attr._build_mode[BuildSettingInfo].value != "bazel"

def should_include_outputs(ctx):
    """Determines whether outputs should be included in the generated project.

    Args:
        ctx: The aspect context.

    Returns:
        `True` if outputs should be included, `False` otherwise. This will be
        `True` for Build with Bazel projects and portions of the build that
        need to build with Bazel (i.e. Focused Projects).
    """
    return ctx.attr._build_mode[BuildSettingInfo].value != "xcode"

def process_dependencies(*, attrs_info, transitive_infos):
    """ Logic for processing target dependencies

    Args:
        attrs_info: Attribute information
        transitive_infos: Transitive information of the deps

    Returns:
        A depset of direct and transitive dependencies
    """
    direct_dependencies = []
    transitive_dependencies = []
    for attr, info in transitive_infos:
        if not (not attrs_info or
                info.target_type in attrs_info.xcode_targets.get(attr, [None])):
            continue
        if info.target:
            direct_dependencies.append(info.target.id)
        else:
            # We pass on the next level of dependencies if the previous target
            # didn't create an Xcode target.
            transitive_dependencies.append(info.dependencies)

    return depset(
        direct_dependencies,
        transitive = transitive_dependencies,
    )

def process_modulemaps(*, swift_info):
    """ Logic for working with modulemaps and their paths

    Args:
        swift_info: A SwiftInfo provider

    Returns:
        A struct containing the files and paths of the modules maps of the passed SwiftInfo
    """
    if not swift_info:
        return struct(
            file_paths = [],
            files = [],
        )

    modulemap_file_paths = []
    modulemap_files = []
    for module in swift_info.direct_modules:
        for module_map in module.compilation_context.module_maps:
            if type(module_map) == "File":
                modulemap = file_path(module_map)
                modulemap_files.append(module_map)
            else:
                modulemap = module_map

            modulemap_file_paths.append(modulemap)

    # Different modules might be defined in the same modulemap file, so we need
    # to deduplicate them.
    return struct(
        file_paths = uniq(modulemap_file_paths),
        files = uniq(modulemap_files),
    )

def process_defines(*, cc_info, build_settings):
    """ Logic for processing defines of a module

    Args:
        cc_info: A CcInfo provider object
        build_settings: build settings of the target

    Return:
        The modified build settings object
    """
    if cc_info and build_settings != None:
        # We don't set `SWIFT_ACTIVE_COMPILATION_CONDITIONS` because the way we
        # process Swift compile options already accounts for `defines`

        # Order should be:
        # - toolchain defines
        # - defines
        # - local defines
        # - copt defines
        # but since build_settings["GCC_PREPROCESSOR_DEFINITIONS"] will have
        # "toolchain defines" and "copt defines", those will both be first
        # before "defines" and "local defines". This will only matter if `copts`
        # is used to override `defines` instead of `local_defines`. If that
        # becomes an issue in practice, we can refactor `process_copts` to
        # support this better.

        defines = depset(
            transitive = [
                cc_info.compilation_context.defines,
                cc_info.compilation_context.local_defines,
            ],
        )
        escaped_defines = [
            define.replace("\\", "\\\\").replace('"', '\\"')
            for define in defines.to_list()
        ]

        setting = build_settings.get(
            "GCC_PREPROCESSOR_DEFINITIONS",
            [],
        ) + escaped_defines

        # Remove duplicates
        setting = reversed(uniq(reversed(setting)))

        set_if_true(build_settings, "GCC_PREPROCESSOR_DEFINITIONS", setting)

def process_sdk_links(*, objc, build_settings):
    """ Processing sdk linker options

    Args:
        objc: A ObjC provider
        build_settings: Build settings for the passed target

    Returns:
        The mutated build settings object
    """
    if not objc or build_settings == None:
        return

    sdk_framework_flags = collections.before_each(
        "-framework",
        objc.sdk_framework.to_list(),
    )
    weak_sdk_framework_flags = collections.before_each(
        "-weak_framework",
        objc.weak_sdk_framework.to_list(),
    )
    sdk_dylib_flags = [
        "-l" + dylib
        for dylib in objc.sdk_dylib.to_list()
    ]

    set_if_true(
        build_settings,
        "OTHER_LDFLAGS",
        (sdk_framework_flags +
         weak_sdk_framework_flags +
         sdk_dylib_flags +
         build_settings.get("OTHER_LDFLAGS", [])),
    )

def process_swiftmodules(*, swift_info):
    """ Processs swiftmodules

    Args:
        swift_info: A SwiftInfo provider object

    Returns:
        The filepaths of all direct module swiftmodules
    """
    if not swift_info:
        return []

    swiftmodules = []
    for module in swift_info.direct_modules:
        for swiftmodule in module.compilation_context.swiftmodules:
            swiftmodules.append(file_path(swiftmodule))

    return swiftmodules
