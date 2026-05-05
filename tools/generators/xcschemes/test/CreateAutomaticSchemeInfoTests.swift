import CustomDump
import PBXProj
import XCScheme
import XCTest

@testable import xcschemes

final class CreateAutomaticSchemeInfoTests: XCTestCase {

    // MARK: - Custom schemes

    func test_customSchemeNames_match() throws {
        // Arrange

        let customSchemeNames: Set<String> = [
            "BLUEPRINT_NAME_Launchable",
            "Other",
        ]
        let launchable = Target(
            key: "Launchable",
            productType: .application,
            buildableReference: .init(
                blueprintIdentifier: "BLUEPRINT_IDENTIFIER_Launchable",
                buildableName: "BUILDABLE_NAME_Launchable",
                blueprintName: "BLUEPRINT_NAME_Launchable",
                referencedContainer: "REFERENCED_CONTAINER_Launchable"
            )
        )

        // Act

        let schemeInfo = try createAutomaticSchemeInfoWithDefaults(
            customSchemeNames: customSchemeNames,
            target: launchable
        )

        // Assert

        XCTAssertNil(schemeInfo)
    }

    func test_customSchemeNames_match_hosted() throws {
        // Arrange

        let customSchemeNames: Set<String> = [
            "BLUEPRINT_NAME_Launchable",
            "Other",
        ]
        let extensionHost = Target(
            key: "Host",
            productType: .appExtension,
            buildableReference: .init(
                blueprintIdentifier: "BLUEPRINT_IDENTIFIER_Host",
                buildableName: "BUILDABLE_NAME_Host",
                blueprintName: "BLUEPRINT_NAME_Host",
                referencedContainer: "REFERENCED_CONTAINER_Host"
            )
        )
        let launchable = Target(
            key: "Launchable",
            productType: .application,
            buildableReference: .init(
                blueprintIdentifier: "BLUEPRINT_IDENTIFIER_Launchable",
                buildableName: "BUILDABLE_NAME_Launchable",
                blueprintName: "BLUEPRINT_NAME_Launchable",
                referencedContainer: "REFERENCED_CONTAINER_Launchable"
            )
        )

        // Act

        let schemeInfo = try createAutomaticSchemeInfoWithDefaults(
            customSchemeNames: customSchemeNames,
            extensionHost: extensionHost,
            target: launchable
        )

        // Assert

        XCTAssertNil(schemeInfo)
    }

    func test_customSchemeNames_noMatch() throws {
        // Arrange

        let customSchemeNames: Set<String> = [
            "Other",
        ]
        let launchable = Target(
            key: "Launchable",
            productType: .application,
            buildableReference: .init(
                blueprintIdentifier: "BLUEPRINT_IDENTIFIER_Launchable",
                buildableName: "BUILDABLE_NAME_Launchable",
                blueprintName: "BLUEPRINT_NAME_Launchable",
                referencedContainer: "REFERENCED_CONTAINER_Launchable"
            )
        )

        // Act

        let schemeInfo = try createAutomaticSchemeInfoWithDefaults(
            customSchemeNames: customSchemeNames,
            target: launchable
        )

        // Assert

        XCTAssertNotNil(schemeInfo)
    }

    // MARK: - Launchable

