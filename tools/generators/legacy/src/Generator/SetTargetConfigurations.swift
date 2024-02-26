import OrderedCollections
import PathKit
import ToolCommon
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
        xcodeConfigurations: Set<String>,
        defaultXcodeConfiguration: String,
        pbxTargets: [ConsolidatedTarget.Key: LabeledPBXNativeTarget],
        hostIDs: [TargetID: [TargetID]],
        hasBazelDependencies: Bool
    ) async throws {
        try await withThrowingTaskGroup(
            of: (pbxTarget: PBXNativeTarget, attributes: [String: Any]).self
        ) { group in
            for (key, disambiguatedTarget) in disambiguatedTargets.targets {
                group.addTask {
                    try setTargetConfiguration(
                        in: pbxProj,
                        for: disambiguatedTarget,
                        key: key,
                        in: disambiguatedTargets,
                        targets: targets,
                        buildMode: buildMode,
                        minimumXcodeVersion: minimumXcodeVersion,
                        xcodeConfigurations: xcodeConfigurations,
                        defaultXcodeConfiguration: defaultXcodeConfiguration,
                        pbxTargets: pbxTargets,
                        hostIDs: hostIDs,
                        hasBazelDependencies: hasBazelDependencies
                    )
                }
            }

            let pbxProject = pbxProj.rootObject!

            for try await (pbxTarget, attributes) in group {
                // `PBXProject` currently isn't thread safe, so we do this
                // serially
                pbxProject.setTargetAttributes(attributes, target: pbxTarget)
            }
        }
    }

    static func setTargetConfiguration(
        in pbxProj: PBXProj,
        for disambiguatedTarget: DisambiguatedTarget,
        key: ConsolidatedTarget.Key,
        in disambiguatedTargets: DisambiguatedTargets,
        targets: [TargetID: Target],
        buildMode: BuildMode,
        minimumXcodeVersion: SemanticVersion,
        xcodeConfigurations: Set<String>,
        defaultXcodeConfiguration: String,
        pbxTargets: [ConsolidatedTarget.Key: LabeledPBXNativeTarget],
        hostIDs: [TargetID: [TargetID]],
        hasBazelDependencies: Bool
    ) throws -> (pbxTarget: PBXNativeTarget, attributes: [String: Any]) {
        guard let labeledPBXTarget = pbxTargets[key] else {
            throw PreconditionError(message: """
Target "\(key)" not found in `pbxTargets`
""")
        }
        let pbxTarget = labeledPBXTarget.pbxTarget

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

        // For any missing configurations, have them equal to the default,
        // and if the default is one of the missing ones, choose the first
        // alphabetically
        let missingConfigurations = xcodeConfigurations.subtracting(
            Set(buildSettings.keys)
        )

        if !missingConfigurations.isEmpty {
            let configurationToCopy = missingConfigurations
                .contains(defaultXcodeConfiguration) ?
                buildSettings.keys.sorted().first! : defaultXcodeConfiguration
            let buildSettingsToCopy = buildSettings[configurationToCopy]!
            for xcodeConfiguration in missingConfigurations {
                buildSettings[xcodeConfiguration] = buildSettingsToCopy
            }
        }

        var buildConfigurations: [XCBuildConfiguration] = []
        for (name, buildSettings) in buildSettings
            .sorted(by: { $0.key < $1.key })
        {
            let buildConfiguration = try XCBuildConfiguration(
                name: name,
                buildSettings: buildSettings.asBuildSettingDictionary()
            )
            pbxProj.add(object: buildConfiguration)
            buildConfigurations.append(buildConfiguration)
        }

        guard buildSettings.keys.contains(defaultXcodeConfiguration) else {
            throw PreconditionError(message: """
`xcodeproj.default_xcode_configuration` "\(defaultXcodeConfiguration)" not one \
of the configurations of "\(key)".
""")
        }

        let configurationList = XCConfigurationList(
            buildConfigurations: buildConfigurations,
            defaultConfigurationName: defaultXcodeConfiguration
        )
        pbxProj.add(object: configurationList)
        pbxTarget.buildConfigurationList = configurationList

        return (pbxTarget, attributes)
    }

    private static func calculateBuildSettings(
        for consolidatedTarget: ConsolidatedTarget,
        buildMode: BuildMode,
        targets: [TargetID: Target],
        hostIDs: [TargetID: [TargetID]],
        hasBazelDependencies: Bool
    ) throws -> [String: [BuildSettingConditional: [String: BuildSetting]]] {
        var buildSettings:
            [String: [BuildSettingConditional: [String: BuildSetting]]] = [:]
        var conditionalFileNames: [String: [String: String]] = [:]
        var allUniqueFiles: Set<FilePath> = []
        var configurationUniqueFiles: [String: Set<FilePath>] = [:]

        for (id, target) in consolidatedTarget.targets {
            var targetBuildSettings = try calculateBuildSettings(
                for: target,
                id: id,
                targets: targets,
                hostIDs: hostIDs[id, default: []],
                buildMode: buildMode,
                hasBazelDependencies: hasBazelDependencies
            )

            for xcodeConfiguration in target.xcodeConfigurations {
                // Calculate "INCLUDED_SOURCE_FILE_NAMES"
                guard
                    let uniqueFiles = consolidatedTarget.uniqueFiles[id]
                else {
                    throw PreconditionError(message: """
Target with id "\(id)" not found in `consolidatedTarget.uniqueFiles`
""")
                }
                if !uniqueFiles.isEmpty {
                    allUniqueFiles.formUnion(uniqueFiles)
                    configurationUniqueFiles[xcodeConfiguration, default: []]
                        .formUnion(uniqueFiles)

                    // This key needs to not have `-` in it
                    // TODO: If we ever add support for Universal targets this
                    //   needs to include more than just the platform name
                    let key = """
\(target.platform.variant.rawValue.uppercased())_FILES
"""
                    conditionalFileNames[
                        xcodeConfiguration, default: [:]
                    ][key] = uniqueFiles
                        .map { $0.path.string.quoted }
                        .sorted()
                        .joined(separator: " ")
                    targetBuildSettings.set(
                        "INCLUDED_SOURCE_FILE_NAMES",
                        to: "$(\(key))"
                    )
                }

                buildSettings[
                    xcodeConfiguration, default: [:]
                ][target.buildSettingConditional] = targetBuildSettings
            }
        }

        // Calculate "EXCLUDED_SOURCE_FILE_NAMES"
        for (
            xcodeConfiguration,
            configurationConditionalFileNames
        ) in conditionalFileNames {
            var anyBuildSettings: [String: BuildSetting] = [:]
            var excludedSourceFileNames: [String] = []
            for (key, fileNames) in configurationConditionalFileNames
                .sorted(by: { $0.key < $1.key })
            {
                anyBuildSettings[key] = .string(fileNames)
                excludedSourceFileNames.append("$(\(key))")
            }

            // Exclude other Xcode configuration unique files as well
            excludedSourceFileNames.append(
                contentsOf: allUniqueFiles
                    .subtracting(configurationUniqueFiles[xcodeConfiguration]!)
                    .map { $0.path.string.quoted }
                    .sorted()
            )

            if !excludedSourceFileNames.isEmpty {
                anyBuildSettings["EXCLUDED_SOURCE_FILE_NAMES"] =
                    .string(excludedSourceFileNames.joined(separator: " "))
                anyBuildSettings["INCLUDED_SOURCE_FILE_NAMES"] = ""
            }

            // Set an `.any` configuration if needed
            if !anyBuildSettings.isEmpty {
                buildSettings[
                    xcodeConfiguration, default: [:]
                ][.any] = anyBuildSettings
            }
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

        if let linkParams = target.linkParams {
            // Drop the `bazel-out` prefix since we use the env var for this
            // portion of the path
            buildSettings.set("LINK_PARAMS_FILE", to: #"""
$(BAZEL_OUT)\#(linkParams.path.string.dropFirst(9))
"""#)
            try buildSettings.prepend(
                onKey: "OTHER_LDFLAGS",
                ["@$(DERIVED_FILE_DIR)/link.params"]
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

        if target.compileTargets.count > 0 {
            buildSettings.set(
                "BAZEL_COMPILE_TARGET_IDS",
                to: target.compileTargets
                    .map(\.id.rawValue)
                    .joined(separator: " ")
            )
        }

        let compileTargetName: String
        if target.compileTargets.count > 0 {
            // Intentionally take the first `compileTargets` entry since this
            // will be Swift in the case where a Swift compile target is present
            // amongst a non-Swift compile target. Swift indexstore imports are
            // the only supported ones right now so this opts to choose that when
            // possible.
            compileTargetName = target.compileTargets[0].name
        } else {
            compileTargetName = target.name
        }
        buildSettings.set("COMPILE_TARGET_NAME", to: compileTargetName)

        buildSettings.set(
            target.platform.os.deploymentTargetBuildSettingKey,
            to: target.platform.minimumOsVersion.pretty
        )

        let productExtension = target.product.path?.path.extension ?? ""
        if productExtension != target.product.type.fileExtension {
            buildSettings.set(
                target.product.type.isBundle ?
                    "WRAPPER_EXTENSION" : "EXECUTABLE_EXTENSION",
                to: productExtension
            )
        }

        if let executableName = target.product.executableName,
           executableName != target.product.name
        {
            buildSettings.set("EXECUTABLE_NAME", to: executableName)
        }

        if buildMode == .xcode && target.product.type.isLaunchable {
            // We need `BUILT_PRODUCTS_DIR` to point to where the
            // binary/bundle is actually at, for running from scheme to work
            buildSettings["BUILT_PRODUCTS_DIR"] = """
$(CONFIGURATION_BUILD_DIR)
"""
            buildSettings["DEPLOYMENT_LOCATION"] = false
        }

        if buildSettings.keys.contains("CODE_SIGN_ENTITLEMENTS") &&
            !buildMode.usesBazelModeBuildScripts
        {
            // This is required because otherwise Xcode can fails the build due
            // to a generated entitlements file being modified by the Bazel
            // build script. We only set this for BwB mode though, because when
            // this is set, Xcode uses the entitlements as provided instead of
            // modifying them, which is needed in BwX mode.
            buildSettings["CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION"] = true
        }

        if buildMode == .xcode, target.product.isResourceBundle {
            // Used to work around CODE_SIGNING_ENABLED = YES in Xcode 14
            buildSettings["CODE_SIGNING_ALLOWED"] = false
        }

        // Set VFS overlays

        let cFlags: [String]
        if let cParams = target.cParams {
            // Drop the `bazel-out` prefix since we use the env var for this
            // portion of the path
            buildSettings.set("C_PARAMS_FILE", to: #"""
$(BAZEL_OUT)\#(cParams.path.string.dropFirst(9))
"""#)
            cFlags = ["@$(DERIVED_FILE_DIR)/c.compile.params"]
        } else {
            cFlags = []
        }

        let cxxFlags: [String]
        if let cxxParams = target.cxxParams {
            // Drop the `bazel-out` prefix since we use the env var for this
            // portion of the path
            buildSettings.set("CXX_PARAMS_FILE", to: #"""
$(BAZEL_OUT)\#(cxxParams.path.string.dropFirst(9))
"""#)
            cxxFlags = ["@$(DERIVED_FILE_DIR)/cxx.compile.params"]
        } else {
            cxxFlags = []
        }

        let swiftFlags: [String]
        if let swiftParams = target.swiftParams {
            // Drop the `bazel-out` prefix since we use the env var for this
            // portion of the path
            buildSettings.set("SWIFT_PARAMS_FILE", to: #"""
$(BAZEL_OUT)\#(swiftParams.path.string.dropFirst(9))
"""#)
            swiftFlags = ["@$(DERIVED_FILE_DIR)/swift.compile.params"]
        } else {
            swiftFlags = []
        }

        var cFlagsPrefix: [String] = []
        var cxxFlagsPrefix: [String] = []
        var swiftFlagsPrefix: [String] = []

        if hasBazelDependencies {
            // Work around stubbed swiftc messing with Indexing setting of
            // `-working-directory` incorrectly
            if buildMode == .bazel {
                if !swiftFlags.isEmpty {
                    swiftFlagsPrefix.append(contentsOf: [
                        "-Xcc",
                        "-working-directory",
                        "-Xcc",
                        "$(PROJECT_DIR)",
                        "-working-directory",
                        "$(PROJECT_DIR)",
                    ])
                }
            }
            if !cFlags.isEmpty {
                cFlagsPrefix.append(
                    contentsOf: ["-working-directory", "$(PROJECT_DIR)"]
                )
            }
            if !cxxFlags.isEmpty {
                cxxFlagsPrefix.append(
                    contentsOf: ["-working-directory", "$(PROJECT_DIR)"]
                )
            }

            switch buildMode {
            case .xcode:
                if target.hasModulemaps {
                    swiftFlagsPrefix.append(contentsOf: [
                        "-Xcc",
                        "-ivfsoverlay",
                        "-Xcc",
                        "$(DERIVED_FILE_DIR)/xcode-overlay.yaml",
                        "-Xcc",
                        "-ivfsoverlay",
                        "-Xcc",
                        "$(OBJROOT)/bazel-out-overlay.yaml",
                    ])
                }

                if target.inputs.containsSourceFiles {
                    if !cFlags.isEmpty {
                        cFlagsPrefix.append(contentsOf: [
                            "-ivfsoverlay",
                            "$(DERIVED_FILE_DIR)/xcode-overlay.yaml",
                        ])
                    }
                    if !cxxFlags.isEmpty {
                        cxxFlagsPrefix.append(contentsOf: [
                            "-ivfsoverlay",
                            "$(DERIVED_FILE_DIR)/xcode-overlay.yaml",
                        ])
                    }
                }
            case .bazel:
                if target.hasModulemaps {
                    swiftFlagsPrefix.append(contentsOf: [
                        "-Xcc",
                        "-ivfsoverlay",
                        "-Xcc",
                        "$(OBJROOT)/bazel-out-overlay.yaml",
                    ])
                }
            }

            if !swiftFlags.isEmpty {
                swiftFlagsPrefix.append(contentsOf: [
                    "-vfsoverlay",
                    "$(OBJROOT)/bazel-out-overlay.yaml",
                ])
            }
            if !cFlags.isEmpty {
                cFlagsPrefix.append(contentsOf: [
                    "-ivfsoverlay",
                    "$(OBJROOT)/bazel-out-overlay.yaml",
                ])
            }
            if !cxxFlags.isEmpty {
                cxxFlagsPrefix.append(contentsOf: [
                    "-ivfsoverlay",
                    "$(OBJROOT)/bazel-out-overlay.yaml",
                ])
            }
        }

        if buildSettings.keys.contains("PREVIEWS_SWIFT_INCLUDE__YES") {
            swiftFlagsPrefix.append(
                "$(PREVIEWS_SWIFT_INCLUDE__$(ENABLE_PREVIEWS))"
            )
        }

        var cFlagsString = (cFlagsPrefix + cFlags).joined(separator: " ")
        var cxxFlagsString = (cxxFlagsPrefix + cxxFlags).joined(separator: " ")
        let swiftFlagsString = (swiftFlagsPrefix + swiftFlags)
            .joined(separator: " ")

        // Append settings when using ASAN
        if target.cHasFortifySource {
            buildSettings["ASAN_OTHER_CFLAGS__"] = "$(ASAN_OTHER_CFLAGS__NO)"
            buildSettings.set("ASAN_OTHER_CFLAGS__NO", to: cFlagsString)
            buildSettings["ASAN_OTHER_CFLAGS__YES"] = #"""
$(ASAN_OTHER_CFLAGS__NO) -Wno-macro-redefined -D_FORTIFY_SOURCE=0
"""#
            cFlagsString = "$(ASAN_OTHER_CFLAGS__$(CLANG_ADDRESS_SANITIZER))"
        }
        if target.cxxHasFortifySource {
            buildSettings["ASAN_OTHER_CPLUSPLUSFLAGS__"] =
                "$(ASAN_OTHER_CPLUSPLUSFLAGS__NO)"
            buildSettings.set(
                "ASAN_OTHER_CPLUSPLUSFLAGS__NO",
                to: cxxFlagsString
            )
            buildSettings["ASAN_OTHER_CPLUSPLUSFLAGS__YES"] = #"""
$(ASAN_OTHER_CPLUSPLUSFLAGS__NO) -Wno-macro-redefined -D_FORTIFY_SOURCE=0
"""#
            cxxFlagsString = """
$(ASAN_OTHER_CPLUSPLUSFLAGS__$(CLANG_ADDRESS_SANITIZER))
"""
        }

        if !swiftFlagsString.isEmpty {
            try buildSettings.prepend(
                onKey: "OTHER_SWIFT_FLAGS",
                swiftFlagsString
            )
        }
        if !cFlagsString.isEmpty {
            buildSettings.set("OTHER_CFLAGS", to: cFlagsString)
        }
        if !cxxFlagsString.isEmpty {
            buildSettings.set("OTHER_CPLUSPLUSFLAGS", to: cxxFlagsString)
        }

        return buildSettings
    }

    private static func handleTestHost(
        for target: ConsolidatedTarget,
        disambiguatedTargets: DisambiguatedTargets,
        pbxTargets: [ConsolidatedTarget.Key: LabeledPBXNativeTarget],
        attributes: inout [String: Any],
        buildSettings:
            inout [String: [BuildSettingConditional: [String: BuildSetting]]]
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
        guard let labeledPBXTestHost = pbxTargets[testHostKey] else {
            throw PreconditionError(message: """
Test host pbxTarget with key \(testHostKey) not found in `pbxTargets`
""")
        }
        let pbxTestHost = labeledPBXTestHost.pbxTarget
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

        for target in targets {
            for xcodeConfiguration in target.xcodeConfigurations {
                guard target.product.type != .uiTestBundle else {
                    buildSettings[
                        xcodeConfiguration, default: [:]
                    ][.any, default: [:]].set(
                        "TEST_TARGET_NAME",
                        to: pbxTestHost.name
                    )

                    // UI test bundles need to be code signed to launch
                    buildSettings[
                        xcodeConfiguration, default: [:]
                    ][.any, default: [:]]["CODE_SIGNING_ALLOWED"] = true

                    continue
                }

                guard let testHostID = target.testHost else {
                    continue
                }

                guard
                    let testHost = consolidatedTestHost.targets[testHostID]
                else {
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
                buildSettings[
                    xcodeConfiguration, default: [:]
                ][conditional, default: [:]].set(
                    "TARGET_BUILD_DIR",
                    to: """
$(BUILD_DIR)/\(testHost.packageBinDir)$(TARGET_BUILD_SUBPATH)
"""
                )
                buildSettings[
                    xcodeConfiguration, default: [:]
                ][conditional, default: [:]].set(
                    "TEST_HOST",
                    to: """
$(BUILD_DIR)/\(testHost.packageBinDir)/\(productPath)/\(executableName)
"""
                )
            }
        }
    }
}

private extension Dictionary where Value == BuildSetting {
    mutating func prepend(
        onKey key: Key,
        onlyIfSet: Bool = false,
        _ content: [String]
    ) throws {
        let maybeBuildSetting = self[key]

        let buildSetting: Value
        if let maybeBuildSetting = maybeBuildSetting {
            buildSetting = maybeBuildSetting
        } else {
            guard !onlyIfSet else {
                return
            }
            buildSetting = .array([])
        }

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
    mutating func prepend(
        onKey key: Key,
        onlyIfSet: Bool = false,
        _ content: String
    ) throws {
        let maybeBuildSetting = self[key]

        let buildSetting: Value
        if let maybeBuildSetting = maybeBuildSetting {
            buildSetting = maybeBuildSetting
        } else {
            guard !onlyIfSet else {
                return
            }
            buildSetting = .string("")
        }

        switch buildSetting {
        case let .string(existing):
            let new: String
            if existing.isEmpty {
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
}

private extension Platform.OS {
    var sdkRoot: String {
        switch self {
        case .macOS: return "macosx"
        case .iOS: return "iphoneos"
        case .tvOS: return "appletvos"
        case .visionOS: return "xros"
        case .watchOS: return "watchos"
        }
    }
}

extension Inputs {
    var containsSourceFiles: Bool {
        return !(srcs.isEmpty && nonArcSrcs.isEmpty)
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

private let nonInheritableKeys: Set<String> = [
    "IPHONEOS_DEPLOYMENT_TARGET",
    "MACOSX_DEPLOYMENT_TARGET",
    "TVOS_DEPLOYMENT_TARGET",
    "XROS_DEPLOYMENT_TARGET",
    "WATCHOS_DEPLOYMENT_TARGET",
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
            let platforms = try Set(
                supportedPlatformsBuildSettings.values
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

        let baseConditions = Set(keys.filter { $0 != .any })

        var buildSettings: [String: BuildSetting] = [:]
        for (key, conditionalBuildSetting) in conditionalBuildSettings {
            let sortedConditionalBuildSettings = conditionalBuildSetting
                .sorted(by: { $0.key < $1.key })
            var remainingConditionalBuildSettings =
                ArraySlice(sortedConditionalBuildSettings)

            let firstCondition = sortedConditionalBuildSettings.first!.key

            var remainingConditions: Set<Key>
            let setBaseValue: Bool
            if firstCondition == .any || nonInheritableKeys.contains(key) {
                remainingConditions = []
                setBaseValue = true
            } else {
                remainingConditions = baseConditions

                // We only set a base value if none of the conditions want to
                // inherit defaults (since they would inherit the base value
                // instead of the default)
                setBaseValue = remainingConditions
                    .subtracting(conditionalBuildSetting.keys).isEmpty
            }

            let baseValue: BuildSetting?
            if setBaseValue {
                let (_, firstValue) =
                    remainingConditionalBuildSettings.popFirst()!
                baseValue = firstValue

                // Set the base value to `.any` or the most preferable condition
                // (i.e. Simulator or Apple Silicon)
                buildSettings[key] = firstValue

                // Set `BAZEL_{COMPILE_,}TARGET_ID` for first condition, for
                // buildRequest handling
                if Set(["BAZEL_TARGET_ID", "BAZEL_COMPILE_TARGET_IDS"])
                    .contains(key)
                {
                    buildSettings.set(
                        firstCondition.conditionalize(key),
                        to: "$(\(key))"
                    )
                }

                remainingConditions.remove(firstCondition)
            } else {
                baseValue = nil

                // Not setting a base value will cause it to inherit defaults.
                // We remove all `remainingConditions` because we don't need
                // to explicitly set them to inherit defaults either.
                remainingConditions.removeAll()
            }

            for (condition, buildSetting) in remainingConditionalBuildSettings {
                remainingConditions.remove(condition)

                guard buildSetting != baseValue else {
                    // Don't set redundant settings
                    continue
                }
                buildSettings[condition.conditionalize(key)] = buildSetting
            }

            for condition in remainingConditions {
                buildSettings[condition.conditionalize(key)] = "$(inherited)"
            }
        }

        return buildSettings.asDictionary
    }
}
