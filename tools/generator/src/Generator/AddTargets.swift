import PathKit
import XcodeProj

extension Generator {
    static func addTargets(
        in pbxProj: PBXProj,
        for disambiguatedTargets: DisambiguatedTargets,
        buildMode: BuildMode,
        products: Products,
        files: [FilePath: File],
        filePathResolver: FilePathResolver,
        bazelDependenciesTarget: PBXAggregateTarget?
    ) throws -> [ConsolidatedTarget.Key: PBXTarget] {
        let pbxProject = pbxProj.rootObject!

        let sortedDisambiguatedTargets = disambiguatedTargets.targets
            .sortedLocalizedStandard(\.value.name)
        var pbxTargets = Dictionary<ConsolidatedTarget.Key, PBXTarget>(
            minimumCapacity: sortedDisambiguatedTargets.count
        )
        for (key, disambiguatedTarget) in sortedDisambiguatedTargets {
            let target = disambiguatedTarget.target
            let inputs = target.inputs
            let outputs = target.outputs
            let productType = target.product.type

            guard let product = products.byTarget[key] else {
                throw PreconditionError(message: """
Product for target "\(key)" not found in `products`
""")
            }

            let buildPhases = [
                try createCopyBazelOutputsScript(
                    in: pbxProj,
                    buildMode: buildMode,
                    productType: productType,
                    productBasename: target.product.basename,
                    outputs: outputs,
                    filePathResolver: filePathResolver
                ),
                try createHeadersPhase(
                    in: pbxProj,
                    productType: productType,
                    inputs: inputs,
                    files: files
                ),
                try createCompileSourcesPhase(
                    in: pbxProj,
                    buildMode: buildMode,
                    productType: productType,
                    inputs: inputs,
                    outputs: outputs,
                    files: files
                ),
                try createCopyGeneratedHeaderScript(
                    in: pbxProj,
                    generatesSwiftHeader: target.generatesSwiftHeader
                ),
                try createFrameworksPhase(
                    in: pbxProj,
                    frameworks: target.linkerInputs.frameworks,
                    files: files
                ),
                try createResourcesPhase(
                    in: pbxProj,
                    buildMode: buildMode,
                    productType: productType,
                    resourceBundleDependencies:
                        target.resourceBundleDependencies,
                    inputs: target.inputs,
                    products: products,
                    files: files,
                    targetKeys: disambiguatedTargets.keys
                ),
                try createEmbedFrameworksPhase(
                    in: pbxProj,
                    buildMode: buildMode,
                    productType: productType,
                    frameworks: target.linkerInputs.embeddable,
                    files: files
                ),
            ]

            let pbxTarget = PBXNativeTarget(
                name: disambiguatedTarget.name,
                buildPhases: buildPhases.compactMap { $0 },
                productName: target.product.name,
                product: productType.setsAssociatedProduct ?
                    product : nil,
                productType: productType
            )
            pbxProj.add(object: pbxTarget)
            pbxProject.targets.append(pbxTarget)
            pbxTargets[key] = pbxTarget

            if let bazelDependenciesTarget = bazelDependenciesTarget {
                _ = try pbxTarget.addDependency(target: bazelDependenciesTarget)
            }
        }

        if let bazelDependenciesTarget = bazelDependenciesTarget {
            pbxTargets[.bazelDependencies] = bazelDependenciesTarget
        }

        return pbxTargets
    }

    private static func createCopyBazelOutputsScript(
        in pbxProj: PBXProj,
        buildMode: BuildMode,
        productType: PBXProductType,
        productBasename: String,
        outputs: ConsolidatedTargetOutputs,
        filePathResolver: FilePathResolver
    ) throws -> PBXShellScriptBuildPhase? {
        guard
            buildMode.usesBazelModeBuildScripts,
            let copyCommand = try outputs.scriptCopyCommand(
                productType: productType,
                productBasename: productBasename,
                filePathResolver: filePathResolver
            )
        else {
            return nil
        }

        let inputPaths: [String]
        if productType.isBundle {
            inputPaths = ["$(TARGET_BUILD_DIR)/$(INFOPLIST_PATH)"]
        } else {
            inputPaths = []
        }

        let script = PBXShellScriptBuildPhase(
            name: "Copy Bazel Outputs",
            inputPaths: inputPaths,
            outputPaths: outputs.outputPaths,
            shellScript: copyCommand,
            showEnvVarsInLog: false,
            alwaysOutOfDate: true
        )
        pbxProj.add(object: script)

        return script
    }

