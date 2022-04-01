import XcodeProj

extension PBXProductType {
    var isAppExtension: Bool {
        switch self {
        case .application: return false
        case .framework: return false
        case .staticFramework: return false
        case .xcFramework: return false
        case .dynamicLibrary: return false
        case .staticLibrary: return false
        case .bundle: return false
        case .unitTestBundle: return false
        case .uiTestBundle: return false
        case .appExtension: return true
        case .commandLineTool: return false
        case .watchApp: return false
        case .watch2App: return false
        case .watch2AppContainer: return false
        case .watchExtension: return true
        case .watch2Extension: return true
        case .tvExtension: return true
        case .messagesApplication: return false
        case .messagesExtension: return true
        case .stickerPack: return false
        case .xpcService: return false
        case .ocUnitTestBundle: return false
        case .xcodeExtension: return true
        case .instrumentsPackage: return false
        case .intentsServiceExtension: return true
        case .onDemandInstallCapableApplication: return false
        case .metalLibrary: return false
        case .driverExtension: return false
        case .systemExtension: return false
        case .none: return false
        }
    }

    var isBundle: Bool {
        switch self {
        case .application: return true
        case .framework: return true
        case .staticFramework: return true
        case .xcFramework: return true
        case .dynamicLibrary: return false
        case .staticLibrary: return false
        case .bundle: return true
        case .unitTestBundle: return true
        case .uiTestBundle: return true
        case .appExtension: return true
        case .commandLineTool: return false
        case .watchApp: return true
        case .watch2App: return true
        case .watch2AppContainer: return true
        case .watchExtension: return true
        case .watch2Extension: return true
        case .tvExtension: return true
        case .messagesApplication: return true
        case .messagesExtension: return true
        case .stickerPack: return true
        case .xpcService: return true
        case .ocUnitTestBundle: return true
        case .xcodeExtension: return true
        case .instrumentsPackage: return true
        case .intentsServiceExtension: return true
        case .onDemandInstallCapableApplication: return true
        case .metalLibrary: return false
        case .driverExtension: return false
        case .systemExtension: return false
        case .none: return false
        }
    }

    var isFramework: Bool {
        switch self {
        case .application: return false
        case .framework: return true
        case .staticFramework: return true
        case .xcFramework: return true
        case .dynamicLibrary: return false
        case .staticLibrary: return false
        case .bundle: return false
        case .unitTestBundle: return false
        case .uiTestBundle: return false
        case .appExtension: return false
        case .commandLineTool: return false
        case .watchApp: return false
        case .watch2App: return false
        case .watch2AppContainer: return false
        case .watchExtension: return false
        case .watch2Extension: return false
        case .tvExtension: return false
        case .messagesApplication: return false
        case .messagesExtension: return false
        case .stickerPack: return false
        case .xpcService: return false
        case .ocUnitTestBundle: return false
        case .xcodeExtension: return false
        case .instrumentsPackage: return false
        case .intentsServiceExtension: return false
        case .onDemandInstallCapableApplication: return false
        case .metalLibrary: return false
        case .driverExtension: return false
        case .systemExtension: return false
        case .none: return false
        }
    }

    var isExecutable: Bool {
        switch self {
        case .application: return true
        case .framework: return true
        case .staticFramework: return false
        case .xcFramework: return true // Could be
        case .dynamicLibrary: return true
        case .staticLibrary: return false
        case .bundle: return true // Could be
        case .unitTestBundle: return true
        case .uiTestBundle: return true
        case .appExtension: return true
        case .commandLineTool: return true
        case .watchApp: return true
        case .watch2App: return true
        case .watch2AppContainer: return true
        case .watchExtension: return true
        case .watch2Extension: return true
        case .tvExtension: return true
        case .messagesApplication: return true
        case .messagesExtension: return true
        case .stickerPack: return false
        case .xpcService: return true
        case .ocUnitTestBundle: return true
        case .xcodeExtension: return true
        case .instrumentsPackage: return false
        case .intentsServiceExtension: return true
        case .onDemandInstallCapableApplication: return true
        case .metalLibrary: return false
        case .driverExtension: return true
        case .systemExtension: return true
        case .none: return false
        }
    }

    var fileType: String? {
        switch self {
        case .application: return "wrapper.application"
        case .framework: return "wrapper.framework"
        case .staticFramework: return "wrapper.framework.static"
        case .xcFramework: return "wrapper.xcframework"
        case .dynamicLibrary: return "compiled.mach-o.dylib"
        case .staticLibrary: return "archive.ar"
        case .bundle: return "wrapper.cfbundle"
        case .unitTestBundle: return "wrapper.cfbundle"
        case .uiTestBundle: return "wrapper.cfbundle"
        case .appExtension: return "wrapper.app-extension"
        case .commandLineTool: return "compiled.mach-o.executable"
        case .watchApp: return "wrapper.application"
        case .watch2App: return "wrapper.application"
        case .watch2AppContainer: return "wrapper.application"
        case .watchExtension: return "wrapper.app-extension"
        case .watch2Extension: return "wrapper.app-extension"
        case .tvExtension: return "wrapper.app-extension"
        case .messagesApplication: return "wrapper.application"
        case .messagesExtension: return "wrapper.app-extension"
        case .stickerPack: return "wrapper.app-extension"
        case .xpcService: return "wrapper.xpc-service"
        case .ocUnitTestBundle: return "wrapper.cfbundle"
        case .xcodeExtension: return "wrapper.app-extension"
        case .instrumentsPackage: return "com.apple.instruments.instrdst"
        case .intentsServiceExtension: return "wrapper.app-extension"
        case .onDemandInstallCapableApplication: return "wrapper.application"
        case .metalLibrary: return nil
        case .driverExtension: return "wrapper.driver-extension"
        case .systemExtension: return "wrapper.system-extension"
        case .none: return nil
        }
    }

    var prettyName: String {
        switch self {
            case .application: return "App"
            case .framework: return "Framework"
            case .staticFramework: return "Static Framework"
            case .xcFramework: return "XCFramework"
            case .dynamicLibrary: return "Dylib"
            case .staticLibrary: return "Library"
            case .bundle: return "Bundle"
            case .unitTestBundle: return "Unit Tests"
            case .uiTestBundle: return "UI Tests"
            case .appExtension: return "App Extension"
            case .commandLineTool: return "Command Line Tool"
            case .watchApp: return "watchOS 1.0 App"
            case .watch2App: return "App"
            case .watch2AppContainer: return "App Container"
            case .watchExtension: return "WatchKit 1.0 Extension"
            case .watch2Extension: return "WatchKit Extension"
            case .tvExtension: return "App Extension"
            case .messagesApplication: return "Messages App"
            case .messagesExtension: return "Messages Extension"
            case .stickerPack: return "Sticker Pack"
            case .xpcService: return "XPC Service"
            case .ocUnitTestBundle: return "OC Unit Tests"
            case .xcodeExtension: return "Xcode Extension"
            case .instrumentsPackage: return "Instruments Package"
            case .intentsServiceExtension: return "Intents Service Extension"
            case .onDemandInstallCapableApplication: return "App Clip"
            case .metalLibrary: return "Metal Library"
            case .driverExtension: return "Driver Extension"
            case .systemExtension: return "System Extension"
            case .none: return "Unknown"
        }
    }
}
