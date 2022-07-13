import XCTest

@testable import generator

extension DictionaryExtensionsTests {
    func test_firstTargetID_aStartTargetMatches() throws {
        let actual = targets.firstTargetID(under: [aTargetID, bTargetID]) { target in
            target.label == barLabel
        }
        XCTAssertEqual(bTargetID, actual)
    }

    func test_firstTargetID_searchMultipleLevels() throws {
        let actual = targets.firstTargetID(under: [bTargetID]) { target in
            target.label == helloLabel
        }
        XCTAssertEqual(eTargetID, actual)
    }

    func test_firstTargetID_breadthFirstSearch() throws {
        // let actual = targets.firstTargetID(under: [aTargetID, bTargetID]) { target in
        //     target.label == helloLabel
        // }
        // XCTAssertEqual(eTargetID, actual)
        XCTFail("IMPLEMENT ME!")
    }

    func test_firstTargetID_doesNotExist() throws {
        XCTFail("IMPLEMENT ME!")
    }
}

class DictionaryExtensionsTests: XCTestCase {
    //  A    B
    //  |    |
    //  C    D
    //       |
    //       E
    // Targets C and E have the same label, but different configurations

    let fooLabel = "//:foo"
    let barLabel = "//:bar"
    let helloLabel = "//:hello"
    let goodbyeLabel = "//:goodbye"

    let chickenConfiguration = "chicken"
    let beefConfiguration = "beef"

    lazy var aTargetID: TargetID = .init("\(fooLabel) \(chickenConfiguration)")
    lazy var aTarget = Target.mock(
        label: fooLabel,
        configuration: chickenConfiguration,
        product: .init(
            type: .staticLibrary,
            name: "a",
            path: .generated("z/A.a")
        ),
        dependencies: [cTargetID]
    )

    lazy var bTargetID: TargetID = .init("\(barLabel) \(beefConfiguration)")
    lazy var bTarget = Target.mock(
        label: barLabel,
        configuration: beefConfiguration,
        product: .init(
            type: .staticLibrary,
            name: "a",
            path: .generated("z/A.a")
        ),
        dependencies: [dTargetID]
    )

    lazy var cTargetID: TargetID = .init("\(helloLabel) \(chickenConfiguration)")
    lazy var cTarget = Target.mock(
        label: helloLabel,
        configuration: chickenConfiguration,
        product: .init(
            type: .staticLibrary,
            name: "a",
            path: .generated("z/A.a")
        )
    )

    lazy var dTargetID: TargetID = .init("\(goodbyeLabel) \(beefConfiguration)")
    lazy var dTarget = Target.mock(
        label: goodbyeLabel,
        configuration: beefConfiguration,
        product: .init(
            type: .staticLibrary,
            name: "a",
            path: .generated("z/A.a")
        ),
        dependencies: [eTargetID]
    )

    lazy var eTargetID: TargetID = .init("\(helloLabel) \(beefConfiguration)")
    lazy var eTarget = Target.mock(
        label: helloLabel,
        configuration: beefConfiguration,
        product: .init(
            type: .staticLibrary,
            name: "a",
            path: .generated("z/A.a")
        )
    )

    lazy var targets: [TargetID: Target] = [
        aTargetID: aTarget,
        bTargetID: bTarget,
        cTargetID: cTarget,
        dTargetID: dTarget,
        eTargetID: eTarget,
    ]
}