    func test_launchable() throws {
        // Arrange

        let launchable = Target(
            key: "Launchable",
            productType: .application,
            buildableReference: .init(
                blueprintIdentifier: "BLUEPRINT_IDENTIFIER_Launchable",
                buildableName: "BUILDABLE_NAME_Launchable",
                blueprintName: "BLUEPRINT_NAME_Launchable",
                referencedContainer: "REFERENCED_CONTAINER_Launchable"
            )
        )

        let expectedSchemeInfo = SchemeInfo(
            name: "BLUEPRINT_NAME_Launchable",
            test: .init(
                buildTargets: [],
                commandLineArguments: [],
                enableAddressSanitizer: false,
                enableThreadSanitizer: false,
                enableUBSanitizer: false,
                enableMainThreadChecker: false,
                enableThreadPerformanceChecker: false,
                environmentVariables: [],
                options: nil,
                testTargets: [],
                useRunArgsAndEnv: true,
                xcodeConfiguration: nil
            ),
            run: .init(
                buildTargets: [],
                commandLineArguments: [],
                customWorkingDirectory: nil,
                enableAddressSanitizer: false,
                enableThreadSanitizer: false,
                enableUBSanitizer: false,
                enableMainThreadChecker: false,
                enableThreadPerformanceChecker: false,
                environmentVariables: baseEnvironmentVariables,
                launchTarget: .target(
                    primary: launchable,
                    extensionHost: nil
                ),
                runBuildPostActionsOnFailure: false,
                storeKitConfiguration: nil,
                xcodeConfiguration: nil
            ),
            profile: .init(
                buildTargets: [],
                commandLineArguments: [],
                customWorkingDirectory: nil,
                environmentVariables: [],
                launchTarget: .target(
                    primary: launchable,
                    extensionHost: nil
                ),
                useRunArgsAndEnv: true,
                xcodeConfiguration: nil
            ),
            executionActions: []
        )

        // Act

        let schemeInfo = try createAutomaticSchemeInfoWithDefaults(
            target: launchable
        )

        // Assert

        XCTAssertNoDifference(schemeInfo, expectedSchemeInfo)
    }

    func test_launchable_hosted() throws {
        // Arrange

        let extensionHost = Target(
            key: "Host",
            productType: .appExtension,
            buildableReference: .init(
                blueprintIdentifier: "BLUEPRINT_IDENTIFIER_Host",
                buildableName: "BUILDABLE_NAME_Host",
                blueprintName: "BLUEPRINT_NAME_Host",
                referencedContainer: "REFERENCED_CONTAINER_Host"
            )
        )
        let launchable = Target(
            key: "Launchable",
            productType: .appExtension,
            buildableReference: .init(
                blueprintIdentifier: "BLUEPRINT_IDENTIFIER_Launchable",
                buildableName: "BUILDABLE_NAME_Launchable",
                blueprintName: "BLUEPRINT_NAME_Launchable",
                referencedContainer: "REFERENCED_CONTAINER_Launchable"
            )
        )

        let expectedSchemeInfo = SchemeInfo(
            name: "BLUEPRINT_NAME_Launchable in BLUEPRINT_NAME_Host",
            test: .init(
                buildTargets: [],
                commandLineArguments: [],
                enableAddressSanitizer: false,
                enableThreadSanitizer: false,
                enableUBSanitizer: false,
                enableMainThreadChecker: false,
                enableThreadPerformanceChecker: false,
                environmentVariables: [],
                options: nil,
                testTargets: [],
                useRunArgsAndEnv: true,
                xcodeConfiguration: nil
            ),
            run: .init(
                buildTargets: [],
                commandLineArguments: [],
                customWorkingDirectory: nil,
                enableAddressSanitizer: false,
                enableThreadSanitizer: false,
                enableUBSanitizer: false,
                enableMainThreadChecker: false,
                enableThreadPerformanceChecker: false,
                environmentVariables: baseEnvironmentVariables,
                launchTarget: .target(
                    primary: launchable,
                    extensionHost: extensionHost
                ),
                runBuildPostActionsOnFailure: false,
                storeKitConfiguration: nil,
                xcodeConfiguration: nil
            ),
            profile: .init(
                buildTargets: [],
                commandLineArguments: [],
                customWorkingDirectory: nil,
                environmentVariables: [],
                launchTarget: .target(
                    primary: launchable,
                    extensionHost: extensionHost
                ),
                useRunArgsAndEnv: true,
                xcodeConfiguration: nil
            ),
            executionActions: []
        )

        // Act

        let schemeInfo = try createAutomaticSchemeInfoWithDefaults(
            extensionHost: extensionHost,
            target: launchable
        )

        // Assert

        XCTAssertNoDifference(schemeInfo, expectedSchemeInfo)
    }

