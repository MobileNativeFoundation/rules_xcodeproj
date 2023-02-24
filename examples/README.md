# Examples

This directory holds several examples using rules_xcodeproj. To open an example, run the `bazel run //:xcodeproj` command from within each directory, then run `xed .` to open the generated project.

* **cc**
    <br> Contains a command line tool written purely in C, exercising many possible use cases of the [cc rules in Bazel](https://bazel.build/reference/be/c-cpp) (consumes `cc_binary`, `cc_library`, external `cc_library`).

* **integration**
    <br> Contains many targets to exercise all of the [rules_apple](https://github.com/bazelbuild/rules_apple/tree/master/doc) rules, along with various ways of using rules_xcodeproj itself (e.g. multi-platform consolidated targets, SwiftUI Previews, device support, etc.).

* **sanitizers**
    <br> Contains targets to test Sanitizers in BwB mode. The main purpose is to make sure sanitizers in BwB mode work and give UI feedback the same way sanitizers do in BwX builds.

## External

Below are some examples outside of this repository that show how to use
rules_xcodeproj in various ways. Since these are permalinks, they might not be
up-to-date with the latest version of rules_xcodeproj. Please check the
latest version on each respective repository.

- [BazelCon 2022 Demo](https://github.com/brentleyjones/rules_xcodeproj-demo)
- [BazelPods](https://github.com/sergeykhliustin/BazelPods/blob/f77e705c46ae73453e8df65c0ad54f67a4ac3f96/xcodeproj/BUILD)
- [Envoy Mobile](https://github.com/envoyproxy/envoy/blob/f6cb005211c389df0dc17d71b6819912e083b5cd/mobile/BUILD#L103-L173)
- [rules_apple iOS app tutorial](https://github.com/bazelbuild/rules_apple/blob/master/doc/tutorials/ios-app.md)
- [SwiftLint](https://github.com/realm/SwiftLint/blob/325d0ee1e44a87fc82afeb874b83ceb82f6728cf/BUILD#L113-L142)
- [SwiftUI iOS App with Bazel template](https://github.com/mattrobmattrob/bazel-ios-swiftui-template/blob/666640b796f347b62b8e5878e00c2d2f44c247cc/BUILD.bazel#L9-L18)
