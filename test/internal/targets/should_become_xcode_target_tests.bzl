load("@bazel_skylib//lib:unittest.bzl", "unittest")

def _should_not_become_xcode_target_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

should_not_become_xcode_target_test = unittest.make(_should_not_become_xcode_target_test)

def should_become_xcode_target_test_suite(name):
    return unittest.suite(
        name,
        should_not_become_xcode_target_test,
    )
