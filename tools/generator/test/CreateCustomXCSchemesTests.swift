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
            envs: [:]
        )
        XCTAssertEqual(actual, [])
    }

    func test_createCustomXCSchemes_withCustomSchemes() throws {
        let actual = try Generator.createCustomXCSchemes(
            schemes: [schemeA, schemeB],
            buildMode: .bazel,
            targetResolver: targetResolver,
            runnerLabel: runnerLabel,
            envs: [:]
        )
        XCTAssertEqual(actual.count, 2)
        XCTAssertEqual(actual.map(\.name), [schemeA.name, schemeB.name])
    }

    func test_createCustomXCSchemes_withCustomSchemes_testEnvOverrides() throws {
        XCTAssertThrowsError(try Generator.createCustomXCSchemes(
            schemes: [schemeC],
            buildMode: .bazel,
            targetResolver: targetResolver,
            runnerLabel: runnerLabel,
            envs: ["B 2": [
                "B_2_SCHEME_VAR": "INITIAL",
                "OTHER_ENV_VAR": "INITIAL"
            ]]
        )) { error in
            if case let UsageError(errorMessage) = $0 {
                XCTAssertEqual(errorMessage, "ERROR Found environment variables with conflicting values ('INITIAL' and 'OVERRIDE')")
            } else {
                XCTFail("Invalid error")
            }
        }
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
