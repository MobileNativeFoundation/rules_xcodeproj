# Examples

This directory holds several examples using rules_xcodeproj. To open an example, run the `bazel run //:xcodeproj` command from within each directory, then run `xed .` to open the generated project.

* **cc**
    <br> Contains a command line tool written purely in C, exercising many possible use cases of the [cc rules in Bazel](https://bazel.build/reference/be/c-cpp) (consumes `cc_binary`, `cc_library`, external `cc_library`).

* **integration**
    <br> Contains many targets to exercise all of the [rules_apple](https://github.com/bazelbuild/rules_apple/tree/master/doc) rules, along with various ways of using rules_xcodeproj itself (e.g. multi-platform consolidated targets, SwiftUI Previews, device support, etc.).

* **sanitizers**
    <br> Contains targets to test Sanitizers in BwB mode. The main purpose is to make sure sanitizers in BwB mode work and give UI feedback the same way sanitizers do in BwX builds.

* **simple**
    <br> Contains a "Hello World" `swift_binary` target. This example's main purpose is to have a target without `Bazel External Repositories` or `Bazel Generated Files` groups in Xcode, and no `BazelDependencies` target in BwX mode.
