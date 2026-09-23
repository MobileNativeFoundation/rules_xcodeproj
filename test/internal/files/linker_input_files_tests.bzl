"""Tests for static-library Xcode Preview linker inputs."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:compilation_providers.bzl", "compilation_providers")

# buildifier: disable=bzl-visibility
load(
    "//xcodeproj/internal/files:linker_input_files.bzl",
    "linker_input_files",
)

# buildifier: disable=bzl-visibility
load(
    "//xcodeproj/internal/files:output_files.bzl",
    "output_files",
    "output_groups",
)

def _paths(files):
    return [file.path for file in files]

def _static_library_preview_libraries_test_impl(ctx):
    env = unittest.begin(ctx)

    primary = ctx.actions.declare_file("libSubject.a")
    first_dependency = ctx.actions.declare_file("libFirstDependency.a")
    second_dependency = ctx.actions.declare_file("libSecondDependency.a")
    for file in [primary, first_dependency, second_dependency]:
        ctx.actions.write(file, "test\n")
    linker_inputs = struct(
        _cc_linker_inputs = (),
        _objc_libraries = (
            primary,
            first_dependency,
            first_dependency,
            second_dependency,
        ),
        _primary_static_library = primary,
    )

    libraries = linker_input_files.get_static_library_preview_libraries(
        linker_inputs,
    )

    asserts.equals(
        env,
        [first_dependency.path, second_dependency.path],
        _paths(libraries),
        "Preview closure excludes the target's own archive and is deduplicated",
    )

    return unittest.end(env)

static_library_preview_libraries_test = unittest.make(
    _static_library_preview_libraries_test_impl,
)

def _static_library(*, static, alwayslink = False, pic = None):
    return struct(
        alwayslink = alwayslink,
        dynamic_library = None,
        pic_static_library = pic,
        resolved_symlink_dynamic_library = None,
        static_library = static,
    )

def _source_static_library_preview_libraries_test_impl(ctx):
    env = unittest.begin(ctx)

    primary = ctx.actions.declare_file("libSubject.a")
    generated_dependency = ctx.actions.declare_file(
        "libGeneratedDependency.a",
    )
    for file in [primary, generated_dependency]:
        ctx.actions.write(file, "test\n")

    source_dependency = ctx.file.source_dependency
    linker_inputs = struct(
        _cc_linker_inputs = (
            struct(libraries = [
                _static_library(static = primary),
                _static_library(static = source_dependency),
                _static_library(static = source_dependency),
                _static_library(static = generated_dependency),
            ]),
        ),
        _objc_libraries = (),
        _primary_static_library = primary,
    )

    libraries = linker_input_files.get_static_library_preview_libraries(
        linker_inputs,
    )

    asserts.equals(
        env,
        [source_dependency.path, generated_dependency.path],
        _paths(libraries),
        (
            "Preview closure retains a cc_import-style source archive, " +
            "excludes the target's generated product, and deduplicates"
        ),
    )

    return unittest.end(env)

source_static_library_preview_libraries_test = unittest.make(
    impl = _source_static_library_preview_libraries_test_impl,
    attrs = {
        "source_dependency": attr.label(
            allow_single_file = [".a"],
            default = Label(
                "//test/internal/files:testdata/libSourceDependency.a",
            ),
        ),
    },
)

def _static_library_preview_path_boundaries_test_impl(ctx):
    env = unittest.begin(ctx)

    # Reduced File-shaped boundaries complement the real source/generated
    # artifacts consumed by static_library_preview_link_params_test.
    cases = [
        ("vendor/libSource.a", True, "$(SRCROOT)/vendor/libSource.a"),
        ("bazel-out/config/bin/libGenerated.a", False, "$(PROJECT_DIR)/bazel-out/config/bin/libGenerated.a"),
        ("external/repo/libSource.a", True, "$(PROJECT_DIR)/external/repo/libSource.a"),
        ("../repo/libSource.a", True, "$(PROJECT_DIR)/../repo/libSource.a"),
        ("vendor/../libSource.a", True, "$(PROJECT_DIR)/vendor/../libSource.a"),
        ("/absolute/libSource.a", True, "/absolute/libSource.a"),
        ("$(BAZEL_EXTERNAL)/repo/libSource.a", True, "$(BAZEL_EXTERNAL)/repo/libSource.a"),
        ("vendor/libStandalone.dylib", True, "$(PROJECT_DIR)/vendor/libStandalone.dylib"),
    ]
    files = [struct(
        path = path,
        is_source = is_source,
        extension = path.rsplit(".", 1)[-1],
        owner = ctx.label,
        basename = path.rsplit("/", 1)[-1],
        dirname = path.rsplit("/", 1)[0],
    ) for path, is_source, _ in cases]
    selected = ctx.actions.declare_file("PathBoundaries/Selected.a")
    ctx.actions.write(selected, "unused selected archive\n")
    writes = {}

    def write(*, output, content):
        writes[output.path] = content
        ctx.actions.write(output, content)

    preview = linker_input_files.create_static_library_preview_link_params(
        actions = struct(declare_file = ctx.actions.declare_file, write = write),
        name = "PathBoundaries",
        linker_inputs = struct(
            _cc_linker_inputs = (struct(libraries = (
                [_static_library(static = selected)] +
                [_static_library(static = file, alwayslink = file == files[0]) for file in files[:-1]] +
                [_dynamic_library(dynamic = files[-1])]
            )),),
            _compilation_providers = struct(cc_info = True, framework_files = depset(), objc = None),
            _objc_libraries = (),
            _primary_static_library = selected,
        ),
    )
    expected = ["-ObjC", "-force_load"] + [
        '"' + path + '"' if "$(" in path else path
        for _, _, path in cases
    ]
    asserts.equals(env, "\n".join(expected) + "\n", writes[preview.file.path])
    asserts.equals(env, _paths(files) + [preview.file.path + ".runtime.json"], _paths(preview.link_input_files), "Path anchoring does not change preparation ownership or retain the selected archive")
    asserts.equals(env, "[]\n", writes[preview.file.path + ".runtime.json"])
    return unittest.end(env)

static_library_preview_path_boundaries_test = unittest.make(
    _static_library_preview_path_boundaries_test_impl,
)

def _dynamic_library(*, dynamic, resolved = None, static = None, pic = None):
    return struct(
        alwayslink = False,
        dynamic_library = dynamic,
        pic_static_library = pic,
        resolved_symlink_dynamic_library = resolved,
        static_library = static,
    )

def _merged_static_library_preview_libraries_test_impl(ctx):
    env = unittest.begin(ctx)
    clang = ctx.actions.declare_file("libMixed_clang.a")
    swift = ctx.actions.declare_file("libMixed_swift.a")
    dependency = ctx.actions.declare_file("dependency/libMixed_swift.a")
    for file in [clang, swift, dependency]:
        ctx.actions.write(file, "test\n")

    inputs = struct(
        _cc_linker_inputs = (struct(libraries = [
            _static_library(static = clang),
            _static_library(static = swift, alwayslink = True),
            _static_library(static = dependency),
            _static_library(static = dependency),
        ]),),
        _compilation_providers = struct(cc_info = True, framework_files = depset(), objc = None),
        _objc_libraries = (),
        _primary_static_library = clang,
    )
    preview = linker_input_files.create_static_library_preview_link_params(
        actions = ctx.actions,
        linker_inputs = inputs,
        name = "Merged",
        product_files = (clang, swift),
    )
    asserts.equals(env, [dependency], list(preview.libraries))
    asserts.equals(env, [dependency.path, preview.file.path + ".runtime.json"], _paths(preview.link_input_files))
    asserts.equals(
        env,
        [swift, dependency],
        linker_input_files.get_static_library_preview_libraries(
            inputs,
            product_files = (clang,),
        ),
        "Retain an unmerged Swift dependency; filter by exact File, not basename",
    )
    return unittest.end(env)

merged_static_library_preview_libraries_test = unittest.make(
    _merged_static_library_preview_libraries_test_impl,
)

def _standalone_dynamic_library_preview_closure_test_impl(ctx):
    env = unittest.begin(ctx)

    solib = ctx.actions.declare_file("_solib/libStandalone.dylib")
    resolved = ctx.actions.declare_file("prebuilt/libStandalone.dylib")
    fallback = ctx.actions.declare_file("deps/libFallback.dylib")
    framework_internal = ctx.actions.declare_file(
        "Sample.framework/libInternal.dylib",
    )
    for file in [solib, resolved, fallback, framework_internal]:
        ctx.actions.write(file, "test\n")

    preview = linker_input_files.create_static_library_preview_link_params(
        actions = ctx.actions,
        linker_inputs = struct(
            _cc_linker_inputs = (
                struct(libraries = [
                    _dynamic_library(dynamic = solib, resolved = resolved),
                    _dynamic_library(dynamic = solib, resolved = resolved),
                    _dynamic_library(dynamic = fallback),
                    _dynamic_library(dynamic = framework_internal),
                ]),
            ),
            _compilation_providers = struct(
                cc_info = True,
                framework_files = depset(),
                objc = None,
            ),
            _objc_libraries = (),
            _primary_static_library = None,
        ),
        name = "StandaloneOnly",
    )

    asserts.true(env, preview != None, "standalone-only closure emits params")
    if preview:
        asserts.equals(env, [], list(preview.libraries))
        asserts.equals(env, [], list(preview.dynamic_frameworks))
        asserts.equals(
            env,
            [resolved.path, fallback.path, preview.file.path + ".runtime.json"],
            _paths(preview.link_input_files),
            "materialize the emitted artifact, preferring resolved files and deduplicating in linker order",
        )
        (_, _, metadata) = output_files.collect(
            actions = ctx.actions,
            compile_params_files = [],
            debug_outputs = None,
            id = "standalone",
            link_params = preview.file,
            name = ctx.label.name,
            output_group_info = None,
            preview_link_input_files = preview.link_input_files,
            swift_info = None,
            transitive_infos = [],
        )
        groups = output_groups.to_output_groups_fields(
            target_output_groups = output_groups.collect(
                metadata = metadata,
                transitive_infos = [],
            ),
        )
        asserts.equals(
            env,
            [preview.file.path, resolved.path, fallback.path, preview.file.path + ".runtime.json"],
            _paths(groups["bl standalone"].to_list()),
            "the Preview output group requests exact standalone producers",
        )
        asserts.equals(env, [], groups["bf standalone"].to_list())
        asserts.false(env, resolved in groups["bp standalone"].to_list())

    return unittest.end(env)

standalone_dynamic_library_preview_closure_test = unittest.make(
    _standalone_dynamic_library_preview_closure_test_impl,
)

def _static_library_preview_dynamic_frameworks_test_impl(ctx):
    env = unittest.begin(ctx)

    lottie_generated = ctx.actions.declare_file(
        "generated/Lottie.framework/Lottie",
    )
    lottie_resolved = ctx.actions.declare_file(
        "source/Lottie.framework/Lottie",
    )
    analytics = ctx.actions.declare_file(
        "generated/Analytics.framework/Analytics",
    )
    malformed = ctx.actions.declare_file("generated/libLoose.dylib")
    duplicate_lottie_file = ctx.actions.declare_file(
        "other/Lottie.framework/Info.plist",
    )
    fallback = ctx.actions.declare_file(
        "generated/Fallback.framework/Fallback",
    )
    incomplete_fallback = ctx.actions.declare_file(
        "generated/Incomplete.framework/Info.plist",
    )
    files = [
        lottie_generated,
        lottie_resolved,
        analytics,
        malformed,
        duplicate_lottie_file,
        fallback,
        incomplete_fallback,
    ]
    for file in files:
        ctx.actions.write(file, "test\n")

    linker_inputs = struct(
        _cc_linker_inputs = (
            struct(libraries = [
                _dynamic_library(
                    dynamic = lottie_generated,
                    resolved = lottie_resolved,
                ),
                _dynamic_library(
                    dynamic = lottie_generated,
                    resolved = lottie_resolved,
                ),
                _dynamic_library(dynamic = malformed),
            ]),
            struct(libraries = [
                _dynamic_library(dynamic = analytics),
            ]),
        ),
        _compilation_providers = struct(
            cc_info = True,
            framework_files = depset([
                duplicate_lottie_file,
                fallback,
                incomplete_fallback,
            ]),
            objc = None,
        ),
    )

    dynamic_frameworks = (
        linker_input_files.get_static_library_preview_dynamic_frameworks(
            linker_inputs,
        )
    )

    asserts.equals(
        env,
        [
            lottie_resolved.path,
            analytics.path,
            fallback.path,
        ],
        _paths(dynamic_frameworks),
        "dynamic frameworks preserve linker order, prefer resolved files, and deduplicate names",
    )

    # Duplicate basenames must not fail generation for projects that never
    # select native Previews. The selected staging script diagnoses collisions.
    collision = struct(
        _cc_linker_inputs = (
            struct(libraries = [
                _dynamic_library(dynamic = lottie_generated),
                _dynamic_library(dynamic = lottie_resolved),
            ]),
        ),
        _compilation_providers = struct(objc = None, framework_files = depset()),
    )
    asserts.equals(
        env,
        [lottie_generated, lottie_resolved],
        linker_input_files.get_static_library_preview_dynamic_frameworks(collision),
    )

    return unittest.end(env)

static_library_preview_dynamic_frameworks_test = unittest.make(
    _static_library_preview_dynamic_frameworks_test_impl,
)

def _dynamic_only_static_library_preview_closure_test_impl(ctx):
    env = unittest.begin(ctx)

    lottie = ctx.actions.declare_file("Lottie.framework/Lottie")
    ctx.actions.write(lottie, "test\n")
    preview_link_params = (
        linker_input_files.create_static_library_preview_link_params(
            actions = ctx.actions,
            linker_inputs = struct(
                _cc_linker_inputs = (),
                _compilation_providers = struct(
                    cc_info = None,
                    framework_files = depset(),
                    objc = struct(
                        dynamic_framework_file = depset([lottie]),
                    ),
                ),
                _objc_libraries = (),
                _primary_static_library = None,
            ),
            name = "DynamicOnly",
        )
    )

    asserts.true(
        env,
        preview_link_params.file != None,
        "dynamic-only closure emits canonical framework params",
    )
    asserts.equals(
        env,
        [],
        list(preview_link_params.libraries),
        "dynamic-only closure has no archive inputs",
    )
    asserts.equals(
        env,
        [preview_link_params.file.path + ".runtime.json"],
        _paths(preview_link_params.link_input_files),
        "dynamic-only closure materializes frameworks through their output group",
    )

    return unittest.end(env)

dynamic_only_static_library_preview_closure_test = unittest.make(
    _dynamic_only_static_library_preview_closure_test_impl,
)

def _static_library_preview_framework_mapping_test_impl(ctx):
    env = unittest.begin(ctx)

    lottie_linker = ctx.actions.declare_file("Lottie.framework/Lottie")
    analytics_linker = ctx.actions.declare_file(
        "Analytics.framework/Analytics",
    )
    lottie_product = ctx.actions.declare_directory(
        "products/Lottie.framework",
    )
    for file in [lottie_linker, analytics_linker]:
        ctx.actions.write(file, "test\n")
    ctx.actions.run_shell(
        outputs = [lottie_product],
        command = "mkdir -p \"$1\"",
        arguments = [lottie_product.path],
    )

    mapped = (
        linker_input_files.map_static_library_preview_dynamic_frameworks(
            dynamic_frameworks = [lottie_linker, analytics_linker],
            framework_product_mappings = [
                (lottie_linker, lottie_product),
            ],
        )
    )

    asserts.equals(
        env,
        [
            (lottie_product.path, True),
            (analytics_linker.path, False),
        ],
        [(file.path, is_framework) for file, is_framework in mapped],
        "framework products are transported whole with executable fallback",
    )

    return unittest.end(env)

static_library_preview_framework_mapping_test = unittest.make(
    _static_library_preview_framework_mapping_test_impl,
)

def _static_library_preview_link_params_test_impl(ctx):
    primary = ctx.actions.declare_file("libSubject.a")
    dependency = ctx.actions.declare_file("deps With Spaces/libDependency.a")
    alwayslink_dependency = ctx.actions.declare_file(
        "deps With Spaces/libAlwayslinkDependency.a",
    )
    lottie = ctx.actions.declare_file(
        "Lottie With Spaces.framework/Lottie With Spaces",
    )
    solib = ctx.actions.declare_file("_solib/libStandalone.dylib")
    resolved = ctx.actions.declare_file("prebuilt With Spaces/libStandalone.dylib")
    fallback = ctx.actions.declare_file("deps/libFallback.dylib")
    unused_dynamic = ctx.actions.declare_file("deps/libStaticAlternative.dylib")
    for file in [
        primary,
        dependency,
        alwayslink_dependency,
        lottie,
        solib,
        resolved,
        fallback,
        unused_dynamic,
    ]:
        ctx.actions.write(file, "test\n")
    source_dependency = ctx.file.source_dependency

    preview_link_params = (
        linker_input_files.create_static_library_preview_link_params(
            actions = ctx.actions,
            linker_inputs = struct(
                _cc_linker_inputs = (
                    struct(libraries = [
                        _static_library(static = primary),
                        _static_library(static = dependency),
                        _static_library(static = source_dependency),
                        _static_library(
                            static = alwayslink_dependency,
                            alwayslink = True,
                        ),
                        _dynamic_library(dynamic = lottie),
                        _dynamic_library(dynamic = solib, resolved = resolved),
                        _dynamic_library(dynamic = solib, resolved = resolved),
                        _dynamic_library(dynamic = fallback),
                        _dynamic_library(
                            dynamic = unused_dynamic,
                            static = dependency,
                        ),
                        _dynamic_library(
                            dynamic = unused_dynamic,
                            pic = alwayslink_dependency,
                        ),
                    ], user_link_flags = ["-Wl,-add_ast_path,Selected.swiftmodule"] if ctx.attr.process_link_flags else []),
                ),
                _compilation_providers = struct(
                    cc_info = True,
                    framework_files = depset(),
                    objc = None,
                ),
                _objc_libraries = (),
                _primary_static_library = primary,
            ),
            name = ctx.label.name,
            tool = ctx.executable._link_params_processor,
        )
    )

    verified = ctx.actions.declare_file(ctx.label.name + ".verified")
    ctx.actions.run_shell(
        inputs = [preview_link_params.file],
        outputs = [verified],
        arguments = [
            preview_link_params.file.path,
            dependency.path,
            source_dependency.path,
            alwayslink_dependency.path,
            resolved.path,
            fallback.path,
            verified.path,
        ],
        command = """\
