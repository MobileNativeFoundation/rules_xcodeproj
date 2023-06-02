import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class RootElementsTests: XCTestCase {
    func test_empty() {
        // Arrange

        let pathTree = PathTreeNode(name: "")
        let workspace = "/Users/TimApple/Star Board"

        let expectedRootElements: [Element] = []
        let expectedPathsToIdentifiers: [BazelPath: String] = [:]
        let expectedKnownRegions: Set<String> = []
        let expectedResolvedRepositories: [ResolvedRepository] = [
            .init(sourcePath: ".", mappedPath: workspace)
        ]

        // Act

        let result = ElementCreator.rootElements(
            pathTree: pathTree,
            workspace: workspace,
            createAttributes: ElementCreator.Stubs.attributes
        )

        // Assert

        XCTAssertNoDifference(result.rootElements, expectedRootElements)
        XCTAssertNoDifference(
            result.pathsToIdentifiers,
            expectedPathsToIdentifiers
        )
        XCTAssertNoDifference(result.knownRegions, expectedKnownRegions)
        XCTAssertNoDifference(
            result.resolvedRepositories,
            expectedResolvedRepositories
        )
    }
    
    // MARK: - elements

    func test_elements() {
        // Arrange

        let pathTree = PathTreeNode(name: "")
        let workspace = "/Users/TimApple/Star Board"

        let expectedRootElements: [Element] = []

        // Act

        let result = ElementCreator.rootElements(
            pathTree: pathTree,
            workspace: workspace,
            createAttributes: ElementCreator.Stubs.attributes
        )

        // Assert

        XCTAssertNoDifference(result.rootElements, expectedRootElements)
    }

    // MARK: - pathsToIdentifiers

    func test_pathsToIdentifiers() {
        // Arrange

        let pathTree = PathTreeNode(name: "")
        let workspace = "/Users/TimApple/Star Board"

        let expectedPathsToIdentifiers: [BazelPath: String] = [:]

        // Act

        let result = ElementCreator.rootElements(
            pathTree: pathTree,
            workspace: workspace,
            createAttributes: ElementCreator.Stubs.attributes
        )

        // Assert

        XCTAssertNoDifference(
            result.pathsToIdentifiers,
            expectedPathsToIdentifiers
        )
    }

    // MARK: - knownRegions

    func test_knownRegions() {
        // Arrange

        let pathTree = PathTreeNode(name: "")
        let workspace = "/Users/TimApple/Star Board"

        let expectedKnownRegions: Set<String> = []

        // Act

        let result = ElementCreator.rootElements(
            pathTree: pathTree,
            workspace: workspace,
            createAttributes: ElementCreator.Stubs.attributes
        )

        // Assert

        XCTAssertNoDifference(result.knownRegions, expectedKnownRegions)
    }

    // MARK: - resolvedRepositories

    func test_resolvedRepositories() {
        // Arrange

        let pathTree = PathTreeNode(name: "")
        let workspace = "/Users/TimApple/Star Board"

        let expectedResolvedRepositories: [ResolvedRepository] = [
            .init(sourcePath: ".", mappedPath: workspace)
        ]

        // Act

        let result = ElementCreator.rootElements(
            pathTree: pathTree,
            workspace: workspace,
            createAttributes: ElementCreator.Stubs.attributes
        )

        // Assert

        XCTAssertNoDifference(
            result.resolvedRepositories,
            expectedResolvedRepositories
        )
    }
}
