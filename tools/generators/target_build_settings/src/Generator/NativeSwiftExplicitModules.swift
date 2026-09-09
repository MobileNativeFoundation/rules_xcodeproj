import Foundation

/// Replaces an owned Bazel graph only when every local native import can be
/// reconstructed from files declared in Preview preparation. Never changes the
/// original argument array or asks Xcode to turn explicit modules off.
enum NativeSwiftExplicitModules {
    private struct Module: Decodable {
        let moduleName: String
        let isSystem: Bool?
        let isFramework: Bool?
        let isBridgingHeaderDependency: Bool?
        let modulePath: String?
        let clangModulePath: String?
        let clangModuleMapPath: String?
    }

    static func normalize(
        _ args: [String],
        manifests: [String: Data],
        preparedPaths: Set<String>
    ) -> [String]? {
        guard !manifests.isEmpty else { return nil }
        var localArgs: [String] = []
        var seenLocalArgs: Set<String> = []
        var pcmBindings: Set<String> = []
        var systemMaps: Set<String> = []
        var localMaps: Set<String> = []
        var ownedMaps: Set<String> = []
        for (path, data) in manifests.sorted(by: { $0.key < $1.key }) {
            guard let modules = try? JSONDecoder().decode([Module].self, from: data),
                  !modules.isEmpty
            else { return nil }
            ownedMaps.insert(path.buildSettingPath().quoteIfNeeded())
            for module in modules {
                guard !module.moduleName.isEmpty,
                      module.isBridgingHeaderDependency != true,
                      (module.modulePath != nil) != (module.clangModulePath != nil)
                else { return nil }
                if let pcm = module.clangModulePath {
                    for value in [pcm, pcm.buildSettingPath()] {
                        pcmBindings.insert("-fmodule-file=\(module.moduleName)=\(value)".quoteIfNeeded())
                        pcmBindings.insert("-fmodule-file=\(value)".quoteIfNeeded())
                    }
                }
                if module.isSystem == true {
                    guard let sdkPath = module.modulePath ?? module.clangModuleMapPath,
                          isOwnedSDKPath(sdkPath)
                    else { return nil }
                    if let map = module.clangModuleMapPath {
                        systemMaps.insert(("-fmodule-map-file=" + map.buildSettingPath()).quoteIfNeeded())
                    }
                    continue
                }
                if let path = module.modulePath {
                    guard preparedPaths.contains(path), path.hasSuffix(".swiftmodule"),
                          let directory = swiftSearchDirectory(path, moduleName: module.moduleName)
                    else { return nil }
                    let option: String
                    let searchPath: String
                    if path.contains(".framework/") {
                        guard let framework = frameworkSearchDirectory(directory, moduleName: module.moduleName) else { return nil }
                        option = "-F"
                        searchPath = framework
                    } else {
                        guard !path.contains(".xcframework/") else { return nil }
                        // rules_apple compiles framework interfaces into a flat
                        // generated module outside the original bundle.
                        if module.isFramework == true {
                            guard path.hasPrefix("bazel-out/"),
                                  (path as NSString).lastPathComponent == module.moduleName + ".swiftmodule"
                            else { return nil }
                        }
                        option = "-I"
                        searchPath = directory
                    }
                    let arg = searchPath.buildSettingPath().quoteIfNeeded()
                    if seenLocalArgs.insert(option + arg).inserted {
                        localArgs += [option, arg]
                    }
                } else if let map = module.clangModuleMapPath {
                    guard preparedPaths.contains(map) else { return nil }
                    if map.contains(".framework/") {
                        guard (map as NSString).lastPathComponent == "module.modulemap",
                              let directory = frameworkSearchDirectory((map as NSString).deletingLastPathComponent, moduleName: module.moduleName)
                        else { return nil }
                        let arg = directory.buildSettingPath().quoteIfNeeded()
                        if seenLocalArgs.insert("-F" + arg).inserted { localArgs += ["-F", arg] }
                    } else {
                        guard module.isFramework != true, !map.contains(".xcframework/") else { return nil }
                    }
                    let arg = ("-fmodule-map-file=" + map.buildSettingPath()).quoteIfNeeded()
                    localMaps.insert(arg)
                    if seenLocalArgs.insert(arg).inserted { localArgs += ["-Xcc", arg] }
                } else {
                    return nil
                }
            }
        }
        var result: [String] = []
        var usedMaps: Set<String> = []
        var i = 0
        while i < args.count {
            let arg = args[i]
            if arg == "-Xfrontend" || arg == "-Xcc" {
                guard i + 1 < args.count else { return nil }
                let value = args[i + 1]
                if arg == "-Xfrontend", value == "-explicit-swift-module-map-file" {
                    guard i + 3 < args.count, args[i + 2] == "-Xfrontend",
                          ownedMaps.contains(args[i + 3])
                    else { return nil }
                    usedMaps.insert(args[i + 3])
                    i += 4
                    continue
                }
                if arg == "-Xfrontend", value == "-disable-implicit-swift-modules" || value == "-disable-building-interface" {
                    i += 2
                    continue
                }
                if arg == "-Xcc" {
                    if value.hasPrefix("-fmodule-file=") || value.hasPrefix("'-fmodule-file=") {
                        guard pcmBindings.contains(value) else { return nil }
                        i += 2
                        continue
                    }
                    if value == "-fmodule-file" || value == "-fmodule-map-file" { return nil }
                    if value.hasPrefix("-fmodule-map-file=") || value.hasPrefix("'-fmodule-map-file="),
                       !systemMaps.contains(value), !localMaps.contains(value)
                    { return nil }
                    if value == "-fno-implicit-modules" || value == "-fno-implicit-module-maps" || systemMaps.contains(value) {
                        i += 2
                        continue
                    }
                }
                result += [arg, value]
                i += 2
                continue
            }
            // Alternate forwarding spellings are not yet normalized atomically.
            if arg.contains("explicit-swift-module-map-file") || arg.contains("fmodule-file") ||
                arg.contains("disable-implicit-swift-modules") || arg.hasPrefix("-Xcc=") || arg.hasPrefix("-Xfrontend=")
            { return nil }
            result.append(arg)
            i += 1
        }
        guard usedMaps == ownedMaps else { return nil }
        return result + localArgs
    }