    func test_launchable_commandLineArguments() throws {
        // Arrange

        let launchable = Target(
            key: "Launchable",
            productType: .watch2App,
            buildableReference: .init(
                blueprintIdentifier: "BLUEPRINT_IDENTIFIER_Launchable",
                buildableName: "BUILDABLE_NAME_Launchable",
                blueprintName: "BLUEPRINT_NAME_Launchable",
                referencedContainer: "REFERENCED_CONTAINER_Launchable"
            )
        )
        let commandLineArguments: [CommandLineArgument] = [
            .init(value: "S", isEnabled: false),
            .init(value: "A", isEnabled: true),
            .init(value: "G A", isLiteralString: false),
        ]

        let expectedSchemeInfo = SchemeInfo(
            name: "BLUEPRINT_NAME_Launchable",
            test: .init(
                buildTargets: [],
                commandLineArguments: [],
                enableAddressSanitizer: false,
                enableThreadSanitizer: false,
                enableUBSanitizer: false,
                enableMainThreadChecker: false,
                enableThreadPerformanceChecker: false,
                environmentVariables: [],
                options: nil,
                testTargets: [],
                useRunArgsAndEnv: true,
                xcodeConfiguration: nil
            ),
            run: .init(
                buildTargets: [],
                commandLineArguments: commandLineArguments,
                customWorkingDirectory: nil,
                enableAddressSanitizer: false,
                enableThreadSanitizer: false,
                enableUBSanitizer: false,
                enableMainThreadChecker: false,
                enableThreadPerformanceChecker: false,
                environmentVariables: baseEnvironmentVariables,
                launchTarget: .target(
                    primary: launchable,
                    extensionHost: nil
                ),
                runBuildPostActionsOnFailure: false,
                storeKitConfiguration: nil,
                xcodeConfiguration: nil
            ),
            profile: .init(
                buildTargets: [],
                commandLineArguments: [],
                customWorkingDirectory: nil,
                environmentVariables: [],
                launchTarget: .target(
                    primary: launchable,
                    extensionHost: nil
                ),
                useRunArgsAndEnv: true,
                xcodeConfiguration: nil
            ),
            executionActions: []
        )

        // Act

        let schemeInfo = try createAutomaticSchemeInfoWithDefaults(
            commandLineArguments: commandLineArguments,
            target: launchable
        )

        // Assert

        XCTAssertNoDifference(schemeInfo, expectedSchemeInfo)
    }

    func test_launchable_environmentVariables() throws {
        // Arrange

        let launchable = Target(
            key: "Launchable",
            productType: .commandLineTool,
            buildableReference: .init(
                blueprintIdentifier: "BLUEPRINT_IDENTIFIER_Launchable",
                buildableName: "BUILDABLE_NAME_Launchable",
                blueprintName: "BLUEPRINT_NAME_Launchable",
                referencedContainer: "REFERENCED_CONTAINER_Launchable"
            )
        )
        let environmentVariables: [EnvironmentVariable] = [
            .init(key: "D", value: "999", isEnabled: true),
            .init(key: "H", value: "2 2", isEnabled: false),
        ]

        let expectedSchemeInfo = SchemeInfo(
            name: "BLUEPRINT_NAME_Launchable",
            test: .init(
                buildTargets: [],
                commandLineArguments: [],
                enableAddressSanitizer: false,
                enableThreadSanitizer: false,
                enableUBSanitizer: false,
                enableMainThreadChecker: false,
                enableThreadPerformanceChecker: false,
                environmentVariables: [],
                options: nil,
                testTargets: [],
                useRunArgsAndEnv: true,
                xcodeConfiguration: nil
            ),
            run: .init(
                buildTargets: [],
                commandLineArguments: [],
                customWorkingDirectory: nil,
                enableAddressSanitizer: false,
                enableThreadSanitizer: false,
                enableUBSanitizer: false,
                enableMainThreadChecker: false,
                enableThreadPerformanceChecker: false,
                environmentVariables:
                    baseEnvironmentVariables + environmentVariables,
                launchTarget: .target(
                    primary: launchable,
                    extensionHost: nil
                ),
                runBuildPostActionsOnFailure: false,
                storeKitConfiguration: nil,
                xcodeConfiguration: nil
            ),
            profile: .init(
                buildTargets: [],
                commandLineArguments: [],
                customWorkingDirectory: nil,
                environmentVariables: [],
                launchTarget: .target(
                    primary: launchable,
                    extensionHost: nil
                ),
                useRunArgsAndEnv: true,
                xcodeConfiguration: nil
            ),
            executionActions: []
        )

        // Act

        let schemeInfo = try createAutomaticSchemeInfoWithDefaults(
            environmentVariables: environmentVariables,
            target: launchable
        )

        // Assert

        XCTAssertNoDifference(schemeInfo, expectedSchemeInfo)
    }

