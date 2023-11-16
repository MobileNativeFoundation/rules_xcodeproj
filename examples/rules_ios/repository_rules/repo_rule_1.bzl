def _repo_rule_1_impl(repository_ctx):
    build_file = """load("foo.bzl", "foo")
foo(
    name = "Foo",
)
"""
    foo = """load("@build_bazel_rules_ios//rules:framework.bzl", "apple_framework", "apple_framework_packaging")

def foo(name):
  apple_framework_packaging(
      name = "FooFmw",
      framework_name = "FooFmw",
      transitive_deps = [],
      platforms = {"ios": "12.0"},
      deps = [
          "@some_repo_rule_2//:FooObjc",
      ],
  )
  apple_framework(
      name = name,
      srcs = ["foo.h", "foo.m"],
      visibility = ["//visibility:public"],
      deps = [":FooFmw"],
  )
"""
    repository_ctx.file("foo.bzl", foo, False)
    repository_ctx.file("foo.h", "", False)
    repository_ctx.file("foo.m", "", False)
    repository_ctx.file("BUILD.bazel", build_file, False)
    repository_ctx.file("WORKSPACE", "workspace(name = \"%s\")" % repository_ctx.name, False)

repo_rule_1 = repository_rule(
    implementation = _repo_rule_1_impl,
    local = False,
    doc = """
Repository rule that declares an apple_framework target.
""",
)
