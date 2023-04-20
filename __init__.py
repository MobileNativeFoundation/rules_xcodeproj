# py_test under bazel doesn't appear to auto create the __init__.py files in the
# .runfiles/build_bazel_rules_apple directory; however py_binary does create it.
# The __init__.py files in all the subdirectories along the way are created by
# py_test just fine; but be have to manually create one (and depend on it) so it
# is provided for the py_tests.