    // MARK: Static library

    func test_library() throws {
        // Arrange

        let library = Target(
            key: "Library",
            productType: .staticLibrary,
            buildableReference: .init(
                blueprintIdentifier: "BLUEPRINT_IDENTIFIER_Library",
                buildableName: "BUILDABLE_NAME_Library",
                blueprintName: "BLUEPRINT_NAME_Library",
                referencedContainer: "REFERENCED_CONTAINER_Library"
            )
        )

        let expectedSchemeInfo = SchemeInfo(
            name: "BLUEPRINT_NAME_Library",
            test: .init(
                buildTargets: [],
                commandLineArguments: [],
                enableAddressSanitizer: false,
                enableThreadSanitizer: false,
                enableUBSanitizer: false,
                enableMainThreadChecker: false,
                enableThreadPerformanceChecker: false,
                environmentVariables: [],
                options: nil,
                testTargets: [],
                useRunArgsAndEnv: true,
                xcodeConfiguration: nil
            ),
            run: .init(
                buildTargets: [library],
                commandLineArguments: [],
                customWorkingDirectory: nil,
                enableAddressSanitizer: false,
                enableThreadSanitizer: false,
                enableUBSanitizer: false,
                enableMainThreadChecker: false,
                enableThreadPerformanceChecker: false,
                environmentVariables: baseEnvironmentVariables,
                launchTarget: nil,
                runBuildPostActionsOnFailure: false,
                storeKitConfiguration: nil,
                xcodeConfiguration: nil
            ),
            profile: .init(
                buildTargets: [],
                commandLineArguments: [],
                customWorkingDirectory: nil,
                environmentVariables: [],
                launchTarget: nil,
                useRunArgsAndEnv: true,
                xcodeConfiguration: nil
            ),
            executionActions: []
        )

        // Act

        let schemeInfo = try createAutomaticSchemeInfoWithDefaults(
            target: library
        )

        // Assert

        XCTAssertNoDifference(schemeInfo, expectedSchemeInfo)
    }

    // MARK: - Test

