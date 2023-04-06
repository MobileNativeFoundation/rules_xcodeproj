import PathKit
import XcodeProj

extension Generator {
    static func addTargets(
        in pbxProj: PBXProj,
        for disambiguatedTargets: DisambiguatedTargets,
        buildMode: BuildMode,
        products: Products,
        files: [FilePath: File],
        compileStub: PBXFileReference?
    ) async throws -> [ConsolidatedTarget.Key: PBXNativeTarget] {
        return try await withThrowingTaskGroup(
            of: (ConsolidatedTarget.Key, PBXNativeTarget).self
        ) { group in
            let targets = disambiguatedTargets.targets

            for (key, disambiguatedTarget) in targets {
                group.addTask {
                    return try (
                        key,
                        addTarget(
                            in: pbxProj,
                            for: disambiguatedTarget,
                            key: key,
                            targetKeys: disambiguatedTargets.keys,
                            buildMode: buildMode,
                            products: products,
                            files: files,
                            compileStub: compileStub
                        )
                    )
                }
            }

            var pbxTargets = [ConsolidatedTarget.Key: PBXNativeTarget](
                minimumCapacity: targets.count
            )
            for try await (key, pbxTarget) in group {
                pbxTargets[key] = pbxTarget
            }

            pbxProj.rootObject!.targets.append(
                contentsOf: pbxTargets.values.sortedLocalizedStandard(\.name)
            )

            return pbxTargets
        }
    }

    private static func addTarget(
        in pbxProj: PBXProj,
        for disambiguatedTarget: DisambiguatedTarget,
        key: ConsolidatedTarget.Key,
        targetKeys: [TargetID: ConsolidatedTarget.Key],
        buildMode: BuildMode,
        products: Products,
        files: [FilePath: File],
        compileStub: PBXFileReference?
    ) throws -> PBXNativeTarget {
        let target = disambiguatedTarget.target
        let inputs = target.inputs
        let outputs = target.outputs
        let productType = target.product.type

        let compileSources: (phase: PBXSourcesBuildPhase, hasCompileStub: Bool)?
        let product: PBXFileReference?
        if target.product.basename != nil {
            guard let actualProduct = products.byTarget[key] else {
                throw PreconditionError(message: """
Product for target "\(key)" not found in `products`
""")
            }
            product = actualProduct
            compileSources = try createCompileSourcesPhase(
                in: pbxProj,
                buildMode: buildMode,
                productType: productType,
                inputs: inputs,
                outputs: outputs,
                files: files,
                compileStub: compileStub
            )
        } else {
            product = nil
            compileSources = nil
        }

        let buildPhases = [
            try createBazelDependenciesScript(
                in: pbxProj,
                buildMode: buildMode,
                productType: productType,
                isResourceBundle: target.product.isResourceBundle,
                outputs: outputs
            ),
            try createCompilingDependenciesScript(
                in: pbxProj,
                buildMode: buildMode,
                hasClangSearchPaths: target.hasClangSearchPaths,
                files: files
            ),
            try createLinkingDependenciesScript(
                in: pbxProj,
                buildMode: buildMode,
                hasCompileStub: compileSources?.hasCompileStub == true,
                hasLinkParams: target.hasLinkParams
            ),
            try createHeadersPhase(
                in: pbxProj,
                productType: productType,
                inputs: inputs,
                files: files
            ),
            compileSources?.phase,
            try createCopyGeneratedHeaderScript(
                in: pbxProj,
                buildMode: buildMode,
                generatesSwiftHeader: target.generatesSwiftHeader
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
                targetKeys: targetKeys
            ),
            try createEmbedFrameworksPhase(
                in: pbxProj,
                buildMode: buildMode,
                productType: productType,
                frameworks: target.linkerInputs.embeddable,
                products: products,
                files: files
            ),
            try createEmbedWatchContentPhase(
                in: pbxProj,
                buildMode: buildMode,
                productType: productType,
                watchApplication: target.watchApplication,
                products: products,
                targetKeys: targetKeys
            ),
            try createEmbedAppExtensionsPhase(
                in: pbxProj,
                buildMode: buildMode,
                productType: productType,
                extensions: target.extensions,
                products: products,
                targetKeys: targetKeys
            ),
            try createEmbedAppClipsPhase(
                in: pbxProj,
                buildMode: buildMode,
                productType: productType,
                appClips: target.appClips,
                products: products,
                targetKeys: targetKeys
            ),
        ]

        let pbxTarget = PBXNativeTarget(
            name: disambiguatedTarget.name,
            buildPhases: buildPhases.compactMap { $0 },
            productName: target.product.name,
            product: productType.setsAssociatedProduct ?
                product : nil,
            productType: productType.forXcode
        )
        pbxProj.add(object: pbxTarget)

        return pbxTarget
    }

