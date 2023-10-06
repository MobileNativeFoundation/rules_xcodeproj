// We only support importing indexes built with rules_xcodeproj, and we override
// our output bases, so we know the the ending of the execution root
let executionRootRegex = #".*/[^/]+/(?:_)?rules_xcodeproj(?:\.noindex)?/[^/]+_output_base/execroot/[^/]+"#

func remapArgs(
    arch: String,
    developerDir: String,
    objectFilePrefix: String,
    srcRoot: String,
    targetPathOverride: String?,
    xcodeExecutionRoot: String,
    xcodeOutputBase: String
) -> [String] {
    // The order of remaps is important. The first match is used. So we try the
    // most specific first. This also allows us to assume previous matches have
    // taken care of those types of files, so more general matches still work
    // later.
    return [
        // Object files
        //
        // These currently come back relative, but we have the execution_root as
        // an optional prefix in case this changes in the future. The path is
        // based on rules_swift's current logic:
        // https://github.com/bazelbuild/rules_swift/blob/6153a848f747e90248a8673869c49631f1323ff3/swift/internal/derived_files.bzl#L114-L119
        // When we add support for C-based index imports we will have to use
        // another pattern:
        // https://github.com/bazelbuild/bazel/blob/c4a1ab8b6577c4376aaaa5c3c2d4ef07d524175c/src/main/java/com/google/devtools/build/lib/rules/cpp/CcCompilationHelper.java#L1358
        "-remap",
        #"^(?:\#(executionRootRegex)/|\./)?(bazel-out/[^/]+/bin/)(?:_swift_incremental/)?(.*?)([^/]+)_objs/.*?([^/]+?)(?:\.swift)?\.o$=\#(objectFilePrefix)/\#(targetPathOverride ?? "$1$2$3")/Objects-normal/\#(arch)/$4.o"#,

        // Generated sources and swiftmodules
        //
        // With object files taken care of, any other paths with `bazel-out/` as
        // their prefix (relative to the execution_root) are assumed to be
        // generated outputs. The two kinds of generated outputs used in the
        // unit files are swiftmodule and source paths. So we map that, along
        // with the `external/` prefix for external sources, to the current
        // execution_root. Finally, currently these paths are returned as
        // absolute, but a future change might make them relative, similar to
        // the object files, so we have the execution_root as an optional
        // prefix.
        "-remap",
        #"^(?:\#(executionRootRegex)/|\./)?bazel-out/=\#(xcodeExecutionRoot)/bazel-out/"#,

        // External sources
        //
        // External sources need to be handled differently, since we use the
        // non-symlinked version in Xcode.
        "-remap",
        #"^(?:\#(executionRootRegex)/|\./)?external/=\#(xcodeOutputBase)/external/"#,

        // Project sources
        //
        // With the other source files and generated files taken care of, all
        // other execution_root prefixed paths should be project sources.
        "-remap",
        #"^\#(executionRootRegex)=\#(srcRoot)"#,

        // Sysroot
        //
        // The only other type of path in the unit files are sysroot based.
        // While these should always be Xcode.app relative, our regex supports
        // command-line tools based paths as well.
        // `DEVELOPER_DIR` has an optional `./` prefix, because index-import
        // adds `./` to all relative paths.
        "-remap",
        #"^(?:.*?/[^/]+/Contents/Developer|(?:./)?DEVELOPER_DIR|/PLACEHOLDER_DEVELOPER_DIR|/Library/Developer/CommandLineTools).*?/SDKs/([^\d.]+)=\#(developerDir)/Platforms/$1.platform/Developer/SDKs/$1"#
    ]
}
