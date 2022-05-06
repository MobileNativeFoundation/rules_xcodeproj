"""Tests for platform processing functions."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//test:utils.bzl", "stringify_dict")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:target.bzl", "testable")

process_top_level_properties = testable.process_top_level_properties

def _process_top_level_properties_test_impl(ctx):
    env = unittest.begin(ctx)

    build_settings = {}
    properties = process_top_level_properties(
        target_name = ctx.attr.target_name,
        target_files = [
            struct(is_source = False, path = p)
            for p in ctx.attr.target_files
        ],
        bundle_info = _bundle_info_stub(ctx.attr.bundle_info),
        tree_artifact_enabled = ctx.attr.tree_artifact_enabled,
        build_settings = build_settings,
    )
    string_build_settings = stringify_dict(build_settings)

    asserts.equals(
        env,
        struct(
            path = ctx.attr.expected_bundle_path,
            type = "g",
            is_folder = False,
        ) if ctx.attr.expected_bundle_path else None,
        properties.bundle_file_path,
        "bundle_file_path",
    )
    asserts.equals(
        env,
        ctx.attr.expected_minimum_deployment_version or None,
        properties.minimum_deployment_os_version,
        "minimum_deployment_os_version",
    )
    asserts.equals(
        env,
        ctx.attr.expected_product_name,
        properties.product_name,
        "product_name",
    )
    asserts.equals(
        env,
        ctx.attr.expected_product_type,
        properties.product_type,
        "product_type",
    )
    asserts.equals(
        env,
        ctx.attr.expected_build_settings,
        string_build_settings,
        "build_settings",
    )

    return unittest.end(env)

process_top_level_properties_test = unittest.make(
    impl = _process_top_level_properties_test_impl,
    attrs = {
        "bundle_info": attr.string_dict(mandatory = False),
        "expected_build_settings": attr.string_dict(mandatory = True),
        "expected_bundle_path": attr.string(mandatory = False),
        "expected_minimum_deployment_version": attr.string(mandatory = False),
        "expected_product_name": attr.string(mandatory = True),
        "expected_product_type": attr.string(mandatory = True),
        "target_files": attr.string_list(mandatory = True),
        "target_name": attr.string(mandatory = True),
        "tree_artifact_enabled": attr.bool(mandatory = True),
    },
)

def _bundle_info(
        *,
        archive_path,
        archive_root,
        bundle_id,
        bundle_extension,
        bundle_name,
        minimum_deployment_os_version,
        product_type):
    return {
        "archive.path": archive_path,
        "archive_root": archive_root,
        "bundle_extension": bundle_extension,
        "bundle_id": bundle_id,
        "bundle_name": bundle_name,
        "minimum_deployment_os_version": minimum_deployment_os_version,
        "product_type": product_type,
    }

def _bundle_info_stub(dict):
    if not dict:
        return None
    return struct(
        archive = struct(
            is_source = False,
            path = dict["archive.path"],
        ),
        archive_root = dict["archive_root"],
        bundle_id = dict["bundle_id"],
        bundle_extension = dict["bundle_extension"],
        bundle_name = dict["bundle_name"],
        minimum_deployment_os_version = dict["minimum_deployment_os_version"],
        product_type = dict["product_type"],
    )

def process_top_level_properties_test_suite(name):
    """Test suite for `process_top_level_properties`.

    Args:
        name: The base name to be used in things created by this macro. Also the
            name of the test suite.
    """
    test_names = []

    def _add_test(
            *,
            name,
            target_name,
            target_files,
            bundle_info,
            tree_artifact_enabled,
            expected_bundle_path,
            expected_minimum_deployment_os_version,
            expected_product_name,
            expected_product_type,
            expected_build_settings):
        test_names.append(name)
        process_top_level_properties_test(
            name = name,
            target_name = target_name,
            target_files = target_files,
            bundle_info = bundle_info,
            tree_artifact_enabled = tree_artifact_enabled,
            expected_bundle_path = expected_bundle_path,
            expected_minimum_deployment_version =
                expected_minimum_deployment_os_version,
            expected_product_name = expected_product_name,
            expected_product_type = expected_product_type,
            expected_build_settings = stringify_dict(expected_build_settings),
            timeout = "short",
        )

    # Non-bundles

    _add_test(
        name = "{}_binary".format(name),
        target_name = "binary",
        target_files = ["bazel-out/some/binary"],
        bundle_info = None,
        tree_artifact_enabled = True,
        expected_bundle_path = None,
        expected_minimum_deployment_os_version = None,
        expected_product_name = "binary",
        expected_product_type = "com.apple.product-type.tool",
        expected_build_settings = {
            "PRODUCT_MODULE_NAME": "_binary_Stub",
        },
    )

    _add_test(
        name = "{}_xctest".format(name),
        target_name = "test",
        target_files = ["bazel-out/some/test.xctest/test"],
        bundle_info = None,
        tree_artifact_enabled = True,
        expected_bundle_path = "some/test.xctest",
        expected_minimum_deployment_os_version = None,
        expected_product_name = "test",
        expected_product_type = "com.apple.product-type.bundle.unit-test",
        expected_build_settings = {
            "PRODUCT_MODULE_NAME": "_test_Stub",
        },
    )

    # Bundles

    _add_test(
        name = "{}_tree_artifact".format(name),
        target_name = "a",
        target_files = [],
        bundle_info = _bundle_info(
            archive_path = "bazel-out/some/flagship.app",
            archive_root = "bazel-out/some/intermediate",
            bundle_id = "com.example.flagship",
            bundle_extension = ".app",
            bundle_name = "flagship",
            minimum_deployment_os_version = "13.1",
            product_type = "com.apple.product-type.application",
        ),
        tree_artifact_enabled = True,
        expected_bundle_path = "some/flagship.app",
        expected_minimum_deployment_os_version = "13.1",
        expected_product_name = "flagship",
        expected_product_type = "com.apple.product-type.application",
        expected_build_settings = {
            "PRODUCT_BUNDLE_IDENTIFIER": "com.example.flagship",
            "PRODUCT_MODULE_NAME": "_flagship_Stub",
        },
    )

    _add_test(
        name = "{}_app".format(name),
        target_name = "a",
        target_files = [],
        bundle_info = _bundle_info(
            archive_path = "bazel-out/some/flagship.app",
            archive_root = "bazel-out/some/intermediate",
            bundle_id = "com.example.flagship",
            bundle_extension = ".app",
            bundle_name = "flagship",
            minimum_deployment_os_version = "11.2",
            product_type = "com.apple.product-type.application",
        ),
        tree_artifact_enabled = False,
        expected_bundle_path = "some/intermediate/Payload/flagship.app",
        expected_minimum_deployment_os_version = "11.2",
        expected_product_name = "flagship",
        expected_product_type = "com.apple.product-type.application",
        expected_build_settings = {
            "PRODUCT_BUNDLE_IDENTIFIER": "com.example.flagship",
            "PRODUCT_MODULE_NAME": "_flagship_Stub",
        },
    )

    _add_test(
        name = "{}_bundled_test".format(name),
        target_name = "a",
        target_files = [],
        bundle_info = _bundle_info(
            archive_path = "bazel-out/some/flagship.xctest",
            archive_root = "bazel-out/some/intermediate",
            bundle_id = "com.example.flagship.test",
            bundle_extension = ".xctest",
            bundle_name = "flagship",
            minimum_deployment_os_version = "12.1",
            product_type = "com.apple.product-type.bundle.unit-test",
        ),
        tree_artifact_enabled = False,
        expected_bundle_path = "some/intermediate/flagship.xctest",
        expected_minimum_deployment_os_version = "12.1",
        expected_product_name = "flagship",
        expected_product_type = "com.apple.product-type.bundle.unit-test",
        expected_build_settings = {
            "PRODUCT_BUNDLE_IDENTIFIER": "com.example.flagship.test",
            "PRODUCT_MODULE_NAME": "_flagship_Stub",
        },
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )
