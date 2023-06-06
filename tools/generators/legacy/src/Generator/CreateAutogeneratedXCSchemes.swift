import GeneratorCommon
import OrderedCollections
import PathKit
import XcodeProj

struct AutogeneratedScheme: Equatable {
    let scheme: XCScheme
    let productTypeSortOrder: Int
}

extension Generator {
    /// Creates an array of `XCScheme` entries for the specified targets.
    static func createAutogeneratedXCSchemes(
        schemeAutogenerationMode: SchemeAutogenerationMode,
        buildMode: BuildMode,
        targetResolver: TargetResolver,
        customSchemeNames: Set<String>,
        args: [TargetID: [String]],
        envs: [TargetID: [String: String]]
    ) throws -> [AutogeneratedScheme] {
        let shouldAutogenerateSchemes: Bool
        switch schemeAutogenerationMode {
        case .none:
            shouldAutogenerateSchemes = false
        case .all:
            shouldAutogenerateSchemes = true
        case .auto:
            shouldAutogenerateSchemes = customSchemeNames.isEmpty
        }
        guard shouldAutogenerateSchemes else {
            return []
        }

        // Scheme names collisions can occur with names that differ by case. The
        // scheme name checks will occur using their lowercased variant.
        let normalizedCustomSchemeNames = Set(
            customSchemeNames.map { $0.lowercased() }
        )

        return try targetResolver
            .targetInfos.filter(\.pbxTarget.shouldCreateScheme)
            .compactMap { targetInfo in
                let pbxTarget = targetInfo.pbxTarget
                let buildConfigurationName = pbxTarget.defaultBuildConfigurationName

                let shouldCreateTestAction = pbxTarget.isTestable
                let shouldCreateLaunchAction = pbxTarget.isLaunchable
                var env: [String: String]?
                var targetArgs: [String]?
                if shouldCreateTestAction {
                    env = try envs.first(where: { testEnv in
                        let testEnvTargetInfo: XCSchemeInfo.TargetInfo = try targetResolver.targetInfo(targetID: testEnv.key)
                        if testEnvTargetInfo == targetInfo {
                            return true
                        }
                        return false
                    })?.value
                    targetArgs = try args.first(where: { passedArgs in
                        let passedArgsTargetInfo: XCSchemeInfo.TargetInfo = try targetResolver.targetInfo(targetID: passedArgs.key)
                        if passedArgsTargetInfo == targetInfo {
                            return true
                        }
                        return false
                    })?.value.extractCommandLineArguments()
                }

                let schemeInfo = try XCSchemeInfo(
                    defaultBuildConfigurationName: buildConfigurationName,
                    buildActionInfo: .init(targets: [
                        .init(targetInfo: targetInfo, buildFor: .allEnabled),
                    ]),
                    launchActionInfo: shouldCreateLaunchAction ?
                        .init(
                            buildConfigurationName: buildConfigurationName,
                            targetInfo: targetInfo
                        ) : nil,
                    testActionInfo: shouldCreateTestAction ?
                        .init(
                            buildConfigurationName: buildConfigurationName,
                            targetInfos: [targetInfo],
                            args: targetArgs,
                            env: env
                        ) : nil,
                    profileActionInfo: shouldCreateLaunchAction ?
                        .init(
                            buildConfigurationName: buildConfigurationName,
                            targetInfo: targetInfo
                        ) : nil,
                    analyzeActionInfo: .init(buildConfigurationName: buildConfigurationName),
                    archiveActionInfo: .init(buildConfigurationName: buildConfigurationName)
                ) { buildActionInfo, _, _, _ in
                    guard let targetInfo = buildActionInfo?.targets.first?.targetInfo else {
                        throw PreconditionError(message: """
    Expected to find a `TargetInfo` in the `BuildActionInfo`.
    """)
                    }
                    let schemeName: String
                    if let selectedHostInfo = try targetInfo.selectedHostInfo,
                        targetInfo.disambiguateHost
                    {
                        schemeName = """
    \(targetInfo.pbxTarget.schemeName) in \(selectedHostInfo.pbxTarget.schemeName)
    """
                    } else {
                        schemeName = targetInfo.pbxTarget.schemeName
                    }
                    return schemeName
                }

                // If a custom scheme exists with a colliding name, then
                // preserve the custom scheme
                guard !normalizedCustomSchemeNames
                    .contains(schemeInfo.name.lowercased())
                else {
                    return nil
                }

                return try AutogeneratedScheme(
                    scheme: XCScheme(
                        buildMode: buildMode,
                        schemeInfo: schemeInfo
                    ),
                    productTypeSortOrder:
                        (pbxTarget.productType ?? .none).sortOrder
                )
            }
    }
}
