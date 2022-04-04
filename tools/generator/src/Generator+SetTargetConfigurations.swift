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
                        return filePathResolver.resolve(filePath).string.quoted
                    }
                )
            }

            let quoteIncludes = target.searchPaths.quoteIncludes
            if !quoteIncludes.isEmpty {
                try targetBuildSettings.prepend(
                    onKey: "USER_HEADER_SEARCH_PATHS",
                    quoteIncludes.map { filePath in
                        return filePathResolver.resolve(filePath).string.quoted
                    }
                )
            }

            let includes = target.searchPaths.includes
            if !includes.isEmpty {
                try targetBuildSettings.prepend(
                    onKey: "HEADER_SEARCH_PATHS",
                    includes.map { filePath in
                        return filePathResolver.resolve(filePath).string.quoted
                    }
                )
            }

            try targetBuildSettings.prepend(
                onKey: "OTHER_SWIFT_FLAGS",
                target.modulemaps
                    .map { filePath -> String in
                        var modulemap = filePathResolver.resolve(filePath)

                        if filePath.type == .generated {
                            modulemap.replaceExtension("xcode.modulemap")
                        }

                        return """
-Xcc -fmodule-map-file=\(modulemap.string.quoted)
"""
                    }
                    .joined(separator: " ")
            )

            if !target.links.isEmpty {
                let linkFileList = filePathResolver
                    .resolve(try target.linkFileListFilePath())
                    .string
                try targetBuildSettings.prepend(
                    onKey: "OTHER_LDFLAGS",
                    ["-filelist", "\(linkFileList),$(BUILD_DIR)".quoted]
                )
            }

            if !target.isSwift
                && target.product.type.isExecutable
                && target.inputs.containsSourceFiles
            {
                try targetBuildSettings.prepend(
                    onKey: "OTHER_LDFLAGS",
                    [
                        """
-L$(TOOLCHAIN_DIR)/usr/lib/swift/$(TARGET_DEVICE_PLATFORM_NAME)
""",
                        "-L/usr/lib/swift",
                    ]
                )
            }

            var buildSettings = targetBuildSettings.asDictionary

            buildSettings["BAZEL_PACKAGE_BIN_DIR"] = target.packageBinDir.string
            buildSettings["SDKROOT"] = target.platform.os.sdkRoot
            buildSettings["TARGET_NAME"] = target.name

            if let infoPlist = target.infoPlist {
              let infoPlistPath = filePathResolver
                    // We need to use `gen_dir` instead of `$(BUILD_DIR)` here
                    // to match the project navigator
                    .resolve(infoPlist, useBuildDir: false)
                    .string.quoted
              buildSettings["INFOPLIST_FILE"] = infoPlistPath
            } else {
              buildSettings["GENERATE_INFOPLIST_FILE"] = true
            }

            let swiftmodules = target.swiftmodules
            if !swiftmodules.isEmpty {
                buildSettings["SWIFT_INCLUDE_PATHS"] = swiftmodules
                    .map { filePath -> String in
                        var dir = filePath
                        dir.path = dir.path.parent().normalize()
                        return filePathResolver.resolve(dir).string.quoted
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
