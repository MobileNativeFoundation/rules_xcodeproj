import CustomDump
import PBXProj
import XCTest

@testable import pbxproj_prefix

class BazelDependenciesBuildSettingsTests: XCTestCase {
    func test() {
        // Arrange

        let platforms: [Platform] = [
            .watchOSDevice,
            .iOSSimulator,
            .watchOSDevice,
            .macOS,
        ]
        let targetIdsFile = "bazel-out/target_ids_file"

        // The tabs for indenting are intentional
        let expectedBuildSettings = #"""
{
				BAZEL_PACKAGE_BIN_DIR = rules_xcodeproj;
				CALCULATE_OUTPUT_GROUPS_SCRIPT = "$(BAZEL_INTEGRATION_DIR)/calculate_output_groups.py";
				CC = "";
				CXX = "";
				INDEXING_SUPPORTED_PLATFORMS__ = "$(INDEXING_SUPPORTED_PLATFORMS__NO)";
				INDEXING_SUPPORTED_PLATFORMS__NO = "macosx iphonesimulator watchos";
				INDEXING_SUPPORTED_PLATFORMS__YES = macosx;
				INDEX_DISABLE_SCRIPT_EXECUTION = YES;
				LD = "";
				LDPLUSPLUS = "";
				LIBTOOL = libtool;
				SUPPORTED_PLATFORMS = "$(INDEXING_SUPPORTED_PLATFORMS__$(INDEX_ENABLE_BUILD_ARENA))";
				SUPPORTS_MACCATALYST = YES;
				SWIFT_EXEC = swiftc;
				TARGET_IDS_FILE = "$(BAZEL_OUT)/target_ids_file";
				TARGET_NAME = BazelDependencies;
			}
"""#

        // Act

        let buildSettings = Generator.bazelDependenciesBuildSettings(
            platforms: platforms,
            targetIdsFile: targetIdsFile
        )

        // Assert

        XCTAssertNoDifference(buildSettings, expectedBuildSettings)
    }
}
