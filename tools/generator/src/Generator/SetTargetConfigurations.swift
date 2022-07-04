import PathKit
import XcodeProj

extension Generator {
    /// Sets the attributes and build configurations for `PBXNativeTarget`s as
    /// defined in the matching `ConsolidatedTarget`.
    ///
    /// This is separate from `addTargets()` to ensure that all
    /// `PBXNativeTarget`s have been created first, as attributes and build
    /// settings related to test hosts need to reference other targets.
    static func setTargetConfigurations(
        in pbxProj: PBXProj,
        for disambiguatedTargets: DisambiguatedTargets,
        buildMode: BuildMode,
        pbxTargets: [ConsolidatedTarget.Key: PBXTarget],
        filePathResolver: FilePathResolver
    ) throws {
        for (key, disambiguatedTarget) in disambiguatedTargets.targets {
            guard let pbxTarget = pbxTargets[key] else {
                throw PreconditionError(message: """
Target "\(key)" not found in `pbxTargets`
""")
            }

            let target = disambiguatedTarget.target

            var attributes: [String: Any] = [
                // TODO: Generate this value
                "CreatedOnToolsVersion": "13.2.1",
                // TODO: Only include properties that make sense for the target
                "LastSwiftMigration": 1320,
            ]

            var buildSettings = try calculateBuildSettings(
                for: target,
                buildMode: buildMode,
                filePathResolver: filePathResolver
            )

            try handleTestHost(
                for: target,
                disambiguatedTargets: disambiguatedTargets,
                pbxTargets: pbxTargets,
                attributes: &attributes,
                buildSettings: &buildSettings
            )

            let debugConfiguration = XCBuildConfiguration(
                name: "Debug",
                buildSettings: try buildSettings.asBuildSettingDictionary(
                    buildMode: buildMode
                )
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

    private static func calculateBuildSettings(
        for consolidatedTarget: ConsolidatedTarget,
        buildMode: BuildMode,
        filePathResolver: FilePathResolver
    ) throws -> [BuildSettingConditional: [String: BuildSetting]] {
        var anyBuildSettings: [String: BuildSetting] = [:]
        var buildSettings: [BuildSettingConditional: [String: BuildSetting]] =
            [:]
        var conditionalFileNames: [String: [String]] = [:]

        for (id, target) in consolidatedTarget.targets {
            var targetBuildSettings = try calculateBuildSettings(
                for: target,
                id: id,
                buildMode: buildMode,
                filePathResolver: filePathResolver
            )

            // Calculate "INCLUDED_SOURCE_FILE_NAMES"
            guard let uniqueFiles = consolidatedTarget.uniqueFiles[id] else {
                throw PreconditionError(message: """
Target with id "\(id)" not found in `consolidatedTarget.uniqueFiles`
""")
            }
            if !uniqueFiles.isEmpty {
                // This key needs to not have `-` in it
                // TODO: If we ever add support for Universal targets this needs
                //   to include more than just the platform name
                let key = "\(target.platform.name.uppercased())_FILES"
                conditionalFileNames[key] = try uniqueFiles
                    .map { filePath in
                        try filePathResolver.resolve(filePath, useGenDir: true)
                            .string
                    }
                    .sortedLocalizedStandard()
                targetBuildSettings.set(
                    "INCLUDED_SOURCE_FILE_NAMES",
                    to: "$(\(key))"
                )
            }

            buildSettings[target.buildSettingConditional] = targetBuildSettings
        }

        // Calculate "EXCLUDED_SOURCE_FILE_NAMES"
        var excludedSourceFileNames: [String] = []
        for (key, fileNames) in conditionalFileNames
            .sorted(by: { $0.key < $1.key })
        {
            anyBuildSettings[key] = .array(fileNames)
            excludedSourceFileNames.append("$(\(key))")
        }
        if !excludedSourceFileNames.isEmpty {
            anyBuildSettings["EXCLUDED_SOURCE_FILE_NAMES"] =
                .array(excludedSourceFileNames)
            anyBuildSettings["INCLUDED_SOURCE_FILE_NAMES"] = ""
        }

        // Set an `.any` configuration if needed
        if !anyBuildSettings.isEmpty {
            buildSettings[.any] = anyBuildSettings
        }

        return buildSettings
    }

    private static func calculateBuildSettings(
        for target: Target,
        id: TargetID,
        buildMode: BuildMode,
        filePathResolver: FilePathResolver
    ) throws -> [String: BuildSetting] {
        var buildSettings = target.buildSettings

        let frameworkIncludes = target.searchPaths.frameworkIncludes
        if !frameworkIncludes.isEmpty {
            try buildSettings.prepend(
                onKey: "FRAMEWORK_SEARCH_PATHS",
                frameworkIncludes.map { filePath in
                    return try filePathResolver.resolve(filePath)
                        .string.quoted
                }
            )
        }

        let quoteIncludes = target.searchPaths.quoteIncludes
        if !quoteIncludes.isEmpty {
            try buildSettings.prepend(
                onKey: "USER_HEADER_SEARCH_PATHS",
                quoteIncludes.map { filePath in
                    return try filePathResolver.resolve(filePath)
                        .string.quoted
                }
            )
        }

        let includes = target.searchPaths.includes
        if !includes.isEmpty {
            try buildSettings.prepend(
                onKey: "HEADER_SEARCH_PATHS",
                includes.map { filePath in
                    return try filePathResolver.resolve(filePath)
                        .string.quoted
                }
            )
        }

        let systemIncludes = target.searchPaths.systemIncludes
        if !systemIncludes.isEmpty {
            try buildSettings.prepend(
                onKey: "SYSTEM_HEADER_SEARCH_PATHS",
                systemIncludes.map { filePath in
                    return try filePathResolver.resolve(filePath)
                        .string.quoted
                }
            )
        }

        try buildSettings.prepend(
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

        let forceLoadLibraries = target.linkerInputs.forceLoad
        if !forceLoadLibraries.isEmpty {
            try buildSettings.prepend(
                onKey: "OTHER_LDFLAGS",
                forceLoadLibraries.flatMap { filePath in
                    return ["-force_load", try filePathResolver.resolve(filePath).string.quoted]
                }
            )
        }

        if !target.linkerInputs.staticLibraries.isEmpty {
            let linkFileList = try filePathResolver
                .resolve(try target.linkFileListFilePath())
                .string
            try buildSettings.prepend(
                onKey: "OTHER_LDFLAGS",
                ["-filelist", linkFileList.quoted]
            )
        }

        let linkopts = target.linkerInputs.linkopts
        if !linkopts.isEmpty {
            try buildSettings.prepend(onKey: "OTHER_LDFLAGS", linkopts)
        }

        buildSettings.set("ARCHS", to: target.platform.arch)
        buildSettings.set("BAZEL_PACKAGE_BIN_DIR", to: target.packageBinDir.string)
        buildSettings.set("BAZEL_TARGET_ID", to: id.rawValue)
        buildSettings.set(
            "EXECUTABLE_EXTENSION",
            to: target.product.path.path.extension ?? ""
        )
        buildSettings.set("PRODUCT_NAME", to: target.product.name)
        buildSettings.set("SDKROOT", to: target.platform.os.sdkRoot)
        buildSettings.set("SUPPORTED_PLATFORMS", to: target.platform.name)
        buildSettings.set("TARGET_NAME", to: target.name)

        if target.product.type.isLaunchable {
            // We need `BUILT_PRODUCTS_DIR` to point to where the
            // binary/bundle is actually at, for running from scheme to work
            buildSettings["BUILT_PRODUCTS_DIR"] = """
$(CONFIGURATION_BUILD_DIR)
"""
            buildSettings["DEPLOYMENT_LOCATION"] = false
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
            buildSettings.set("INFOPLIST_FILE", to: infoPlistPath.string.quoted)
        } else if buildMode.allowsGeneratedInfoPlists {
            buildSettings["GENERATE_INFOPLIST_FILE"] = true
        }

        if let entitlements = target.inputs.entitlements {
            let entitlementsPath = try filePathResolver.resolve(
                entitlements,
                // Path needs to use `$(GEN_DIR)` to ensure XCBuild picks it
                // up on first generation
                useGenDir: true
            )
            buildSettings.set(
                "CODE_SIGN_ENTITLEMENTS",
                to: entitlementsPath.string.quoted
            )

            // This is required because otherwise Xcode fails the build due
            // the entitlements file being modified by the Bazel build script.
            buildSettings["CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION"] = true
        }

        if let pch = target.inputs.pch {
            let pchPath = try filePathResolver.resolve(pch, useGenDir: true)

            buildSettings.set("GCC_PREFIX_HEADER", to: pchPath.string.quoted)
        }

        let swiftmodules = target.swiftmodules
        if !swiftmodules.isEmpty {
            let includePaths = try swiftmodules
                .map { filePath -> String in
                    var dir = filePath
                    dir.path = dir.path.parent().normalize()
                    return try filePathResolver.resolve(dir).string.quoted
                }
                .uniqued()
                .joined(separator: " ")
            buildSettings.set("SWIFT_INCLUDE_PATHS", to: includePaths)
        }

        if let swiftOutputs = target.outputs.swift {
            let swiftmoduleOutputPaths = try swiftOutputs.paths(
                filePathResolver: filePathResolver
            )
            if !swiftmoduleOutputPaths.isEmpty {
                buildSettings.set(
                    "BAZEL_OUTPUTS_SWIFTMODULE",
                    to: swiftmoduleOutputPaths.joined(separator: "\n")
                )
            }

            if let generatedHeader = swiftOutputs.generatedHeader {
                buildSettings.set(
                    "BAZEL_OUTPUTS_SWIFT_GENERATED_HEADER",
                    to: try filePathResolver.resolve(
                        generatedHeader,
                        useOriginalGeneratedFiles: true
                    )
                )
            }
        }

        if let productOutput = target.outputs.product {
            buildSettings.set(
                "BAZEL_OUTPUTS_PRODUCT",
                to: try filePathResolver.resolve(
                    productOutput,
                    useOriginalGeneratedFiles: true
                )
            )
        }

        if let ldRunpathSearchPaths = target.ldRunpathSearchPaths {
            buildSettings.set(
                "LD_RUNPATH_SEARCH_PATHS",
                to: ldRunpathSearchPaths
            )
        }

        return buildSettings
    }

    private static func handleTestHost(
        for target: ConsolidatedTarget,
        disambiguatedTargets: DisambiguatedTargets,
        pbxTargets: [ConsolidatedTarget.Key: PBXTarget],
        attributes: inout [String: Any],
        buildSettings: inout [BuildSettingConditional: [String: BuildSetting]]
    ) throws {
        let targets = target.targets.values

        // Consolidated targets all have the same consolidated test host, so we
        // can just pick the first one
        guard let aTestHostID = targets.first?.testHost else {
            return
        }

        guard let testHostKey = disambiguatedTargets.keys[aTestHostID] else {
            throw PreconditionError(message: """
Test host target with id "\(aTestHostID)" not found in \
`disambiguatedTargets.keys`
""")
        }
        guard let pbxTestHost = pbxTargets[testHostKey] else {
            throw PreconditionError(message: """
Test host pbxTarget with key \(testHostKey) not found in `pbxTargets`
""")
        }
        attributes["TestTargetID"] = pbxTestHost

        guard
            let consolidatedTestHost = disambiguatedTargets
                .targets[testHostKey]?.target
        else {
            throw PreconditionError(message: """
Test host target with key "\(testHostKey)" not found in \
`disambiguatedTargets.targets`
""")
        }

        guard target.product.type != .uiTestBundle else {
            buildSettings[.any, default: [:]].set(
                "TEST_TARGET_NAME",
                to: pbxTestHost.name
            )

            // UI test bundles need to be code signed to launch
            buildSettings[.any, default: [:]]["CODE_SIGNING_ALLOWED"] = true

            return
        }

        buildSettings[.any, default: [:]]["BUNDLE_LOADER"] =
            "$(TEST_HOST)"

        for target in targets {
            guard let testHostID = target.testHost else {
                continue
            }

            guard let testHost = consolidatedTestHost.targets[testHostID] else {
                throw PreconditionError(message: """
Test host target with id "\(testHostID)" not found in \
`consolidatedTestHost.targets`
""")
            }

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

            let conditional = target.buildSettingConditional
            buildSettings[conditional, default: [:]].set(
                "TARGET_BUILD_DIR",
                to: """
$(BUILD_DIR)/\(testHost.packageBinDir)$(TARGET_BUILD_SUBPATH)
"""
            )
            buildSettings[conditional, default: [:]].set(
                "TEST_HOST",
                to: """
$(BUILD_DIR)/\(testHost.packageBinDir)/\(productPath)/\(productName)
"""
            )
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
        case .tvOS: return "appletvos"
        case .watchOS: return "watchos"
        }
    }
}

private extension Inputs {
    var containsSourceFiles: Bool {
        return !(srcs.isEmpty && nonArcSrcs.isEmpty)
    }
}

private extension Outputs.Swift {
    func paths(filePathResolver: FilePathResolver) throws -> [String] {
        return try [
                module,
                doc,
                sourceInfo,
                interface,
            ]
            .compactMap { $0 }
            .map { filePath in
                return try filePathResolver.resolve(
                    filePath,
                    useOriginalGeneratedFiles: true
                ).string
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

private extension Dictionary where Value == BuildSetting {
    mutating func set(_ key: Key, to value: Path) {
        self[key] = .string(value.string)
    }
}

private extension BuildSetting {
    func toString(key: String) throws -> String {
        guard case let .string(string) = self else {
            throw PreconditionError(message: """
"\(key)" in `buildSettings` was not a `.string()`. Instead found \(self)
""")
        }
        return string
    }
}

private let iPhonePlatforms: Set<String> = [
    "iphoneos",
    "iphonesimulator",
]

private extension Dictionary
where Key == BuildSettingConditional, Value == [String: BuildSetting] {
    func asBuildSettingDictionary(
        buildMode: BuildMode
    ) throws -> [String: Any] {
        var conditionalBuildSettings: [
            String: [BuildSettingConditional: BuildSetting]
        ] = [:]
        for (conditional, buildSettings) in self {
            for (key, buildSetting) in buildSettings {
                conditionalBuildSettings[key, default: [:]][conditional] =
                    buildSetting
            }
        }

        // Properly set "SDKROOT"
        if let sdkrootBuildSettings = conditionalBuildSettings
            .removeValue(forKey: "SDKROOT")
        {
            conditionalBuildSettings["SDKROOT"] = [
                .any: sdkrootBuildSettings
                    .sorted { $0.key < $1.key }
                    .first!.value,
            ]
        }

        // Properly set "SUPPORTED_PLATFORMS"
        if let supportedPlatformsBuildSettings = conditionalBuildSettings
            .removeValue(forKey: "SUPPORTED_PLATFORMS")
        {
            let platforms = Set(
                try supportedPlatformsBuildSettings.values
                    .map { try $0.toString(key: "SUPPORTED_PLATFORMS") }
            )

            conditionalBuildSettings["SUPPORTED_PLATFORMS"] = [
                .any: .string(
                    platforms.sorted().reversed().joined(separator: " ")
                ),
            ]

            if !platforms.intersection(iPhonePlatforms).isEmpty {
                conditionalBuildSettings[
                    "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD"
                ] = [.any: .bool(platforms.contains("iphoneos"))]
            }
        }

        // TODO: If we ever add support for Universal targets we need to
        //   consolidate "ARCHS" to an `.any` conditional

        var buildSettings: [String: BuildSetting] = [:]
        for (key, conditionalBuildSetting) in conditionalBuildSettings {
            let sortedConditionalBuildSettings = conditionalBuildSetting
                .sorted(by: { $0.key < $1.key } )
            var remainingConditionalBuildSettings =
                sortedConditionalBuildSettings[
                    sortedConditionalBuildSettings.indices
                ]

            guard
                let (_, first) = remainingConditionalBuildSettings.popFirst()
            else {
                continue
            }

            // Set the base value to `.any` or the most preferable condition
            // (i.e. Simulator or Apple Silicon)
            buildSettings[key] = first

            for (condition, buildSetting) in remainingConditionalBuildSettings {
                guard buildSetting != first else {
                    // Don't set redundant settings
                    continue
                }
                buildSettings[condition.conditionalize(key)] = buildSetting
            }
        }

        return buildSettings.asDictionary
    }
}