    private static func createHeadersPhase(
        in pbxProj: PBXProj,
        productType: PBXProductType,
        inputs: ConsolidatedTargetInputs,
        files: [FilePath: File]
    ) throws -> PBXHeadersBuildPhase? {
        guard productType.isFramework else {
            return nil
        }

        let publicHeaders = inputs.hdrs
        let projectHeaders = Set(inputs.srcs).filter(\.path.isHeader)
            .union(Set(inputs.nonArcSrcs).filter(\.path.isHeader))
            .subtracting(publicHeaders)

        let publicHeaderFiles = publicHeaders.map { HeaderFile($0, .public) }
        let projectHeaderFiles = projectHeaders.map { HeaderFile($0, .project) }
        let headerFiles = Set(publicHeaderFiles + projectHeaderFiles)

        guard !headerFiles.isEmpty else {
            return nil
        }

        func buildFile(headerFile: HeaderFile) throws -> PBXBuildFile {
            guard let file = files[headerFile.filePath] else {
                throw PreconditionError(message: """
File "\(headerFile.filePath)" not found in `files`
""")
            }
            let pbxBuildFile = PBXBuildFile(
                file: file.fileElement,
                settings: headerFile.settings
            )
            pbxProj.add(object: pbxBuildFile)
            return pbxBuildFile
        }

        let buildPhase = PBXHeadersBuildPhase(
            files: try headerFiles.map(buildFile).sortedLocalizedStandard()
        )
        pbxProj.add(object: buildPhase)

        return buildPhase
    }

    private static func createCompileSourcesPhase(
        in pbxProj: PBXProj,
        buildMode: BuildMode,
        productType: PBXProductType,
        inputs: ConsolidatedTargetInputs,
        outputs: ConsolidatedTargetOutputs,
        files: [FilePath: File]
    ) throws -> PBXSourcesBuildPhase? {
        let forcedBazelCompileFiles = outputs
            .forcedBazelCompileFiles(buildMode: buildMode)
        let sources = forcedBazelCompileFiles.map(SourceFile.init) +
            inputs.srcs.excludingHeaders.map(SourceFile.init) +
            inputs.nonArcSrcs.excludingHeaders.map { filePath in
                return SourceFile(
                    filePath,
                    compilerFlags: ["-fno-objc-arc"]
                )
            }

        guard !sources.isEmpty || productType != .bundle else {
            return nil
        }

        func buildFile(sourceFile: SourceFile) throws -> PBXBuildFile {
            guard let file = files[sourceFile.filePath] else {
                throw PreconditionError(message: """
File "\(sourceFile.filePath)" not found in `files`
""")
            }
            let pbxBuildFile = PBXBuildFile(
                file: file.fileElement,
                settings: sourceFile.settings
            )
            pbxProj.add(object: pbxBuildFile)
            return pbxBuildFile
        }

        let sourceFiles: [SourceFile]
        if sources.isEmpty {
            sourceFiles = [SourceFile(.internal(compileStubPath))]
        } else {
            sourceFiles = sources
        }

        let buildPhase = PBXSourcesBuildPhase(
            files: try sourceFiles.map(buildFile)
        )
        pbxProj.add(object: buildPhase)

        return buildPhase
    }

