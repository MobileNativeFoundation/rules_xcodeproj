import CustomDump
import PBXProj
import XCScheme
import XCTest

@testable import xcschemes

final class CreateAutomaticSchemeInfosTests: XCTestCase {

    // MARK: - autogenerationMode

    func test_autogenerationMode_all() throws {
        // Arrange

        let autogenerationMode = AutogenerationMode.all
        let customSchemeNames: Set<String> = [
            "A",
            "B scheme",
        ]
        let targets: [Target] = [
            .mock(key: "B"),
            .mock(key: "A"),
            .mock(key: "C"),
        ]

        let createTargetAutomaticSchemeInfos =
            Generator.CreateTargetAutomaticSchemeInfos.mock(
                targetSchemeInfos: [
                    [.mock(name: "B scheme")],
                    [.mock(name: "A scheme 1"), .mock(name: "A scheme 2")],
                    [.mock(name: "C scheme")],
                ]
            )

        let expectedSchemeInfos: [SchemeInfo] = [
            .mock(name: "B scheme"),
            .mock(name: "A scheme 1"),
            .mock(name: "A scheme 2"),
            .mock(name: "C scheme"),
        ]

        // Act

        let schemeInfos = try createAutomaticSchemeInfosWithDefaults(
            autogenerationMode: autogenerationMode,
            customSchemeNames: customSchemeNames,
            targets: targets,
            createTargetAutomaticSchemeInfos:
                createTargetAutomaticSchemeInfos.mock
        )

        // Assert

        XCTAssertNoDifference(schemeInfos, expectedSchemeInfos)
    }

    func test_autogenerationMode_auto_withoutCustomSchemeNames() throws {
        // Arrange

        let autogenerationMode = AutogenerationMode.auto
        let customSchemeNames: Set<String> = []
        let targets: [Target] = [
            .mock(key: "B"),
            .mock(key: "A"),
            .mock(key: "C"),
        ]

        let createTargetAutomaticSchemeInfos =
            Generator.CreateTargetAutomaticSchemeInfos.mock(
                targetSchemeInfos: [
                    [.mock(name: "B scheme")],
                    [.mock(name: "A scheme 1"), .mock(name: "A scheme 2")],
                    [.mock(name: "C scheme")],
                ]
            )

        let expectedSchemeInfos: [SchemeInfo] = [
            .mock(name: "B scheme"),
            .mock(name: "A scheme 1"),
            .mock(name: "A scheme 2"),
            .mock(name: "C scheme"),
        ]

        // Act

        let schemeInfos = try createAutomaticSchemeInfosWithDefaults(
            autogenerationMode: autogenerationMode,
            customSchemeNames: customSchemeNames,
            targets: targets,
            createTargetAutomaticSchemeInfos:
                createTargetAutomaticSchemeInfos.mock
        )

        // Assert

        XCTAssertNoDifference(schemeInfos, expectedSchemeInfos)
    }

    func test_autogenerationMode_auto_withCustomSchemeNames() throws {
        // Arrange

        let autogenerationMode = AutogenerationMode.auto
        let customSchemeNames: Set<String> = [
            "Z",
        ]
        let targets: [Target] = [
            .mock(key: "B"),
            .mock(key: "A"),
            .mock(key: "C"),
        ]

        let createTargetAutomaticSchemeInfos =
            Generator.CreateTargetAutomaticSchemeInfos.mock(
                targetSchemeInfos: []
            )

        let expectedSchemeInfos: [SchemeInfo] = []

        // Act

        let schemeInfos = try createAutomaticSchemeInfosWithDefaults(
            autogenerationMode: autogenerationMode,
            customSchemeNames: customSchemeNames,
            targets: targets,
            createTargetAutomaticSchemeInfos:
                createTargetAutomaticSchemeInfos.mock
        )

        // Assert

        XCTAssertNoDifference(schemeInfos, expectedSchemeInfos)
    }

    func test_autogenerationMode_none() throws {
        // Arrange

        let autogenerationMode = AutogenerationMode.none
        let targets: [Target] = [
            .mock(key: "B"),
            .mock(key: "A"),
            .mock(key: "C"),
        ]

        let createTargetAutomaticSchemeInfos =
            Generator.CreateTargetAutomaticSchemeInfos.mock(
                targetSchemeInfos: []
            )

        let expectedSchemeInfos: [SchemeInfo] = []

        // Act

        let schemeInfos = try createAutomaticSchemeInfosWithDefaults(
            autogenerationMode: autogenerationMode,
            targets: targets,
            createTargetAutomaticSchemeInfos:
                createTargetAutomaticSchemeInfos.mock
        )

        // Assert

        XCTAssertNoDifference(schemeInfos, expectedSchemeInfos)
    }

