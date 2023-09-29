import PBXProj

extension Generator {
    struct CreateProductObject {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Creates a `PBXBuildFile` element.
        func callAsFunction(
            productType: PBXProductType,
            subIdentifier: Identifiers.BuildFiles.SubIdentifier,
            isAssociatedWithTarget: Bool
        ) -> Object {
            return callable(
                /*productType:*/ productType,
                /*subIdentifier:*/ subIdentifier,
                /*isAssociatedWithTarget:*/ isAssociatedWithTarget
            )
        }
    }
}

// MARK: - CreateProductObject.Callable

extension Generator.CreateProductObject {
    typealias Callable = (
        _ productType: PBXProductType,
        _ subIdentifier: Identifiers.BuildFiles.SubIdentifier,
        _ isAssociatedWithTarget: Bool
    ) -> Object

    static func defaultCallable(
        productType: PBXProductType,
        subIdentifier: Identifiers.BuildFiles.SubIdentifier,
        isAssociatedWithTarget: Bool
    ) -> Object {
        let content = #"""
{isa = PBXFileReference; explicitFileType = \#(productType.fileType.pbxProjEscaped); includeInIndex = 0; path = \#(subIdentifier.path.path.pbxProjEscaped); sourceTree = BUILT_PRODUCTS_DIR; }
"""#

        return Object(
            identifier: Identifiers.BuildFiles.id(subIdentifier: subIdentifier),
            content: content
        )
    }
}

private extension PBXProductType {
    var fileType: String {
        switch self {
        case .application: return "wrapper.application"
        case .messagesApplication: return "wrapper.application"
        case .onDemandInstallCapableApplication: return "wrapper.application"
        case .watch2App: return "wrapper.application"
        case .watch2AppContainer: return "wrapper.application"
        case .appExtension: return "wrapper.app-extension"
        case .intentsServiceExtension: return "wrapper.app-extension"
        case .messagesExtension: return "wrapper.app-extension"
        case .stickerPack: return "wrapper.app-extension"
        case .tvExtension: return "wrapper.app-extension"
        case .extensionKitExtension: return "wrapper.app-extension"
        case .watch2Extension: return "wrapper.app-extension"
        case .xcodeExtension: return "wrapper.app-extension"
        case .resourceBundle, .bundle: return "wrapper.cfbundle"
        case .ocUnitTestBundle: return "wrapper.cfbundle"
        case .unitTestBundle: return "wrapper.cfbundle"
        case .uiTestBundle: return "wrapper.cfbundle"
        case .framework: return "wrapper.framework"
        case .staticFramework: return "wrapper.framework.static"
        case .xcFramework: return "wrapper.xcframework"
        case .dynamicLibrary: return "compiled.mach-o.dylib"
        case .staticLibrary: return "archive.ar"
        case .driverExtension: return "wrapper.driver-extension"
        case .instrumentsPackage: return "com.apple.instruments.instrdst"
        case .metalLibrary: return "file"
        case .systemExtension: return "wrapper.system-extension"
        case .commandLineTool: return "compiled.mach-o.executable"
        case .xpcService: return "wrapper.xpc-service"
        }
    }
}
