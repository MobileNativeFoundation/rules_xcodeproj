import XCTest

@testable import generator

// MARK: `filterDependencyTree` Tests

extension TargetIDTargetDictionaryExtensionsTests {
    func test_filterDependencyTree_includeAllDeps() throws {
        let actual = targets.filterDependencyTree(startingWith: [bTargetID]) { _ in true }
        let expected = [
            bTargetID: bTarget,
            dTargetID: dTarget,
            eTargetID: eTarget,
        ]
        XCTAssertEqual(expected, actual)
    }

    func test_filterDependencyTree_filterOutMiddleOfTree() throws {
        // Filter out a node in the middle of the tree. The result should not include the excluded
        // node or its children.
        let actual = targets.filterDependencyTree(startingWith: [bTargetID]) { target in
            // The dTarget has goodbyeLabel
            target.label != goodbyeLabel
        }
        let expected = [
            bTargetID: bTarget,
        ]
        XCTAssertEqual(expected, actual)
    }

    func test_filterDependencyTree_filterOutBottomOfTree() throws {
        // Filter out a leaf node. The result should not include everything except the leaf node.
        let actual = targets.filterDependencyTree(startingWith: [bTargetID]) { target in
            // The eTarget has helloLabel
            target.label != helloLabel
        }
        let expected = [
            bTargetID: bTarget,
            dTargetID: dTarget,
        ]
        XCTAssertEqual(expected, actual)
    }

    func test_filterDependencyTree_filterOutTopOfTree() throws {
        // Filter out the root nodes. The result should not include anything
        let actual = targets.filterDependencyTree(startingWith: [bTargetID]) { target in
            // The bTarget has barLabel
            target.label != barLabel
        }
        let expected = [TargetID: Target]()
        XCTAssertEqual(expected, actual)
    }

    func test_filterDependencyTree_withMultipleRoots() throws {
        let actual = targets.filterDependencyTree(startingWith: [aTargetID, bTargetID]) { target in
            // The cTarget and eTarget has helloLabel
            target.label != helloLabel
        }
        let expected = [
            aTargetID: aTarget,
            bTargetID: bTarget,
            dTargetID: dTarget,
        ]
        XCTAssertEqual(expected, actual)
    }
}

// MARK: `firstTargetID` Tests

extension TargetIDTargetDictionaryExtensionsTests {
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
        let actual = targets.firstTargetID(under: [aTargetID, bTargetID]) { target in
            target.label == helloLabel
        }
        XCTAssertEqual(cTargetID, actual)
    }

    func test_firstTargetID_doesNotExist() throws {
        let actual = targets.firstTargetID(under: [aTargetID, bTargetID]) { target in
            target.label == BazelLabel("//:doesNotExist")
        }
        XCTAssertNil(actual)
    }
}

// MARK: Test Data

class TargetIDTargetDictionaryExtensionsTests: XCTestCase {
    //  A    B
    //  |    |
    //  C    D
    //       |
    //       E
    // Targets C and E have the same label, but different configurations

    let fooLabel: BazelLabel = "@//:foo"
    let barLabel: BazelLabel = "@//:bar"
    let helloLabel: BazelLabel = "@//:hello"
    let goodbyeLabel: BazelLabel = "@//:goodbye"

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
