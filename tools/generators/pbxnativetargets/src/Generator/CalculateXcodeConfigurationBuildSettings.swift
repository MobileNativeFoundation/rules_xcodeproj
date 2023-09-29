import PBXProj
import ToolCommon

extension Generator {
    struct CalculateXcodeConfigurationBuildSettings {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Calculates the build settings for one of the target's Xcode
        /// configurations.
        func callAsFunction(
            platformBuildSettings: [PlatformBuildSettings],
            allConditionalFiles: Set<BazelPath>
        ) -> [BuildSetting] {
            return callable(
                /*platformBuildSettings:*/ platformBuildSettings,
                /*allConditionalFiles:*/ allConditionalFiles
            )
        }
    }
}

// MARK: - CalculateXcodeConfigurationBuildSettings.Callable

extension Generator.CalculateXcodeConfigurationBuildSettings {
    typealias Callable = (
        _ platformBuildSettings: [PlatformBuildSettings],
        _ allConditionalFiles: Set<BazelPath>
    ) -> [BuildSetting]

    static func defaultCallable(
        platformBuildSettings: [PlatformBuildSettings],
        allConditionalFiles: Set<BazelPath>
    ) -> [BuildSetting] {
        var buildSettings: [BuildSetting] = []
        var conditionalFiles: Set<BazelPath> = []
        var excludedSourceFileNames: [String] = []
        var platformedBuildSettings: [String: [(Platform, String)]] = [:]
        var platformConditionalFiles: [(String, Set<BazelPath>)] = []
        for platformBuildSettings in platformBuildSettings {
            let platform = platformBuildSettings.platform

            // Collect all build settings by key
            for buildSetting in platformBuildSettings.buildSettings {
                platformedBuildSettings[buildSetting.key, default: []]
                    .append((platform, buildSetting.value))
            }

            // Set per-platform conditional files
            if !platformBuildSettings.conditionalFiles.isEmpty {
                let key = """
\(platformBuildSettings.platform.rawValue.uppercased())_FILES
"""

                conditionalFiles
                    .formUnion(platformBuildSettings.conditionalFiles)
                excludedSourceFileNames.append(#"$(\#(key))"#)

                platformConditionalFiles.append(
                    (key, platformBuildSettings.conditionalFiles)
                )

                buildSettings.append(
                    .init(
                        key: key,
                        // Lots of code just to quote and `.pbxProjEscaped` the
                        // paths
                        value: #"""
"\#(
    platformBuildSettings.conditionalFiles
        .map { $0.path.quoteIfNeeded }
        // FIXME: See if we can not sort
        .sorted()
        .joined(separator: " ")
)"
"""#
                    )
                )

                let (
                    includeKey,
                    pbxProjEscapedIncludeKey
                ) = platform.conditionalizedBuildSettingKey(
                    "INCLUDED_SOURCE_FILE_NAMES"
                )

                buildSettings.append(
                    .init(
                        key: includeKey,
                        pbxProjEscapedKey: pbxProjEscapedIncludeKey,
                        value: #""$(\#(key))""#
                    )
                )
            }
        }

        // Exclude other configuration conditional files as well
        excludedSourceFileNames.append(
            contentsOf: allConditionalFiles
                .subtracting(conditionalFiles)
                .map { $0.path.quoteIfNeeded }
                // FIXME: See if we can not sort
                .sorted()
        )

        // Set configuration-wide conditional files
        if !excludedSourceFileNames.isEmpty {
            buildSettings.append(
                .init(
                    key: "EXCLUDED_SOURCE_FILE_NAMES",
                    // FIXME: Xcode wants as an array if multiple item?
                    value: #"""
"\#(excludedSourceFileNames.joined(separator: " "))"
"""#
                )
            )
            // TODO: See if we can do the normal thing here instead
            // (baseline is for the main platform)
            buildSettings.append(
                .init(
                    key: "INCLUDED_SOURCE_FILE_NAMES",
                    value: #""""#
                )
            )
        }

        let allPlatforms = Set(platformBuildSettings.map(\.platform))
        let basePlatform = platformBuildSettings.first!.platform

        for (key, platformAndValues) in platformedBuildSettings {
            let isNonInheritableKey = nonInheritableKeys.contains(key)

            var remainingPlatforms: Set<Platform>
            let setBaseValue: Bool
            if isNonInheritableKey {
                remainingPlatforms = []
                setBaseValue = true
            } else {
                remainingPlatforms = allPlatforms

                // We only set a base value if none of the platforms want to
                // inherit defaults (since they would inherit the base value
                // instead of the default)
                setBaseValue = remainingPlatforms
                    .subtracting(platformAndValues.map(\.0)).isEmpty
            }

            var remainingPlatformAndValues = ArraySlice(platformAndValues)

            let baseValue: String?
            if setBaseValue {
                let (_, firstValue) = remainingPlatformAndValues.popFirst()!
                baseValue = firstValue

                // Set the base value to the first platform, which will be
                // previously sorted, resulting in the most preferable default
                buildSettings.append(.init(key: key, value: firstValue))

                remainingPlatforms.remove(basePlatform)
            } else {
                baseValue = nil

                // Not setting a base value will cause it to inherit defaults.
                // We remove all `remainingPlatforms` because we don't need to
                // explicitly set them to inherit defaults either.
                remainingPlatforms.removeAll()
            }

            for (platform, value) in remainingPlatformAndValues {
                remainingPlatforms.remove(platform)

                guard value != baseValue else {
                    // Don't set redundant settings
                    continue
                }

                let (
                    conditionalizedKey,
                    pbxProjEscapedConditionalizedKey
                ) = platform.conditionalizedBuildSettingKey(key)
                buildSettings.append(
                    .init(
                        key: conditionalizedKey,
                        pbxProjEscapedKey: pbxProjEscapedConditionalizedKey,
                        value: value
                    )
                )
            }

            for platform in remainingPlatforms {
                let (
                    conditionalizedKey,
                    pbxProjEscapedConditionalizedKey
                ) = platform.conditionalizedBuildSettingKey(key)
                buildSettings.append(
                    .init(
                        key: conditionalizedKey,
                        pbxProjEscapedKey: pbxProjEscapedConditionalizedKey,
                        value: #""$(inherited)""#
                    )
                )
            }
        }

        return buildSettings
    }
}

struct PlatformBuildSettings: Equatable {
    let platform: Platform
    let conditionalFiles: Set<BazelPath>
    let buildSettings: [PlatformVariantBuildSetting]
}

private let nonInheritableKeys: Set<String> = [
    "IPHONEOS_DEPLOYMENT_TARGET",
    "MACOSX_DEPLOYMENT_TARGET",
    "TVOS_DEPLOYMENT_TARGET",
    "WATCHOS_DEPLOYMENT_TARGET",
]

private extension Platform {
    func conditionalizedBuildSettingKey(
        _ key: String
    ) -> (key: String, pbxProjEscapedKey: String) {
        let conditionalizedKey = #"\#(key)[sdk=\#(rawValue)*]"#
        return (
            key: conditionalizedKey,
            pbxProjEscapedKey: #""\#(conditionalizedKey)""#
        )
    }
}

private extension String {
    var quoteIfNeeded: String {
        guard !contains(" ") else {
            return #"\"\#(self)\""#
        }
        return self
    }
}
