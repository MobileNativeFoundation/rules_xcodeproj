"""Tests for static-library Xcode Preview linker inputs."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load(
    "//xcodeproj/internal/files:linker_input_files.bzl",
    "linker_input_files",
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

def _dynamic_library(*, dynamic, resolved = None):
    return struct(
        alwayslink = False,
        dynamic_library = dynamic,
        pic_static_library = None,
        resolved_symlink_dynamic_library = resolved,
        static_library = None,
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
        [],
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
    dependency = ctx.actions.declare_file("deps/libDependency.a")
    alwayslink_dependency = ctx.actions.declare_file(
        "deps/libAlwayslinkDependency.a",
    )
    lottie = ctx.actions.declare_file("Lottie.framework/Lottie")
    for file in [primary, dependency, alwayslink_dependency, lottie]:
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
                    ]),
                ),
                _compilation_providers = struct(
                    cc_info = True,
                    framework_files = depset(),
                    objc = None,
                ),
                _objc_libraries = (),
                _primary_static_library = primary,
            ),
            name = "Subject",
        )
    )

    verified = ctx.actions.declare_file("preview_link_params.verified")
    ctx.actions.run_shell(
        inputs = [preview_link_params.file],
        outputs = [verified],
        arguments = [
            preview_link_params.file.path,
            dependency.path,
            source_dependency.path,
            alwayslink_dependency.path,
            verified.path,
        ],
        command = """\
set -euo pipefail

diff -u <(printf '%s\\n' \\
  '-F$(TARGET_BUILD_DIR)' \\
  '-framework' \\
  'Lottie' \\
  '-rpath' \\
  '$(TARGET_BUILD_DIR)' \\
  '-ObjC' \\
  '$(PROJECT_DIR)/'"$2" \\
  '$(PROJECT_DIR)/'"$3" \\
  '-force_load' \\
  '$(PROJECT_DIR)/'"$4") "$1"
! grep -Eq '^-ref-framework$|^@rpath/' "$1"
printf 'verified\\n' > "$5"
""",
    )

    executable = ctx.actions.declare_file("preview_link_params_test.sh")
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
        "source_dependency": attr.label(
            allow_single_file = [".a"],
            default = Label(
                "//test/internal/files:testdata/libSourceDependency.a",
            ),
        ),
    },
    implementation = _static_library_preview_link_params_test_impl,
    test = True,
)

def linker_input_files_test_suite(name):
    return unittest.suite(
        name,
        dynamic_only_static_library_preview_closure_test,
        source_static_library_preview_libraries_test,
        static_library_preview_dynamic_frameworks_test,
        static_library_preview_framework_mapping_test,
        static_library_preview_libraries_test,
    )
