import PathKit
import XcodeProj

extension Generator {
    /// Sets the attributes and build configurations for `PBXNativeTarget`s as
    /// defined in the matching `Target`.
    ///
    /// This is separate from `addTargets()` to ensure that all
    /// `PBXNativeTarget`s have been created first, as attributes and build
    /// settings related to test hosts need to reference other targets.
    static func setTargetConfigurations(
        in pbxProj: PBXProj,
        for disambiguatedTargets: [TargetID: DisambiguatedTarget],
        pbxTargets: [TargetID: PBXNativeTarget],
        filePathResolver: FilePathResolver
    ) throws {
        for (id, disambiguatedTarget) in disambiguatedTargets {
            guard let pbxTarget = pbxTargets[id] else {
                throw PreconditionError(message: """
Target "\(id)" not found in `pbxTargets`
""")
            }

            let target = disambiguatedTarget.target

            var attributes: [String: Any] = [
                // TODO: Generate this value
                "CreatedOnToolsVersion": "13.2.1",
                // TODO: Only include properties that make sense for the target
                "LastSwiftMigration": 1320,
            ]
            var targetBuildSettings = target.buildSettings

            let frameworkIncludes = target.searchPaths.frameworkIncludes
            if !frameworkIncludes.isEmpty {
                try targetBuildSettings.prepend(
                    onKey: "FRAMEWORK_SEARCH_PATHS",
                    frameworkIncludes.map { filePath in
                        return try filePathResolver.resolve(filePath)
                            .string.quoted
                    }
                )
            }

            let quoteIncludes = target.searchPaths.quoteIncludes
            if !quoteIncludes.isEmpty {
                try targetBuildSettings.prepend(
                    onKey: "USER_HEADER_SEARCH_PATHS",
                    quoteIncludes.map { filePath in
                        return try filePathResolver.resolve(filePath)
                            .string.quoted
                    }
                )
            }

            let includes = target.searchPaths.includes
            if !includes.isEmpty {
                try targetBuildSettings.prepend(
                    onKey: "HEADER_SEARCH_PATHS",
                    includes.map { filePath in
                        return try filePathResolver.resolve(filePath)
                            .string.quoted
                    }
                )
            }

            let systemIncludes = target.searchPaths.systemIncludes
            if !systemIncludes.isEmpty {
                try targetBuildSettings.prepend(
                    onKey: "SYSTEM_HEADER_SEARCH_PATHS",
                    systemIncludes.map { filePath in
                        return try filePathResolver.resolve(filePath)
                            .string.quoted
                    }
                )
            }

            try targetBuildSettings.prepend(
                onKey: "OTHER_SWIFT_FLAGS",
                target.modulemaps
                    .map { filePath -> String in
                        var modulemap = try filePathResolver.resolve(filePath)

                        if filePath.type == .generated {
                            modulemap.replaceExtension("xcode.modulemap")
                        }

                        return """
-Xcc -fmodule-map-file=\(modulemap.string.quoted)
"""
                    }
                    .joined(separator: " ")
            )

            if target.isSwift {
                guard case let .array(cFlags) =
                        targetBuildSettings["OTHER_CFLAGS", default: .array([])]
                else {
                    throw PreconditionError(message: """
"OTHER_CFLAGS" in `targetBuildSettings` was not an `.array()`. Instead found \
\(targetBuildSettings["OTHER_CFLAGS", default: .array([])])
""")
                }

                // `OTHER_CFLAGS` here comes from cc_toolchain. We want to pass
                // those to clang for PCM compilation
                try targetBuildSettings.prepend(
                    onKey: "OTHER_SWIFT_FLAGS",
                    cFlags.map { "-Xcc \($0)" }.joined(separator: " ")
                )
            }

            if !target.isSwift && target.product.type.isExecutable {
                try targetBuildSettings.prepend(
                    onKey: "OTHER_LDFLAGS",
                    [
                        "-Wl,-rpath,/usr/lib/swift",
                        """
-L$(TOOLCHAIN_DIR)/usr/lib/swift/$(PLATFORM_NAME)
""",
                        "-L/usr/lib/swift",
                    ]
                )
            }

            if !target.linkerInputs.staticLibraries.isEmpty {
                let linkFileList = try filePathResolver
                    .resolve(try target.linkFileListFilePath())
                    .string
                try targetBuildSettings.prepend(
                    onKey: "OTHER_LDFLAGS",
                    ["-filelist", linkFileList.quoted]
                )
            }

            var buildSettings = targetBuildSettings.asDictionary

            buildSettings["ARCHS"] = target.platform.arch
            buildSettings["BAZEL_PACKAGE_BIN_DIR"] = target.packageBinDir.string
            buildSettings["SDKROOT"] = target.platform.os.sdkRoot
            buildSettings["TARGET_NAME"] = target.name

            if target.product.type.isLaunchable {
                // We need `BUILT_PRODUCTS_DIR` to point to where the
                // binary/bundle is actually at, for running from scheme to work
                buildSettings["BUILT_PRODUCTS_DIR"] = """
$(CONFIGURATION_BUILD_DIR)
"""
            }

            if let infoPlist = target.infoPlist {
                var infoPlistPath = try filePathResolver.resolve(
                    infoPlist,
                    useGenDir: true
                )
                
                // If the plist is generated, use the patched version that
                // removes a specific key that causes a warning when building
                // with Xcode
                if infoPlist.type == .generated {
                    infoPlistPath.replaceExtension("xcode.plist")
                }
                buildSettings["INFOPLIST_FILE"] = infoPlistPath.string.quoted
            } else {
              buildSettings["GENERATE_INFOPLIST_FILE"] = true
            }

            if let entitlements = target.entitlements {
                let entitlementsPath = try filePathResolver.resolve(
                    entitlements,
                    // Path needs to use `$(GEN_DIR)` to ensure XCBuild picks it
                    // up on first generation
                    useGenDir: true
                )
                buildSettings["CODE_SIGN_ENTITLEMENTS"] = entitlementsPath
                    .string.quoted

                // This is required because otherwise Xcode fails the build due 
                // the entitlements file being modified by the Bazel build script.
                buildSettings["CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION"] = true
            }

            if let pch = target.inputs.pch {
                let pchPath = try filePathResolver.resolve(pch, useGenDir: true)

                buildSettings["GCC_PREFIX_HEADER"] = pchPath.string.quoted
            }

            let swiftmodules = target.swiftmodules
            if !swiftmodules.isEmpty {
                buildSettings["SWIFT_INCLUDE_PATHS"] = try swiftmodules
                    .map { filePath -> String in
                        var dir = filePath
                        dir.path = dir.path.parent().normalize()
                        return try filePathResolver.resolve(dir).string.quoted
                    }
                    .uniqued()
                    .joined(separator: " ")
            }

            if let ldRunpathSearchPaths = target.ldRunpathSearchPaths {
                buildSettings["LD_RUNPATH_SEARCH_PATHS"] = ldRunpathSearchPaths
            }

            if let testHostID = target.testHost {
                guard
                    let testHost = disambiguatedTargets[testHostID]?.target
                else {
                    throw PreconditionError(message: """
Test host target with id "\(testHostID)" not found in `disambiguatedTargets`
""")
                }
                guard let pbxTestHost = pbxTargets[testHostID] else {
                    throw PreconditionError(message: """
Test host pbxTarget with id "\(testHostID)" not found in `pbxTargets`
""")
                }

                attributes["TestTargetID"] = pbxTestHost

                if target.product.type == .uiTestBundle {
                    buildSettings["TEST_TARGET_NAME"] = pbxTestHost.name
                } else {
                    guard let productPath = pbxTestHost.product?.path else {
                        throw PreconditionError(message: """
`product.path` not set on test host "\(pbxTestHost.name)"
""")
                    }
                    guard let productName = pbxTestHost.productName else {
                        throw PreconditionError(message: """
`productName` not set on test host "\(pbxTestHost.name)"
""")
                    }

                    buildSettings["TARGET_BUILD_DIR"] = """
$(BUILD_DIR)/\(testHost.packageBinDir)$(TARGET_BUILD_SUBPATH)
"""
                    buildSettings["TEST_HOST"] = """
$(BUILD_DIR)/\(testHost.packageBinDir)/\(productPath)/\(productName)
"""
                    buildSettings["BUNDLE_LOADER"] = "$(TEST_HOST)"
                }
            }

            let debugConfiguration = XCBuildConfiguration(
                name: "Debug",
                buildSettings: buildSettings
            )
            pbxProj.add(object: debugConfiguration)
            let configurationList = XCConfigurationList(
                buildConfigurations: [debugConfiguration],
                defaultConfigurationName: debugConfiguration.name
            )
            pbxProj.add(object: configurationList)
            pbxTarget.buildConfigurationList = configurationList

            let pbxProject = pbxProj.rootObject!
            pbxProject.setTargetAttributes(attributes, target: pbxTarget)
        }
    }
}