set -euo pipefail

diff -u <(printf '%s\\n' \\
  '"-F$(TARGET_BUILD_DIR)"' \\
  '-framework' \\
  '"Lottie With Spaces"' \\
  '-rpath' \\
  '"$(TARGET_BUILD_DIR)"' \\
  '-ObjC' \\
  '"$(PROJECT_DIR)/'"$2"'"' \\
  '"$(SRCROOT)/'"$3"'"' \\
  '-force_load' \\
  '"$(PROJECT_DIR)/'"$4"'"' \\
  '"$(PROJECT_DIR)/'"$5"'"' \\
  '"$(PROJECT_DIR)/'"$6"'"') "$1"
! grep -Eq '^-ref-framework$|^@rpath/' "$1"

# Expand build settings before tokenizing, including paths whose relative
# portion has no whitespace. Only controlled fixture arguments reach eval.
response="$(<"$1")"
project_dir_setting='$(PROJECT_DIR)'
srcroot_setting='$(SRCROOT)'
target_build_dir_setting='$(TARGET_BUILD_DIR)'
project_dir='/Execution Root'
srcroot='/Workspace Root'
target_build_dir='/Build Products'
response="${response//$project_dir_setting/$project_dir}"
response="${response//$srcroot_setting/$srcroot}"
response="${response//$target_build_dir_setting/$target_build_dir}"
eval "parsed=($response)"
diff -u <(printf '%s\\n' \\
  '-F/Build Products' \\
  '-framework' \\
  'Lottie With Spaces' \\
  '-rpath' \\
  '/Build Products' \\
  '-ObjC' \\
  '/Execution Root/'"$2" \\
  '/Workspace Root/'"$3" \\
  '-force_load' \\
  '/Execution Root/'"$4" \\
  '/Execution Root/'"$5" \\
  '/Execution Root/'"$6") <(printf '%s\\n' "${parsed[@]}")
