import ArgumentParser

public enum PBXProductType: String, ExpressibleByArgument {
    // Applications
    case application = "com.apple.product-type.application"
    case messagesApplication = "com.apple.product-type.application.messages"
    case onDemandInstallCapableApplication = "com.apple.product-type.application.on-demand-install-capable"
    case watchApp = "com.apple.product-type.application.watchapp"
    case watch2App = "com.apple.product-type.application.watchapp2"
    case watch2AppContainer = "com.apple.product-type.application.watchapp2-container"

    // App extensions
    case appExtension = "com.apple.product-type.app-extension"
    case intentsServiceExtension = "com.apple.product-type.app-extension.intents-service"
    case messagesExtension = "com.apple.product-type.app-extension.messages"
    case stickerPack = "com.apple.product-type.app-extension.messages-sticker-pack"
    case tvExtension = "com.apple.product-type.tv-app-extension"

    // Other extensions
    case extensionKitExtension = "com.apple.product-type.extensionkit-extension"
    case watchExtension = "com.apple.product-type.watchkit-extension"
    case watch2Extension = "com.apple.product-type.watchkit2-extension"
    case xcodeExtension = "com.apple.product-type.xcode-extension"

    // Bundles
    case bundle = "com.apple.product-type.bundle"
    case ocUnitTestBundle = "com.apple.product-type.bundle.ocunit-test"
    case unitTestBundle = "com.apple.product-type.bundle.unit-test"
    case uiTestBundle = "com.apple.product-type.bundle.ui-testing"

    // Frameworks
    case framework = "com.apple.product-type.framework"
    case staticFramework = "com.apple.product-type.framework.static"
    case xcFramework = "com.apple.product-type.xcframework"

    // Libraries
    case dynamicLibrary = "com.apple.product-type.library.dynamic"
    case staticLibrary = "com.apple.product-type.library.static"

    // Other
    case driverExtension = "com.apple.product-type.driver-extension"
    case instrumentsPackage = "com.apple.product-type.instruments-package"
    case metalLibrary = "com.apple.product-type.metal-library"
    case systemExtension = "com.apple.product-type.system-extension"
    case commandLineTool = "com.apple.product-type.tool"
    case xpcService = "com.apple.product-type.xpc-service"
}
