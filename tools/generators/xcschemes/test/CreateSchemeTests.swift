import CustomDump
import PBXProj
import XCScheme
import XCTest

@testable import xcschemes

final class CreateSchemeTests: XCTestCase {
    func test_testAction_usesFirstTestableForCustomLLDBInitFile() throws {
        // Arrange

        let buildOnlyTarget = Target.mock(
            key: "BuildOnly",
            productType: .staticLibrary,
            buildableReference: buildableReference(
                name: "BuildOnly",
                referencedContainer: "container:/tmp/BuildOnly.xcodeproj"
            )
        )
        let testableTarget = Target.mock(
            key: "Tests",
            productType: .unitTestBundle,
            buildableReference: buildableReference(
                name: "Tests",
                referencedContainer: "container:/tmp/Tests.xcodeproj"
            )
        )
        let expectedTestAction = createExpectedTestAction(
            buildableReference: testableTarget.buildableReference
        )

        // Act

        let scheme = try createSchemeWithDefaults(
            schemeInfo: .mock(
                name: "Scheme",
                test: .mock(
                    buildTargets: [buildOnlyTarget],
                    testTargets: [.init(target: testableTarget, isEnabled: true)]
                )
            )
        )

        let testAction = try XCTUnwrap(extractTestAction(from: scheme))

        // Assert

        XCTAssertNoDifference(testAction, expectedTestAction)
    }

    func test_profileAction_usesProfileTargetForCustomLLDBInitFile() throws {
        // Arrange

        let runTarget = Target.mock(
            key: "Run",
            productType: .application,
            buildableReference: buildableReference(
                name: "Run",
                referencedContainer: "container:/tmp/Run.xcodeproj"
            )
        )
        let profileTarget = Target.mock(
            key: "Profile",
            productType: .application,
            buildableReference: buildableReference(
                name: "Profile",
                referencedContainer: "container:/tmp/Profile.xcodeproj"
            )
        )
        let expectedProfileAction = createExpectedProfileAction(
            buildableReference: profileTarget.buildableReference
        )

        // Act

        let scheme = try createSchemeWithDefaults(
            schemeInfo: .mock(
                name: "Scheme",
                run: .mock(
                    launchTarget: .target(
                        primary: runTarget,
                        extensionHost: nil
                    )
                ),
                profile: .mock(
                    launchTarget: .target(
                        primary: profileTarget,
                        extensionHost: nil
                    )
                )
            )
        )

        let profileAction = try XCTUnwrap(extractProfileAction(from: scheme))

        // Assert

        XCTAssertNoDifference(profileAction, expectedProfileAction)
    }

    func test_launchAction_pathRunnableDoesNotUseBuildEntryLLDBInitFile() throws {
        // Arrange

        let buildOnlyTarget = Target.mock(
            key: "BuildOnly",
            productType: .application,
            buildableReference: buildableReference(
                name: "BuildOnly",
                referencedContainer: "container:/tmp/BuildOnly.xcodeproj"
            )
        )
        let expectedLaunchAction = CreateLaunchAction.defaultCallable(
            buildConfiguration: "Debug",
            commandLineArguments: [],
            customLLDBInitFile: nil,
            customWorkingDirectory: nil,
            enableAddressSanitizer: false,
            enableThreadSanitizer: false,
            enableUBSanitizer: false,
            enableMainThreadChecker: false,
            enableThreadPerformanceChecker: false,
            environmentVariables: [],
            postActions: [],
            preActions: [],
            runnable: .path(path: "/tmp/tool"),
            storeKitConfiguration: nil
        )

        // Act

        let scheme = try createSchemeWithDefaults(
            schemeInfo: .mock(
                name: "Scheme",
                run: .mock(
                    buildTargets: [buildOnlyTarget],
                    launchTarget: .path("/tmp/tool")
                )
            )
        )

        let launchAction = try XCTUnwrap(extractLaunchAction(from: scheme))

        // Assert

        XCTAssertNoDifference(launchAction, expectedLaunchAction)
    }
}

private func createSchemeWithDefaults(
    schemeInfo: SchemeInfo
) throws -> String {
    try Generator.CreateScheme.defaultCallable(
        defaultXcodeConfiguration: "Debug",
        extensionPointIdentifiers: [:],
        schemeInfo: schemeInfo,
        createAnalyzeAction: CreateAnalyzeAction(),
        createArchiveAction: CreateArchiveAction(),
        createBuildAction: CreateBuildAction(),
        createLaunchAction: CreateLaunchAction(),
        createProfileAction: CreateProfileAction(),
        createSchemeXML: XCScheme.CreateScheme(),
        createTestAction: CreateTestAction()
    ).scheme
}

private func extractTestAction(from scheme: String) -> String? {
    extractElement(named: "TestAction", from: scheme)
}

private func extractProfileAction(from scheme: String) -> String? {
    extractElement(named: "ProfileAction", from: scheme)
}

private func extractLaunchAction(from scheme: String) -> String? {
    extractElement(named: "LaunchAction", from: scheme)
}

private func extractElement(named name: String, from scheme: String) -> String? {
    guard
        let start = scheme.range(of: "   <\(name)"),
        let end = scheme.range(of: "</\(name)>")
    else {
        return nil
    }

    return String(scheme[start.lowerBound ..< end.upperBound])
}

private func buildableReference(
    name: String,
    referencedContainer: String
) -> BuildableReference {
    return .init(
        blueprintIdentifier: "\(name)_blueprintIdentifier",
        buildableName: "\(name)_buildableName",
        blueprintName: name,
        referencedContainer: referencedContainer
    )
}

private func createExpectedProfileAction(
    buildableReference: BuildableReference
) -> String {
    return CreateProfileAction.defaultCallable(
        buildConfiguration: "Debug",
        commandLineArguments: [],
        customLLDBInitFile: "/tmp/Profile.xcodeproj/rules_xcodeproj/bazel.lldbinit",
        customWorkingDirectory: nil,
        environmentVariables: [],
        postActions: [],
        preActions: [updateLldbInitAndCopyDSYMsAction(
            buildableReference: buildableReference
        )],
        useLaunchSchemeArgsEnv: true,
        runnable: .plain(buildableReference: buildableReference)
    )
}

private func createExpectedTestAction(
    buildableReference: BuildableReference
) -> String {
    return CreateTestAction.defaultCallable(
        appLanguage: nil,
        appRegion: nil,
        codeCoverage: false,
        buildConfiguration: "Debug",
        commandLineArguments: [],
        customLLDBInitFile: "/tmp/Tests.xcodeproj/rules_xcodeproj/bazel.lldbinit",
        enableAddressSanitizer: false,
        enableThreadSanitizer: false,
        enableUBSanitizer: false,
        enableMainThreadChecker: false,
        enableThreadPerformanceChecker: false,
        environmentVariables: [],
        expandVariablesBasedOn: buildableReference,
        postActions: [],
        preActions: [updateLldbInitAndCopyDSYMsAction(
            buildableReference: buildableReference
        )],
        testables: [
            .init(
                buildableReference: buildableReference,
                isSkipped: false
            ),
        ],
        useLaunchSchemeArgsEnv: false
    )
}

private func updateLldbInitAndCopyDSYMsAction(
    buildableReference: BuildableReference
) -> ExecutionAction {
    return .init(
        title: "Update .lldbinit and copy dSYMs",
        escapedScriptText: #"""
"$BAZEL_INTEGRATION_DIR/create_lldbinit.sh"
"$BAZEL_INTEGRATION_DIR/copy_dsyms.sh"

"""#.schemeXmlEscaped,
        expandVariablesBasedOn: buildableReference
    )
}