    // MARK: - createTargetAutomaticSchemeInfos

    func test_createTargetAutomaticSchemeInfos() throws {
        // Arrange

        let buildPostActions: [AutogenerationConfig.Action] = [
            .init(title: "Build End", scriptText: "echo end\n", order: 100),
        ]
        let buildPreActions: [AutogenerationConfig.Action] = [
            .init(title: "Build Start", scriptText: "echo start\n", order: -200),
        ]
        let profilePostActions: [AutogenerationConfig.Action] = [
            .init(title: "Profile End", scriptText: "echo profile-end\n", order: 75),
        ]
        let profilePreActions: [AutogenerationConfig.Action] = [
            .init(title: "Profile Start", scriptText: "echo profile-start\n", order: -75),
        ]
        let runPostActions: [AutogenerationConfig.Action] = [
            .init(title: "Run End", scriptText: "echo run-end\n", order: 200),
        ]
        let runPreActions: [AutogenerationConfig.Action] = [
            .init(title: "Run Start", scriptText: "echo run-start\n", order: -100),
        ]
        let testPostActions: [AutogenerationConfig.Action] = [
            .init(title: "Test End", scriptText: "echo test-end\n", order: 50),
        ]
        let testPreActions: [AutogenerationConfig.Action] = [
            .init(title: "Test Start", scriptText: "echo test-start\n", order: -50),
        ]
        let commandLineArguments: [TargetID: [CommandLineArgument]] = [
            "A": [
                .init(value: "-v", isEnabled: true),
                .init(value: "version", isEnabled: false),
                .init(value: "grouped arg", isLiteralString: false),
            ],
            "C": [],
            "Z": [.init(value: "No", isEnabled: false)],
        ]
        let customSchemeNames: Set<String> = [
            "Z",
        ]
        let environmentVariables: [TargetID: [EnvironmentVariable]] = [
            "B": [
                .init(key: "VAR", value: "not enabled", isEnabled: false),
                .init(key: "ENV VAR", value: "1", isEnabled: true),
            ],
            "Z": [.init(key: "X", value: "No", isEnabled: false)],
        ]
        let extensionHostIDs: [TargetID : [TargetID]] = [
            "XyZ": ["3", "WWW"],
        ]
        let targets: [Target] = [
            .mock(key: "Z", productType: .watch2Extension),
            .mock(key: "B", productType: .appExtension),
            .mock(key: "A", productType: .messagesExtension),
            .mock(key: "C", productType: .application),
        ]
        let targetsByID: [TargetID: Target] = [
            "Q": .mock(key: "Q"),
        ]
        let targetsByKey: [Target.Key: Target] = [
            ["1", "D"]: .mock(key: ["1", "D"]),
        ]

        // The order these are called is based on the sorting of `targets`,
        // first on the product type, then on
        // `buildableReference.blueprintName`. Also, certain product types are
        // filtered out.
        let expectedCreateTargetAutomaticSchemeInfosCalled: [
            Generator.CreateTargetAutomaticSchemeInfos.MockTracker.Called
        ] = [
            .init(
                buildPostActions: buildPostActions,
                buildPreActions: buildPreActions,
                buildRunPostActionsOnFailure: true,
                profilePostActions: profilePostActions,
                profilePreActions: profilePreActions,
                commandLineArguments: [],
                customSchemeNames: customSchemeNames,
                environmentVariables: [],
                extensionHostIDs: extensionHostIDs,
                runPostActions: runPostActions,
                runPreActions: runPreActions,
                target: .mock(key: "C", productType: .application),
                testPostActions: testPostActions,
                testPreActions: testPreActions,
                targetsByID: targetsByID,
                targetsByKey: targetsByKey,
                testOptions: nil
            ),
            .init(
                buildPostActions: buildPostActions,
                buildPreActions: buildPreActions,
                buildRunPostActionsOnFailure: true,
                profilePostActions: profilePostActions,
                profilePreActions: profilePreActions,
                commandLineArguments: [
                    .init(value: "-v", isEnabled: true),
                    .init(value: "version", isEnabled: false),
                    .init(value: "grouped arg", isLiteralString: false),
                ],
                customSchemeNames: customSchemeNames,
                environmentVariables: [],
                extensionHostIDs: extensionHostIDs,
                runPostActions: runPostActions,
                runPreActions: runPreActions,
                target: .mock(key: "A", productType: .messagesExtension),
                testPostActions: testPostActions,
                testPreActions: testPreActions,
                targetsByID: targetsByID,
                targetsByKey: targetsByKey,
                testOptions: nil
            ),
            .init(
                buildPostActions: buildPostActions,
                buildPreActions: buildPreActions,
                buildRunPostActionsOnFailure: true,
                profilePostActions: profilePostActions,
                profilePreActions: profilePreActions,
                commandLineArguments: [],
                customSchemeNames: customSchemeNames,
                environmentVariables: [
                    .init(key: "VAR", value: "not enabled", isEnabled: false),
                    .init(key: "ENV VAR", value: "1", isEnabled: true),
                ],
                extensionHostIDs: extensionHostIDs,
                runPostActions: runPostActions,
                runPreActions: runPreActions,
                target: .mock(key: "B", productType: .appExtension),
                testPostActions: testPostActions,
                testPreActions: testPreActions,
                targetsByID: targetsByID,
                targetsByKey: targetsByKey,
                testOptions: nil
            ),
        ]
        let createTargetAutomaticSchemeInfos =
            Generator.CreateTargetAutomaticSchemeInfos.mock(
                targetSchemeInfos: [
                    [.mock(name: "Scheme 4")],
                    [.mock(name: "Scheme Z"), .mock(name: "Scheme 2")],
                    [.mock(name: "Scheme 1")],
                ]
            )

        let expectedSchemeInfos: [SchemeInfo] = [
            .mock(name: "Scheme 4"),
            .mock(name: "Scheme Z"),
            .mock(name: "Scheme 2"),
            .mock(name: "Scheme 1"),
        ]

        // Act

        let schemeInfos = try createAutomaticSchemeInfosWithDefaults(
            buildPostActions: buildPostActions,
            buildPreActions: buildPreActions,
            buildRunPostActionsOnFailure: true,
            profilePostActions: profilePostActions,
            profilePreActions: profilePreActions,
            commandLineArguments: commandLineArguments,
            customSchemeNames: customSchemeNames,
            environmentVariables: environmentVariables,
            extensionHostIDs: extensionHostIDs,
            runPostActions: runPostActions,
            runPreActions: runPreActions,
            targets: targets,
            testPostActions: testPostActions,
            testPreActions: testPreActions,
            targetsByID: targetsByID,
            targetsByKey: targetsByKey,
            createTargetAutomaticSchemeInfos:
                createTargetAutomaticSchemeInfos.mock
        )

        // Assert

        XCTAssertNoDifference(schemeInfos, expectedSchemeInfos)
        XCTAssertNoDifference(
            createTargetAutomaticSchemeInfos.tracker.called,
            expectedCreateTargetAutomaticSchemeInfosCalled
        )
    }
}

