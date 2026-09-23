"""Tests for target attribute transport into pbxnativetargets."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//test:mock_actions.bzl", "mock_actions")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:pbxproj_partials.bzl", "pbxproj_partials")

def _target(*, product_path = None, link_params = None):
    return struct(
        bundle_id = None,
        compile_target_ids = "",
        id = "STATIC_LIBRARY_ID",
        link_params = link_params,
        outputs = struct(product_path = product_path),
        product = struct(executable_name = None),
    )

def _static_library_link_params_test_impl(ctx):
    env = unittest.begin(ctx)

    link_params = mock_actions.mock_file(
        "bazel-out/libSubject.rules_xcodeproj.preview.link.params",
    )
    actual = pbxproj_partials.top_level_target_attributes_args(
        xcode_target = _target(link_params = link_params),
        unit_test_host = "",
    )

    asserts.equals(
        env,
        [
            "STATIC_LIBRARY_ID",
            "",
            "",
            link_params,
            "",
            "",
            "",
        ],
        actual,
        "static-library Preview link params are serialized with empty optional fields",
    )

    return unittest.end(env)

def _non_top_level_without_link_params_test_impl(ctx):
    env = unittest.begin(ctx)

    actual = pbxproj_partials.top_level_target_attributes_args(
        xcode_target = _target(),
        unit_test_host = "",
    )

    asserts.equals(
        env,
        [],
        actual,
        "ordinary non-top-level targets are not serialized",
    )

    return unittest.end(env)

def _top_level_product_path_test_impl(ctx):
    env = unittest.begin(ctx)

    actual = pbxproj_partials.top_level_target_attributes_args(
        xcode_target = _target(product_path = "bazel-out/Subject.app"),
        unit_test_host = "HOST_ID",
    )

    asserts.equals(
        env,
        [
            "STATIC_LIBRARY_ID",
            "",
            "bazel-out/Subject.app",
            "",
            "",
            "",
            "HOST_ID",
        ],
        actual,
        "existing top-level product attributes remain serialized",
    )

    return unittest.end(env)

static_library_link_params_test = unittest.make(
    _static_library_link_params_test_impl,
)
non_top_level_without_link_params_test = unittest.make(
    _non_top_level_without_link_params_test_impl,
)
top_level_product_path_test = unittest.make(
    _top_level_product_path_test_impl,
)

def top_level_target_attributes_args_test_suite(name):
    return unittest.suite(
        name,
        static_library_link_params_test,
        non_top_level_without_link_params_test,
        top_level_product_path_test,
    )
