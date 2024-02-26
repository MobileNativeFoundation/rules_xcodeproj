import Foundation
import PBXProj
import ToolCommon

extension Generator {
    struct CalculatePlatformVariantBuildSettings {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Calculates the build settings for one of the target's platform
        /// variants.
        func callAsFunction(
            isBundle: Bool,
            originalProductBasename: String,
            productType: PBXProductType,
            platformVariant: Target.PlatformVariant
        ) async throws -> [PlatformVariantBuildSetting] {
            return try await callable(
                /*isBundle:*/ isBundle,
                /*originalProductBasename:*/ originalProductBasename,
                /*productType:*/ productType,
                /*platformVariant:*/ platformVariant
            )
        }
    }
}

// MARK: - CalculatePlatformVariantBuildSettings.Callable

extension Generator.CalculatePlatformVariantBuildSettings {
    typealias Callable = (
        _ isBundle: Bool,
        _ originalProductBasename: String,
        _ productType: PBXProductType,
        _ platformVariant: Target.PlatformVariant
    ) async throws -> [PlatformVariantBuildSetting]

    static func defaultCallable(
        isBundle: Bool,
        originalProductBasename: String,
        productType: PBXProductType,
        platformVariant: Target.PlatformVariant
    ) async throws -> [PlatformVariantBuildSetting] {
        var buildSettings: [PlatformVariantBuildSetting] = []

        buildSettings.append(
            .init(key: "ARCHS", value: platformVariant.arch.pbxProjEscaped)
        )
        buildSettings.append(
            .init(
                key: "BAZEL_PACKAGE_BIN_DIR",
                value: platformVariant.packageBinDir.pbxProjEscaped
            )
        )
        buildSettings.append(
            .init(
                key: "BAZEL_TARGET_ID",
                value: platformVariant.id.rawValue.pbxProjEscaped
            )
        )
        buildSettings.append(
            .init(
                key:
                    platformVariant.platform.os.deploymentTargetBuildSettingKey,
                value: platformVariant.osVersion.pretty.pbxProjEscaped
            )
        )

        if let bundleID = platformVariant.bundleID {
            buildSettings.append(
                .init(
                    key: "PRODUCT_BUNDLE_IDENTIFIER",
                    value: bundleID.pbxProjEscaped
                )
            )
        }

        if !platformVariant.moduleName.isEmpty {
            buildSettings.append(
                .init(
                    key: "PRODUCT_MODULE_NAME",
                    value: platformVariant.moduleName.pbxProjEscaped
                )
            )
        }

        if let outputsProductPath = platformVariant.outputsProductPath {
            buildSettings.append(
                .init(
                    key: "BAZEL_OUTPUTS_PRODUCT",
                    value: outputsProductPath.pbxProjEscaped
                )
            )
            buildSettings.append(
                .init(
                    key: "BAZEL_OUTPUTS_PRODUCT_BASENAME",
                    value: platformVariant.productBasename.pbxProjEscaped
                )
            )
        }

        if let dSYMPathsBuildSetting = platformVariant.dSYMPathsBuildSetting {
            buildSettings.append(
                .init(
                    key: "BAZEL_OUTPUTS_DSYM",
                    value: dSYMPathsBuildSetting.pbxProjEscaped
                )
            )
        }

        if let executableName = platformVariant.executableName,
           executableName != platformVariant.productName
        {
            buildSettings.append(
                .init(
                    key: "EXECUTABLE_NAME",
                    value: executableName.pbxProjEscaped
                )
            )
        }

        let productExtension = (originalProductBasename as NSString).pathExtension
        if productExtension != productType.fileExtension {
            buildSettings.append(
                .init(
                    key: isBundle ?
                        "WRAPPER_EXTENSION" : "EXECUTABLE_EXTENSION",
                    value: productExtension.pbxProjEscaped
                )
            )
        }

        if let compileTargetIDs = platformVariant.compileTargetIDs {
            buildSettings.append(
                .init(
                    key: "BAZEL_COMPILE_TARGET_IDS",
                    value: compileTargetIDs.pbxProjEscaped
                )
            )
        }

        if let testHost = platformVariant.unitTestHost {
            buildSettings.append(
                .init(
                    key: "TARGET_BUILD_DIR",
                    value: #"""
"$(BUILD_DIR)/\#(testHost.packageBinDir)$(TARGET_BUILD_SUBPATH)"
"""#
                )
            )
            buildSettings.append(
                .init(
                    key: "TEST_HOST",
                    value: #"""
"$(BUILD_DIR)/\#(testHost.packageBinDir)/\#(testHost.basename)/\#(testHost.executableName)"
"""#
                )
            )
        }

        if let linkParams = platformVariant.linkParams {
            // Drop the `bazel-out` prefix since we use the env var for this
            // portion of the path
            buildSettings.append(
                .init(
                    key: "LINK_PARAMS_FILE",
                    value: #"""
"$(BAZEL_OUT)\#(linkParams.dropFirst(9))"
"""#
                )
            )
            buildSettings.append(
                .init(
                    key: "OTHER_LDFLAGS",
                    value: #""@$(DERIVED_FILE_DIR)/link.params""#
                )
            )
        }

        buildSettings.append(contentsOf: platformVariant.buildSettingsFromFile)

        return buildSettings
    }
}

struct PlatformVariantBuildSetting: Equatable {
    let key: String
    let value: String
}

private extension Platform.OS {
    var deploymentTargetBuildSettingKey: String {
        switch self {
        case .macOS: return "MACOSX_DEPLOYMENT_TARGET"
        case .iOS: return "IPHONEOS_DEPLOYMENT_TARGET"
        case .tvOS: return "TVOS_DEPLOYMENT_TARGET"
        case .visionOS: return "XROS_DEPLOYMENT_TARGET"
        case .watchOS: return "WATCHOS_DEPLOYMENT_TARGET"
        }
    }

    var sdkRoot: String {
        switch self {
        case .macOS: return "macosx"
        case .iOS: return "iphoneos"
        case .tvOS: return "appletvos"
        case .visionOS: return "xros"
        case .watchOS: return "watchos"
        }
    }
}

private extension PBXProductType {
    var fileExtension: String? {
        switch self {
        case .application,
                .messagesApplication,
                .onDemandInstallCapableApplication,
                .watch2App,
                .watch2AppContainer:
            return "app"
        case .appExtension,
                .intentsServiceExtension,
                .messagesExtension,
                .stickerPack,
                .tvExtension,
                .extensionKitExtension,
                .watch2Extension,
                .xcodeExtension:
            return "appex"
        case .resourceBundle, .bundle:
            return "bundle"
        case .ocUnitTestBundle:
            return "octest"
        case .unitTestBundle, .uiTestBundle:
            return "xctest"
        case .framework, .staticFramework:
            return "framework"
        case .xcFramework:
            return "xcframework"
        case .dynamicLibrary:
            return "dylib"
        case .staticLibrary:
            return "a"
        case .driverExtension:
            return "dext"
        case .instrumentsPackage:
            return "instrpkg"
        case .metalLibrary:
            return "metallib"
        case .systemExtension:
            return "systemextension"
        case .commandLineTool:
            return nil
        case .xpcService:
            return "xpc"
        }
    }
}
