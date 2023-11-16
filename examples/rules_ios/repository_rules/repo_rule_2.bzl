def _repo_rule_2_impl(repository_ctx):
    build_file = """
objc_library(
    name = "FooObjc",
    srcs = ["foo.m", "foo.h"],
    visibility = ["//visibility:public"],
)
"""
    repository_ctx.file("foo.h", "", False)
    repository_ctx.file("foo.m", "", False)
    repository_ctx.file("BUILD.bazel", build_file, False)
    repository_ctx.file("WORKSPACE", "workspace(name = \"%s\")" % repository_ctx.name, False)

repo_rule_2 = repository_rule(
    implementation = _repo_rule_2_impl,
    local = False,
    doc = """
Repository rule that declares an apple_framework target.
""",
)
