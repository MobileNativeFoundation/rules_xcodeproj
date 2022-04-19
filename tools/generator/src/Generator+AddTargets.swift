import PathKit
import XcodeProj

extension Generator {
    // Xcode likes this list as a string, and apparently in reverse
    static let allPlatforms = """
watchsimulator \
watchos \
macosx \
iphonesimulator \
iphoneos \
driverkit \
appletvsimulator \
appletvos
"""

    static let bazelExec = #"""
env -i \
  DEVELOPER_DIR="$DEVELOPER_DIR" \
  HOME="$HOME" \
  PATH="${PATH//\/usr\/local\/bin//opt/homebrew/bin:/usr/local/bin}" \
  USER="$USER" \
  "$BAZEL_PATH"
"""#

    static func addTargets(
        in pbxProj: PBXProj,
        for disambiguatedTargets: [TargetID: DisambiguatedTarget],
        products: Products,
        files: [FilePath: File],
        filePathResolver: FilePathResolver,
        xcodeprojBazelLabel: String
    ) throws -> [TargetID: PBXNativeTarget] {
        let pbxProject = pbxProj.rootObject!

        let setupTarget = try createSetupTarget(
            in: pbxProj,
            filePathResolver: filePathResolver
        )

        let generatedFilesTarget = try createGeneratedFilesTarget(
            in: pbxProj,
            files: files,
            filePathResolver: filePathResolver,
            xcodeprojBazelLabel: xcodeprojBazelLabel,
            setupTarget: setupTarget
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

            let frameworkLinks = target.links.filter { $0.type != .generated }
                + target.frameworks

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
                    frameworks: frameworkLinks,
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
            } else {
                _ = try pbxTarget.addDependency(target: setupTarget)
            }
        }

        return pbxTargets
    }

    private static func createSetupTarget(
        in pbxProj: PBXProj,
        filePathResolver: FilePathResolver
    ) throws -> PBXAggregateTarget {
        let pbxProject = pbxProj.rootObject!

        let debugConfiguration = XCBuildConfiguration(
            name: "Debug",
            buildSettings: [
                "ALLOW_TARGET_PLATFORM_SPECIALIZATION": true,
                "BAZEL_PACKAGE_BIN_DIR": "rules_xcodeproj",
                "INDEX_FORCE_SCRIPT_EXECUTION": true,
                "SUPPORTED_PLATFORMS": allPlatforms,
                "SUPPORTS_MACCATALYST": true,
                "TARGET_NAME": "Setup",
            ]
        )
        pbxProj.add(object: debugConfiguration)
        let configurationList = XCConfigurationList(
            buildConfigurations: [debugConfiguration],
            defaultConfigurationName: debugConfiguration.name
        )
        pbxProj.add(object: configurationList)

        let script = PBXShellScriptBuildPhase(
            shellScript: #"""
set -eu

output_path=$(\#(bazelExec) \
  info \
  output_path)
external="${output_path%/*/*/*}/external"

mkdir -p "$LINKS_DIR"
cd "$LINKS_DIR"

# Add BUILD and DONT_FOLLOW_SYMLINKS_WHEN_TRAVERSING_THIS_DIRECTORY_VIA_A_RECURSIVE_TARGET_PATTERN
# files to the internal links directory to prevent Bazel from recursing into it,
# and thus following the `external` and `bazel-out` symlinks
touch BUILD
touch DONT_FOLLOW_SYMLINKS_WHEN_TRAVERSING_THIS_DIRECTORY_VIA_A_RECURSIVE_TARGET_PATTERN

# Need to remove the directory that Xcode creates as part of output prep
rm -rf gen_dir

ln -sfn "$output_path" bazel-out
ln -sfn "$external" external
ln -sfn "$BUILD_DIR/bazel-out" gen_dir

cd "$BUILD_DIR"
ln -sfn "$PROJECT_DIR" SRCROOT
ln -sfn "$external" external

# Create parent directories of generated files, so the project navigator works
# better faster

mkdir -p bazel-out
cd bazel-out

sed 's|\/[^\/]*$||' \
  "\#(
  filePathResolver
      .resolve(.internal(rsyncFileListPath), useScriptVariables: true)
      .string
)" \
  | uniq \
  | while IFS= read -r dir
do
  mkdir -p "$dir"
done