    func test_test() throws {
        // Arrange

        let test = Target(
            key: "Test",
            productType: .unitTestBundle,
            buildableReference: .init(
                blueprintIdentifier: "BLUEPRINT_IDENTIFIER_Test",
                buildableName: "BUILDABLE_NAME_Test",
                blueprintName: "BLUEPRINT_NAME_Test",
                referencedContainer: "REFERENCED_CONTAINER_Test"
            )
        )

        let expectedSchemeInfo = SchemeInfo(
            name: "BLUEPRINT_NAME_Test",
            test: .init(
                buildTargets: [],
                commandLineArguments: [],
                enableAddressSanitizer: false,
                enableThreadSanitizer: false,
                enableUBSanitizer: false,
                enableMainThreadChecker: false,
                enableThreadPerformanceChecker: false,
                environmentVariables: baseEnvironmentVariables,
                options: nil,
                testTargets: [.init(target: test, isEnabled: true)],
                useRunArgsAndEnv: false,
                xcodeConfiguration: nil
            ),
            run: .init(
                buildTargets: [test],
                commandLineArguments: [],
                customWorkingDirectory: nil,
                enableAddressSanitizer: false,
                enableThreadSanitizer: false,
                enableUBSanitizer: false,
                enableMainThreadChecker: false,
                enableThreadPerformanceChecker: false,
                environmentVariables: [],
                launchTarget: nil,
                runBuildPostActionsOnFailure: false,
                storeKitConfiguration: nil,
                xcodeConfiguration: nil
            ),
            profile: .init(
                buildTargets: [],
                commandLineArguments: [],
                customWorkingDirectory: nil,
                environmentVariables: [],
                launchTarget: nil,
                useRunArgsAndEnv: true,
                xcodeConfiguration: nil
            ),
            executionActions: []
        )

        // Act

        let schemeInfo = try createAutomaticSchemeInfoWithDefaults(
            target: test
        )

        // Assert

        XCTAssertNoDifference(schemeInfo, expectedSchemeInfo)
    }

    func test_test_commandLineArguments() throws {
        // Arrange

        let test = Target(
            key: "Test",
            productType: .unitTestBundle,
            buildableReference: .init(
                blueprintIdentifier: "BLUEPRINT_IDENTIFIER_Test",
                buildableName: "BUILDABLE_NAME_Test",
                blueprintName: "BLUEPRINT_NAME_Test",
                referencedContainer: "REFERENCED_CONTAINER_Test"
            )
        )
        let commandLineArguments: [CommandLineArgument] = [
            .init(value: "B", isEnabled: false),
            .init(value: "G AA", isLiteralString: false),
            .init(value: "F", isEnabled: true),
        ]

        let expectedSchemeInfo = SchemeInfo(
            name: "BLUEPRINT_NAME_Test",
            test: .init(
                buildTargets: [],
                commandLineArguments: commandLineArguments,
                enableAddressSanitizer: false,
                enableThreadSanitizer: false,
                enableUBSanitizer: false,
                enableMainThreadChecker: false,
                enableThreadPerformanceChecker: false,
                environmentVariables: baseEnvironmentVariables,
                options: nil,
                testTargets: [.init(target: test, isEnabled: true)],
                useRunArgsAndEnv: false,
                xcodeConfiguration: nil
            ),
            run: .init(
                buildTargets: [test],
                commandLineArguments: [],
                customWorkingDirectory: nil,
                enableAddressSanitizer: false,
                enableThreadSanitizer: false,
                enableUBSanitizer: false,
                enableMainThreadChecker: false,
                enableThreadPerformanceChecker: false,
                environmentVariables: [],
                launchTarget: nil,
                runBuildPostActionsOnFailure: false,
                storeKitConfiguration: nil,
                xcodeConfiguration: nil
            ),
            profile: .init(
                buildTargets: [],
                commandLineArguments: [],
                customWorkingDirectory: nil,
                environmentVariables: [],
                launchTarget: nil,
                useRunArgsAndEnv: true,
                xcodeConfiguration: nil
            ),
            executionActions: []
        )

        // Act

        let schemeInfo = try createAutomaticSchemeInfoWithDefaults(
            commandLineArguments: commandLineArguments,
            target: test
        )

        // Assert

        XCTAssertNoDifference(schemeInfo, expectedSchemeInfo)
    }

