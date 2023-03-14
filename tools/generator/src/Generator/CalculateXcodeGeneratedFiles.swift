import PathKit

extension Generator {
    static func calculateXcodeGeneratedFiles(
        buildMode: BuildMode,
        targets: [TargetID: Target]
    ) throws -> [FilePath: FilePath] {
        var xcodeGeneratedFiles: [FilePath: FilePath] = [:]
        func setXcodeGeneratedFile(
            _ filePath: FilePath,
            to newFilePath: FilePath
        ) throws {
            if let existingValue = xcodeGeneratedFiles[filePath] {
                throw PreconditionError(message: """
Tried to set `xcodeGeneratedFiles[\(filePath)]` to `\(newFilePath)`, but it \
already was set to `\(existingValue)`.
""")
            }
            xcodeGeneratedFiles[filePath] = newFilePath
        }

        switch buildMode {
        case .xcode:
            for (_, target) in targets {
                guard let productPath = target.product.path,
                      !target.isUnfocusedDependency
                else {
                    continue
                }

                xcodeGeneratedFiles[productPath] = productPath
                for filePath in target.product.additionalPaths {
                    try setXcodeGeneratedFile(filePath, to: productPath)
                }
                if let swift = target.outputs.swift {
                    try setXcodeGeneratedFile(
                        swift.module,
                        to: target.xcodeSwiftModuleFilePath(swift.module)
                    )
                    if let generatedHeader = swift.generatedHeader {
                        try setXcodeGeneratedFile(
                            generatedHeader,
                            to: target.xcodeSwiftGeneratedHeaderFilePath(
                                generatedHeader
                            )
                        )
                    }
                }
            }
        default:
            break
        }

        return xcodeGeneratedFiles
    }
}

// MARK: - Extensions

private extension Target {
    func xcodeSwiftGeneratedHeaderFilePath(_ filePath: FilePath) -> FilePath {
        guard let productPath = product.path else {
            // Should be caught earlier
            return filePath
        }

        // Needs to be adjusted when target merging changes the configuration
        #if DEBUG
        guard filePath.path.components[1] == "bin" else {
            // Handle weird test fixtures
            let components = productPath.path.components[0 ..< 1] +
                filePath.path.components[1...]
            var filePath = filePath
            filePath.path = Path(components: components)
            return filePath
        }
        #endif

        let components = productPath.path.components[0 ..< 2] +
            filePath.path.components[2...]
        var filePath = filePath
        filePath.path = Path(components: components)
        return filePath
    }

    func xcodeSwiftModuleFilePath(_ filePath: FilePath) -> FilePath {
        guard let productPath = product.path else {
            // Should be caught earlier
            return filePath
        }

        if product.type.isFramework {
            return productPath + "Modules/\(filePath.path.lastComponent)"
        } else {
            return productPath.parent() + filePath.path.lastComponent
        }
    }
}
