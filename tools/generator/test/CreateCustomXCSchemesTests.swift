import XCTest
import XcodeProj

@testable import generator

extension CreateCustomXCSchemesTests {
    func test_createCustomXCSchemes_noCustomSchemes() throws {
        let actual = try Generator.createCustomXCSchemes(
            schemes: [],
            buildMode: .bazel,
            targetResolver: targetResolver,
            runnerLabel: runnerLabel,
            testEnvs: [:]
        )
        XCTAssertEqual(actual, [])
    }

    func test_createCustomXCSchemes_withCustomSchemes() throws {
        let actual = try Generator.createCustomXCSchemes(
            schemes: [schemeA, schemeB],
            buildMode: .bazel,
            targetResolver: targetResolver,
            runnerLabel: runnerLabel,
            testEnvs: [:]
        )
        XCTAssertEqual(actual.count, 2)
        XCTAssertEqual(actual.map(\.name), [schemeA.name, schemeB.name])
    }

    func test_createCustomXCSchemes_withCustomSchemes_testEnvOverrides() throws {
        let actual = try Generator.createCustomXCSchemes(
            schemes: [schemeC],
            buildMode: .bazel,
            targetResolver: targetResolver,
            runnerLabel: runnerLabel,
            testEnvs: ["B 2": [
                "B_2_SCHEME_VAR": "INITIAL",
                "OTHER_ENV_VAR": "INITIAL"
            ]]
        )
        XCTAssertEqual(actual.count, 1)
        XCTAssertEqual(actual.map(\.name), [schemeC.name])
        let environmentVariables: [XCScheme.EnvironmentVariable] = try XCTUnwrap(actual.first?.testAction?.environmentVariables)
        let testActionEnvironmentVariables: [String: String] = environmentVariables.reduce(into: [String: String]()) { partialResult, element in
            partialResult[element.variable] = element.value
        }
        XCTAssertEqual(testActionEnvironmentVariables["B_2_SCHEME_VAR"], "OVERRIDE")
        XCTAssertEqual(testActionEnvironmentVariables["OTHER_ENV_VAR"], "INITIAL")
    }
}

class CreateCustomXCSchemesTests: XCTestCase {
    let runnerLabel = BazelLabel("@//foo")

    let directories = FilePathResolver.Directories(
        workspace: "/Users/TimApple/app",
        projectRoot: "/Users/TimApple",
        external: "/private/var/tmp/_bazel_rx/H/execroot/R1/external",
        bazelOut: "/private/var/tmp/_bazel_rx/H/execroot/R1/bazel-out",
        internalDirectoryName: "rules_xcodeproj",
        bazelIntegration: "bazel",
        workspaceOutput: "examples/foo/Foo.xcodeproj"
    )
    lazy var filePathResolver = FilePathResolver(
        directories: directories
    )

    lazy var targetResolver = Fixtures.targetResolver(
        directories: directories,
        referencedContainer: filePathResolver.containerReference
    )

    lazy var schemeA = try! XcodeScheme(
        name: "Scheme A",
        launchAction: .init(target: targetResolver.targets["A 2"]!.label)
    )

    lazy var schemeB = try! XcodeScheme(
        name: "Scheme B",
        launchAction: .init(target: targetResolver.targets["A 2"]!.label)
    )

    lazy var schemeC = try! XcodeScheme(
        name: "Scheme C",
        testAction: .init(
            targets: [targetResolver.targets["B 2"]!.label],
            env: ["B_2_SCHEME_VAR": "OVERRIDE"]
        )
    )
}