printf 'verified\\n' > "$7"
""",
    )

    executable = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(
        executable,
        content = """\
#!/bin/bash
set -euo pipefail
readonly marker="$TEST_SRCDIR/$TEST_WORKSPACE/{marker}"
[[ "$(cat "$marker")" == "verified" ]]
""".format(marker = verified.short_path),
        is_executable = True,
    )

    return [DefaultInfo(
        executable = executable,
        runfiles = ctx.runfiles(files = [verified]),
    )]

static_library_preview_link_params_test = rule(
    attrs = {
        # A real Swift toolchain flag routes the same provider inputs through
        # ProcessLinkParams instead of the no-user-flags direct writer.
        "process_link_flags": attr.bool(),
        "source_dependency": attr.label(
            allow_single_file = [".a"],
            default = Label(
                "//test/internal/files:testdata/libSourceDependency.a",
            ),
        ),
        "_link_params_processor": attr.label(default = "//tools/params_processors:link_params_processor", executable = True, cfg = "exec"),
    },
    implementation = _static_library_preview_link_params_test_impl,
    test = True,
)

def _top_level_preview_dynamic_inputs_test_impl(ctx):
    env = unittest.begin(ctx)
    solib = ctx.actions.declare_file("_solib/Dependency.framework/Dependency")
    resolved = ctx.actions.declare_file("Dependency.framework/Dependency")
    unused = ctx.actions.declare_file("libUnused.dylib")
    selected_archive = ctx.actions.declare_file("libSelected.a")
    objects = ctx.actions.declare_file("Selected-linker.objlist")
    header = ctx.actions.declare_file("Dependency.h")
    for file in [solib, resolved, unused, selected_archive, objects, header]:
        ctx.actions.write(file, "test\n")

    for use_objc in [False, True]:
        providers = struct(
            objc = struct(
                library = depset(),
                imported_library = depset(),
                static_framework_file = depset(),
                dynamic_framework_file = depset([solib, unused]),
                link_inputs = depset(),
            ) if use_objc else None,
            cc_info = struct(linking_context = struct(linker_inputs = depset([
                struct(
                    additional_inputs = (),
                    libraries = (
                        _dynamic_library(dynamic = solib, resolved = resolved),
                        _dynamic_library(dynamic = unused),
                        _static_library(static = selected_archive),
                    ),
                ),
            ]))),
            framework_files = depset(),
        )
        linker_inputs = linker_input_files.collect(
            target = struct(actions = [struct(
                mnemonic = "CppLink",
                args = ("actual-link-args",),
                inputs = depset([solib, selected_archive, objects, header]),
            )]),
            automatic_target_info = struct(link_mnemonics = ["CppLink"]),
            compilation_providers = providers,
            is_top_level = True,
        )
        values = linker_inputs._top_level_values
        asserts.equals(
            env,
            [solib],
            list(values.preview_link_input_files),
            "Preview prepares the consumed lexical dynamic input, not its resolved replacement, unused libraries, selected archive or headers",
        )
        asserts.equals(
            env,
            [objects],
            list(values.link_args_inputs),
            "Generating link params must not build dynamic dependencies",
        )

    return unittest.end(env)

top_level_preview_dynamic_inputs_test = unittest.make(
    _top_level_preview_dynamic_inputs_test_impl,
)

def _test_cc_info(ctx, libraries, user_link_flags = [], additional_inputs = []):
    # Real CcInfo/linking-context wrappers exercise the production merge API.
    return CcInfo(
        linking_context = cc_common.create_linking_context(
            linker_inputs = depset([
                cc_common.create_linker_input(
                    owner = ctx.label,
                    libraries = depset(libraries),
                    user_link_flags = user_link_flags,
                    additional_inputs = depset(additional_inputs),
                ),
            ]),
        ),
    )

_PreviewLibrariesInfo = provider(
    doc = "Real LibraryToLink fixtures for CcInfo propagation tests.",
    fields = {
        "libraries": "LibraryToLink objects keyed by fixture name.",
        "object": "A declared object owned by this dependency, not the selected target.",
    },
)

def _preview_libraries_impl(ctx):
    cc_toolchain = find_cc_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
    )
    libraries = {}
    for name, path in {
        "archive": "libFrameworkImplementation.a",
        "framework": "Generated.framework/Generated",
        "imported": "Imported.framework/Imported",
        "lipobin": "Generated_lipobin.dylib",
        "unused": "Unused.framework/Unused",
    }.items():
        file = ctx.actions.declare_file(ctx.label.name + "/" + path)
        ctx.actions.write(file, "test\n")
        libraries[name] = cc_common.create_library_to_link(
            actions = ctx.actions,
            cc_toolchain = cc_toolchain,
            feature_configuration = feature_configuration,
            **({"static_library": file} if name == "archive" else {"dynamic_library": file})
        )
    object = ctx.actions.declare_file(ctx.label.name + "/dependency.o")
    ctx.actions.write(object, "test\n")
    return [_PreviewLibrariesInfo(libraries = libraries, object = object)]

_preview_libraries = rule(
    implementation = _preview_libraries_impl,
    fragments = ["cpp"],
    toolchains = use_cc_toolchain(),
)

def _framework_preview_dynamic_propagation_test_impl(ctx):
    env = unittest.begin(ctx)
    libraries = ctx.attr.libraries[_PreviewLibrariesInfo].libraries
    framework = libraries["framework"].dynamic_library
    lipobin = libraries["lipobin"].dynamic_library
    imported = libraries["imported"].dynamic_library
    unused = libraries["unused"].dynamic_library
    resolved = libraries["framework"].resolved_symlink_dynamic_library
    resolved_lipobin = libraries["lipobin"].resolved_symlink_dynamic_library
    archive = libraries["archive"].static_library
    for name in ["framework", "lipobin", "imported", "unused"]:
        library = libraries[name]
        asserts.true(env, library.resolved_symlink_dynamic_library != None)
        asserts.true(env, library.dynamic_library != library.resolved_symlink_dynamic_library)
    selected = ctx.actions.declare_file("Selected.app/Selected")
    objects = ctx.actions.declare_file("FrameworkConsumer-linker.objlist")
    for file in [selected, objects]:
        ctx.actions.write(file, "test\n")

    imported_cc = _test_cc_info(ctx, [libraries["imported"]])
    (imported_target, imported_provider) = compilation_providers.collect(
        cc_info = imported_cc,
        objc = None,
    )
    asserts.equals(
        env,
        [imported],
        getattr(imported_target, "preview_dynamic_library_files", depset()).to_list(),
        "collect retains exact dynamic LibraryToLink artifacts",
    )
    (_, framework_provider) = compilation_providers.merge(
        # Generated frameworks expose different LibraryToLink files in their
        # target CcInfo and AppleDynamicFrameworkInfo.cc_info.
        cc_info = _test_cc_info(ctx, [
            libraries["framework"],
            libraries["archive"],
        ]),
        apple_dynamic_framework_info = struct(
            cc_info = _test_cc_info(ctx, [
                libraries["lipobin"],
                libraries["imported"],
                libraries["unused"],
                libraries["archive"],
            ]),
            framework_files = depset([resolved]),
            objc = None,
        ),
        propagate_providers = True,
        transitive_compilation_providers = [(None, imported_provider)],
    )
    asserts.equals(
        env,
        imported_cc,
        framework_provider._cc_info,
        "framework workaround still excludes both direct CcInfo providers from ordinary merging",
    )
    (_, wrapper_provider) = compilation_providers.merge(
        propagate_providers = True,
        transitive_compilation_providers = [
            (None, framework_provider),
            (None, imported_provider),
        ],
    )
    (target, stopped_provider) = compilation_providers.merge(
        propagate_providers = False,
        transitive_compilation_providers = [(None, wrapper_provider)],
    )
    asserts.equals(
        env,
        sorted(_paths([framework, lipobin, imported, unused])),
        sorted(_paths(getattr(target, "preview_dynamic_library_files", depset()).to_list())),
        "both framework providers and wrapper transitives survive, deduplicated, without static/resolved artifacts",
    )
    for use_objc in [False, True]:
        providers = struct(
            cc_info = target.cc_info,
            framework_files = target.framework_files,
            preview_dynamic_library_files = getattr(target, "preview_dynamic_library_files", depset()),
            objc = struct(
                library = depset(),
                imported_library = depset(),
                static_framework_file = depset(),
                dynamic_framework_file = depset([imported]),
                link_inputs = depset(),
            ) if use_objc else None,
        )
        values = linker_input_files.collect(
            target = struct(actions = [struct(
                mnemonic = "CppLink",
                args = ("actual-link-args",),
                inputs = depset([lipobin, imported, framework, archive, selected, resolved, resolved_lipobin, objects]),
            )]),
            automatic_target_info = struct(link_mnemonics = ["CppLink"]),
            compilation_providers = providers,
            is_top_level = True,
        )._top_level_values
        asserts.equals(
            env,
            [lipobin, imported, framework],
            list(values.preview_link_input_files),
            "actual action intersection preserves lexical order in CcInfo and legacy Objc branches, excluding unused/static/resolved artifacts",
        )
        asserts.equals(env, [objects], list(values.link_args_inputs))

    (blocked_target, _) = compilation_providers.merge(
        propagate_providers = True,
        transitive_compilation_providers = [(None, stopped_provider)],
    )
    asserts.equals(env, None, stopped_provider._cc_info)
    asserts.equals(
        env,
        [],
        getattr(blocked_target, "preview_dynamic_library_files", depset()).to_list(),
        "non-propagating targets keep their local Preview artifacts but stop downstream propagation",
    )

    # Existing opaque provider shapes and legacy AppleDynamicFrameworkInfo
    # without cc_info remain accepted at the API boundary.
    (compatible_target, _) = compilation_providers.merge(
        apple_dynamic_framework_info = struct(
            framework_files = depset(),
            objc = None,
        ),
        propagate_providers = True,
        transitive_compilation_providers = [(None, struct(
            _cc_info = imported_cc,
            _propagated_framework_files = depset(),
            _propagated_objc = None,
        ))],
    )
    asserts.equals(env, imported_cc, compatible_target.cc_info)

    return unittest.end(env)

framework_preview_dynamic_propagation_test = unittest.make(
    _framework_preview_dynamic_propagation_test_impl,
    attrs = {
        "libraries": attr.label(mandatory = True, providers = [_PreviewLibrariesInfo]),
    },
)

def _static_library_preview_link_flags_test_impl(ctx):
    env = unittest.begin(ctx)
    library = ctx.attr.libraries[_PreviewLibrariesInfo].libraries["archive"]
    flags = ["-u", "_preview_registration", "-weak_framework", "Optional Framework", "-reexport_framework", "Transitive", "-Lrelative/lib", "-lCustom"]
    for use_objc in [False, True]:
        for with_archive in [False, True]:
            cc_info = _test_cc_info(ctx, [library] if with_archive else [], flags)
            writes = {}
            runs = []

            def write(*, output, content):
                writes[output.path] = content
                ctx.actions.write(output, content)

            def run(**kwargs):
                runs.append(kwargs)
                for output in kwargs["outputs"]:
                    ctx.actions.write(output, "transport-only test\n")

            preview = linker_input_files.create_static_library_preview_link_params(
                actions = struct(declare_file = ctx.actions.declare_file, write = write, run = run),
                name = "LinkFlags_{}_{}".format(use_objc, with_archive),
                tool = "link_params_processor",
                linker_inputs = struct(
                    _cc_linker_inputs = tuple(cc_info.linking_context.linker_inputs.to_list()) if not use_objc else (),
                    _compilation_providers = struct(
                        cc_info = cc_info,
                        framework_files = depset(),
                        objc = struct(linkopt = depset(flags), dynamic_framework_file = depset()) if use_objc else None,
                    ),
                    _objc_libraries = (library.static_library,) if use_objc and with_archive else (),
                    _primary_static_library = None,
                ),
            )
            asserts.true(env, preview != None, "A flag-only dependency still needs Preview linker metadata")
            if preview:
                expected = ["libtool"] + (["-ObjC", "$(PROJECT_DIR)/{}".format(library.static_library.path)] if with_archive else []) + flags
                asserts.equals(env, "\n".join(expected) + "\n", writes[preview.file.path + ".raw"], "Declared link flags survive with and without archive dependencies")
                asserts.equals(env, [], json.decode(writes[preview.file.path + ".products.json"]))
                asserts.equals(env, [preview.file.path, preview.file.path + ".products.json", "static", preview.file.path + ".raw"], runs[0]["arguments"])
                asserts.equals(env, [preview.file.path + ".raw", preview.file.path + ".products.json"], _paths(runs[0]["inputs"]), "Generating argument metadata must not build link artifacts")
    return unittest.end(env)

static_library_preview_link_flags_test = unittest.make(
    _static_library_preview_link_flags_test_impl,
    attrs = {"libraries": attr.label(mandatory = True, providers = [_PreviewLibrariesInfo])},
)

def _static_library_preview_link_flag_inputs_test_impl(ctx):
    env = unittest.begin(ctx)
    archive = ctx.attr.libraries[_PreviewLibrariesInfo].libraries["archive"]
    dependency_object = ctx.attr.libraries[_PreviewLibrariesInfo].object
    primary = ctx.actions.declare_file("Selected.a")
    merged = ctx.actions.declare_file("Merged.a")
    selected_object = ctx.actions.declare_file("Selected.o")
    selected_autolink = ctx.actions.declare_file("Selected.autolink")
    debug_module = ctx.actions.declare_file("Selected.swiftmodule")
    symbols = ctx.actions.declare_file("symbols with 'quotes'.txt")
    response = ctx.actions.declare_file("dependency.rsp")
    for file in [primary, merged, selected_object, selected_autolink, debug_module, symbols, response]:
        ctx.actions.write(file, "fixture\n")
    additional_inputs = [primary, merged, selected_object, selected_autolink, debug_module, symbols, response, dependency_object]
    flags = [
        "-u",
        "_first",
        "-u",
        "_second",
        "-Wl,-force_load," + primary.path,
        "-Xlinker",
        "-force_load",
        "-Xlinker",
        merged.path,
        selected_object.path,
        "@" + selected_autolink.path,
        "-Wl,-add_ast_path," + debug_module.path,
        "-exported_symbols_list",
        symbols.path,
        "@" + response.path,
        dependency_object.path,
    ]
    cc_info = _test_cc_info(ctx, [archive], flags, additional_inputs)
    writes = {}
    runs = []

    def write(*, output, content):
        writes[output.path] = content
        ctx.actions.write(output, content)

    def run(**kwargs):
        runs.append(kwargs)
        for output in kwargs["outputs"]:
            ctx.actions.write(output, "transport-only test\n")

    preview = linker_input_files.create_static_library_preview_link_params(
        actions = struct(declare_file = ctx.actions.declare_file, write = write, run = run),
        name = "Nested/FlagInputs",
        tool = "link_params_processor",
        product_files = [merged],
        linker_inputs = struct(
            _cc_linker_inputs = tuple(cc_info.linking_context.linker_inputs.to_list()),
            _compilation_providers = struct(cc_info = cc_info, framework_files = depset(), objc = None),
            _objc_libraries = (),
            _primary_static_library = primary,
        ),
    )
    asserts.equals(env, _paths([archive.static_library, symbols, response, dependency_object]) + [preview.file.path + ".runtime.json"], _paths(preview.link_input_files), "Prepare required declared link files and dependency objects, never selected products/objects/autolink or debug modules")
    asserts.equals(env, [preview.file.path, preview.file.path + ".runtime.json"], _paths(runs[0]["outputs"]), "Runtime policy is a declared paired metadata output")
    asserts.equals(env, _paths([merged, primary, selected_object, selected_autolink]), json.decode(writes[preview.file.path + ".products.json"]), "Processor receives exact exclusion paths, including merged selected products")
    asserts.equals(env, flags, writes[preview.file.path + ".raw"].splitlines()[3:], "Repeated flags, wrappers, quotes and response references survive transport verbatim")
    asserts.equals(env, [preview.file.path + ".raw", preview.file.path + ".products.json"], _paths(runs[0]["inputs"]), "No generated link input becomes a project-generation action input")
    return unittest.end(env)

static_library_preview_link_flag_inputs_test = unittest.make(
    _static_library_preview_link_flag_inputs_test_impl,
    attrs = {"libraries": attr.label(mandatory = True, providers = [_PreviewLibrariesInfo])},
)

def _preview_registration_library_impl(ctx):
    cc_toolchain = find_cc_toolchain(ctx)
    features = cc_common.configure_features(ctx = ctx, cc_toolchain = cc_toolchain)
    source = ctx.actions.declare_file(ctx.label.name + ".c")
    ctx.actions.write(source, "int preview_registration(void) { return 42; }\n")
    _, compilation_outputs = cc_common.compile(
        actions = ctx.actions,
        name = ctx.label.name,
        cc_toolchain = cc_toolchain,
        feature_configuration = features,
        srcs = [source],
    )
    _, linking_outputs = cc_common.create_linking_context_from_compilation_outputs(
        actions = ctx.actions,
        name = ctx.label.name,
        cc_toolchain = cc_toolchain,
        feature_configuration = features,
        compilation_outputs = compilation_outputs,
        disallow_dynamic_library = True,
    )
    library = linking_outputs.library_to_link
    return [
        DefaultInfo(files = depset([library.static_library])),
        _PreviewLibrariesInfo(libraries = {"archive": library}, object = compilation_outputs.objects[0]),
    ]

_preview_registration_library = rule(
    implementation = _preview_registration_library_impl,
    fragments = ["cpp"],
    toolchains = use_cc_toolchain(),
)

def _static_library_preview_declared_flags_test_impl(ctx):
    library = ctx.attr.libraries[_PreviewLibrariesInfo].libraries["archive"]
    dependency_object = ctx.attr.libraries[_PreviewLibrariesInfo].object
    verified = []
    for use_objc, with_archive, required_only in [(False, False, False), (False, True, False), (True, False, False), (True, True, False), (False, True, True)]:
        name = "DeclaredFlags_{}_{}_{}".format(use_objc, with_archive, required_only)
        flags = ["-Wl,-u,_preview_registration", "-fprofile-instr-generate", "-nodefaultlibs"]
        selected = None
        additional_inputs = []
        symbols = None
        response = None
        if not required_only:
            selected = ctx.actions.declare_file(name + ".selected.a")
            selected_object = ctx.actions.declare_file(name + ".selected.o")
            selected_autolink = ctx.actions.declare_file(name + ".selected.autolink")
            debug_module = ctx.actions.declare_file(name + ".swiftmodule")
            symbols = ctx.actions.declare_file(name + ".exports with 'quotes'.txt")
            response = ctx.actions.declare_file(name + ".dependency.rsp")
            additional_inputs = [selected, selected_object, selected_autolink, debug_module, symbols, response, dependency_object]
            ctx.actions.run_shell(
                outputs = additional_inputs[:-1],
                command = "echo 'Link artifacts must not be built while generating Preview params' >&2; exit 1",
            )
            flags += ["-Wl,-weak_framework,Optional Framework", "-Wl,-reexport_framework,Transitive", "-Lrelative/lib", "-lCustom", "-F__BAZEL_XCODE_SDKROOT__/System/Library/Frameworks", "-L__BAZEL_XCODE_DEVELOPER_DIR__/usr/lib"]
            flags += ["-Wl,-force_load," + selected.path, selected_object.path, "@" + selected_autolink.path, "-Wl,-add_ast_path," + debug_module.path, "-exported_symbols_list", symbols.path, "@" + response.path, dependency_object.path]
        cc_info = _test_cc_info(ctx, [library] if with_archive else [], flags, additional_inputs)
        preview = linker_input_files.create_static_library_preview_link_params(
            actions = ctx.actions,
            name = name,
            tool = ctx.executable._link_params_processor,
            linker_inputs = struct(
                _cc_linker_inputs = tuple(cc_info.linking_context.linker_inputs.to_list()) if not use_objc else (),
                _compilation_providers = struct(
                    cc_info = cc_info,
                    framework_files = depset(),
                    objc = struct(linkopt = depset(flags), link_inputs = depset(additional_inputs), dynamic_framework_file = depset()) if use_objc else None,
                ),
                _objc_libraries = (library.static_library,) if use_objc and with_archive else (),
                _primary_static_library = selected,
            ),
        )
        expected = ctx.actions.declare_file(name + ".expected")
        expected_args = (["-ObjC", '"$(PROJECT_DIR)/{}"'.format(library.static_library.path)] if with_archive else []) + ["-u", "_preview_registration"]
        if not required_only:
            expected_args += ["-weak_framework", '"Optional Framework"', "-reexport_framework", "Transitive", '"-L$(PROJECT_DIR)/relative/lib"', "-lCustom", '"-F$(SDKROOT)/System/Library/Frameworks"', '"-L$(DEVELOPER_DIR)/usr/lib"']
            expected_args += ["-exported_symbols_list", '"$(PROJECT_DIR)/{}"'.format(symbols.path), '"@$(PROJECT_DIR)/{}"'.format(response.path), '"$(PROJECT_DIR)/{}"'.format(dependency_object.path)]
        ctx.actions.write(expected, "\n".join(expected_args) + "\n")
        marker = ctx.actions.declare_file(name + ".verified")
        runtime_policy = preview.link_input_files[-1]
        expected_policy = ctx.actions.declare_file(name + ".expected.runtime.json")
        ctx.actions.write(expected_policy, '["-fprofile-instr-generate","-nodefaultlibs"]\n')
        ctx.actions.run_shell(
            inputs = [preview.file, runtime_policy, expected, expected_policy],
            outputs = [marker],
            arguments = [expected.path, preview.file.path, marker.path, expected_policy.path, runtime_policy.path],
            command = "diff -u \"$1\" \"$2\" && diff -u \"$4\" \"$5\" && printf 'verified\\n' > \"$3\"",
        )
        verified.append(marker)

    executable = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(
        executable,
        content = "#!/bin/bash\nset -euo pipefail\n" + "\n".join([
            '[[ "$(cat "$TEST_SRCDIR/$TEST_WORKSPACE/' + file.short_path + '\")" == verified ]]'
            for file in verified
        ]) + "\n",
        is_executable = True,
    )
    return [DefaultInfo(executable = executable, runfiles = ctx.runfiles(files = verified))]

static_library_preview_declared_flags_test = rule(
    implementation = _static_library_preview_declared_flags_test_impl,
    test = True,
    attrs = {
        "libraries": attr.label(default = ":linker_input_files_registration_library", providers = [_PreviewLibrariesInfo]),
        "_link_params_processor": attr.label(default = "//tools/params_processors:link_params_processor", executable = True, cfg = "exec"),
    },
)

def linker_input_files_test_suite(name):
    libraries = name + "_framework_libraries"
    _preview_libraries(name = libraries, testonly = True)
    _preview_registration_library(name = name + "_registration_library", testonly = True)
    return unittest.suite(
        name,
        dynamic_only_static_library_preview_closure_test,
        partial.make(framework_preview_dynamic_propagation_test, libraries = ":" + libraries),
        merged_static_library_preview_libraries_test,
        source_static_library_preview_libraries_test,
        static_library_preview_path_boundaries_test,
        standalone_dynamic_library_preview_closure_test,
        static_library_preview_dynamic_frameworks_test,
        static_library_preview_framework_mapping_test,
        static_library_preview_libraries_test,
        top_level_preview_dynamic_inputs_test,
        partial.make(static_library_preview_link_flags_test, libraries = ":" + libraries),
        partial.make(static_library_preview_link_flag_inputs_test, libraries = ":" + libraries),
    )
