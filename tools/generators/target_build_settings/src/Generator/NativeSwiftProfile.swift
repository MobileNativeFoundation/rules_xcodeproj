/// Tracks selected Swift instrumentation without parsing shell-escaped settings
/// or interpreting a path/symbol/Clang argument as a Swift generation option.
struct NativeSwiftProfile {
    private(set) var isRequired = false
    private var driverValue = false
    private var frontendValue = false
    private var nextIsFrontend = false
    private let valueArgs: Set<String>

    init(valueArgs: Set<String>) {
        self.valueArgs = valueArgs.union(Self.retainedValueArgs)
    }

    mutating func consume(_ arg: String) {
        if nextIsFrontend {
            nextIsFrontend = false
            if frontendValue {
                frontendValue = false
            } else {
                isRequired = isRequired || arg == "-profile-generate" ||
                    arg == "-ir-profile-generate" || arg == "-cs-profile-generate" ||
                    arg.hasPrefix("-ir-profile-generate=") || arg.hasPrefix("-cs-profile-generate=")
                frontendValue = valueArgs.contains(arg)
            }
        } else if driverValue {
            driverValue = false
        } else if arg == "-Xfrontend" {
            nextIsFrontend = true
        } else {
            // IR/CS spellings are frontend-only: direct driver requests do not
            // reach the frontend on the supported Xcode 26.5/26.6 toolchains.
            isRequired = isRequired || arg == "-profile-generate"
            driverValue = valueArgs.contains(arg)
        }
    }

    /// Xcode-owned bindings are supplied from the existing Swift skip table.
    /// Values in each namespace are consumed once, even when they look like
    /// another binding or are interleaved with a different namespace.
    private static let retainedValueArgs: Set<String> = [
        "-D", "-F", "-Fsystem", "-I", "-L", "-l",
        "-Xcc", "-Xlinker", "-Xllvm", "-Xwrapped-swift",
        "-emit-const-values-path", "-emit-objc-header-path", "-import-objc-header",
        "-load-plugin-executable", "-load-plugin-library", "-plugin-path",
        "-explicit-swift-module-map-file", "-vfsoverlay", "-working-directory",
        "-module-abi-name", "-module-link-name", "-package-name", "-user-module-version",
        "-resource-dir", "-serialize-diagnostics-path", "-tools-directory", "-use-ld",
        "-swift-version", "-const-gather-protocols-file", "-project-name", "-index-unit-output-path",
        "-stats-output-dir", "-cas-path", "-save-optimization-record-path",
    ]
}