    private static func swiftSearchDirectory(_ path: String, moduleName: String) -> String? {
        let directory = (path as NSString).deletingLastPathComponent
        if (path as NSString).lastPathComponent == moduleName + ".swiftmodule" {
            return directory.isEmpty ? "." : directory
        }
        // Binary imports select an architecture file inside Module.swiftmodule.
        guard (directory as NSString).lastPathComponent == moduleName + ".swiftmodule" else { return nil }
        let parent = (directory as NSString).deletingLastPathComponent
        return parent.isEmpty ? "." : parent
    }

    private static func frameworkSearchDirectory(_ modules: String, moduleName: String) -> String? {
        guard (modules as NSString).lastPathComponent == "Modules" else { return nil }
        let framework = (modules as NSString).deletingLastPathComponent
        guard (framework as NSString).lastPathComponent == moduleName + ".framework" else { return nil }
        let directory = (framework as NSString).deletingLastPathComponent
        return directory.isEmpty ? "." : directory
    }

    private static func isOwnedSDKPath(_ path: String) -> Bool {
        guard !path.split(separator: "/").contains("..") else { return false }
        if path.hasPrefix("__BAZEL_XCODE_SDKROOT__/") { return true }
        if path.hasPrefix("__BAZEL_XCODE_DEVELOPER_DIR__/Platforms/") ||
            path.hasPrefix("__BAZEL_XCODE_DEVELOPER_DIR__/Toolchains/")
        { return true }
        return path.range(
            of: #"^__bazel_developer_dir_[0-9]+_[0-9]+_[0-9]+_[A-Za-z0-9]+/(Platforms|Toolchains)/"#,
            options: .regularExpression
        ) != nil
    }
}
