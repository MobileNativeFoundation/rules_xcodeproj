import XcodeProj

enum XCSchemeConstants {
    // GH399: Derive the defaultLastUpgradeVersion
    static let defaultLastUpgradeVersion = "1320"
    static let lldbInitVersion = "1.7"
}

// MARK: XCScheme.PBXTargetInfo

extension XCScheme {
    struct PBXTargetInfo {
        let pbxTarget: PBXTarget
        let buildableReference: XCScheme.BuildableReference

        init(pbxTarget: PBXTarget, referencedContainer: String) {
             self.pbxTarget = pbxTarget
             buildableReference = .init(
                 pbxTarget: pbxTarget,
                 referencedContainer: referencedContainer
             )
        }
    }
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
        targetInfos: PBXTargetInfos,
        hostBuildableReference: XCScheme.BuildableReference?,
        hostIndex: Int?
    ) where PBXTargetInfos.Element == XCScheme.PBXTargetInfo {
        let buildableReferences = targetInfos.map(\.buildableReference)

        let entries: [XCScheme.BuildAction.Entry] = (buildableReferences + [hostBuildableReference])
            .compactMap { $0 }
            .map { .init(withDefaults: $0) }

        let preActions: [XCScheme.ExecutionAction]
        if buildMode.usesBazelModeBuildScripts {
            let targetInfoPreActions: [XCScheme.ExecutionAction] = targetInfos
                .compactMap { .init(targetInfo: $0, hostIndex: hostIndex) }
            preActions = targetInfoPreActions.isEmpty ? [] :
                [.clearBazelBuildOutputGroupsFile] + targetInfoPreActions
        } else {
            preActions = []
        }

        self.init(
            buildActionEntries: entries,
            preActions: preActions,
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
    static let clearBazelBuildOutputGroupsFile = XCScheme.ExecutionAction(
        scriptText: #"""
if [[ -s "$BAZEL_BUILD_OUTPUT_GROUPS_FILE" ]]; then
    rm "$BAZEL_BUILD_OUTPUT_GROUPS_FILE"
fi
"""#,
        title: "Clear Bazel Build Output Groups File"
    )

    convenience init?(targetInfo: XCScheme.PBXTargetInfo, hostIndex: Int?) {
        guard targetInfo.pbxTarget is PBXNativeTarget else {
          return nil
        }

        let hostTargetOutputGroup: String
        if let hostIndex = hostIndex {
            hostTargetOutputGroup = #"""
echo "b $BAZEL_HOST_TARGET_ID_\#(hostIndex)" >> "$BAZEL_BUILD_OUTPUT_GROUPS_FILE"
"""#
        } else {
            hostTargetOutputGroup = ""
        }

        let scriptText = #"""
mkdir -p "${BAZEL_BUILD_OUTPUT_GROUPS_FILE%/*}"
echo "b $BAZEL_TARGET_ID" >> "$BAZEL_BUILD_OUTPUT_GROUPS_FILE"
\#(hostTargetOutputGroup)
"""#
        self.init(
            scriptText: scriptText,
            title: "Set Bazel Build Output Groups for \(targetInfo.pbxTarget.name)",
            environmentBuildable: targetInfo.buildableReference
        )
    }
}
