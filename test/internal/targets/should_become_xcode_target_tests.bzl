load("@bazel_skylib//lib:unittest.bzl", "unittest")

def _should_not_become_xcode_target_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

should_not_become_xcode_target_test = unittest.make(_should_not_become_xcode_target_test)

def _for_apple_bundle_info_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

for_apple_bundle_info_test = unittest.make(_for_apple_bundle_info_test)

def _exclude_apple_bundle_import_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

exclude_apple_bundle_import_test = unittest.make(_exclude_apple_bundle_import_test)

def _include_apple_resource_bundle_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

include_apple_resource_bundle_test = unittest.make(_include_apple_resource_bundle_test)

def _include_command_line_tool_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

include_command_line_tool_test = unittest.make(_include_command_line_tool_test)

def _exclude_executable_that_is_source_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

exclude_executable_that_is_source_test = unittest.make(_exclude_executable_that_is_source_test)

def should_become_xcode_target_test_suite(name):
    return unittest.suite(
        name,
        should_not_become_xcode_target_test,
        for_apple_bundle_info_test,
        exclude_apple_bundle_import_test,
        include_apple_resource_bundle_test,
        include_command_line_tool_test,
        exclude_executable_that_is_source_test,
    )
