# Frequently Asked Questions

<!--
The TOC for this document was generated using https://github.com/ekalinin/github-markdown-toc.go.

# Install gh-md-toc
brew install github-markdown-toc

# Generate TOC
gh-md-toc --hide-header --hide-footer --start-depth=1
-->
* [My Xcode project seems to be of of sync with my Bazel project\. What should I do?](#my-xcode-project-seems-to-be-of-of-sync-with-my-bazel-project-what-should-i-do)
* [When I open my Xcode project, the Bazel Generated Files folder in the project navigator is red\. How do I fix this?](#when-i-open-my-xcode-project-the-bazel-generated-files-folder-in-the-project-navigator-is-red-how-do-i-fix-this)

## My Xcode project seems to be of of sync with my Bazel project. What should I do?

The generated Xcode project includes scripts to synchronize select Bazel
generated files (e.g. `Info.plist`) with Xcode. Perform the following steps to
synchronize these file:

1. Open the Xcode project: `xed path/to/MyApp.xcodeproj`.
2. Select the `Bazel Generated Files` scheme (Menu: `Product` > `Scheme` >
   `Bazel Generated Files`).
3. Build the `Bazel Generated Files` scheme (Menu: `Product` > `Build`).
4. If items under the `Bazel Generated Files` group in the Project navigator are
   red, close and re-open the project.

All targets that depend on generates files depend on the `Bazel Generated Files`
target, so building any of those targets will also synchronize Xcode.

## When I open my Xcode project, the `Bazel Generated Files` group in the Project navigator is red. How do I fix this?

If Xcode shows Project navigator items in red, it usually means that they are
not present. You merely need to synchronize the files with your Bazel project by
following
[these steps](#my-xcode-project-seems-to-be-of-of-sync-with-my-bazel-project-what-should-i-do).