    func test_test_environmentVariables() throws {
        // Arrange

        let test = Target(
            key: "Test",
            productType: .unitTestBundle,
            buildableReference: .init(
                blueprintIdentifier: "BLUEPRINT_IDENTIFIER_Test",
                buildableName: "BUILDABLE_NAME_Test",
                blueprintName: "BLUEPRINT_NAME_Test",
                referencedContainer: "REFERENCED_CONTAINER_Test"
            )
        )
        let environmentVariables: [EnvironmentVariable] = [
            .init(key: "Z", value: "1", isEnabled: true),
            .init(key: "A", value: "2", isEnabled: false),
        ]

        let expectedSchemeInfo = SchemeInfo(
            name: "BLUEPRINT_NAME_Test",
            test: .init(
                buildTargets: [],
                commandLineArguments: [],
                enableAddressSanitizer: false,
                enableThreadSanitizer: false,
                enableUBSanitizer: false,
                enableMainThreadChecker: false,
                enableThreadPerformanceChecker: false,
                environmentVariables:
                    baseEnvironmentVariables + environmentVariables,
                options: nil,
                testTargets: [.init(target: test, isEnabled: true)],
                useRunArgsAndEnv: false,
                xcodeConfiguration: nil
            ),
            run: .init(
                buildTargets: [test],
                commandLineArguments: [],
                customWorkingDirectory: nil,
                enableAddressSanitizer: false,
                enableThreadSanitizer: false,
                enableUBSanitizer: false,
                enableMainThreadChecker: false,
                enableThreadPerformanceChecker: false,
                environmentVariables: [],
                launchTarget: nil,
                runBuildPostActionsOnFailure: false,
                storeKitConfiguration: nil,
                xcodeConfiguration: nil
            ),
            profile: .init(
                buildTargets: [],
                commandLineArguments: [],
                customWorkingDirectory: nil,
                environmentVariables: [],
                launchTarget: nil,
                useRunArgsAndEnv: true,
                xcodeConfiguration: nil
            ),
            executionActions: []
        )

        // Act

        let schemeInfo = try createAutomaticSchemeInfoWithDefaults(
            environmentVariables: environmentVariables,
            target: test
        )

        // Assert

        XCTAssertNoDifference(schemeInfo, expectedSchemeInfo)
    }

    func test_test_options() throws {
        // Arrange

        let test = Target(
            key: "Test",
            productType: .unitTestBundle,
            buildableReference: .init(
                blueprintIdentifier: "BLUEPRINT_IDENTIFIER_Test",
                buildableName: "BUILDABLE_NAME_Test",
                blueprintName: "BLUEPRINT_NAME_Test",
                referencedContainer: "REFERENCED_CONTAINER_Test"
            )
        )

        let expectedSchemeInfo = SchemeInfo(
            name: "BLUEPRINT_NAME_Test",
            test: .init(
                buildTargets: [],
                commandLineArguments: [],
                enableAddressSanitizer: false,
                enableThreadSanitizer: false,
                enableUBSanitizer: false,
                enableMainThreadChecker: false,
                enableThreadPerformanceChecker: false,
                environmentVariables: baseEnvironmentVariables,
                options: .init(
                    appLanguage: "en",
                    appRegion: "US",
                    codeCoverage: false
                ),
                testTargets: [.init(target: test, isEnabled: true)],
                useRunArgsAndEnv: false,
                xcodeConfiguration: nil
            ),
            run: .init(
                buildTargets: [test],
                commandLineArguments: [],
                customWorkingDirectory: nil,
                enableAddressSanitizer: false,
                enableThreadSanitizer: false,
                enableUBSanitizer: false,
                enableMainThreadChecker: false,
                enableThreadPerformanceChecker: false,
                environmentVariables: [],
                launchTarget: nil,
                runBuildPostActionsOnFailure: false,
                storeKitConfiguration: nil,
                xcodeConfiguration: nil
            ),
            profile: .init(
                buildTargets: [],
                commandLineArguments: [],
                customWorkingDirectory: nil,
                environmentVariables: [],
                launchTarget: nil,
                useRunArgsAndEnv: true,
                xcodeConfiguration: nil
            ),
            executionActions: []
        )

        // Act

        let schemeInfo = try createAutomaticSchemeInfoWithDefaults(
            target: test,
            testOptions: .init(
                appLanguage: "en",
                appRegion: "US",
                codeCoverage: false
            )
        )

        // Assert

        XCTAssertNoDifference(schemeInfo, expectedSchemeInfo)
    }