private extension Dictionary where Value == BuildSetting {
    mutating func prepend(onKey key: Key, _ content: String) throws {
        let buildSetting = self[key, default: .string("")]
        switch buildSetting {
        case .string(let existing):
            let new: String
            if content.isEmpty {
                new = existing
            } else if existing.isEmpty {
                new = content
            } else {
                new = "\(content) \(existing)"
            }
            guard !new.isEmpty else {
                return
            }
            self[key] = .string(new)
        default:
            throw PreconditionError(message: """
Build setting for \(key) is not a string: \(buildSetting)
""")
        }
    }

    mutating func prepend(onKey key: Key, _ content: [String]) throws {
        let buildSetting = self[key, default: .array([])]
        switch buildSetting {
        case .array(let existing):
            let new = content + existing
            guard !new.isEmpty else {
                return
            }
            self[key] = .array(new)
        default:
            throw PreconditionError(message: """
Build setting for \(key) is not an array: \(buildSetting)
""")
        }
    }
}

extension Target {
    fileprivate var ldRunpathSearchPaths: [String]? {
        switch (platform.os, product.type) {
        // Applications
        case (.macOS, .application):
            return [
                "$(inherited)",
                "@executable_path/../Frameworks",
            ]
        case (_, .application), (_, .onDemandInstallCapableApplication):
            return [
                "$(inherited)",
                "@executable_path/Frameworks",
            ]

        // Frameworks
        case (.macOS, .framework):
            return [
                "$(inherited)",
                "@executable_path/../Frameworks",
                "@loader_path/Frameworks",
            ]
        case (_, .framework):
            return [
                "$(inherited)",
                "@executable_path/Frameworks",
                "@loader_path/Frameworks",
            ]

        // App Extensions
        case (.macOS, let type) where type.isAppExtension:
            return [
                "$(inherited)",
                "@executable_path/../Frameworks",
                "@executable_path/../../../../Frameworks",
            ]
        case (.watchOS, .appExtension):
            // This needs to be before the below `type.isAppExtension` check
            // as `.appExtension` is covered in that
            return [
                "$(inherited)",
                "@executable_path/Frameworks",
                "@executable_path/../../Frameworks",
                "@executable_path/../../../../Frameworks",
            ]
        case (_, let type) where type.isAppExtension:
            return [
                "$(inherited)",
                "@executable_path/Frameworks",
                "@executable_path/../../Frameworks",
            ]

        default:
            // Tests don't need a special setting, they are handled by Xcode
            return nil
        }
    }