"""#,
            showEnvVarsInLog: false,
            alwaysOutOfDate: true
        )
        pbxProj.add(object: script)

        let pbxTarget = PBXAggregateTarget(
            name: "Setup",
            buildConfigurationList: configurationList,
            buildPhases: [script],
            productName: "Setup"
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

    private static func createGeneratedFilesTarget(
        in pbxProj: PBXProj,
        files: [FilePath: File],
        filePathResolver: FilePathResolver,
        xcodeprojBazelLabel: String,
        setupTarget: PBXAggregateTarget
    ) throws -> PBXAggregateTarget? {
        guard files.containsGeneratedFiles else {
            return nil
        }

        let pbxProject = pbxProj.rootObject!

        let debugConfiguration = XCBuildConfiguration(
            name: "Debug",
            buildSettings: [
                "ALLOW_TARGET_PLATFORM_SPECIALIZATION": true,
                "BAZEL_PACKAGE_BIN_DIR": "rules_xcodeproj",
                "INDEX_FORCE_SCRIPT_EXECUTION": true,
                "SUPPORTED_PLATFORMS": allPlatforms,
                "SUPPORTS_MACCATALYST": true,
                "TARGET_NAME": "GenerateBazelFiles",
            ]
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

\#(bazelExec) \
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

cd "$BAZEL_OUT"

rsync \
  --files-from "\#(
    filePathResolver
        .resolve(.internal(rsyncFileListPath), useScriptVariables: true)
        .string
)" \
  --chmod=u+w \
  -L \
  . \
  "$GEN_DIR"

"""#,
            showEnvVarsInLog: false
        )
        pbxProj.add(object: copyFilesScript)

        let fixModuleMapsScript = createFixModulemapsScript(
            in: pbxProj,
            files: files,
            filePathResolver: filePathResolver
        )

        let fixInfoPlistsScript = createFixInfoPlistsScript(
            in: pbxProj,
            files: files,
            filePathResolver: filePathResolver
        )

        let pbxTarget = PBXAggregateTarget(
            name: "Bazel Generated Files",
            buildConfigurationList: configurationList,
            buildPhases: [
                generateFilesScript,
                copyFilesScript,
                fixModuleMapsScript,
                fixInfoPlistsScript,
            ].compactMap { $0 },
            productName: "Bazel Generated Files"
        )
        pbxProj.add(object: pbxTarget)
        pbxProject.targets.append(pbxTarget)

        let attributes: [String: Any] = [
            // TODO: Generate this value
            "CreatedOnToolsVersion": "13.2.1",
        ]
        pbxProject.setTargetAttributes(attributes, target: pbxTarget)

        _ = try pbxTarget.addDependency(target: setupTarget, in: pbxProj)

        return pbxTarget
    }

    private static func createFixModulemapsScript(
        in pbxProj: PBXProj,
        files: [FilePath: File],
        filePathResolver: FilePathResolver
    ) -> PBXShellScriptBuildPhase? {
        guard files.containsModulemaps else {
            return nil
        }

        let script = PBXShellScriptBuildPhase(
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
    's%^(\s*(\w+ )?header )(?!("\.\.(\/\.\.)*\/|")(bazel-out|external)\/)("(\.\.\/)*)(.*")%\1\6SRCROOT/\8%' \
    < "$input" \
    > "$output"
done < "$SCRIPT_INPUT_FILE_LIST_0"

"""#,
            showEnvVarsInLog: false
        )
        pbxProj.add(object: script)

        return script
    }

    private static func createFixInfoPlistsScript(
        in pbxProj: PBXProj,
        files: [FilePath: File],
        filePathResolver: FilePathResolver
    ) -> PBXShellScriptBuildPhase? {
        guard files.containsInfoPlists else {
            return nil
        }

        let script = PBXShellScriptBuildPhase(
            name: "Fix Info.plists",
            inputFileListPaths: [
                filePathResolver
                    .resolve(.internal(infoPlistsFileListPath))
                    .string,
            ],
            outputFileListPaths: [
                filePathResolver
                    .resolve(.internal(fixedInfoPlistsFileListPath))
                    .string,
            ],
            shellScript: #"""
set -eu

while IFS= read -r input; do
  output="${input%.plist}.xcode.plist"
  cp "$input" "$output"
  plutil -remove UIDeviceFamily "$output" || true
done < "$SCRIPT_INPUT_FILE_LIST_0"

"""#,
            showEnvVarsInLog: false
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
        productType: PBXProductType,
        inputs: Inputs,
        files: [FilePath: File]
    ) throws -> PBXSourcesBuildPhase? {
        let sources = inputs.srcs.map(SourceFile.init) +
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
        productType: PBXProductType,
        resourceBundles: Set<FilePath>,
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

extension Dictionary where Key == FilePath {
    var containsModulemaps: Bool {
        contains(where: { filePath, _ in
            return filePath.type == .generated
                && filePath.path.extension == "modulemap"
        })
    }

    var containsInfoPlists: Bool {
        contains(where: { filePath, _ in
            return filePath.type == .generated
                && filePath.path.lastComponent == "Info.plist"
        })
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

// Re-implementation of helper on `PBXNativeTarget` until our patch lands:
// https://github.com/tuist/XcodeProj/pull/677
extension PBXAggregateTarget {
    /// Adds a local target dependency to the target.
    ///
    /// - Parameter target: dependency target.
    /// - Returns: target dependency reference.
    /// - Throws: an error if the dependency cannot be created.
    func addDependency(target: PBXTarget, in pbxProj: PBXProj) throws -> PBXTargetDependency? {
        let pbxProject = pbxProj.rootObject!
        let proxy = PBXContainerItemProxy(containerPortal: .project(pbxProject),
                                          remoteGlobalID: .object(target),
                                          proxyType: .nativeTarget,
                                          remoteInfo: target.name)
        pbxProj.add(object: proxy)
        let targetDependency = PBXTargetDependency(name: target.name,
                                                   target: target,
                                                   targetProxy: proxy)
        pbxProj.add(object: targetDependency)
        dependencies.append(targetDependency)
        return targetDependency
    }
}
