import PathKit
import XcodeProj

extension Generator {
    static func addTargets(
        in pbxProj: PBXProj,
        for disambiguatedTargets: [TargetID: DisambiguatedTarget],
        products: Products,
        files: [FilePath: File],
        filePathResolver: FilePathResolver,
        xcodeprojBazelLabel: String
    ) throws -> [TargetID: PBXNativeTarget] {
        let pbxProject = pbxProj.rootObject!

        let generatedFilesTarget = try createGeneratedFilesTarget(
            in: pbxProj,
            files: files,
            filePathResolver: filePathResolver,
            xcodeprojBazelLabel: xcodeprojBazelLabel
        )

        let sortedDisambiguatedTargets = disambiguatedTargets
            .sortedLocalizedStandard(\.value.name)
        var pbxTargets = Dictionary<TargetID, PBXNativeTarget>(
            minimumCapacity: disambiguatedTargets.count
        )
        for (id, disambiguatedTarget) in sortedDisambiguatedTargets {
            let target = disambiguatedTarget.target
            let inputs = target.inputs
            let productType = target.product.type

            guard let product = products.byTarget[id] else {
                throw PreconditionError(message: """
Product for target "\(id)" not found in `products`
""")
            }

            let buildPhases = [
                try createHeadersPhase(
                    in: pbxProj,
                    productType: productType,
                    inputs: inputs,
                    files: files
                ),
                try createCompileSourcesPhase(
                    in: pbxProj,
                    productType: productType,
                    inputs: inputs,
                    files: files
                ),
                try createCopyGeneratedHeaderScript(
                    in: pbxProj,
                    isSwift: target.isSwift,
                    buildSettings: target.buildSettings
                ),
                try createFrameworksPhase(
                    in: pbxProj,
                    frameworks: target.frameworks,
                    files: files
                ),
                try createResourcesPhase(
                    in: pbxProj,
                    productType: productType,
                    resourceBundles: target.resourceBundles,
                    inputs: target.inputs,
                    products: products,
                    files: files
                ),
                try createEmbedFrameworksPhase(
                    in: pbxProj,
                    productType: productType,
                    frameworks: target.frameworks,
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

            if
                target.inputs.containsGeneratedFiles,
                let generatedFilesTarget = generatedFilesTarget
            {
                _ = try pbxTarget.addDependency(target: generatedFilesTarget)
            }
        }

        return pbxTargets
    }

    private static func createGeneratedFilesTarget(
        in pbxProj: PBXProj,
        files: [FilePath: File],
        filePathResolver: FilePathResolver,
        xcodeprojBazelLabel: String
    ) throws -> PBXAggregateTarget? {
        guard files.containsGeneratedFiles else {
            return nil
        }

        let pbxProject = pbxProj.rootObject!

        let debugConfiguration = XCBuildConfiguration(
            name: "Debug",
            buildSettings: ["BAZEL_PACKAGE_BIN_DIR": "BazelGeneratedFiles"]
        )
        pbxProj.add(object: debugConfiguration)
        let configurationList = XCConfigurationList(
            buildConfigurations: [debugConfiguration],
            defaultConfigurationName: debugConfiguration.name
        )
        pbxProj.add(object: configurationList)

        let generateFilesScript = PBXShellScriptBuildPhase(
            name: "Generate Files",
            outputFileListPaths: [
                filePathResolver
                    .resolve(.internal(generatedFileListPath))
                    .string,
            ],
            shellScript: #"""
set -eu

PATH="${PATH//\/usr\/local\/bin//opt/homebrew/bin:/usr/local/bin}" \
  ${BAZEL_PATH} \
  build \
  --output_groups=generated_inputs \
  \#(xcodeprojBazelLabel)

"""#,
            showEnvVarsInLog: false,
            alwaysOutOfDate: true
        )
        pbxProj.add(object: generateFilesScript)

        let copyFilesScript = PBXShellScriptBuildPhase(
            name: "Copy Files",
            inputFileListPaths: [
                filePathResolver
                    .resolve(.internal(generatedFileListPath))
                    .string,
            ],
            outputFileListPaths: [
                filePathResolver
                    .resolve(.internal(copiedGeneratedFileListPath))
                    .string,
            ],
            shellScript: #"""
set -eu

cd "\#(filePathResolver.generatedDirectory)"

rsync \
  --files-from "\#(
    filePathResolver
        .resolve(.internal(rsyncFileListPath), useScriptVariables: true)
        .string
)" \
  -L \
  . \
  "$BUILD_DIR/bazel-out"

cd "$PROJECT_FILE_PATH/rules_xcodeproj"

# Need to remove the directory that Xcode creates as part of output prep
rm -rf gen_dir

ln -sf "$BUILD_DIR/bazel-out" gen_dir

"""#,
            showEnvVarsInLog: false
        )
        pbxProj.add(object: copyFilesScript)

        let fixModuleMapsScript = PBXShellScriptBuildPhase(
            name: "Fix Modulemaps",
            inputFileListPaths: [
                filePathResolver
                    .resolve(.internal(modulemapsFileListPath))
                    .string,
            ],
            outputFileListPaths: [
                filePathResolver
                    .resolve(.internal(fixedModulemapsFileListPath))
                    .string,
            ],
            shellScript: #"""
set -eu

while IFS= read -r input; do
  output="${input%.modulemap}.xcode.modulemap"
  perl -p -e \
    's%^(    *(\w )*header "(\.\.\/)*)(((?!(bazel-out|external)).)*")%\1SRCROOT/\4%' \
    < "$input" \
    > "$output"
done < "$SCRIPT_INPUT_FILE_LIST_0"

cd "$BUILD_DIR"
ln -sfn "$PROJECT_DIR" SRCROOT
ln -sfn "\#(
    filePathResolver.resolve(.external(""), useScriptVariables: true)
)" external

"""#,
            showEnvVarsInLog: false
        )
        pbxProj.add(object: fixModuleMapsScript)

        let pbxTarget = PBXAggregateTarget(
            name: "Bazel Generated Files",
            buildConfigurationList: configurationList,
            buildPhases: [
                generateFilesScript,
                copyFilesScript,
                fixModuleMapsScript,
            ],
            productName: "Bazel Generated Files"
        )
        pbxProj.add(object: pbxTarget)
        pbxProject.targets.append(pbxTarget)

        let attributes: [String: Any] = [
            // TODO: Generate this value
            "CreatedOnToolsVersion": "13.2.1",
        ]
        pbxProject.setTargetAttributes(attributes, target: pbxTarget)

        return pbxTarget
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
        let projectHeaders = inputs.srcs.filter(\.path.isHeader)
            .union(inputs.nonArcSrcs.filter(\.path.isHeader))
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
        productType: PBXProductType,
        inputs: Inputs,
        files: [FilePath: File]
    ) throws -> PBXSourcesBuildPhase? {
        let sources = Set(
            inputs.srcs.map(SourceFile.init)
            + inputs.nonArcSrcs.map { filePath in
                return SourceFile(
                    filePath,
                    compilerFlags: ["-fno-objc-arc"]
                )
            }
        )

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

        let sourceFiles: Set<SourceFile>
        if sources.isEmpty {
            sourceFiles = [SourceFile(.internal(compileStubPath))]
        } else {
            sourceFiles = sources
        }

        let buildPhase = PBXSourcesBuildPhase(
            files: try sourceFiles.map(buildFile).sortedLocalizedStandard()
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
        productType: PBXProductType,
        resourceBundles: Set<Path>,
        inputs: Inputs,
        products: Products,
        files: [FilePath: File]
    ) throws -> PBXResourcesBuildPhase? {
        guard productType.isBundle
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

        func productReference(path: Path) throws -> PBXFileReference {
            guard let reference = products.byPath[path] else {
                throw PreconditionError(message: """
Resource bundle product reference with path "\(path)" not found in `products`
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
        productType: PBXProductType,
        frameworks: [FilePath],
        files: [FilePath: File]
    ) throws -> PBXCopyFilesBuildPhase? {
        guard productType.isBundle && !frameworks.isEmpty else {
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

extension Inputs {
    var containsSourceFiles: Bool {
        return !(srcs.isEmpty && nonArcSrcs.isEmpty)
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
