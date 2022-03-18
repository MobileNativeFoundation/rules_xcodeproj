load("@bazel_skylib//lib:unittest.bzl", "unittest")

def _from_fixture_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

from_fixture_test = unittest.make(_from_fixture_test)

def _from_fixtures_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

from_fixtures_test = unittest.make(_from_fixtures_test)

def xcodeproj_tests_test_suite():
    return unittest.suite(
        "xcodeproj_tests_tests",
        from_fixture_test,
        from_fixtures_test,
    )
