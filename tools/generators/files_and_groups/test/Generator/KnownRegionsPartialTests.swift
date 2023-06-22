import CustomDump
import Foundation
import PBXProj
import XCTest

@testable import files_and_groups

class KnownRegionsPartialTests: XCTestCase {

    // MARK: - knownRegions

    func test_single_knownRegions() {
        // Arrange

        let developmentRegion = "en"
        let knownRegions: Set<String> = ["en"]
        let useBaseInternationalization = false

        // The tabs for indenting are intentional
        let expectedKnownRegionsPartial = #"""
			knownRegions = (
				en,
			);

"""#

        // Act

        let knownRegionsPartial = Generator.knownRegionsPartial(
			knownRegions: knownRegions,
            developmentRegion: developmentRegion,
            useBaseInternationalization: useBaseInternationalization
        )

        // Assert

        XCTAssertNoDifference(
            knownRegionsPartial,
            expectedKnownRegionsPartial
        )
    }

    func test_multiple_knownRegions() {
        // Arrange

        let developmentRegion = "fr"
        let knownRegions: Set<String> = ["Base", "fr-CA", "en", "en-GB", "fr"]
        let useBaseInternationalization = true

        // The tabs for indenting are intentional
        let expectedKnownRegionsPartial = #"""
			knownRegions = (
				en,
				"en-GB",
				fr,
				"fr-CA",
				Base,
			);

"""#

        // Act

        let knownRegionsPartial = Generator.knownRegionsPartial(
			knownRegions: knownRegions,
            developmentRegion: developmentRegion,
            useBaseInternationalization: useBaseInternationalization
        )

        // Assert

        XCTAssertNoDifference(
            knownRegionsPartial,
            expectedKnownRegionsPartial
        )
    }

    // MARK: - developmentRegion

    func test_developmentRegion() {
        // Arrange

        let developmentRegion = "xyz"
        let knownRegions: Set<String> = []
        let useBaseInternationalization = false

        // The tabs for indenting are intentional
        let expectedKnownRegionsPartial = #"""
			knownRegions = (
				xyz,
			);

"""#

        // Act

        let knownRegionsPartial = Generator.knownRegionsPartial(
            knownRegions: knownRegions,
            developmentRegion: developmentRegion,
            useBaseInternationalization: useBaseInternationalization
        )

        // Assert

        XCTAssertNoDifference(
            knownRegionsPartial,
            expectedKnownRegionsPartial
        )
    }

    // MARK: - useBaseInternationalization

    func test_useBaseInternationalization() {
        // Arrange

        let developmentRegion = "en"
        let knownRegions: Set<String> = ["en"]
        let useBaseInternationalization = true

        // The tabs for indenting are intentional
        let expectedKnownRegionsPartial = #"""
			knownRegions = (
				en,
				Base,
			);

"""#

        // Act

        let knownRegionsPartial = Generator.knownRegionsPartial(
			knownRegions: knownRegions,
            developmentRegion: developmentRegion,
            useBaseInternationalization: useBaseInternationalization
        )

        // Assert

        XCTAssertNoDifference(
            knownRegionsPartial,
            expectedKnownRegionsPartial
        )
    }

    func test_noUseBaseInternationalization() {
        // Arrange

        let developmentRegion = "en"
        let knownRegions: Set<String> = ["en"]
        let useBaseInternationalization = false

        // The tabs for indenting are intentional
        let expectedKnownRegionsPartial = #"""
			knownRegions = (
				en,
			);

"""#

        // Act

        let knownRegionsPartial = Generator.knownRegionsPartial(
			knownRegions: knownRegions,
            developmentRegion: developmentRegion,
            useBaseInternationalization: useBaseInternationalization
        )

        // Assert

        XCTAssertNoDifference(
            knownRegionsPartial,
            expectedKnownRegionsPartial
        )
    }
}
