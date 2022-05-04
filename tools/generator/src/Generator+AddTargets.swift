import PathKit
import XcodeProj

extension Generator {
    static func addTargets(
        in pbxProj: PBXProj,
        for disambiguatedTargets: [TargetID: DisambiguatedTarget],
        buildMode: BuildMode,
        products: Products,
        files: [FilePath: File],
        filePathResolver: FilePathResolver,
        bazelDependenciesTarget: PBXAggregateTarget?
    ) throws -> [TargetID: PBXTarget] {
        let pbxProject = pbxProj.rootObject!

        let sortedDisambiguatedTargets = disambiguatedTargets
            .sortedLocalizedStandard(\.value.name)
        var pbxTargets = Dictionary<TargetID, PBXTarget>(
            minimumCapacity: disambiguatedTargets.count
        )
        for (id, disambiguatedTarget) in sortedDisambiguatedTargets {
            let target = disambiguatedTarget.target
            let inputs = target.inputs
            let outputs = target.outputs
            let productType = target.product.type

            guard let product = products.byTarget[id] else {
                throw PreconditionError(message: """
Product for target "\(id)" not found in `products`
""")
            }

            let buildPhases = [
                try createCopyBazelOutputsScript(
                    in: pbxProj,
                    buildMode: buildMode,
                    product: target.product,
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
                    isSwift: target.isSwift,
                    buildSettings: target.buildSettings
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
                    resourceBundles: target.resourceBundles,
                    inputs: target.inputs,
                    products: products,
                    files: files
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
                product: product,
                productType: target.product.type
            )
            pbxProj.add(object: pbxTarget)
            pbxProject.targets.append(pbxTarget)
            pbxTargets[id] = pbxTarget

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
        product: Product,
        outputs: Outputs,
        filePathResolver: FilePathResolver
    ) throws -> PBXShellScriptBuildPhase? {
        guard
            buildMode.usesBazelModeBuildScripts,
            let copyCommand = try outputs.scriptCopyCommand(
                product: product,
                filePathResolver: filePathResolver
            )
        else {
            return nil
        }

        let script = PBXShellScriptBuildPhase(
            name: "Copy Bazel Outputs",
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
        inputs: Inputs,
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
        inputs: Inputs,
        outputs: Outputs,
        files: [FilePath: File]
    ) throws -> PBXSourcesBuildPhase? {
        let forcedBazelCompileFiles = outputs
            .forcedBazelCompileFiles(buildMode: buildMode)
        let sources = forcedBazelCompileFiles.map(SourceFile.init) +
            inputs.srcs.map(SourceFile.init) +
            inputs.nonArcSrcs.map { filePath in
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
        isSwift: Bool,
        buildSettings: [String: BuildSetting]
    ) throws -> PBXShellScriptBuildPhase? {
        guard
            isSwift,
            buildSettings["SWIFT_OBJC_INTERFACE_HEADER_NAME"] != .string("")
        else {
            return nil
        }

        let shellScript = PBXShellScriptBuildPhase(
            name: "Copy Swift Generated Header",
            inputPaths: [
                "$(DERIVED_FILE_DIR)/$(SWIFT_OBJC_INTERFACE_HEADER_NAME)",
            ],
            outputPaths: [
                "$(CONFIGURATION_BUILD_DIR)/$(SWIFT_OBJC_INTERFACE_HEADER_NAME)",
            ],
            shellScript: #"""
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
        resourceBundles: Set<FilePath>,
        inputs: Inputs,
        products: Products,
        files: [FilePath: File]
    ) throws -> PBXResourcesBuildPhase? {
        guard !buildMode.usesBazelModeBuildScripts
            && productType.isBundle
            && !(inputs.resources.isEmpty && resourceBundles.isEmpty)
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

        func productReference(filePath: FilePath) throws -> PBXFileReference {
            guard let reference = products.byFilePath[filePath] else {
                throw PreconditionError(message: """
Resource bundle product reference with file path "\(filePath)" not found in \
`products`
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
        let produceResources = try resourceBundles.map(productReference)
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
        switch `extension` {
        case "h": return true
        case "hh": return true
        case "hpp": return true
        default: return false
        }
    }
}

extension Outputs {
    func forcedBazelCompileFiles(buildMode: BuildMode) -> Set<FilePath> {
        guard buildMode.usesBazelModeBuildScripts else {
            return []
        }

        if swift != nil {
            return [.internal(Generator.bazelForcedSwiftCompilePath)]
        }

        return []
    }

    fileprivate var outputPaths: [String] {
        if swift != nil {
            return [
                "$(DERIVED_FILE_DIR)/\(Generator.bazelForcedSwiftCompilePath)",
            ]
        }

        return []
    }

    fileprivate func scriptCopyCommand(
        product: Product,
        filePathResolver: FilePathResolver
    ) throws -> String? {
        guard bundle != nil || swift != nil else {
            return nil
        }

        let commands = [
            try conditionalCopyCommand(
                product: product,
                filePathResolver: filePathResolver
            ),
            try swiftCopyCommand(filePathResolver: filePathResolver),
        ].compactMap { $0 }

        return #"""
set -euo pipefail

mkdir -p "$OBJECT_FILE_DIR-normal/$ARCHS"


"""# + commands.joined(separator: "\n")
    }

    fileprivate func conditionalCopyCommand(
        product: Product,
        filePathResolver: FilePathResolver
    ) throws -> String {
        return #"""
if [[ "$ACTION" == indexbuild ]]; then
  # Write to "$BAZEL_BUILD_OUTPUT_GROUPS_FILE" to allow next index to catch up
  echo "i $BAZEL_TARGET_ID" > "$BAZEL_BUILD_OUTPUT_GROUPS_FILE"
\#(try nonIndexCopyCommand(
    product: product,
    filePathResolver: filePathResolver
))\#
fi

"""#
    }

    private static func extractBundleCommand(
        outputPath: Path,
        bundlePathPrefix: String,
        bundlePath: String
    ) -> String {
        return #"""
  readonly archive="\#(outputPath)"
  readonly expanded_dest="$DERIVED_FILE_DIR/expanded_archive"
  readonly sha_output="$DERIVED_FILE_DIR/archive.sha256"

  existing_sha=$(cat "$sha_output" 2>/dev/null || true)
  sha=$(shasum -a 256 "$archive")

  if [[ "$existing_sha" != "$sha" || ! -d "$expanded_dest\#(bundlePathPrefix)/\#(bundlePath)" ]]; then
    mkdir -p "$expanded_dest"
    rm -rf "${expanded_dest:?}/"
    unzip -q "$archive" -d "$expanded_dest"
    echo "$sha" > "$sha_output"
  fi

  cd "$expanded_dest\#(bundlePathPrefix)"

"""#
    }

    private func nonIndexCopyCommand(
        product: Product,
        filePathResolver: FilePathResolver
    ) throws -> String {
        guard let bundle = bundle else {
            return ""
        }

        let outputPath = try filePathResolver
            .resolve(bundle, useOriginalGeneratedFiles: true, mode: .script)
        let bundlePath = product.path.path.lastComponent

        let extract: String
        switch bundle.path.extension {
        case "ipa":
            extract = Self.extractBundleCommand(
                outputPath: outputPath,
                bundlePathPrefix: "/Payload",
                bundlePath: bundlePath
            )
        case "zip":
            extract = Self.extractBundleCommand(
                outputPath: outputPath,
                bundlePathPrefix: "",
                bundlePath: bundlePath
            )
        default:
            extract = #"""
  cd "\#(outputPath.parent())"

"""#
        }

        let excludeList: String
        if product.type.isApplication {
            excludeList = #"""
    --exclude-from="\#(
try filePathResolver
    .resolve(.internal(Generator.appRsyncExcludeFileListPath), mode: .script)
    .string
)" \

"""#
        } else {
            excludeList = ""
        }

        return #"""
else
  # Copy bundle
\#(extract)\#
  rsync \
    --copy-links \
    --recursive \
    --times \
    --delete \
\#(excludeList)\#
    --chmod=u+w \
    --out-format="%n%L" \
    "\#(bundlePath)" \
    "$TARGET_BUILD_DIR"

"""#
    }

    private func swiftCopyCommand(
        filePathResolver: FilePathResolver
    ) throws -> String? {
        guard let swift = swift else {
            return nil
        }

        let copyGeneratedHeader: String
        if let generatedHeader = swift.generatedHeader {
            copyGeneratedHeader = #"""
# Copy generated header
mkdir -p "$OBJECT_FILE_DIR-normal/$ARCHS/${SWIFT_OBJC_INTERFACE_HEADER_NAME%/*}"
cp \
  "\#(try filePathResolver
    .resolve(
        generatedHeader,
        useOriginalGeneratedFiles: true,
        mode: .script
))" \
  "$OBJECT_FILE_DIR-normal/$ARCHS/$SWIFT_OBJC_INTERFACE_HEADER_NAME"
chmod u+w "$OBJECT_FILE_DIR-normal/$ARCHS/$SWIFT_OBJC_INTERFACE_HEADER_NAME"


"""#
        } else {
            copyGeneratedHeader = ""
        }

        return #"""
\#(copyGeneratedHeader)\#
# Copy swiftmodule
log="$(mktemp)"
rsync \
  \#(try swift
    .paths(filePathResolver: filePathResolver)
    .joined(separator: #" \\#n  "#)) \
  --times \
  --chmod=u+w \
  -L \
  --out-format="%n%L" \
  "$OBJECT_FILE_DIR-normal/$ARCHS" \
  | tee "$log"
if [[ -s "$log" ]]; then
  touch "$DERIVED_FILE_DIR/\#(Generator.bazelForcedSwiftCompilePath)"
fi

"""#
    }
}

private extension Outputs.Swift {
    func paths(filePathResolver: FilePathResolver) throws -> [String] {
        return try [
                module,
                doc,
                sourceInfo,
                interface,
            ]
            .compactMap { $0 }
            .map { filePath in
                return """
"\(try filePathResolver
    .resolve(filePath, useOriginalGeneratedFiles: true, mode: .script))"
"""
            }
    }
}
