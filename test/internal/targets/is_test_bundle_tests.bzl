load("@bazel_skylib//lib:unittest.bzl", "unittest")

def _is_test_bundle_for_ios_test_bundle_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

is_test_bundle_for_ios_test_bundle_test = unittest.make(_is_test_bundle_for_ios_test_bundle_test)

def _is_test_bundle_for_macos_test_bundel_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

is_test_bundle_for_macos_test_bundel_test = unittest.make(_is_test_bundle_for_macos_test_bundel_test)

def _is_test_bundle_has_provider_but_not_dep_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

is_test_bundle_has_provider_but_not_dep_test = unittest.make(_is_test_bundle_has_provider_but_not_dep_test)

def _is_test_bundle_does_not_have_provider_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

is_test_bundle_does_not_have_provider_test = unittest.make(_is_test_bundle_does_not_have_provider_test)

def is_test_bundle_test_suite(name):
    return unittest.suite(
        name,
        is_test_bundle_for_ios_test_bundle_test,
        is_test_bundle_for_macos_test_bundel_test,
        is_test_bundle_has_provider_but_not_dep_test,
        is_test_bundle_does_not_have_provider_test,
    )
