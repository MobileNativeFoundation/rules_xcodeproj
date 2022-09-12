# Examples

This directory holds several examples using rules_xcodeproj. To open an example, run the `bazel run //:xcodeproj` command from within each directory, then run `xed .` to open the generated project.

* **cc**
    <br> Contains a command line tool written purely in C, exercising many possible use cases of the [cc rules in Bazel](https://bazel.build/reference/be/c-cpp) (consumes `cc_binary`, `cc_library`, external `cc_library`).

* **integration**
    <br> Contains many targets to exercise all of the [rules_apple](https://github.com/bazelbuild/rules_apple/tree/master/doc) rules, along with various ways of using rules_xcodeproj itself (e.g. multi-platform consolidated targets, SwiftUI Previews, device support, etc.).

* **simple**
    <br> Contains a "Hello World" `swift_binary` target to exercise the [rules_swift](https://github.com/bazelbuild/rules_swift/tree/master/doc) rule sets.
