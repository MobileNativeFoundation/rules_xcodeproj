import XCTest

@testable import generator

extension CreateCustomXCSchemesTests {
    func test_createCustomXCSchemes_noCustomSchemes() throws {
        XCTFail("IMPLEMENT ME!")
    }

    func test_createCustomXCSchemes_withCustomSchemes() throws {
        XCTFail("IMPLEMENT ME!")
    }
}

class CreateCustomXCSchemesTests: XCTestCase {
    let filePathResolver = FilePathResolver(
        internalDirectoryName: "rules_xcodeproj",
        workspaceOutputPath: "examples/foo/Foo.xcodeproj"
    )

    lazy var targetResolver = Fixtures.targetResolver(
        referencedContainer: filePathResolver.containerReference
    )

    lazy var schemeA = XcodeScheme(
        name: "Scheme A",
        launchAction: .init(target: targetResolver.targets["A 2"]!.label)
    )

    lazy var schemeB = XcodeScheme(
        name: "Scheme B",
        launchAction: .init(target: targetResolver.targets["A 2"]!.label)
    )
}
