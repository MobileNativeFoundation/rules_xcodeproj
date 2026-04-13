import Foundation
import PBXProj
import ToolCommon
import XCTest

@testable import files_and_groups

final class ElementCreatorTests: XCTestCase {
    func test_nestedSynchronizedFolderObjectsAreStillEmitted() throws {
        let temporaryDirectory = try TemporaryDirectory()
        let workspace = temporaryDirectory.url

        try FileManager.default.createDirectory(
            at: workspace.appendingPathComponent("App/Tests", isDirectory: true),
            withIntermediateDirectories: true
        )

        let executionRootFile = workspace.appendingPathComponent(
            "execution_root.txt"
        )
        try workspace.path.write(
            to: executionRootFile,
            atomically: false,
            encoding: .utf8
        )

        let selectedModelVersionsFile = workspace.appendingPathComponent(
            "selected_model_versions.json"
        )
        try "[]".write(
            to: selectedModelVersionsFile,
            atomically: false,
            encoding: .utf8
        )

        let pathTree: [PathTreeNode] = [
            .synchronizedGroup(
                name: "App",
                synchronizedFolder: .init(
                    path: "App",
                    targets: [
                        .init(
                            folderPath: "App",
                            targetIdentifier: "APP_TARGET /* App */",
                            targetName: "App",
                            includedPaths: [],
                            excludedPaths: []
                        )
                    ]
                )
            )
        ]
        let synchronizedFolders: [SynchronizedFolderTarget] = [
            .init(
                folderPath: "App",
                targetIdentifier: "APP_TARGET /* App */",
                targetName: "App",
                includedPaths: [],
                excludedPaths: []
            ),
            .init(
                folderPath: "App/Tests",
                targetIdentifier: "TEST_TARGET /* Tests */",
                targetName: "Tests",
                includedPaths: [],
                excludedPaths: []
            ),
        ]

        let arguments = try ElementCreator.Arguments.parse([
            workspace.path,
            "App/App.xcodeproj",
            executionRootFile.path,
            selectedModelVersionsFile.path,
            "",
            "",
            "",
        ])

        let createdElements = try ElementCreator(
            environment: .default
        ).create(
            pathTree: pathTree,
            arguments: arguments,
            compileStubNeeded: false,
            synchronizedFolders: synchronizedFolders
        )

        let nestedIdentifier = Identifiers.FilesAndGroups.synchronizedRootGroup(
            "App/Tests",
            name: "Tests"
        )

        XCTAssertTrue(createdElements.partial.contains(nestedIdentifier))
        XCTAssertTrue(createdElements.partial.contains("name = Tests;"))
        XCTAssertTrue(createdElements.partial.contains("path = App/Tests;"))
        XCTAssertTrue(createdElements.partial.contains("sourceTree = SOURCE_ROOT;"))
    }
}
