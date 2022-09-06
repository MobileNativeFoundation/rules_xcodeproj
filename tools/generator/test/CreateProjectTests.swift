import CustomDump
import PathKit
import XCTest

@testable import generator
@testable import XcodeProj

final class CreateProjectTests: XCTestCase {
    func test_xcode() throws {
        // Arrange

        let project = Fixtures.project
        let projectRootDirectory: Path = "~/Developer/project"

        let filePathResolver = FilePathResolver(
            workspaceDirectory: "/Users/TimApple/app",
            externalDirectory: "/some/bazel13/external",
            bazelOutDirectory: "/some/bazel13/bazel-out",
            internalDirectoryName: "r_xcp",
            workspaceOutputPath: "X.xcodeproj"
        )

        let expectedPBXProj = PBXProj()

        let expectedMainGroup = PBXGroup(sourceTree: .group)
        expectedPBXProj.add(object: expectedMainGroup)

        let debugConfiguration = XCBuildConfiguration(
            name: "Debug",
            buildSettings: project.buildSettings.asDictionary.merging([
                "BAZEL_EXEC_ROOT": filePathResolver.externalDirectory
                    .parent().normalize().string,
                "BAZEL_EXTERNAL": filePathResolver.externalDirectory.string,
                "BAZEL_LLDB_INIT": "$(OBJROOT)/bazel.lldbinit",
                "BAZEL_OUT": filePathResolver.bazelOutDirectory.string,
                "BAZEL_WORKSPACE_ROOT": "$(SRCROOT)",
                "BAZEL_INTEGRATION_DIR": "$(INTERNAL_DIR)/bazel",
                "BUILD_WORKSPACE_DIRECTORY": "$(SRCROOT)",
                "BUILT_PRODUCTS_DIR": """
$(INDEXING_BUILT_PRODUCTS_DIR__$(INDEX_ENABLE_BUILD_ARENA))
""",
                "CONFIGURATION_BUILD_DIR": """
$(BUILD_DIR)/$(BAZEL_PACKAGE_BIN_DIR)
""",
                "DEPLOYMENT_LOCATION": """
$(INDEXING_DEPLOYMENT_LOCATION__$(INDEX_ENABLE_BUILD_ARENA)),
""",
                "DSTROOT": "$(PROJECT_TEMP_DIR)",
                "LINKS_DIR": "$(INTERNAL_DIR)/links",
                "INDEX_FORCE_SCRIPT_EXECUTION": true,
                "INDEXING_BUILT_PRODUCTS_DIR__": """
$(INDEXING_BUILT_PRODUCTS_DIR__NO)
""",
                "INDEXING_BUILT_PRODUCTS_DIR__NO": "$(BUILD_DIR)",
                "INDEXING_BUILT_PRODUCTS_DIR__YES": """
$(CONFIGURATION_BUILD_DIR)
""",
                "INDEXING_DEPLOYMENT_LOCATION__": """
$(INDEXING_DEPLOYMENT_LOCATION__NO)
""",
                "INDEXING_DEPLOYMENT_LOCATION__NO": true,
                "INDEXING_DEPLOYMENT_LOCATION__YES": false,
                "INSTALL_PATH": "$(BAZEL_PACKAGE_BIN_DIR)/$(TARGET_NAME)/bin",
                "INTERNAL_DIR": "$(PROJECT_FILE_PATH)/r_xcp",
                "SCHEME_TARGET_IDS_FILE": """
$(OBJROOT)/scheme_target_ids
""",
                "SUPPORTS_MACCATALYST": false,
                "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
                "TARGET_TEMP_DIR": """
$(PROJECT_TEMP_DIR)/$(BAZEL_PACKAGE_BIN_DIR)/$(COMPILE_TARGET_NAME)
""",
            ]) { $1 }
        )
        expectedPBXProj.add(object: debugConfiguration)
        let expectedBuildConfigurationList = XCConfigurationList(
            buildConfigurations: [debugConfiguration],
            defaultConfigurationName: debugConfiguration.name
        )
        expectedPBXProj.add(object: expectedBuildConfigurationList)

        let attributes: [String: Any] = [
            "BuildIndependentTargetsInParallel": 1,
            "LastSwiftUpdateCheck": 9999,
            "LastUpgradeCheck": 9999,
        ]

        let expectedPBXProject = PBXProject(
            name: "Bazel",
            buildConfigurationList: expectedBuildConfigurationList,
            compatibilityVersion: "Xcode 13.0",
            mainGroup: expectedMainGroup,
            developmentRegion: "en",
            projectDirPath: projectRootDirectory.normalize().string,
            attributes: attributes
        )
        expectedPBXProj.add(object: expectedPBXProject)
        expectedPBXProj.rootObject = expectedPBXProject

        // Act

        let createdPBXProj = Generator.createProject(
            buildMode: .xcode,
            project: project,
            projectRootDirectory: projectRootDirectory,
            filePathResolver: filePathResolver
        )

        try createdPBXProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(createdPBXProj, expectedPBXProj)
    }

