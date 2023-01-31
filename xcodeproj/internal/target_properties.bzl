"""Functions for processing target properties"""

load(":collections.bzl", "set_if_true", "uniq")

def should_include_non_xcode_outputs(ctx):
    """Determines whether outputs of non Xcode targets should be included in \
    output groups.

    Args:
        ctx: The aspect context.

    Returns:
        `True` if the outputs should be included, `False` otherwise. This will
        be `True` for modes that build primarily with Xcode.
    """
    return ctx.attr._build_mode == "xcode"

def process_dependencies(*, automatic_target_info, transitive_infos):
    """Logic for processing target dependencies.

    Args:
        automatic_target_info: Attribute information
        transitive_infos: Transitive information of the deps

    Returns:
        A `tuple` containing two elements:

        *   A `depset` of direct dependencies.
        *   A `depset` of direct and transitive dependencies.
    """
    direct_dependencies = []
    direct_transitive_dependencies = []
    all_transitive_dependencies = []
    for attr, info in transitive_infos:
        if not (not automatic_target_info or
                info.target_type in automatic_target_info.xcode_targets.get(
                    attr,
                    [None],
                )):
            continue
        all_transitive_dependencies.append(info.transitive_dependencies)
        if info.xcode_target and info.xcode_target.should_create_xcode_target:
            # TODO: Refactor `should_create_xcode_target` and
            # `should_generate_target` handling. The only reason we don't use
            # `should_generate_target` for header-only targets is because we
            # want to be able to unfocus their files.
            direct_dependencies.append(info.xcode_target.id)
        else:
            # We pass on the next level of dependencies if the previous target
            # didn't create an Xcode target.
            direct_transitive_dependencies.append(info.dependencies)

    direct = depset(
        direct_dependencies,
        transitive = direct_transitive_dependencies,
    )
    transitive = depset(
        direct_dependencies,
        transitive = all_transitive_dependencies,
    )
    return (direct, transitive)

def process_modulemaps(*, swift_info):
    """Logic for working with modulemaps and their paths.

    Args:
        swift_info: A `SwiftInfo` provider.

    Returns:
        A `tuple` of files of the modules maps of the passed `SwiftInfo`.
    """
    if not swift_info:
        return ()

    modulemap_files = []
    for module in swift_info.direct_modules:
        compilation_context = module.compilation_context
        if not compilation_context:
            continue

        for module_map in compilation_context.module_maps:
            if type(module_map) == "File":
                modulemap_files.append(module_map)

    # Different modules might be defined in the same modulemap file, so we need
    # to deduplicate them.
    return tuple(uniq(modulemap_files))

def process_codesignopts(*, codesignopts, build_settings):
    """Logic for processing code signing flags.

    Args:
        codesignopts: A `list` of code sign options
        build_settings: A mutable `dict` that will be updated with code signing
            flag build settings that are processed.
    Returns:
        The modified build settings object
    """
    if codesignopts and build_settings != None:
        set_if_true(build_settings, "OTHER_CODE_SIGN_FLAGS", codesignopts)

def process_swiftmodules(*, swift_info):
    """Processes swiftmodules.

    Args:
        swift_info: The `SwiftInfo` provider for the target.

    Returns:
        A `list` of `File`s of dependent swiftmodules.
    """
    if not swift_info:
        return []

    files = []
    for module in swift_info.direct_modules:
        compilation_context = module.compilation_context
        if not compilation_context:
            continue

        files.extend(compilation_context.swiftmodules)

    return files
