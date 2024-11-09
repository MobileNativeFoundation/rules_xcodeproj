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
                commandLineArguments: [],
                customSchemeNames: customSchemeNames,
                environmentVariables: [],
                extensionHostIDs: extensionHostIDs,
                target: .mock(key: "C", productType: .application),
                targetsByID: targetsByID,
                targetsByKey: targetsByKey,
                testOptions: nil
            ),
            .init(
                commandLineArguments: [
                    .init(value: "-v", isEnabled: true),
                    .init(value: "version", isEnabled: false),
                    .init(value: "grouped arg", isLiteralString: false),
                ],
                customSchemeNames: customSchemeNames,
                environmentVariables: [],
                extensionHostIDs: extensionHostIDs,
                target: .mock(key: "A", productType: .messagesExtension),
                targetsByID: targetsByID,
                targetsByKey: targetsByKey,
                testOptions: nil
            ),
            .init(
                commandLineArguments: [],
                customSchemeNames: customSchemeNames,
                environmentVariables: [
                    .init(key: "VAR", value: "not enabled", isEnabled: false),
                    .init(key: "ENV VAR", value: "1", isEnabled: true),
                ],
                extensionHostIDs: extensionHostIDs,
                target: .mock(key: "B", productType: .appExtension),
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
            commandLineArguments: commandLineArguments,
            customSchemeNames: customSchemeNames,
            environmentVariables: environmentVariables,
            extensionHostIDs: extensionHostIDs,
            targets: targets,
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
    commandLineArguments: [TargetID: [CommandLineArgument]] = [:],
    customSchemeNames: Set<String> = [],
    environmentVariables: [TargetID: [EnvironmentVariable]] = [:],
    extensionHostIDs: [TargetID : [TargetID]] = [:],
    targets: [Target],
    targetsByID: [TargetID : Target] = [:],
    targetsByKey: [Target.Key : Target] = [:],
    createTargetAutomaticSchemeInfos: Generator.CreateTargetAutomaticSchemeInfos,
    testOptions: SchemeInfo.Test.Options? = nil
) throws -> [SchemeInfo] {
    return try Generator.CreateAutomaticSchemeInfos.defaultCallable(
        autogenerationMode: autogenerationMode,
        commandLineArguments: commandLineArguments,
        customSchemeNames: customSchemeNames,
        environmentVariables: environmentVariables,
        extensionHostIDs: extensionHostIDs,
        targets: targets,
        targetsByID: targetsByID,
        targetsByKey: targetsByKey,
        createTargetAutomaticSchemeInfos: createTargetAutomaticSchemeInfos,
        testOptions: testOptions
    )
}