    func test_bazel() throws {
        // Arrange

        let project = Fixtures.project
        let projectRootDirectory: Path = "~/Developer/project"

        let filePathResolver = FilePathResolver(
            workspaceDirectory: "/Users/TimApple/app",
            externalDirectory: "/some/bazel16/external",
            bazelOutDirectory: "/some/bazel16/bazel-out",
            internalDirectoryName: "r_xcp",
            workspaceOutputPath: "X.xcodeproj"
        )

        let expectedPBXProj = PBXProj()

        let expectedMainGroup = PBXGroup(sourceTree: .group)
        expectedPBXProj.add(object: expectedMainGroup)

        let debugConfiguration = XCBuildConfiguration(
            name: "Debug",
            buildSettings: project.buildSettings.asDictionary.merging([
                "BAZEL_EXEC_ROOT": filePathResolver.externalDirectory
                    .parent().normalize().string,
                "BAZEL_EXTERNAL": filePathResolver.externalDirectory.string,
                "BAZEL_LLDB_INIT": "$(OBJROOT)/bazel.lldbinit",
                "BAZEL_OUT": filePathResolver.bazelOutDirectory.string,
                "BAZEL_WORKSPACE_ROOT": "$(SRCROOT)",
                "BUILD_WORKSPACE_DIRECTORY": "$(SRCROOT)",
                "BAZEL_INTEGRATION_DIR": "$(INTERNAL_DIR)/bazel",
                "BUILT_PRODUCTS_DIR": """
$(INDEXING_BUILT_PRODUCTS_DIR__$(INDEX_ENABLE_BUILD_ARENA))
""",
                "CC": "$(BAZEL_INTEGRATION_DIR)/cc.sh",
                "CXX": "$(BAZEL_INTEGRATION_DIR)/cc.sh",
                "CODE_SIGNING_ALLOWED": false,
                "CONFIGURATION_BUILD_DIR": """
$(BUILD_DIR)/$(BAZEL_PACKAGE_BIN_DIR)
""",
                "DEPLOYMENT_LOCATION": """
$(INDEXING_DEPLOYMENT_LOCATION__$(INDEX_ENABLE_BUILD_ARENA)),
""",
                "DSTROOT": "$(PROJECT_TEMP_DIR)",
                "LD": "$(BAZEL_INTEGRATION_DIR)/ld.sh",
                "LDPLUSPLUS": "$(BAZEL_INTEGRATION_DIR)/ld.sh",
                "LIBTOOL": "$(BAZEL_INTEGRATION_DIR)/libtool.sh",
                "LINKS_DIR": "$(INTERNAL_DIR)/links",
                "INDEX_FORCE_SCRIPT_EXECUTION": true,
                "INDEXING_BUILT_PRODUCTS_DIR__": """
$(INDEXING_BUILT_PRODUCTS_DIR__NO)
""",
                "INDEXING_BUILT_PRODUCTS_DIR__NO": "$(BUILD_DIR)",
                "INDEXING_BUILT_PRODUCTS_DIR__YES": """
$(CONFIGURATION_BUILD_DIR)
""",
                "INDEXING_DEPLOYMENT_LOCATION__": """
$(INDEXING_DEPLOYMENT_LOCATION__NO)
""",
                "INDEXING_DEPLOYMENT_LOCATION__NO": true,
                "INDEXING_DEPLOYMENT_LOCATION__YES": false,
                "INSTALL_PATH": "$(BAZEL_PACKAGE_BIN_DIR)/$(TARGET_NAME)/bin",
                "INTERNAL_DIR": "$(PROJECT_FILE_PATH)/r_xcp",
                "SCHEME_TARGET_IDS_FILE": """
$(OBJROOT)/scheme_target_ids
""",
                "SUPPORTS_MACCATALYST": false,
                "SWIFT_EXEC": "$(BAZEL_INTEGRATION_DIR)/swiftc.py",
                "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
                "SWIFT_USE_INTEGRATED_DRIVER": false,
                "TARGET_TEMP_DIR": """
$(PROJECT_TEMP_DIR)/$(BAZEL_PACKAGE_BIN_DIR)/$(COMPILE_TARGET_NAME)
""",
            ]) { $1 }
        )
        expectedPBXProj.add(object: debugConfiguration)
        let expectedBuildConfigurationList = XCConfigurationList(
            buildConfigurations: [debugConfiguration],
            defaultConfigurationName: debugConfiguration.name
        )
        expectedPBXProj.add(object: expectedBuildConfigurationList)

        let attributes: [String: Any] = [
            "BuildIndependentTargetsInParallel": 1,
            "LastSwiftUpdateCheck": 9999,
            "LastUpgradeCheck": 9999,
        ]

        let expectedPBXProject = PBXProject(
            name: "Bazel",
            buildConfigurationList: expectedBuildConfigurationList,
            compatibilityVersion: "Xcode 13.0",
            mainGroup: expectedMainGroup,
            developmentRegion: "en",
            projectDirPath: projectRootDirectory.normalize().string,
            attributes: attributes
        )
        expectedPBXProj.add(object: expectedPBXProject)
        expectedPBXProj.rootObject = expectedPBXProject

        // Act

        let createdPBXProj = Generator.createProject(
            buildMode: .bazel,
            project: project,
            projectRootDirectory: projectRootDirectory,
            filePathResolver: filePathResolver
        )

        try createdPBXProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(createdPBXProj, expectedPBXProj)
    }
}
