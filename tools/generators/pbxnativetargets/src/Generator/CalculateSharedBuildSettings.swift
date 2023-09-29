import OrderedCollections
import PBXProj
import ToolCommon

extension Generator {
    struct CalculateSharedBuildSettings {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Calculates a target's shared build settings. These are the build
        /// settings that are the same for every Xcode configuration.
        func callAsFunction(
            name: String,
            label: BazelLabel,
            productType: PBXProductType,
            productName: String,
            platforms: OrderedSet<Platform>,
            uiTestHostName: String?
        ) -> [BuildSetting] {
            return callable(
                /*name:*/ name,
                /*label:*/ label,
                /*productType:*/ productType,
                /*productName:*/ productName,
                /*platforms:*/ platforms,
                /*uiTestHostName:*/ uiTestHostName
            )
        }
    }
}

// MARK: - CalculateSharedBuildSettings.Callable

extension Generator.CalculateSharedBuildSettings {
    typealias Callable = (
        _ name: String,
        _ label: BazelLabel,
        _ productType: PBXProductType,
        _ productName: String,
        _ platforms: OrderedSet<Platform>,
        _ uiTestHostName: String?
    ) -> [BuildSetting]

    static func defaultCallable(
        name: String,
        label: BazelLabel,
        productType: PBXProductType,
        productName: String,
        platforms: OrderedSet<Platform>,
        uiTestHostName: String?
    ) -> [BuildSetting] {
        var buildSettings: [BuildSetting] = []

        buildSettings.append(
            .init(key: "PRODUCT_NAME", value: productName.pbxProjEscaped)
        )
        buildSettings.append(
            .init(key: "TARGET_NAME", value: name.pbxProjEscaped)
        )
        buildSettings.append(
            .init(
                key: "COMPILE_TARGET_NAME",
                value: label.name.pbxProjEscaped
            )
        )

        buildSettings.append(
            .init(key: "SDKROOT", value: platforms.first!.os.sdkRoot)
        )
        buildSettings.append(
            .init(
                key: "SUPPORTED_PLATFORMS",
                value: platforms.map(\.rawValue).joined(separator: " ")
                    .pbxProjEscaped
            )
        )

        if !platforms.intersection(iPhonePlatforms).isEmpty {
            buildSettings.append(
                .init(
                    key: "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD",
                    value: platforms.contains(.iOSDevice) ? "YES" : "NO"
                )
            )
        }

        if productType != .resourceBundle {
            // This is used in `calculate_output_groups.py`. We only want to set
            // it on buildable targets.
            buildSettings.append(
                .init(
                    key: "BAZEL_LABEL",
                    value: label.description.pbxProjEscaped
                )
            )
        } else {
            // Used to work around CODE_SIGNING_ENABLED = YES in Xcode 14
            buildSettings.append(
                .init(key: "CODE_SIGNING_ALLOWED", value: "NO")
            )
        }

        if productType == .uiTestBundle {
            if let uiTestHostName {
                buildSettings.append(
                    .init(
                        key: "TEST_TARGET_NAME",
                        value: uiTestHostName.pbxProjEscaped
                    )
                )
            }
        } else if productType == .staticFramework {
            // We set the `productType` to `.framework` to get the better
            // looking icon, so we need to manually set `MACH_O_TYPE`
            buildSettings.append(.init(key: "MACH_O_TYPE", value: "staticlib"))
        }

        if productType.isLaunchable {
            // We need `BUILT_PRODUCTS_DIR` to point to where the
            // binary/bundle is actually at, for running from scheme to work
            buildSettings.append(
                .init(
                    key: "BUILT_PRODUCTS_DIR",
                    value: #""$(CONFIGURATION_BUILD_DIR)""#
                )
            )
            buildSettings.append(.init(key: "DEPLOYMENT_LOCATION", value: "NO"))
        }

        return buildSettings
    }
}

private let iPhonePlatforms: Set<Platform> = [
    .iOSDevice,
    .iOSSimulator,
]

private extension PBXProductType {
    var isLaunchable: Bool {
        switch self {
        case .application,
             .messagesApplication,
             .onDemandInstallCapableApplication,
             .watch2App,
             .watch2AppContainer,
             .appExtension,
             .intentsServiceExtension,
             .messagesExtension,
             .tvExtension,
             .extensionKitExtension,
             .watch2Extension,
             .xcodeExtension,
             .ocUnitTestBundle,
             .unitTestBundle,
             .uiTestBundle,
             .driverExtension,
             .systemExtension,
             .commandLineTool,
             .xpcService:
            return true
        default:
            return false
        }
    }
}

private extension Platform.OS {
    var deploymentTargetBuildSettingKey: String {
        switch self {
        case .macOS: return "MACOSX_DEPLOYMENT_TARGET"
        case .iOS: return "IPHONEOS_DEPLOYMENT_TARGET"
        case .tvOS: return "TVOS_DEPLOYMENT_TARGET"
        case .watchOS: return "WATCHOS_DEPLOYMENT_TARGET"
        }
    }

    var sdkRoot: String {
        switch self {
        case .macOS: return "macosx"
        case .iOS: return "iphoneos"
        case .tvOS: return "appletvos"
        case .watchOS: return "watchos"
        }
    }
}
