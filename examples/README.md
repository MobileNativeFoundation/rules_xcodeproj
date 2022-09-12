# Examples

This directory holds several examples using rules_xcodeproj. To open and example run the respective `xcodeproj` generate command from each directory.

* **cc**
    <br> Contains a command line tool written purely in C, exercising many possible use cases of the [cc rules in Bazel](https://bazel.build/reference/be/c-cpp) (consumes `cc_binary`, `cc_library`, external `cc_library`).

* **integration**
    <br> Contains many targets to exercise all [rules_apple](https://github.com/bazelbuild/rules_apple/tree/master/doc) based rule sets.

* **simple**
    <br> Contains a "Hello World" `swift_binary` target to exercise the [rules_swift](https://github.com/bazelbuild/rules_swift/tree/master/doc) rule sets.
