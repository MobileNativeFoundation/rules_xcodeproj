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
            var targetBuildSettings = target.buildSettings

            let quoteHeaders = target.searchPaths.quoteHeaders
            if !quoteHeaders.isEmpty {
                targetBuildSettings["USER_HEADER_SEARCH_PATHS"] = .array(
                    quoteHeaders.map { filePath in
                        return filePathResolver.resolve(filePath).string.quoted
                    }
                )
            }

            let includes = target.searchPaths.includes
            if !includes.isEmpty {
                targetBuildSettings["HEADER_SEARCH_PATHS"] = .array(
                    includes.map { filePath in
                        return filePathResolver.resolve(filePath).string.quoted
                    }
                )
            }

            try targetBuildSettings.prepend(
                onKey: "OTHER_SWIFT_FLAGS",
                target.modulemaps
                    .map { filePath -> String in
                        let modulemap = filePathResolver
                            .resolve(filePath)
                            .string.quoted
                        return "-Xcc -fmodule-map-file=\(modulemap)"
                    }
            )

            var buildSettings = targetBuildSettings.asDictionary
            
            buildSettings["BAZEL_PACKAGE_BIN_DIR"] = target.packageBinDir.string

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

private extension Dictionary where Value == BuildSetting {
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