    func linkFileListFilePath() throws -> FilePath {
        var components = packageBinDir.components
        guard
            components.count >= 3,
            components[0] == "bazel-out",
            components[2] == "bin"
        else {
            throw PreconditionError(message: """
`packageBinDir` is in unexpected format: \(packageBinDir)
""")
        }
        // Remove "bin/"
        components.remove(at: 2)
        // Remove "bazel-out/"
        components.remove(at: 0)
        // Add our components
        components = ["targets"] + components + ["\(name).LinkFileList"]

        return .internal(Path(components: components))
    }
}

private extension Inputs {
    var containsSourceFiles: Bool {
        return !(srcs.isEmpty && nonArcSrcs.isEmpty)
    }
}

private extension Platform.OS {
    var sdkRoot: String {
        switch self {
        case .macOS: return "macosx"
        case .iOS: return "iphoneos"
        case .watchOS: return "watchos"
        case .tvOS: return "appletvos"
        }
    }
}

private extension String {
    func removingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else {
            return self
        }
        return String(self.prefix(prefix.count))
    }
}

extension Array where Element: Hashable {
    /// Return the array with all duplicates removed.
    ///
    /// i.e. `[ 1, 2, 3, 1, 2 ].uniqued() == [ 1, 2, 3 ]`
    ///
    /// - note: Taken from stackoverflow.com/a/46354989/3141234, as
    ///         per @Alexander's comment.
    public func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
