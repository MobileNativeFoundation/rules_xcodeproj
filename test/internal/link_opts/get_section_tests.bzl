load("@bazel_skylib//lib:unittest.bzl", "unittest")

def _get_section_segment_does_not_exist_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

get_section_segment_does_not_exist_test = unittest.make(_get_section_segment_does_not_exist_test)

def _get_section_section_does_not_exist_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

get_section_section_does_not_exist_test = unittest.make(_get_section_section_does_not_exist_test)

def _get_section_section_exists_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

get_section_section_exists_test = unittest.make(_get_section_section_exists_test)

def get_section_test_suite():
    return unittest.suite(
        "get_section_tests",
        get_section_segment_does_not_exist_test,
        get_section_section_does_not_exist_test,
        get_section_section_exists_test,
    )