    func test_buildActions() throws {
        // Arrange

        let launchable = Target(
            key: "Launchable",
            productType: .application,
            buildableReference: .init(
                blueprintIdentifier: "BLUEPRINT_IDENTIFIER_Launchable",
                buildableName: "BUILDABLE_NAME_Launchable",
                blueprintName: "BLUEPRINT_NAME_Launchable",
                referencedContainer: "REFERENCED_CONTAINER_Launchable"
            )
        )
        let buildPreActions: [AutogenerationConfig.Action] = [
            .init(
                title: "Build Start",
                scriptText: "echo start\n",
                order: -200
            ),
        ]
        let buildPostActions: [AutogenerationConfig.Action] = [
            .init(
                title: "Build End",
                scriptText: "echo end\n",
                order: 100
            ),
        ]
        let runPreActions: [AutogenerationConfig.Action] = [
            .init(
                title: #"Run Start (DevX & "Logs")"#,
                scriptText: "echo \"<run start & go>\"\n",
                order: -100
            ),
        ]
        let runPostActions: [AutogenerationConfig.Action] = [
            .init(
                title: #"Run End (DevX & "Logs")"#,
                scriptText: "echo \"<run end & done>\"\n",
                order: 200
            ),
        ]
        let testPreActions: [AutogenerationConfig.Action] = [
            .init(
                title: "Test Start",
                scriptText: "echo test-start\n",
                order: -50
            ),
        ]
        let testPostActions: [AutogenerationConfig.Action] = [
            .init(
                title: "Test End",
                scriptText: "echo test-end\n",
                order: 50
            ),
        ]
        let profilePreActions: [AutogenerationConfig.Action] = [
            .init(
                title: "Profile Start",
                scriptText: "echo profile-start\n",
                order: -75
            ),
        ]
        let profilePostActions: [AutogenerationConfig.Action] = [
            .init(
                title: "Profile End",
                scriptText: "echo profile-end\n",
                order: 75
            ),
        ]

        let expectedSchemeInfo = SchemeInfo(
            name: "BLUEPRINT_NAME_Launchable",
            test: .init(
                buildTargets: [],
                commandLineArguments: [],
                enableAddressSanitizer: false,
                enableThreadSanitizer: false,
                enableUBSanitizer: false,
                enableMainThreadChecker: false,
                enableThreadPerformanceChecker: false,
                environmentVariables: [],
                options: nil,
                testTargets: [],
                useRunArgsAndEnv: true,
                xcodeConfiguration: nil
            ),
            run: .init(
                buildTargets: [],
                commandLineArguments: [],
                customWorkingDirectory: nil,
                enableAddressSanitizer: false,
                enableThreadSanitizer: false,
                enableUBSanitizer: false,
                enableMainThreadChecker: false,
                enableThreadPerformanceChecker: false,
                environmentVariables: baseEnvironmentVariables,
                launchTarget: .target(
                    primary: launchable,
                    extensionHost: nil
                ),
                runBuildPostActionsOnFailure: true,
                storeKitConfiguration: nil,
                xcodeConfiguration: nil
            ),
            profile: .init(
                buildTargets: [],
                commandLineArguments: [],
                customWorkingDirectory: nil,
                environmentVariables: [],
                launchTarget: .target(
                    primary: launchable,
                    extensionHost: nil
                ),
                useRunArgsAndEnv: true,
                xcodeConfiguration: nil
            ),
            executionActions: [
                .init(
                    title: "Build Start",
                    scriptText: "echo start\n",
                    action: .build,
                    isPreAction: true,
                    target: launchable,
                    order: -200
                ),
                .init(
                    title: "Build End",
                    scriptText: "echo end\n",
                    action: .build,
                    isPreAction: false,
                    target: launchable,
                    order: 100
                ),
                .init(
                    title: #"Run Start (DevX & "Logs")"#,
                    scriptText: "echo \"<run start & go>\"\n",
                    action: .run,
                    isPreAction: true,
                    target: launchable,
                    order: -100
                ),
                .init(
                    title: #"Run End (DevX & "Logs")"#,
                    scriptText: "echo \"<run end & done>\"\n",
                    action: .run,
                    isPreAction: false,
                    target: launchable,
                    order: 200
                ),
                .init(
                    title: "Test Start",
                    scriptText: "echo test-start\n",
                    action: .test,
                    isPreAction: true,
                    target: launchable,
                    order: -50
                ),
                .init(
                    title: "Test End",
                    scriptText: "echo test-end\n",
                    action: .test,
                    isPreAction: false,
                    target: launchable,
                    order: 50
                ),
                .init(
                    title: "Profile Start",
                    scriptText: "echo profile-start\n",
                    action: .profile,
                    isPreAction: true,
                    target: launchable,
                    order: -75
                ),
                .init(
                    title: "Profile End",
                    scriptText: "echo profile-end\n",
                    action: .profile,
                    isPreAction: false,
                    target: launchable,
                    order: 75
                ),
            ]
        )

        // Act

        let schemeInfo = try createAutomaticSchemeInfoWithDefaults(
            buildPostActions: buildPostActions,
            buildPreActions: buildPreActions,
            buildRunPostActionsOnFailure: true,
            profilePostActions: profilePostActions,
            profilePreActions: profilePreActions,
            runPostActions: runPostActions,
            runPreActions: runPreActions,
            target: launchable,
            testPostActions: testPostActions,
            testPreActions: testPreActions
        )

        // Assert

        XCTAssertNoDifference(schemeInfo, expectedSchemeInfo)
    }
}