    private static func createCopyGeneratedHeaderScript(
        in pbxProj: PBXProj,
        generatesSwiftHeader: Bool
    ) throws -> PBXShellScriptBuildPhase? {
        guard generatesSwiftHeader else {
            return nil
        }

        let shellScript = PBXShellScriptBuildPhase(
            name: "Copy Swift Generated Header",
            inputPaths: [
                "$(DERIVED_FILE_DIR)/$(SWIFT_OBJC_INTERFACE_HEADER_NAME)",
            ],
            outputPaths: [
                """
$(CONFIGURATION_BUILD_DIR)/$(SWIFT_OBJC_INTERFACE_HEADER_NAME)
""",
            ],
            shellScript: #"""
if [[ -z "${SWIFT_OBJC_INTERFACE_HEADER_NAME:-}" ]]; then
  exit 0
fi

cp "${SCRIPT_INPUT_FILE_0}" "${SCRIPT_OUTPUT_FILE_0}"

"""#,
            showEnvVarsInLog: false
        )
        pbxProj.add(object: shellScript)

        return shellScript
    }

    private static func createFrameworksPhase(
        in pbxProj: PBXProj,
        frameworks: [FilePath],
        files: [FilePath: File]
    ) throws -> PBXFrameworksBuildPhase? {
        guard !frameworks.isEmpty else {
            return nil
        }

        func buildFile(filePath: FilePath) throws -> PBXBuildFile {
            guard let framework = files[filePath] else {
                throw PreconditionError(message: """
Framework with file path "\(filePath)" not found in `files`
""")
            }
            guard let fileElement = framework.fileElement else {
                throw PreconditionError(message: """
Framework with file path "\(filePath)" had nil `PBXFileElement` in `files`
""")
            }
            let pbxBuildFile = PBXBuildFile(file: fileElement)
            pbxProj.add(object: pbxBuildFile)
            return pbxBuildFile
        }

        let buildPhase = PBXFrameworksBuildPhase(
            files: try frameworks.map(buildFile)
        )
        pbxProj.add(object: buildPhase)

        return buildPhase
    }

    private static func createResourcesPhase(
        in pbxProj: PBXProj,
        buildMode: BuildMode,
        productType: PBXProductType,
        resourceBundleDependencies: Set<TargetID>,
        inputs: ConsolidatedTargetInputs,
        products: Products,
        files: [FilePath: File],
        targetKeys: [TargetID: ConsolidatedTarget.Key]
    ) throws -> PBXResourcesBuildPhase? {
        guard !buildMode.usesBazelModeBuildScripts
            && productType.isBundle
            && !(inputs.resources.isEmpty && resourceBundleDependencies.isEmpty)
        else {
            return nil
        }

        func fileElement(filePath: FilePath) throws -> PBXFileElement {
            guard let resource = files[filePath] else {
                throw PreconditionError(message: """
Resource with file path "\(filePath)" not found in `files`
""")
            }
            guard let fileElement = resource.fileElement else {
                throw PreconditionError(message: """
Resource with file path "\(filePath)" had nil `PBXFileElement` in `files`
""")
            }
            return fileElement
        }

        func productReference(id: TargetID) throws -> PBXFileReference {
            guard let key = targetKeys[id] else {
                throw PreconditionError(message: """
Resource bundle product with id "\(id)" not found in `targetKeys`
""")
            }
            guard let reference = products.byTarget[key] else {
                throw PreconditionError(message: """
Resource bundle product reference with key \(key) not found in `products`
""")
            }
            return reference
        }

        func buildFile(fileElement: PBXFileElement) -> PBXBuildFile {
            let pbxBuildFile = PBXBuildFile(file: fileElement)
            pbxProj.add(object: pbxBuildFile)
            return pbxBuildFile
        }

        let nonProductResources = try inputs.resources.map(fileElement)
        let produceResources = try resourceBundleDependencies
            .map(productReference)
        let fileElements = Set(nonProductResources + produceResources)

        let buildPhase = PBXResourcesBuildPhase(
            files: fileElements.map(buildFile).sortedLocalizedStandard()
        )
        pbxProj.add(object: buildPhase)

        return buildPhase
    }

    private static func createEmbedFrameworksPhase(
        in pbxProj: PBXProj,
        buildMode: BuildMode,
        productType: PBXProductType,
        frameworks: [FilePath],
        files: [FilePath: File]
    ) throws -> PBXCopyFilesBuildPhase? {
        guard  !buildMode.usesBazelModeBuildScripts
            && productType.isBundle
            && !frameworks.isEmpty
        else {
            return nil
        }

        func buildFile(filePath: FilePath) throws -> PBXBuildFile {
            guard let framework = files[filePath] else {
                throw PreconditionError(message: """
Framework with file path "\(filePath)" not found in `files`
""")
            }
            guard let fileElement = framework.fileElement else {
                throw PreconditionError(message: """
Framework with file path "\(filePath)" had nil `PBXFileElement` in `files`
""")
            }
            let pbxBuildFile = PBXBuildFile(
                file: fileElement,
                settings: [
                    "ATTRIBUTES": ["CodeSignOnCopy", "RemoveHeadersOnCopy"],
                ]
            )
            pbxProj.add(object: pbxBuildFile)
            return pbxBuildFile
        }

        let buildPhase = PBXCopyFilesBuildPhase(
            dstPath: "",
            dstSubfolderSpec: .frameworks,
            name: "Embed Frameworks",
            files: try frameworks.map(buildFile)
        )
        pbxProj.add(object: buildPhase)

        return buildPhase
    }
}

private extension Sequence where Element == FilePath {
    var excludingHeaders: [Element] {
        self.filter { !$0.path.isHeader }
    }
}

private struct HeaderFile: Hashable {
    enum Visibility {
        case `public`
        case project
    }

    let filePath: FilePath
    let visibility: Visibility

    init(_ filePath: FilePath, _ visibility: Visibility) {
        self.filePath = filePath
        self.visibility = visibility
    }

    var settings: [String: Any]? {
        switch visibility {
        case .public:
            // We don't use `BuildSetting.array` here, because Xcode uses an
            // array even for a single item, while `BuildSetting.array` will
            // turn that into a string.
            return ["ATTRIBUTES": ["Public"]]
        case .project:
            return nil
        }
    }
}

private struct SourceFile: Hashable {
    let filePath: FilePath
    let compilerFlags: [String]?

    init(_ filePath: FilePath) {
        self.init(filePath, compilerFlags: nil)
    }

    init(_ filePath: FilePath, compilerFlags: [String]?) {
        self.filePath = filePath
        self.compilerFlags = compilerFlags
    }

    var settings: [String: Any]? {
        return compilerFlags.flatMap { flags in
            return ["COMPILER_FLAGS": BuildSetting.array(flags).asAny]
        }
    }
}

private extension Path {
    var isHeader: Bool {
        if let ext = `extension` {
            return Xcode.headersExtensions.contains(".\(ext)")
        } else {
            return false
        }
    }
}

private extension ConsolidatedTarget {
    var generatesSwiftHeader: Bool {
        guard isSwift else {
            return false
        }

        return targets.values.contains { target in
            guard let headerBuildSetting = target
                .buildSettings["SWIFT_OBJC_INTERFACE_HEADER_NAME"]
            else {
                // Not setting `SWIFT_OBJC_INTERFACE_HEADER_NAME` will cause
                // the default `ModuleName-Swift.h` to be generated
                return true
            }
            return headerBuildSetting != .string("")
        }
    }
}

private extension ConsolidatedTargetLinkerInputs {
    var frameworks: [FilePath] {
        return staticFrameworks + dynamicFrameworks
    }

    var embeddable: [FilePath] {
        return dynamicFrameworks
    }
}

private extension ConsolidatedTargetOutputs {
    func forcedBazelCompileFiles(buildMode: BuildMode) -> Set<FilePath> {
        if buildMode.usesBazelModeBuildScripts && hasSwiftOutputs {
            return [.internal(Generator.bazelForcedSwiftCompilePath)]
        }

        return []
    }

    var outputPaths: [String] {
        if hasSwiftOutputs {
            return [
                "$(DERIVED_FILE_DIR)/\(Generator.bazelForcedSwiftCompilePath)",
            ]
        }

        return []
    }

    func scriptCopyCommand(
        productType: PBXProductType,
        productBasename: String,
        filePathResolver: FilePathResolver
    ) throws -> String? {
        guard hasOutputs else {
            return nil
        }

        let excludeList: String
        if productType.isApplication {
            excludeList = try filePathResolver.resolve(
                .internal(Generator.appRsyncExcludeFileListPath),
                mode: .script
            )
            .string
        } else {
            excludeList = ""
        }

        return #"""
set -euo pipefail

"$BAZEL_INTEGRATION_DIR/copy_outputs.sh" \
  "\#(Generator.bazelForcedSwiftCompilePath)" \
  "\#(productBasename)" \
  "\#(excludeList)"

"""#
    }
}
