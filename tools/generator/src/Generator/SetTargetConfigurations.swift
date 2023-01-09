import OrderedCollections
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
        targets: [TargetID: Target],
        buildMode: BuildMode,
        minimumXcodeVersion: SemanticVersion,
        pbxTargets: [ConsolidatedTarget.Key: PBXTarget],
        hostIDs: [TargetID: [TargetID]],
        hasBazelDependencies: Bool
    ) throws {
        for (key, disambiguatedTarget) in disambiguatedTargets.targets {
            guard let pbxTarget = pbxTargets[key] else {
                throw PreconditionError(message: """
Target "\(key)" not found in `pbxTargets`
""")
            }

            let target = disambiguatedTarget.target

            var attributes: [String: Any] = [
                "CreatedOnToolsVersion": minimumXcodeVersion.full,
                // TODO: Only include properties that make sense for the target
                "LastSwiftMigration": 9999,
            ]

            var buildSettings = try calculateBuildSettings(
                for: target,
                buildMode: buildMode,
                targets: targets,
                hostIDs: hostIDs,
                hasBazelDependencies: hasBazelDependencies
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
                buildSettings: try buildSettings.asBuildSettingDictionary()
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
        targets: [TargetID: Target],
        hostIDs: [TargetID: [TargetID]],
        hasBazelDependencies: Bool
    ) throws -> [BuildSettingConditional: [String: BuildSetting]] {
        var anyBuildSettings: [String: BuildSetting] = [:]
        var buildSettings: [BuildSettingConditional: [String: BuildSetting]] =
            [:]
        var conditionalFileNames: [String: String] = [:]

        for (id, target) in consolidatedTarget.targets {
            var targetBuildSettings = try calculateBuildSettings(
                for: target,
                id: id,
                targets: targets,
                hostIDs: hostIDs[id, default: []],
                buildMode: buildMode,
                hasBazelDependencies: hasBazelDependencies
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
                let key = """
\(target.platform.variant.rawValue.uppercased())_FILES
"""
                conditionalFileNames[key] = uniqueFiles
                    .map { FilePathResolver.resolve($0).quoted }
                    .sorted()
                    .joined(separator: " ")
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
            anyBuildSettings[key] = .string(fileNames)
            excludedSourceFileNames.append("$(\(key))")
        }
        if !excludedSourceFileNames.isEmpty {
            anyBuildSettings["EXCLUDED_SOURCE_FILE_NAMES"] =
                .string(excludedSourceFileNames.joined(separator: " "))
            anyBuildSettings["INCLUDED_SOURCE_FILE_NAMES"] = ""
        }

        // Set an `.any` configuration if needed
        if !anyBuildSettings.isEmpty {
            buildSettings[.any] = anyBuildSettings
        }

        return buildSettings
    }

    // swiftlint:disable:next cyclomatic_complexity
    private static func calculateBuildSettings(
        for target: Target,
        id: TargetID,
        targets: [TargetID: Target],
        hostIDs: [TargetID],
        buildMode: BuildMode,
        hasBazelDependencies: Bool
    ) throws -> [String: BuildSetting] {
        var buildSettings = target.buildSettings

        // Work around stubbed swiftc messing with Indexing setting of
        // `-working-directory` incorrectly
        if buildMode == .bazel {
            try buildSettings.prepend(
                onKey: "OTHER_SWIFT_FLAGS",
                """
-Xcc -working-directory=$(PROJECT_DIR) -working-directory=$(PROJECT_DIR)
"""
            )
        }

        if let linkParams = target.linkParams {
            try buildSettings.prepend(
                onKey: "OTHER_LDFLAGS",
                ["@$(DERIVED_FILE_DIR)/link.params"]
            )
            buildSettings.set(
                "LINK_PARAMS_FILE",
                to: FilePathResolver.resolveGenerated(linkParams.path)
            )
        }

        buildSettings.set("ARCHS", to: target.platform.arch)
        buildSettings.set(
            "BAZEL_PACKAGE_BIN_DIR",
            to: target.packageBinDir.string
        )
        buildSettings.set("BAZEL_TARGET_ID", to: id.rawValue)
        buildSettings.set("PRODUCT_NAME", to: target.product.name)
        buildSettings.set("SDKROOT", to: target.platform.os.sdkRoot)
        buildSettings.set(
            "SUPPORTED_PLATFORMS",
            to: target.platform.variant.rawValue
        )
        buildSettings.set("TARGET_NAME", to: target.name)

        if !target.product.isResourceBundle {
            // This is used in `calculate_output_groups.py`. We only want to set
            // it on buildable targets
            buildSettings.set("BAZEL_LABEL", to: target.label.description)
        }

        if target.product.type == .staticFramework {
            // We set the `productType` to `.framework` to get the better
            // looking icon, so we need to manually set `MACH_O_TYPE`
            buildSettings["MACH_O_TYPE"] = "staticlib"
        }

        let compileTargetName: String
        if let compileTarget = target.compileTarget {
            buildSettings.set(
                "BAZEL_COMPILE_TARGET_ID",
                to: compileTarget.id.rawValue
            )
            compileTargetName = compileTarget.name
        } else {
            compileTargetName = target.name
        }
        buildSettings.set("COMPILE_TARGET_NAME", to: compileTargetName)

        buildSettings.set(
            target.platform.os.deploymentTargetBuildSettingKey,
            to: target.platform.minimumOsVersion.pretty
        )

        if target.isTestonly {
            buildSettings["ENABLE_TESTING_SEARCH_PATHS"] = true
        }

        let executableExtension = target.product.path?.path.extension ?? ""
        if executableExtension != target.product.type.fileExtension {
            buildSettings.set(
                "EXECUTABLE_EXTENSION",
                to: executableExtension
            )
        }

        if let executableName = target.product.executableName,
           executableName != target.product.name {
            buildSettings.set("EXECUTABLE_NAME", to: executableName)
        }

        for (index, id) in hostIDs.enumerated() {
            let hostTarget = try targets.value(
                for: id,
                context: "looking up host target"
            )
            buildSettings.set(
                "BAZEL_HOST_LABEL_\(index)",
                to: hostTarget.label.description
            )
            buildSettings.set("BAZEL_HOST_TARGET_ID_\(index)", to: id.rawValue)
        }

        if target.product.type.isLaunchable {
            // We need `BUILT_PRODUCTS_DIR` to point to where the
            // binary/bundle is actually at, for running from scheme to work
            buildSettings["BUILT_PRODUCTS_DIR"] = """
$(CONFIGURATION_BUILD_DIR)
"""
            buildSettings["DEPLOYMENT_LOCATION"] = false
        }

        if let infoPlist = target.infoPlist {
            buildSettings.set(
                "INFOPLIST_FILE",
                to: FilePathResolver.resolve(infoPlist)
            )
        } else if buildMode.allowsGeneratedInfoPlists {
            buildSettings["GENERATE_INFOPLIST_FILE"] = true
        }

        if let entitlements = target.inputs.entitlements {
            buildSettings.set(
                "CODE_SIGN_ENTITLEMENTS",
                to: FilePathResolver.resolve(entitlements)
            )

            if !buildMode.usesBazelModeBuildScripts {
                // This is required because otherwise Xcode can fails the build
                // due to a generated entitlements file being modified by the
                // Bazel build script.
                // We only set this for BwB mode though, because when this is
                // set, Xcode uses the entitlements as provided instead of
                // modifying them, which is needed in BwX mode.
                buildSettings[
                    "CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION"
                ] = true
            }
        }

        if buildMode == .xcode && target.product.isResourceBundle {
            // Used to work around CODE_SIGNING_ENABLED = YES in Xcode 14
            buildSettings["CODE_SIGNING_ALLOWED"] = false
        }

        if let pch = target.inputs.pch {
            buildSettings.set(
                "GCC_PREFIX_HEADER",
                to: FilePathResolver.resolve(pch)
            )
        }

        // TODO: Think about setting this `link.params` directly. This will
        // ensure they come after other `-rpath` declarations, and will probably
        // allow us to remove setting `FRAMEWORK_SEARCH_PATHS` (and instead use
        // a `compile.params`).
        if buildMode == .xcode && target.product.type == .framework {
            buildSettings.set("LD_RUNPATH_SEARCH_PATHS", to: [
                "$(PREVIEWS_LD_RUNPATH_SEARCH_PATHS__$(ENABLE_PREVIEWS))",
            ])
            buildSettings.set("PREVIEWS_LD_RUNPATH_SEARCH_PATHS__", to: [
                "$(PREVIEWS_LD_RUNPATH_SEARCH_PATHS__NO)",
            ])
            buildSettings.set(
                "PREVIEWS_LD_RUNPATH_SEARCH_PATHS__NO",
                to: []
            )
            buildSettings.set("PREVIEWS_LD_RUNPATH_SEARCH_PATHS__YES", to: [
                "$(FRAMEWORK_SEARCH_PATHS)",
            ])
        }
        
        // Set VFS overlays

        if hasBazelDependencies {
            if target.isSwift {
                try buildSettings.prepend(
                    onKey: "OTHER_SWIFT_FLAGS",
                    "-vfsoverlay $(OBJROOT)/bazel-out-overlay.yaml"
                )
            } else {
                try buildSettings.prepend(
                    onKey: "OTHER_CFLAGS",
                    ["-ivfsoverlay", "$(OBJROOT)/bazel-out-overlay.yaml"]
                )

                try buildSettings.prepend(
                    onKey: "OTHER_CPLUSPLUSFLAGS",
                    ["-ivfsoverlay", "$(OBJROOT)/bazel-out-overlay.yaml"]
                )
            }

            switch buildMode {
            case .xcode:
                if target.hasModulemaps {
                    try buildSettings.prepend(
                        onKey: "OTHER_SWIFT_FLAGS",
                        #"""
-Xcc -ivfsoverlay -Xcc $(DERIVED_FILE_DIR)/xcode-overlay.yaml \#
-Xcc -ivfsoverlay -Xcc $(OBJROOT)/bazel-out-overlay.yaml
"""#
                    )
                }

                if !target.isSwift && target.searchPaths.hasIncludes
                {
                    try buildSettings.prepend(
                        onKey: "OTHER_CFLAGS",
                        ["-ivfsoverlay", "$(DERIVED_FILE_DIR)/xcode-overlay.yaml"]
                    )

                    try buildSettings.prepend(
                        onKey: "OTHER_CPLUSPLUSFLAGS",
                        ["-ivfsoverlay", "$(DERIVED_FILE_DIR)/xcode-overlay.yaml"]
                    )
                }
            case .bazel:
                if target.hasModulemaps {
                    try buildSettings.prepend(
                        onKey: "OTHER_SWIFT_FLAGS",
                        #"""
-Xcc -ivfsoverlay -Xcc $(OBJROOT)/bazel-out-overlay.yaml
"""#
                    )
                }
            }
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

            let executableName = testHost.product.executableName ??
                testHost.product.name

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
$(BUILD_DIR)/\(testHost.packageBinDir)/\(productPath)/\(executableName)
"""
            )
        }
    }
}

private extension Dictionary where Value == BuildSetting {
    mutating func prepend(onKey key: Key, _ content: String) throws {
        let buildSetting = self[key, default: .string("")]
        switch buildSetting {
        case let .string(existing):
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
        case let .array(existing):
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
    private func internalTargetFilesPath() throws -> Path {
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
        components = ["targets"] + components

        return Path(components: components)
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

private extension String {
    func removingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else {
            return self
        }
        return String(self.prefix(prefix.count))
    }
}

public extension Array where Element: Hashable {
    /// Return the array with all duplicates removed.
    ///
    /// i.e. `[ 1, 2, 3, 1, 2 ].uniqued() == [ 1, 2, 3 ]`
    ///
    /// - note: Taken from stackoverflow.com/a/46354989/3141234, as
    ///         per @Alexander's comment.
    func uniqued() -> [Element] {
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
    func asBuildSettingDictionary() throws -> [String: Any] {
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
                .sorted(by: { $0.key < $1.key })
            var remainingConditionalBuildSettings =
                sortedConditionalBuildSettings[
                    sortedConditionalBuildSettings.indices
                ]

            guard
                let (firstCondition, first) = remainingConditionalBuildSettings
                    .popFirst()
            else {
                continue
            }

            // Set the base value to `.any` or the most preferable condition
            // (i.e. Simulator or Apple Silicon)
            buildSettings[key] = first

            // Set `BAZEL_{COMPILE_,}TARGET_ID` for first condition, for
            // buildRequest handling
            if Set(["BAZEL_TARGET_ID", "BAZEL_COMPILE_TARGET_ID"])
                .contains(key)
            {
                buildSettings.set(
                    firstCondition.conditionalize(key),
                    to: "$(\(key))"
                )
            }

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
