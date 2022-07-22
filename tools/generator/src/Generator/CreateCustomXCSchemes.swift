import PathKit
import XcodeProj

// TODO: Add support for extension points.
// TODO: Add support for hosts?

extension Generator {
    /// Creates an array of `XCScheme` entries from the scheme descriptions.
    static func createCustomXCSchemes(
        schemes _: [XcodeScheme],
        buildMode _: BuildMode,
        filePathResolver _: FilePathResolver,
        targets _: [TargetID: Target],
        consolidatedTargetKeys _: [TargetID: ConsolidatedTarget.Key],
        pbxTargets _: [ConsolidatedTarget.Key: PBXTarget]
    ) throws -> [XCScheme] {
        // TODO: FIX ME
        return []
        // let referencedContainer = filePathResolver.containerReference
        // return schemes.map { scheme in
        //     createCustomXCSchemes(
        //         scheme: scheme,
        //         buildMode: buildMode,
        //         referencedContainer: referencedContainer,
        //         targets: targets,
        //         consolidatedTargetKeys: consolidatedTargetKeys,
        //         pbxTargets: pbxTargets
        //     )
        // }
    }

    // private static func createCustomXCScheme(
    //     scheme _: XcodeScheme,
    //     buildMode _: BuildMode,
    //     referencedContainer _: String,
    //     targets: [TargetID: Target],
    //     consolidatedTargetKeys _: [TargetID: ConsolidatedTarget.Key],
    //     pbxTargets _: [ConsolidatedTarget.Key: PBXTarget]
    // ) throws -> XCScheme {
    //     let schemeTargetIDs = scheme.resolveTargetIDs(targets: targets)

    //     return XCScheme(
    //         name: schemeName,
    //         lastUpgradeVersion: XCSchemes.defaultLastUpgradeVersion,
    //         version: XCSchemes.lldbInitVersion,
    //         buildAction: buildAction,
    //         testAction: testAction,
    //         launchAction: launchAction,
    //         profileAction: profileAction,
    //         analyzeAction: analyzeAction,
    //         archiveAction: archiveAction,
    //         wasCreatedForAppExtension: productType.isExtension ? true : nil
    //     )
    // }
}