    private static func createBazelDependenciesScript(
        in pbxProj: PBXProj,
        buildMode: BuildMode,
        productType: PBXProductType,
        isResourceBundle: Bool,
        outputs: ConsolidatedTargetOutputs
    ) throws -> PBXShellScriptBuildPhase? {
        guard buildMode.usesBazelModeBuildScripts, !isResourceBundle else {
            return nil
        }

        let copyOutputs: String
        if let bazelBasename = outputs.productBasename {
            copyOutputs = #"""
else
  "$BAZEL_INTEGRATION_DIR/copy_outputs.sh" \
    "\#(Generator.bazelForcedSwiftCompilePath)" \
    "\#(bazelBasename)" \
    "\#(productType.rsyncExcludeFile)"
"""#
        } else {
            copyOutputs = ""
        }

        let shellScript = #"""
set -euo pipefail

if [[ "$ACTION" == "indexbuild" ]]; then
  cd "$SRCROOT"

  "$BAZEL_INTEGRATION_DIR/generate_index_build_bazel_dependencies.sh"
\#(copyOutputs)
fi

"""#

        let inputPaths: [String]
        if productType.isBundle {
            inputPaths = ["$(TARGET_BUILD_DIR)/$(INFOPLIST_PATH)"]
        } else {
            inputPaths = []
        }

        let script = PBXShellScriptBuildPhase(
            name: """
Copy Bazel Outputs / Generate Bazel Dependencies (Index Build)
""",
            inputPaths: inputPaths,
            outputPaths: outputs.outputPaths,
            shellScript: shellScript,
            showEnvVarsInLog: false,
            alwaysOutOfDate: true
        )
        pbxProj.add(object: script)

        return script
    }

    private static func createCompilingDependenciesScript(
        in pbxProj: PBXProj,
        buildMode: BuildMode,
        hasClangSearchPaths: Bool,
        files _: [FilePath: File]
    ) throws -> PBXShellScriptBuildPhase? {
        guard buildMode == .xcode, hasClangSearchPaths else {
            return nil
        }

        let script = PBXShellScriptBuildPhase(
            name: "Create compiling dependencies",
            inputPaths: ["$(BAZEL_INTEGRATION_DIR)/create_xcode_overlay.sh"],
            outputPaths: ["$(DERIVED_FILE_DIR)/xcode-overlay.yaml"],
            shellScript: "\"$SCRIPT_INPUT_FILE_0\"\n",
            showEnvVarsInLog: false
        )
        pbxProj.add(object: script)

        return script
    }

    private static func createLinkingDependenciesScript(
        in pbxProj: PBXProj,
        buildMode: BuildMode,
        hasCompileStub: Bool,
        hasLinkParams: Bool
    ) throws -> PBXShellScriptBuildPhase? {
        guard hasLinkParams else {
            return nil
        }

        let action = #"""
perl -pe 's/^("?)(.*\$\(.*\).*?)("?)$/"$2"/ ; s/\$(\()?([a-zA-Z_]\w*)(?(1)\))/$ENV{$2}/g' \
  "$SCRIPT_INPUT_FILE_0" > "$SCRIPT_OUTPUT_FILE_0"
"""#
        var shellScriptComponents: [String]
        if buildMode == .xcode {
            shellScriptComponents = [
                #"""
set -euo pipefail

\#(action)

"""#,
            ]
        } else {
            shellScriptComponents = [
                #"""
set -euo pipefail

if [[ "${ENABLE_PREVIEWS:-}" == "YES" ]]; then
\#(action)
else
  touch "$SCRIPT_OUTPUT_FILE_0"
fi

"""#,
            ]
        }

        var outputsPaths = ["$(DERIVED_FILE_DIR)/link.params"]
        if hasCompileStub {
            outputsPaths.append("$(DERIVED_FILE_DIR)/_CompileStub_.m")
            shellScriptComponents.append(#"""
touch "$SCRIPT_OUTPUT_FILE_1"

"""#)
        }

        let script = PBXShellScriptBuildPhase(
            name: "Create linking dependencies",
            inputPaths: ["$(LINK_PARAMS_FILE)"],
            outputPaths: outputsPaths,
            shellScript: shellScriptComponents.joined(separator: "\n"),
            showEnvVarsInLog: false
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

        let buildPhase = try PBXHeadersBuildPhase(
            files: headerFiles.map(buildFile).sortedLocalizedStandard()
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
        files: [FilePath: File],
        compileStub: PBXFileReference?
    ) throws -> (phase: PBXSourcesBuildPhase, hasCompileStub: Bool)? {
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

        guard productType.hasCompilePhase else {
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

        let hasCompileStub = sources.isEmpty

        let buildFiles: [PBXBuildFile]
        if hasCompileStub {
            guard let compileStub = compileStub else {
                throw PreconditionError(message: "`compileStub` is nil")
            }

            let compileStubBuildFile = PBXBuildFile(file: compileStub)
            pbxProj.add(object: compileStubBuildFile)
            buildFiles = [compileStubBuildFile]
        } else {
            buildFiles = try sources.map(buildFile)
        }

        let buildPhase = PBXSourcesBuildPhase(files: buildFiles)
        pbxProj.add(object: buildPhase)

        return (buildPhase, hasCompileStub)
    }

    private static func createCopyGeneratedHeaderScript(
        in pbxProj: PBXProj,
        buildMode: BuildMode,
        generatesSwiftHeader: Bool
    ) throws -> PBXShellScriptBuildPhase? {
        guard buildMode == .xcode, generatesSwiftHeader else {
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
        guard !buildMode.usesBazelModeBuildScripts,
            productType.isBundle,
            !(inputs.resources.isEmpty && resourceBundleDependencies.isEmpty)
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
        products: Products,
        files: [FilePath: File]
    ) throws -> PBXCopyFilesBuildPhase? {
        guard !buildMode.usesBazelModeBuildScripts,
            productType.embedsFrameworks,
            !frameworks.isEmpty
        else {
            return nil
        }

        func fileElement(filePath: FilePath) throws -> PBXFileElement {
            if let fileElement = products.byFilePath[filePath] {
                return fileElement
            }
            guard let framework = files[filePath] else {
                throw PreconditionError(message: """
Framework with file path "\(filePath)" not found in `products` or `files`
""")
            }
            guard let fileElement = framework.fileElement else {
                throw PreconditionError(message: """
Framework with file path "\(filePath)" had nil `PBXFileElement` in `files`
""")
            }
            return fileElement
        }

        func buildFile(fileElement: PBXFileElement) throws -> PBXBuildFile {
            let pbxBuildFile = PBXBuildFile(
                file: fileElement,
                settings: [
                    "ATTRIBUTES": ["CodeSignOnCopy", "RemoveHeadersOnCopy"],
                ]
            )
            pbxProj.add(object: pbxBuildFile)
            return pbxBuildFile
        }

        let buildPhase = try PBXCopyFilesBuildPhase(
            dstPath: "",
            dstSubfolderSpec: .frameworks,
            name: "Embed Frameworks",
            files: frameworks.map(fileElement).uniqued().map(buildFile)
        )
        pbxProj.add(object: buildPhase)

        return buildPhase
    }

    private static func createEmbedWatchContentPhase(
        in pbxProj: PBXProj,
        buildMode: BuildMode,
        productType: PBXProductType,
        watchApplication: TargetID?,
        products: Products,
        targetKeys: [TargetID: ConsolidatedTarget.Key]
    ) throws -> PBXCopyFilesBuildPhase? {
        guard !buildMode.usesBazelModeBuildScripts,
              let watchApplication = watchApplication,
              productType.isBundle
        else {
            return nil
        }

        func buildFile(id: TargetID) throws -> PBXBuildFile {
            guard let key = targetKeys[id] else {
                throw PreconditionError(message: """
Watch application product with id "\(id)" not found in `targetKeys`
""")
            }
            guard let reference = products.byTarget[key] else {
                throw PreconditionError(message: """
Watch application product reference with key \(key) not found in `products`
""")
            }

            let pbxBuildFile = PBXBuildFile(
                file: reference,
                settings: [
                    "ATTRIBUTES": ["RemoveHeadersOnCopy"],
                ]
            )
            pbxProj.add(object: pbxBuildFile)
            return pbxBuildFile
        }

        let buildPhase = PBXCopyFilesBuildPhase(
            dstPath: "$(CONTENTS_FOLDER_PATH)/Watch",
            dstSubfolderSpec: .productsDirectory,
            name: "Embed Watch Content",
            files: [try buildFile(id: watchApplication)]
        )
        pbxProj.add(object: buildPhase)

        return buildPhase
    }

    private static func createEmbedAppExtensionsPhase(
        in pbxProj: PBXProj,
        buildMode: BuildMode,
        productType: PBXProductType,
        extensions: Set<TargetID>,
        products: Products,
        targetKeys: [TargetID: ConsolidatedTarget.Key]
    ) throws -> PBXCopyFilesBuildPhase? {
        guard !buildMode.usesBazelModeBuildScripts || productType == .watch2App,
              !extensions.isEmpty,
              productType.isBundle
        else {
            return nil
        }

        func buildFile(id: TargetID) throws -> PBXBuildFile {
            guard let key = targetKeys[id] else {
                throw PreconditionError(message: """
App extension product with id "\(id)" not found in `targetKeys`
""")
            }
            guard let reference = products.byTarget[key] else {
                throw PreconditionError(message: """
App extension product reference with key \(key) not found in `products`
""")
            }

            let pbxBuildFile = PBXBuildFile(
                file: reference,
                settings: [
                    "ATTRIBUTES": ["RemoveHeadersOnCopy"],
                ]
            )
            pbxProj.add(object: pbxBuildFile)
            return pbxBuildFile
        }

        let buildPhase = try PBXCopyFilesBuildPhase(
            dstPath: "",
            dstSubfolderSpec: .plugins,
            name: "Embed App Extensions",
            files: extensions.map(buildFile)
        )
        pbxProj.add(object: buildPhase)

        return buildPhase
    }

    private static func createEmbedAppClipsPhase(
        in pbxProj: PBXProj,
        buildMode: BuildMode,
        productType: PBXProductType,
        appClips: Set<TargetID>,
        products: Products,
        targetKeys: [TargetID: ConsolidatedTarget.Key]
    ) throws -> PBXCopyFilesBuildPhase? {
        guard !buildMode.usesBazelModeBuildScripts,
              !appClips.isEmpty,
              productType.isBundle
        else {
            return nil
        }

        func buildFile(id: TargetID) throws -> PBXBuildFile {
            guard let key = targetKeys[id] else {
                throw PreconditionError(message: """
App clip product with id "\(id)" not found in `targetKeys`
""")
            }
            guard let reference = products.byTarget[key] else {
                throw PreconditionError(message: """
App clip product reference with key \(key) not found in `products`
""")
            }

            let pbxBuildFile = PBXBuildFile(
                file: reference,
                settings: [
                    "ATTRIBUTES": ["RemoveHeadersOnCopy"],
                ]
            )
            pbxProj.add(object: pbxBuildFile)
            return pbxBuildFile
        }

        let buildPhase = try PBXCopyFilesBuildPhase(
            dstPath: "$(CONTENTS_FOLDER_PATH)/AppClips",
            dstSubfolderSpec: .productsDirectory,
            name: "Embed App Clips",
            files: appClips.map(buildFile)
        )
        pbxProj.add(object: buildPhase)

        return buildPhase
    }
}

private extension Sequence where Element == FilePath {
    var excludingHeaders: [Element] {
        filter { !$0.path.isHeader }
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
    var embeddable: [FilePath] {
        return dynamicFrameworks
    }
}

private extension ConsolidatedTargetOutputs {
    func forcedBazelCompileFiles(buildMode _: BuildMode) -> Set<FilePath> {
        // TODO: Re-enable for Swift diagnostics replay
//        if buildMode.usesBazelModeBuildScripts, hasSwiftOutputs {
//            return [.internal(Generator.bazelForcedSwiftCompilePath)]
//        }

        return []
    }

    var outputPaths: [String] {
        // TODO: Re-enable for Swift diagnostics replay
//        if hasSwiftOutputs {
//            return [
//                "$(DERIVED_FILE_DIR)/\(Generator.bazelForcedSwiftCompilePath)",
//            ]
//        }

        return []
    }
}

private extension PBXProductType {
    var rsyncExcludeFile: String {
        switch self {
        case .application,
            .messagesApplication,
            .onDemandInstallCapableApplication,
            .watch2AppContainer:
            return "$BAZEL_INTEGRATION_DIR/app.exclude.rsynclist"
        case .framework:
            return "$BAZEL_INTEGRATION_DIR/framework.exclude.rsynclist"
        case .unitTestBundle,
            .uiTestBundle:
            return "$BAZEL_INTEGRATION_DIR/xctest.exclude.rsynclist"
        case .appExtension,
            .extensionKitExtension,
            .intentsServiceExtension,
            .messagesExtension,
            .tvExtension,
            .watch2Extension:
            return "$BAZEL_INTEGRATION_DIR/appex.exclude.rsynclist"
        case .watch2App:
            return "$BAZEL_INTEGRATION_DIR/watchos2_app.exclude.rsynclist"
        default:
            return ""
        }
    }
}
