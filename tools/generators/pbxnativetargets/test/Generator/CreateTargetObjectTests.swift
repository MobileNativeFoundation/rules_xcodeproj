import CustomDump
import XCTest

@testable import pbxnativetargets
@testable import PBXProj

class CreateTargetObjectTests: XCTestCase {
    func test_noDependencies() {
        // Arrange

        let identifier = Identifiers.Targets.Identifier(
            pbxProjEscapedName: "a",
            subIdentifier: .init(shard: "A_SHARD", hash: "A_HASH"),
            full: "A_ID /* a */",
            withoutComment: "A_ID"
        )
        let productType = PBXProductType.commandLineTool
        let productName = "Jolly Ranchers"
        let productSubIdentifier = Identifiers.BuildFiles.SubIdentifier(
            shard: "B_SHARD",
            type: .product,
            path: "product.basename",
            hash: "B_HASH"
        )
        let dependencySubIdentifiers: [Identifiers.Targets.SubIdentifier] = []
        let buildConfigurationListIdentifier = "BCL_ID"
        let buildPhaseIdentifiers = [
            "BPZ",
            "BP2",
            "BPA",
        ]

        // The tabs for indenting are intentional
        let expectedObject = Object(
            identifier: "A_ID /* a */",
            content: #"""
{
			isa = PBXNativeTarget;
			buildConfigurationList = BCL_ID;
			buildPhases = (
				BPZ,
				BP2,
				BPA,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = a;
			productName = "Jolly Ranchers";
			productReference = B_SHARD00B_HASH0000000000FF /* product.basename */;
			productType = "com.apple.product-type.tool";
		}
"""#
        )

        // Act

        let object = Generator.CreateTargetObject.defaultCallable(
            identifier: identifier,
            productType: productType,
            productName: productName,
            productSubIdentifier: productSubIdentifier,
            dependencySubIdentifiers: dependencySubIdentifiers,
            buildConfigurationListIdentifier: buildConfigurationListIdentifier,
            buildPhaseIdentifiers: buildPhaseIdentifiers
        )

        // Assert

        XCTAssertNoDifference(object, expectedObject)
    }

    func test_dependencies() {
        // Arrange

        let identifier = Identifiers.Targets.Identifier(
            pbxProjEscapedName: "a (macOS)".pbxProjEscaped,
            subIdentifier: .init(shard: "A_SHARD", hash: "A_HASH"),
            full: "A_ID /* a */",
            withoutComment: "A_ID"
        )
        let productType = PBXProductType.commandLineTool
        let productName = "A"
        let productSubIdentifier = Identifiers.BuildFiles.SubIdentifier(
            shard: "B_SHARD",
            type: .product,
            path: "product.basename",
            hash: "B_HASH"
        )
        let dependencySubIdentifiers: [Identifiers.Targets.SubIdentifier] = [
            .init(shard: "DEP_C_SHARD", hash: "DEP_C_HASH"),
            .init(shard: "DEP_A_SHARD", hash: "DEP_A_HASH"),
            .init(shard: "DEP_B_SHARD", hash: "DEP_B_HASH"),
        ]
        let buildConfigurationListIdentifier = "BCL_ID"
        let buildPhaseIdentifiers = [
            "BPZ",
            "BP2",
            "BPA",
        ]

        // The tabs for indenting are intentional
        let expectedObject = Object(
            identifier: "A_ID /* a */",
            content: #"""
{
			isa = PBXNativeTarget;
			buildConfigurationList = BCL_ID;
			buildPhases = (
				BPZ,
				BP2,
				BPA,
			);
			buildRules = (
			);
			dependencies = (
				A_SHARD02A_HASHDEP_C_SHARD00DEP_C_HASH /* PBXTargetDependency */,
				A_SHARD02A_HASHDEP_A_SHARD00DEP_A_HASH /* PBXTargetDependency */,
				A_SHARD02A_HASHDEP_B_SHARD00DEP_B_HASH /* PBXTargetDependency */,
			);
			name = "a (macOS)";
			productName = A;
			productReference = B_SHARD00B_HASH0000000000FF /* product.basename */;
			productType = "com.apple.product-type.tool";
		}
"""#
        )

        // Act

        let object = Generator.CreateTargetObject.defaultCallable(
            identifier: identifier,
            productType: productType,
            productName: productName,
            productSubIdentifier: productSubIdentifier,
            dependencySubIdentifiers: dependencySubIdentifiers,
            buildConfigurationListIdentifier: buildConfigurationListIdentifier,
            buildPhaseIdentifiers: buildPhaseIdentifiers
        )

        // Assert

        XCTAssertNoDifference(object, expectedObject)
    }
}
