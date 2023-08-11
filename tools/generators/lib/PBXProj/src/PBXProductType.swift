import ArgumentParser

// Values here need to match those in `product.bzl`
public enum PBXProductType: String, ExpressibleByArgument {
    // Applications
    case application = "a"
    case messagesApplication = "M"
    case onDemandInstallCapableApplication = "A"
    case watchApp = "0"
    case watch2App = "w"
    case watch2AppContainer = "c"

    // App extensions
    case appExtension = "e"
    case intentsServiceExtension = "i"
    case messagesExtension = "m"
    case stickerPack = "s"
    case tvExtension = "t"

    // Other extensions
    case extensionKitExtension = "E"
    case watchExtension = "1"
    case watch2Extension = "W"
    case xcodeExtension = "2"

    // Bundles
    case resourceBundle = "b"
    case bundle = "B"
    case ocUnitTestBundle = "o"
    case unitTestBundle = "u"
    case uiTestBundle = "U"

    // Frameworks
    case framework = "f"
    case staticFramework = "F"
    case xcFramework = "x"

    // Libraries
    case dynamicLibrary = "l"
    case staticLibrary = "L"

    // Other
    case driverExtension = "d"
    case instrumentsPackage = "I"
    case metalLibrary = "3"
    case systemExtension = "S"
    case commandLineTool = "T"
    case xpcService = "X"
}

extension PBXProductType {
    public var identifier: String {
        switch self {
        case .application:
            return "com.apple.product-type.application"
        case .messagesApplication:
            return "com.apple.product-type.application.messages"
        case .onDemandInstallCapableApplication:
            return "com.apple.product-type.application.on-demand-install-capable"
        case .watchApp:
            return "com.apple.product-type.application.watchapp"
        case .watch2App:
            return "com.apple.product-type.application.watchapp2"
        case .watch2AppContainer:
            return "com.apple.product-type.application.watchapp2-container"
        case .appExtension:
            return "com.apple.product-type.app-extension"
        case .intentsServiceExtension:
            return "com.apple.product-type.app-extension.intents-service"
        case .messagesExtension:
            return "com.apple.product-type.app-extension.messages"
        case .stickerPack:
            return "com.apple.product-type.app-extension.messages-sticker-pack"
        case .tvExtension:
            return "com.apple.product-type.tv-app-extension"
        case .extensionKitExtension:
            return "com.apple.product-type.extensionkit-extension"
        case .watchExtension:
            return "com.apple.product-type.watchkit-extension"
        case .watch2Extension:
            return "com.apple.product-type.watchkit2-extension"
        case .xcodeExtension:
            return "com.apple.product-type.xcode-extension"
        case .resourceBundle, .bundle:
            return "com.apple.product-type.bundle"
        case .ocUnitTestBundle:
            return "com.apple.product-type.bundle.ocunit-test"
        case .unitTestBundle:
            return "com.apple.product-type.bundle.unit-test"
        case .uiTestBundle:
            return "com.apple.product-type.bundle.ui-testing"
        case .framework:
            return "com.apple.product-type.framework"
        case .staticFramework:
            return "com.apple.product-type.framework.static"
        case .xcFramework:
            return "com.apple.product-type.xcframework"
        case .dynamicLibrary:
            return "com.apple.product-type.library.dynamic"
        case .staticLibrary:
            return "com.apple.product-type.library.static"
        case .driverExtension:
            return "com.apple.product-type.driver-extension"
        case .instrumentsPackage:
            return "com.apple.product-type.instruments-package"
        case .metalLibrary:
            return "com.apple.product-type.metal-library"
        case .systemExtension:
            return "com.apple.product-type.system-extension"
        case .commandLineTool:
            return "com.apple.product-type.tool"
        case .xpcService:
            return "com.apple.product-type.xpc-service"
        }
    }
}
