import XcodeProj

enum XCSchemeConstants {
    // GH399: Derive the defaultLastUpgradeVersion
    static let defaultLastUpgradeVersion = "1320"
    static let lldbInitVersion = "1.7"
}

// MARK: XCScheme.BuildableReference

extension XCScheme.BuildableReference {
    convenience init(pbxTarget: PBXTarget, referencedContainer: String) {
        self.init(
            referencedContainer: referencedContainer,
            blueprint: pbxTarget,
            buildableName: pbxTarget.buildableName,
            blueprintName: pbxTarget.name
        )
    }
}

// MARK: XCScheme.BuildAction

extension XCScheme.BuildAction {
    convenience init<PBXTargetInfos: Sequence>(
        buildMode: BuildMode,
        targetInfos: PBXTargetInfos
    ) where PBXTargetInfos.Element == XCScheme.PBXTargetInfo {
        self.init(
            buildActionEntries: targetInfos.buildActionEntries,
            preActions: buildMode.usesBazelModeBuildScripts ?
                targetInfos.bazelBuildPreActions : [],
            parallelizeBuild: true,
            buildImplicitDependencies: true
        )
    }
}

// MARK: XCScheme.BuildAction.Entry

extension XCScheme.BuildAction.Entry {
    convenience init(withDefaults buildableReference: XCScheme.BuildableReference) {
        self.init(
            buildableReference: buildableReference,
            buildFor: [
                .running,
                .testing,
                .profiling,
                .archiving,
                .analyzing,
            ]
        )
    }
}

// MARK: XCScheme.ExecutionAction

extension XCScheme.ExecutionAction {
    static let initBazelBuildOutputGroupsFile = XCScheme.ExecutionAction(
        scriptText: #"""
mkdir -p "${BAZEL_BUILD_OUTPUT_GROUPS_FILE%/*}"
if [[ -s "$BAZEL_BUILD_OUTPUT_GROUPS_FILE" ]]; then
    rm "$BAZEL_BUILD_OUTPUT_GROUPS_FILE"
fi
"""#,
        title: "Initialize Bazel Build Output Groups File"
    )

    // convenience init?(targetInfo: XCScheme.PBXTargetInfo, hostIndex: Int?) {
    //     guard targetInfo.pbxTarget is PBXNativeTarget else {
    //       return nil
    //     }

    //     let hostTargetOutputGroup: String
    //     if let hostIndex = hostIndex {
    //         hostTargetOutputGroup = #"""
// echo "b $BAZEL_HOST_TARGET_ID_\#(hostIndex)" >> "$BAZEL_BUILD_OUTPUT_GROUPS_FILE"
// """#
    //     } else {
    //         hostTargetOutputGroup = ""
    //     }

    //     let scriptText = #"""
// echo "b $BAZEL_TARGET_ID" >> "$BAZEL_BUILD_OUTPUT_GROUPS_FILE"
// \#(hostTargetOutputGroup)
// """#
    //     self.init(
    //         scriptText: scriptText,
    //         title: "Set Bazel Build Output Groups for \(targetInfo.pbxTarget.name)",
    //         environmentBuildable: targetInfo.buildableReference
    //     )
    // }

    convenience init(
        bazelBuildFor buildableReference: XCScheme.BuildableReference,
        name: String,
        hostIndex: Int?
    ) {
        let hostTargetOutputGroup: String
        if let hostIndex = hostIndex {
            hostTargetOutputGroup = #"""
echo "b $BAZEL_HOST_TARGET_ID_\#(hostIndex)" >> "$BAZEL_BUILD_OUTPUT_GROUPS_FILE"
"""#
        } else {
            hostTargetOutputGroup = ""
        }

        let scriptText = #"""
echo "b $BAZEL_TARGET_ID" >> "$BAZEL_BUILD_OUTPUT_GROUPS_FILE"
\#(hostTargetOutputGroup)
"""#
        self.init(
            scriptText: scriptText,
            title: "Set Bazel Build Output Groups for \(name)",
            environmentBuildable: buildableReference
        )
    }
}
