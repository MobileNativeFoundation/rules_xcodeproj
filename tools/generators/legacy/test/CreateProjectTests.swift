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

        let directories = Directories(
            workspace: "/Users/TimApple/app",
            projectRoot: projectRootDirectory,
            executionRoot: "/tmp/bazel-output-base/rules_xcodeproj/build_output_base/execroot/rules_xcodeproj",
            internalDirectoryName: "r_xcp",
            workspaceOutput: "X.xcodeproj"
        )

        let expectedPBXProj = PBXProj(objectVersion: 56)

        let expectedMainGroup = PBXGroup(
            sourceTree: .absolute,
            path: directories.workspace.string,
            usesTabs: true,
            indentWidth: 3,
            tabWidth: 2
        )
        expectedPBXProj.add(object: expectedMainGroup)

        let buildSettings: [String: Any] = [
            "ALWAYS_SEARCH_USER_PATHS": false,
            "BAZEL_CONFIG": project.bazelConfig,
            "BAZEL_EXTERNAL": "$(BAZEL_OUTPUT_BASE)/external",
            "BAZEL_LLDB_INIT": "$(HOME)/.lldbinit-rules_xcodeproj",
            "BAZEL_OUT": "$(PROJECT_DIR)/bazel-out",
            "_BAZEL_OUTPUT_BASE": "$(PROJECT_DIR)/../..",
            "BAZEL_OUTPUT_BASE": "$(_BAZEL_OUTPUT_BASE:standardizepath)",
            "BAZEL_WORKSPACE_ROOT": "$(SRCROOT)",
            "BAZEL_INTEGRATION_DIR": "$(INTERNAL_DIR)/bazel",
            "BUILD_MARKER_FILE": "$(OBJROOT)/build_marker",
            "BUILD_WORKSPACE_DIRECTORY": "$(SRCROOT)",
            "BUILD_DIR": """
$(SYMROOT)/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)
""",
            "BUILT_PRODUCTS_DIR": """
$(INDEXING_BUILT_PRODUCTS_DIR__$(INDEX_ENABLE_BUILD_ARENA))
""",
            "CLANG_ENABLE_OBJC_ARC": true,
            "CLANG_MODULES_AUTOLINK": false,
            "CONFIGURATION_BUILD_DIR": """
$(BUILD_DIR)/$(BAZEL_PACKAGE_BIN_DIR)
""",
            "COPY_PHASE_STRIP": false,
            "DEBUG_INFORMATION_FORMAT": "dwarf",
            "DEPLOYMENT_LOCATION": """
$(INDEXING_DEPLOYMENT_LOCATION__$(INDEX_ENABLE_BUILD_ARENA)),
""",
            "DSTROOT": "$(PROJECT_TEMP_DIR)",
            "ENABLE_DEFAULT_SEARCH_PATHS": "NO",
            "ENABLE_STRICT_OBJC_MSGSEND": true,
            "ENABLE_USER_SCRIPT_SANDBOXING": false,
            "GCC_OPTIMIZATION_LEVEL": "0",
            "INDEX_DATA_STORE_DIR": "$(INDEX_DATA_STORE_DIR)",
            "INDEX_FORCE_SCRIPT_EXECUTION": true,
            "INDEX_IMPORT": "/tmp/index-import",
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
            "INDEXING_PROJECT_DIR__": "$(INDEXING_PROJECT_DIR__NO)",
            "INDEXING_PROJECT_DIR__NO": """
/tmp/bazel-output-base/rules_xcodeproj/build_output_base/execroot/rules_xcodeproj
""",
            "INDEXING_PROJECT_DIR__YES": """
/tmp/bazel-output-base/rules_xcodeproj/indexbuild_output_base/execroot/rules_xcodeproj
""",
            "INSTALL_PATH": "$(BAZEL_PACKAGE_BIN_DIR)/$(TARGET_NAME)/bin",
            "INTERNAL_DIR": "$(PROJECT_FILE_PATH)/r_xcp",
            "LD_OBJC_ABI_VERSION": "",
            "LD_DYLIB_INSTALL_NAME": "",
            "LD_RUNPATH_SEARCH_PATHS": "",
            "ONLY_ACTIVE_ARCH": true,
            "PROJECT_DIR": """
$(INDEXING_PROJECT_DIR__$(INDEX_ENABLE_BUILD_ARENA))
""",
            "RULES_XCODEPROJ_BUILD_MODE": "xcode",
            "SRCROOT": directories.workspace.string,
            "SUPPORTS_MACCATALYST": false,
            "SWIFT_OBJC_INTERFACE_HEADER_NAME": "",
            "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
            "SWIFT_VERSION": "5.0",
            "TARGET_TEMP_DIR": """
$(PROJECT_TEMP_DIR)/$(BAZEL_PACKAGE_BIN_DIR)/$(COMPILE_TARGET_NAME)
""",
            "USE_HEADERMAP": false,
            "VALIDATE_WORKSPACE": false,
        ]

        let profileConfiguration = XCBuildConfiguration(
            name: "Profile",
            buildSettings: buildSettings
        )
        expectedPBXProj.add(object: profileConfiguration)
        let releaseConfiguration = XCBuildConfiguration(
            name: "Release",
            buildSettings: buildSettings
        )
        expectedPBXProj.add(object: releaseConfiguration)
        let expectedBuildConfigurationList = XCConfigurationList(
            buildConfigurations: [profileConfiguration, releaseConfiguration],
            defaultConfigurationName: "Profile"
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
            compatibilityVersion: "Xcode 14.0",
            mainGroup: expectedMainGroup,
            developmentRegion: "es",
            projectDirPath: directories.executionRoot.string,
            attributes: attributes
        )
        expectedPBXProj.add(object: expectedPBXProject)
        expectedPBXProj.rootObject = expectedPBXProject

        // Act

        let createdPBXProj = Generator.createProject(
            buildMode: .xcode,
            forFixtures: false,
            project: project,
            directories: directories,
            indexImport: project.indexImport,
            minimumXcodeVersion: project.minimumXcodeVersion
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

        let directories = Directories(
            workspace: "/Users/TimApple/app",
            projectRoot: projectRootDirectory,
            executionRoot: "/tmp/bazel-output-base/rules_xcodeproj/build_output_base/execroot/rules_xcodeproj",
            internalDirectoryName: "r_xcp",
            workspaceOutput: "X.xcodeproj"
        )

        let expectedPBXProj = PBXProj(objectVersion: 56)

        let expectedMainGroup = PBXGroup(
            sourceTree: .absolute,
            path: directories.workspace.string,
            usesTabs: true,
            indentWidth: 3,
            tabWidth: 2
        )
        expectedPBXProj.add(object: expectedMainGroup)

        let buildSettings: [String: Any] = [
            "ALWAYS_SEARCH_USER_PATHS": false,
            "ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOLS": false,
            "BAZEL_CONFIG": "rules_xcodeproj_fixtures",
            "BAZEL_EXTERNAL": "$(BAZEL_OUTPUT_BASE)/external",
            "BAZEL_LLDB_INIT": "$(HOME)/.lldbinit-rules_xcodeproj",
            "BAZEL_OUT": "$(PROJECT_DIR)/bazel-out",
            "_BAZEL_OUTPUT_BASE": "$(PROJECT_DIR)/../..",
            "BAZEL_OUTPUT_BASE": "$(_BAZEL_OUTPUT_BASE:standardizepath)",
            "BAZEL_WORKSPACE_ROOT": "$(SRCROOT)",
            "BUILD_DIR": """
$(SYMROOT)/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)
""",
            "BUILD_MARKER_FILE": "$(OBJROOT)/build_marker",
            "BUILD_WORKSPACE_DIRECTORY": "$(SRCROOT)",
            "BAZEL_INTEGRATION_DIR": "$(INTERNAL_DIR)/bazel",
            "BUILT_PRODUCTS_DIR": """
$(INDEXING_BUILT_PRODUCTS_DIR__$(INDEX_ENABLE_BUILD_ARENA))
""",
            "CC": "$(BAZEL_INTEGRATION_DIR)/clang.sh",
            "CXX": "$(BAZEL_INTEGRATION_DIR)/clang.sh",
            "CLANG_ENABLE_OBJC_ARC": true,
            "CLANG_MODULES_AUTOLINK": false,
            "CODE_SIGNING_ALLOWED": false,
            "CONFIGURATION_BUILD_DIR": """
$(BUILD_DIR)/$(BAZEL_PACKAGE_BIN_DIR)
""",
            "COPY_PHASE_STRIP": false,
            "DEBUG_INFORMATION_FORMAT": "dwarf",
            "DEPLOYMENT_LOCATION": """
$(INDEXING_DEPLOYMENT_LOCATION__$(INDEX_ENABLE_BUILD_ARENA)),
""",
            "DSTROOT": "$(PROJECT_TEMP_DIR)",
            "ENABLE_DEFAULT_SEARCH_PATHS": "NO",
            "ENABLE_STRICT_OBJC_MSGSEND": true,
            "ENABLE_USER_SCRIPT_SANDBOXING": false,
            "GCC_OPTIMIZATION_LEVEL": "0",
            "LD": "$(BAZEL_INTEGRATION_DIR)/ld.sh",
            "LDPLUSPLUS": "$(BAZEL_INTEGRATION_DIR)/ld.sh",
            "LIBTOOL": "$(BAZEL_INTEGRATION_DIR)/libtool.sh",
            "INDEX_DATA_STORE_DIR": "$(INDEX_DATA_STORE_DIR)",
            "INDEX_FORCE_SCRIPT_EXECUTION": true,
            "INDEX_IMPORT": "/tmp/index-import",
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
            "INDEXING_PROJECT_DIR__": "$(INDEXING_PROJECT_DIR__NO)",
            "INDEXING_PROJECT_DIR__NO": """
/tmp/bazel-output-base/rules_xcodeproj/build_output_base/execroot/rules_xcodeproj
""",
            "INDEXING_PROJECT_DIR__YES": """
/tmp/bazel-output-base/rules_xcodeproj/indexbuild_output_base/execroot/rules_xcodeproj
""",
            "INSTALL_PATH": "$(BAZEL_PACKAGE_BIN_DIR)/$(TARGET_NAME)/bin",
            "INTERNAL_DIR": "$(PROJECT_FILE_PATH)/r_xcp",
            "LD_OBJC_ABI_VERSION": "",
            "LD_DYLIB_INSTALL_NAME": "",
            "LD_RUNPATH_SEARCH_PATHS": "",
            "ONLY_ACTIVE_ARCH": true,
            "PROJECT_DIR": """
$(INDEXING_PROJECT_DIR__$(INDEX_ENABLE_BUILD_ARENA))
""",
            "RULES_XCODEPROJ_BUILD_MODE": "bazel",
            "SRCROOT": directories.workspace.string,
            "SUPPORTS_MACCATALYST": false,
            "SWIFT_EXEC": "$(BAZEL_INTEGRATION_DIR)/swiftc",
            "SWIFT_OBJC_INTERFACE_HEADER_NAME": "",
            "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
            "SWIFT_USE_INTEGRATED_DRIVER": false,
            "SWIFT_VERSION": "5.0",
            "TARGET_TEMP_DIR": """
$(PROJECT_TEMP_DIR)/$(BAZEL_PACKAGE_BIN_DIR)/$(COMPILE_TARGET_NAME)
""",
            "USE_HEADERMAP": false,
            "VALIDATE_WORKSPACE": false,
        ]

        let profileConfiguration = XCBuildConfiguration(
            name: "Profile",
            buildSettings: buildSettings
        )
        let releaseConfiguration = XCBuildConfiguration(
            name: "Release",
            buildSettings: buildSettings
        )
        expectedPBXProj.add(object: releaseConfiguration)
        expectedPBXProj.add(object: profileConfiguration)
        let expectedBuildConfigurationList = XCConfigurationList(
            buildConfigurations: [profileConfiguration, releaseConfiguration],
            defaultConfigurationName: "Profile"
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
            compatibilityVersion: "Xcode 14.0",
            mainGroup: expectedMainGroup,
            developmentRegion: "es",
            projectDirPath: directories.executionRoot.string,
            attributes: attributes
        )
        expectedPBXProj.add(object: expectedPBXProject)
        expectedPBXProj.rootObject = expectedPBXProject

        // Act

        let createdPBXProj = Generator.createProject(
            buildMode: .bazel,
            forFixtures: false,
            project: project,
            directories: directories,
            indexImport: project.indexImport,
            minimumXcodeVersion: project.minimumXcodeVersion
        )

        try createdPBXProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(createdPBXProj, expectedPBXProj)
    }
}
