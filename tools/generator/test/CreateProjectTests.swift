import CustomDump
import PathKit
import XCTest

@testable import generator
@testable import XcodeProj

final class CreateProjectTests: XCTestCase {
    func test_xcode() throws {
        // Arrange

        let project = Fixtures.project
        let projectRootDirectory: Path = "/Users/TimApple"

        let directories = FilePathResolver.Directories(
            workspace: "/Users/TimApple/app",
            projectRoot: projectRootDirectory,
            external: "/some/bazel13/external",
            bazelOut: "/some/bazel13/bazel-out",
            internalDirectoryName: "r_xcp",
            bazelIntegration: "stubs",
            workspaceOutput: "X.xcodeproj"
        )

        let expectedPBXProj = PBXProj()

        let expectedMainGroup = PBXGroup(
            sourceTree: .absolute,
            path: directories.workspace.string
        )
        expectedPBXProj.add(object: expectedMainGroup)

        let debugConfiguration = XCBuildConfiguration(
            name: "Debug",
            buildSettings: project.buildSettings.asDictionary.merging([
                "BAZEL_EXTERNAL": "$(PROJECT_DIR)/external",
                "BAZEL_LLDB_INIT": "$(OBJROOT)/bazel.lldbinit",
                "BAZEL_OUT": "$(PROJECT_DIR)/bazel-out",
                "BAZEL_WORKSPACE_ROOT": "$(SRCROOT)",
                "BAZEL_INTEGRATION_DIR": "$(INTERNAL_DIR)/bazel",
                "BUILD_WORKSPACE_DIRECTORY": "$(SRCROOT)",
                "BUILD_DIR": """
$(SYMROOT)/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)
""",
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
                "ENABLE_DEFAULT_SEARCH_PATHS": "NO",
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
                "_SRCROOT": directories.workspace.string,
                "SRCROOT": "$(_SRCROOT:standardizepath)",
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
            projectDirPath: directories.bazelOut.parent().string,
            attributes: attributes
        )
        expectedPBXProj.add(object: expectedPBXProject)
        expectedPBXProj.rootObject = expectedPBXProject

        // Act

        let createdPBXProj = Generator.createProject(
            buildMode: .xcode,
            project: project,
            directories: directories
        )

        try createdPBXProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(createdPBXProj, expectedPBXProj)
    }

    func test_bazel() throws {
        // Arrange

        let project = Fixtures.project
        let projectRootDirectory: Path = "/Users/TimApple"

        let directories = FilePathResolver.Directories(
            workspace: "/Users/TimApple/app",
            projectRoot: projectRootDirectory,
            external: "/some/bazel16/external",
            bazelOut: "/some/bazel16/bazel-out",
            internalDirectoryName: "r_xcp",
            bazelIntegration: "stubs",
            workspaceOutput: "X.xcodeproj"
        )

        let expectedPBXProj = PBXProj()

        let expectedMainGroup = PBXGroup(
            sourceTree: .absolute,
            path: directories.workspace.string
        )
        expectedPBXProj.add(object: expectedMainGroup)

        let debugConfiguration = XCBuildConfiguration(
            name: "Debug",
            buildSettings: project.buildSettings.asDictionary.merging([
                "BAZEL_EXTERNAL": "$(PROJECT_DIR)/external",
                "BAZEL_LLDB_INIT": "$(OBJROOT)/bazel.lldbinit",
                "BAZEL_OUT": "$(PROJECT_DIR)/bazel-out",
                "BAZEL_WORKSPACE_ROOT": "$(SRCROOT)",
                "BUILD_DIR": """
$(SYMROOT)/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)
""",
                "BUILD_WORKSPACE_DIRECTORY": "$(SRCROOT)",
                "BAZEL_INTEGRATION_DIR": "$(INTERNAL_DIR)/bazel",
                "BUILT_PRODUCTS_DIR": """
$(INDEXING_BUILT_PRODUCTS_DIR__$(INDEX_ENABLE_BUILD_ARENA))
""",
                "CC": "$(BAZEL_INTEGRATION_DIR)/clang.sh",
                "CXX": "$(BAZEL_INTEGRATION_DIR)/clang.sh",
                "CODE_SIGNING_ALLOWED": false,
                "CONFIGURATION_BUILD_DIR": """
$(BUILD_DIR)/$(BAZEL_PACKAGE_BIN_DIR)
""",
                "DEPLOYMENT_LOCATION": """
$(INDEXING_DEPLOYMENT_LOCATION__$(INDEX_ENABLE_BUILD_ARENA)),
""",
                "DSTROOT": "$(PROJECT_TEMP_DIR)",
                "ENABLE_DEFAULT_SEARCH_PATHS": "NO",
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
                "_SRCROOT": directories.workspace.string,
                "SRCROOT": "$(_SRCROOT:standardizepath)",
                "SUPPORTS_MACCATALYST": false,
                "SWIFT_EXEC": "$(BAZEL_INTEGRATION_DIR)/swiftc",
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
            projectDirPath: directories.bazelOut.parent().string,
            attributes: attributes
        )
        expectedPBXProj.add(object: expectedPBXProject)
        expectedPBXProj.rootObject = expectedPBXProject

        // Act

        let createdPBXProj = Generator.createProject(
            buildMode: .bazel,
            project: project,
            directories: directories
        )

        try createdPBXProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(createdPBXProj, expectedPBXProj)
    }
}