private let baseEnvironmentVariables: [EnvironmentVariable] = [
    .init(key: "BUILD_WORKING_DIRECTORY", value: "$(BUILT_PRODUCTS_DIR)"),
    .init(
        key: "BUILD_WORKSPACE_DIRECTORY",
        value: "$(BUILD_WORKSPACE_DIRECTORY)"
    ),
]

private func createAutomaticSchemeInfoWithDefaults(
    buildPostActions: [AutogenerationConfig.Action] = [],
    buildPreActions: [AutogenerationConfig.Action] = [],
    buildRunPostActionsOnFailure: Bool = false,
    profilePostActions: [AutogenerationConfig.Action] = [],
    profilePreActions: [AutogenerationConfig.Action] = [],
    commandLineArguments: [CommandLineArgument] = [],
    customSchemeNames: Set<String> = [],
    environmentVariables: [EnvironmentVariable] = [],
    extensionHost: Target? = nil,
    runPostActions: [AutogenerationConfig.Action] = [],
    runPreActions: [AutogenerationConfig.Action] = [],
    target: Target,
    testPostActions: [AutogenerationConfig.Action] = [],
    testPreActions: [AutogenerationConfig.Action] = [],
    testOptions: SchemeInfo.Test.Options? = nil
) throws -> SchemeInfo? {
    return try Generator.CreateAutomaticSchemeInfo.defaultCallable(
        buildPostActions: buildPostActions,
        buildPreActions: buildPreActions,
        buildRunPostActionsOnFailure: buildRunPostActionsOnFailure,
        profilePostActions: profilePostActions,
        profilePreActions: profilePreActions,
        commandLineArguments: commandLineArguments,
        customSchemeNames: customSchemeNames,
        environmentVariables: environmentVariables,
        extensionHost: extensionHost,
        runPostActions: runPostActions,
        runPreActions: runPreActions,
        target: target,
        testPostActions: testPostActions,
        testPreActions: testPreActions,
        testOptions: testOptions
    )
}

extension Target.Key: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: TargetID...) {
        self.init(elements.sorted())
    }
}

extension Target.Key: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init([TargetID(value)])
    }
}