private func createAutomaticSchemeInfosWithDefaults(
    autogenerationMode: AutogenerationMode = .all,
    buildPostActions: [AutogenerationConfig.Action] = [],
    buildPreActions: [AutogenerationConfig.Action] = [],
    buildRunPostActionsOnFailure: Bool = false,
    profilePostActions: [AutogenerationConfig.Action] = [],
    profilePreActions: [AutogenerationConfig.Action] = [],
    commandLineArguments: [TargetID: [CommandLineArgument]] = [:],
    customSchemeNames: Set<String> = [],
    environmentVariables: [TargetID: [EnvironmentVariable]] = [:],
    extensionHostIDs: [TargetID : [TargetID]] = [:],
    runPostActions: [AutogenerationConfig.Action] = [],
    runPreActions: [AutogenerationConfig.Action] = [],
    targets: [Target],
    testPostActions: [AutogenerationConfig.Action] = [],
    testPreActions: [AutogenerationConfig.Action] = [],
    targetsByID: [TargetID : Target] = [:],
    targetsByKey: [Target.Key : Target] = [:],
    createTargetAutomaticSchemeInfos: Generator.CreateTargetAutomaticSchemeInfos,
    testOptions: SchemeInfo.Test.Options? = nil
) throws -> [SchemeInfo] {
    return try Generator.CreateAutomaticSchemeInfos.defaultCallable(
        autogenerationMode: autogenerationMode,
        buildPostActions: buildPostActions,
        buildPreActions: buildPreActions,
        buildRunPostActionsOnFailure: buildRunPostActionsOnFailure,
        profilePostActions: profilePostActions,
        profilePreActions: profilePreActions,
        commandLineArguments: commandLineArguments,
        customSchemeNames: customSchemeNames,
        environmentVariables: environmentVariables,
        extensionHostIDs: extensionHostIDs,
        runPostActions: runPostActions,
        runPreActions: runPreActions,
        targets: targets,
        targetsByID: targetsByID,
        targetsByKey: targetsByKey,
        testPostActions: testPostActions,
        testPreActions: testPreActions,
        createTargetAutomaticSchemeInfos: createTargetAutomaticSchemeInfos,
        testOptions: testOptions
    )
}
