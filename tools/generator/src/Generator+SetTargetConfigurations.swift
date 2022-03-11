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
        externalDirectory: Path,
        generatedDirectory: Path
    ) throws {
        for (id, disambiguatedTarget) in disambiguatedTargets {
            guard let pbxTarget = pbxTargets[id] else {
                throw PreconditionError(message: """
Target "\(id)" not found in `pbxTargets`.
""")
            }

            let target = disambiguatedTarget.target

            var attributes: [String: Any] = [
                // TODO: Generate this value
                "CreatedOnToolsVersion": "13.2.1",
                // TODO: Only include properties that make sense for the target
                "LastSwiftMigration": 1320,
            ]
            var buildSettings = target.buildSettings.asDictionary

            let quoteHeaders = target.searchPaths.quoteHeaders
            if !quoteHeaders.isEmpty {
                buildSettings["USER_HEADER_SEARCH_PATHS"] = quoteHeaders
                    .resolved(
                        externalDirectory: externalDirectory,
                        generatedDirectory: generatedDirectory
                    )
            }

            buildSettings["TARGET_NAME"] = disambiguatedTarget.nameBuildSetting

            if let testHostID = target.testHost {
                guard let testHost = pbxTargets[testHostID] else {
                    throw PreconditionError(message: """
Test host with id "\(testHostID)" not found
""")
                }

                attributes["TestTargetID"] = testHost

                if target.product.type == .uiTestBundle {
                    buildSettings["TEST_TARGET_NAME"] = testHost.name
                } else {
                    guard let productPath = testHost.product?.path else {
                        throw PreconditionError(message: """
`product.path` not set on test host "\(testHost.name)"
""")
                    }
                    guard let productName = testHost.productName else {
                        throw PreconditionError(message: """
`productName` not set on test host "\(testHost.name)"
""")
                    }
                    buildSettings["BUNDLE_LOADER"] = "$(TEST_HOST)"
                    buildSettings["TEST_HOST"] =
                        "$(BUILT_PRODUCTS_DIR)/\(productPath)/\(productName)"
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

private extension Sequence where Element == FilePath {
    /// Returns the source root relative paths of the files in the sequence.
    func resolved(
        externalDirectory: Path,
        generatedDirectory: Path
    ) -> [String] {
        return map { filePath in
            return filePath.resolved(
                externalDirectory: externalDirectory,
                generatedDirectory: generatedDirectory
            )
        }
    }
}

private extension FilePath {
    /// Returns the source root relative path.
    func resolved(
        externalDirectory: Path,
        generatedDirectory: Path
    ) -> String {
        switch type {
        case .external:
            return (externalDirectory + path).quotedString
        case .generated:
            return (generatedDirectory + path).quotedString
        default:
            return path.quotedString
        }
    }
}

private extension Path {
    /// Wraps the path in quotes if it needs it
    var quotedString: String {
        guard string.rangeOfCharacter(from: .whitespaces) != nil else {
            return string
        }
        return #""\#(string)""#
    }
}
