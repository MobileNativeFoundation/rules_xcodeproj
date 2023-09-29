import PBXProj

extension PBXProductType {
    var isBundle: Bool {
        switch self {
        case .application,
                .messagesApplication,
                .onDemandInstallCapableApplication,
                .watch2App,
                .watch2AppContainer,
                .appExtension,
                .intentsServiceExtension,
                .messagesExtension,
                .stickerPack,
                .tvExtension,
                .extensionKitExtension,
                .watch2Extension,
                .xcodeExtension,
                .resourceBundle,
                .bundle,
                .ocUnitTestBundle,
                .unitTestBundle,
                .uiTestBundle,
                .framework,
                .staticFramework,
                .driverExtension,
                .instrumentsPackage,
                .systemExtension,
                .xpcService:
            return true
        default:
            return false
        }
    }

    var setsProductReference: Bool {
        // We remove the association for non-launchable and non-bundle products
        // to allow the correct path to be shown in the project navigator
        switch self {
        case .application,
                .messagesApplication,
                .onDemandInstallCapableApplication,
                .watch2App,
                .watch2AppContainer,
                .appExtension,
                .intentsServiceExtension,
                .messagesExtension,
                .stickerPack,
                .tvExtension,
                .extensionKitExtension,
                .watch2Extension,
                .xcodeExtension,
                .resourceBundle,
                .bundle,
                .ocUnitTestBundle,
                .unitTestBundle,
                .uiTestBundle,
                .framework,
                .staticFramework,
                .driverExtension,
                .instrumentsPackage,
                .systemExtension,
                .commandLineTool,
                .xpcService:
            return true
        default:
            return false
        }
    }
}
