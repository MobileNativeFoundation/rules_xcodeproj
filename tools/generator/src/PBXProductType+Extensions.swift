import XcodeProj

extension PBXProductType {
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
}
