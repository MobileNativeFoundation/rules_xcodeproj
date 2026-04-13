import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CreateSynchronizedGroupTests: XCTestCase {
    func test_membershipExceptions() throws {
        let temporaryDirectory = try TemporaryDirectory()
        let workspace = temporaryDirectory.url

        let folderURL = workspace
            .appendingPathComponent("App", isDirectory: true)
            .appendingPathComponent("Sources", isDirectory: true)
        try FileManager.default.createDirectory(
            at: folderURL,
            withIntermediateDirectories: true
        )

        try "struct Feature {}".write(
            to: folderURL.appendingPathComponent("Feature.swift"),
            atomically: false,
            encoding: .utf8
        )
        try "{}".write(
            to: folderURL.appendingPathComponent("Info.plist"),
            atomically: false,
            encoding: .utf8
        )
        try "notes".write(
            to: folderURL.appendingPathComponent("README.md"),
            atomically: false,
            encoding: .utf8
        )

        let createAttributes = ElementCreator.CreateAttributes.stub(
            elementAttributes: .init(
                sourceTree: .group,
                name: nil,
                path: "Sources"
            ),
            resolvedRepository: nil
        )
        let createSynchronizedGroup = ElementCreator.CreateSynchronizedGroup(
            createAttributes: createAttributes,
            installPath: "App/App.xcodeproj",
            workspace: workspace.path
        )

        let synchronizedFolder = PathTreeNode.SynchronizedFolder(
            path: "App/Sources",
            targets: [
                .init(
                    folderPath: "App/Sources",
                    targetIdentifier: "TARGET /* App */",
                    targetName: "App",
                    includedPaths: ["App/Sources/Feature.swift"],
                    excludedPaths: ["App/Sources/Info.plist"]
                )
            ]
        )

        let result = createSynchronizedGroup(
            name: "Sources",
            synchronizedFolder: synchronizedFolder,
            bazelPathType: .workspace
        )

        let exceptionIdentifier =
            Identifiers.FilesAndGroups.synchronizedBuildFileExceptionSet(
                path: "App/Sources",
                targetIdentifier: "TARGET /* App */"
            )
        let groupIdentifier = Identifiers.FilesAndGroups.synchronizedRootGroup(
            "App/Sources",
            name: "Sources"
        )

        let expectedResult = GroupChild.ElementAndChildren(
            element: .init(
                name: "Sources",
                object: .init(
                    identifier: groupIdentifier,
                    content: #"""
{
			isa = PBXFileSystemSynchronizedRootGroup;
			exceptions = (
				\#(exceptionIdentifier),
			);
			path = Sources;
			sourceTree = "<group>";
		}
"""#
                ),
                sortOrder: .groupLike
            ),
            transitiveObjects: [
                .init(
                    identifier: exceptionIdentifier,
                    content: #"""
{
			isa = PBXFileSystemSynchronizedBuildFileExceptionSet;
			membershipExceptions = (
				Info.plist,
				README.md,
			);
			target = TARGET /* App */;
		}
"""#
                ),
                .init(
                    identifier: groupIdentifier,
                    content: #"""
{
			isa = PBXFileSystemSynchronizedRootGroup;
			exceptions = (
				\#(exceptionIdentifier),
			);
			path = Sources;
			sourceTree = "<group>";
		}
"""#
                ),
            ],
            bazelPathAndIdentifiers: [
                ("App/Sources", groupIdentifier),
            ],
            knownRegions: [],
            resolvedRepositories: []
        )

        XCTAssertNoDifference(result, expectedResult)
    }

    func test_ignoresGeneratedProjectBundle() throws {
        let temporaryDirectory = try TemporaryDirectory()
        let workspace = temporaryDirectory.url

        let folderURL = workspace
            .appendingPathComponent("App", isDirectory: true)
            .appendingPathComponent("Sources", isDirectory: true)
        try FileManager.default.createDirectory(
            at: folderURL,
            withIntermediateDirectories: true
        )

        let projectURL = workspace
            .appendingPathComponent("App", isDirectory: true)
            .appendingPathComponent("App.xcodeproj", isDirectory: true)
        try FileManager.default.createDirectory(
            at: projectURL,
            withIntermediateDirectories: true
        )
        try "{}".write(
            to: projectURL.appendingPathComponent("project.pbxproj"),
            atomically: false,
            encoding: .utf8
        )

        try "struct Feature {}".write(
            to: folderURL.appendingPathComponent("Feature.swift"),
            atomically: false,
            encoding: .utf8
        )
        try "notes".write(
            to: folderURL.appendingPathComponent("README.md"),
            atomically: false,
            encoding: .utf8
        )

        let createAttributes = ElementCreator.CreateAttributes.stub(
            elementAttributes: .init(
                sourceTree: .group,
                name: nil,
                path: "App"
            ),
            resolvedRepository: nil
        )
        let createSynchronizedGroup = ElementCreator.CreateSynchronizedGroup(
            createAttributes: createAttributes,
            installPath: "App/App.xcodeproj",
            workspace: workspace.path
        )

        let synchronizedFolder = PathTreeNode.SynchronizedFolder(
            path: "App",
            targets: [
                .init(
                    folderPath: "App",
                    targetIdentifier: "TARGET /* App */",
                    targetName: "App",
                    includedPaths: ["App/Sources/Feature.swift"],
                    excludedPaths: []
                )
            ]
        )

        let result = createSynchronizedGroup(
            name: "App",
            synchronizedFolder: synchronizedFolder,
            bazelPathType: .workspace
        )

        let exceptionIdentifier =
            Identifiers.FilesAndGroups.synchronizedBuildFileExceptionSet(
                path: "App",
                targetIdentifier: "TARGET /* App */"
            )
        let groupIdentifier = Identifiers.FilesAndGroups.synchronizedRootGroup(
            "App",
            name: "App"
        )

        let expectedResult = GroupChild.ElementAndChildren(
            element: .init(
                name: "App",
                object: .init(
                    identifier: groupIdentifier,
                    content: #"""
{
			isa = PBXFileSystemSynchronizedRootGroup;
			exceptions = (
				\#(exceptionIdentifier),
			);
			path = App;
			sourceTree = "<group>";
		}
"""#
                ),
                sortOrder: .groupLike
            ),
            transitiveObjects: [
                .init(
                    identifier: exceptionIdentifier,
                    content: #"""
{
			isa = PBXFileSystemSynchronizedBuildFileExceptionSet;
			membershipExceptions = (
				Sources/README.md,
			);
			target = TARGET /* App */;
		}
"""#
                ),
                .init(
                    identifier: groupIdentifier,
                    content: #"""
{
			isa = PBXFileSystemSynchronizedRootGroup;
			exceptions = (
				\#(exceptionIdentifier),
			);
			path = App;
			sourceTree = "<group>";
		}
"""#
                ),
            ],
            bazelPathAndIdentifiers: [
                ("App", groupIdentifier),
            ],
            knownRegions: [],
            resolvedRepositories: []
        )

        XCTAssertNoDifference(result, expectedResult)
    }

    func test_forceWorkspaceRooted() throws {
        let temporaryDirectory = try TemporaryDirectory()
        let workspace = temporaryDirectory.url

        let createSynchronizedGroup = ElementCreator.CreateSynchronizedGroup(
            createAttributes: ElementCreator.CreateAttributes.stub(
                elementAttributes: .init(
                    sourceTree: .group,
                    name: nil,
                    path: "unused"
                ),
                resolvedRepository: nil
            ),
            installPath: "App/App.xcodeproj",
            workspace: workspace.path
        )

        let synchronizedFolder = PathTreeNode.SynchronizedFolder(
            path: "App/Tests",
            targets: [
                .init(
                    folderPath: "App/Tests",
                    targetIdentifier: "TARGET /* Tests */",
                    targetName: "Tests",
                    includedPaths: [],
                    excludedPaths: []
                )
            ]
        )

        let result = createSynchronizedGroup(
            name: "Tests",
            synchronizedFolder: synchronizedFolder,
            bazelPathType: .workspace,
            forceWorkspaceRooted: true
        )

        let groupIdentifier = Identifiers.FilesAndGroups.synchronizedRootGroup(
            "App/Tests",
            name: "Tests"
        )

        let expectedResult = GroupChild.ElementAndChildren(
            element: .init(
                name: "Tests",
                object: .init(
                    identifier: groupIdentifier,
                    content: #"""
{
			isa = PBXFileSystemSynchronizedRootGroup;
			name = Tests;
			path = App/Tests;
			sourceTree = SOURCE_ROOT;
		}
"""#
                ),
                sortOrder: .groupLike
            ),
            transitiveObjects: [
                .init(
                    identifier: groupIdentifier,
                    content: #"""
{
			isa = PBXFileSystemSynchronizedRootGroup;
			name = Tests;
			path = App/Tests;
			sourceTree = SOURCE_ROOT;
		}
"""#
                ),
            ],
            bazelPathAndIdentifiers: [
                ("App/Tests", groupIdentifier),
            ],
            knownRegions: [],
            resolvedRepositories: []
        )

        XCTAssertNoDifference(result, expectedResult)
    }

    func test_folderTypeResourcesKeepDescendantsIncluded() throws {
        let temporaryDirectory = try TemporaryDirectory()
        let workspace = temporaryDirectory.url

        let folderURL = workspace
            .appendingPathComponent("App", isDirectory: true)
        let assetsURL = folderURL
            .appendingPathComponent("Assets.xcassets", isDirectory: true)
        let accentColorURL = assetsURL
            .appendingPathComponent("AccentColor.colorset", isDirectory: true)
        try FileManager.default.createDirectory(
            at: accentColorURL,
            withIntermediateDirectories: true
        )

        try "{}".write(
            to: assetsURL.appendingPathComponent("Contents.json"),
            atomically: false,
            encoding: .utf8
        )
        try "{}".write(
            to: accentColorURL.appendingPathComponent("Contents.json"),
            atomically: false,
            encoding: .utf8
        )
        try "notes".write(
            to: folderURL.appendingPathComponent("README.md"),
            atomically: false,
            encoding: .utf8
        )

        let createAttributes = ElementCreator.CreateAttributes.stub(
            elementAttributes: .init(
                sourceTree: .group,
                name: nil,
                path: "App"
            ),
            resolvedRepository: nil
        )
        let createSynchronizedGroup = ElementCreator.CreateSynchronizedGroup(
            createAttributes: createAttributes,
            installPath: "App/App.xcodeproj",
            workspace: workspace.path
        )

        let synchronizedFolder = PathTreeNode.SynchronizedFolder(
            path: "App",
            targets: [
                .init(
                    folderPath: "App",
                    targetIdentifier: "TARGET /* App */",
                    targetName: "App",
                    includedPaths: ["App/Assets.xcassets"],
                    excludedPaths: []
                )
            ]
        )

        let result = createSynchronizedGroup(
            name: "App",
            synchronizedFolder: synchronizedFolder,
            bazelPathType: .workspace
        )

        let exceptionIdentifier =
            Identifiers.FilesAndGroups.synchronizedBuildFileExceptionSet(
                path: "App",
                targetIdentifier: "TARGET /* App */"
            )
        let groupIdentifier = Identifiers.FilesAndGroups.synchronizedRootGroup(
            "App",
            name: "App"
        )

        let expectedResult = GroupChild.ElementAndChildren(
            element: .init(
                name: "App",
                object: .init(
                    identifier: groupIdentifier,
                    content: #"""
{
			isa = PBXFileSystemSynchronizedRootGroup;
			exceptions = (
				\#(exceptionIdentifier),
			);
			path = App;
			sourceTree = "<group>";
		}
"""#
                ),
                sortOrder: .groupLike
            ),
            transitiveObjects: [
                .init(
                    identifier: exceptionIdentifier,
                    content: #"""
{
			isa = PBXFileSystemSynchronizedBuildFileExceptionSet;
			membershipExceptions = (
				README.md,
			);
			target = TARGET /* App */;
		}
"""#
                ),
                .init(
                    identifier: groupIdentifier,
                    content: #"""
{
			isa = PBXFileSystemSynchronizedRootGroup;
			exceptions = (
				\#(exceptionIdentifier),
			);
			path = App;
			sourceTree = "<group>";
		}
"""#
                ),
            ],
            bazelPathAndIdentifiers: [
                ("App", groupIdentifier),
            ],
            knownRegions: [],
            resolvedRepositories: []
        )

        XCTAssertNoDifference(result, expectedResult)
    }

}
