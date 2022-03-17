import PathKit
import XcodeProj

extension Generator {
    static func addTargets(
        in pbxProj: PBXProj,
        for disambiguatedTargets: [TargetID: DisambiguatedTarget],
        products: Products,
        files: [FilePath: File],
        xcodeprojBazelLabel: String
    ) throws -> [TargetID: PBXNativeTarget] {
        let pbxProject = pbxProj.rootObject!

        let generatedFilesTarget = try createGeneratedFilesTarget(
            in: pbxProj,
            files: files,
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

            guard let product = products.byTarget[id] else {
                throw PreconditionError(message: """
Product for target "\(id)" not found
""")
            }

            let headersPhase = try createHeadersPhase(
                in: pbxProj,
                productType: target.product.type,
                inputs: inputs,
                files: files
            )
            let sourcesBuildPhase = try createCompileSourcesPhase(
                in: pbxProj,
                inputs: inputs,
                files: files
            )

            // TODO: Framework embeds

            // TODO: Copy resources

            let pbxTarget = PBXNativeTarget(
                name: disambiguatedTarget.name,
                buildPhases: [
                    headersPhase,
                    sourcesBuildPhase,
                ].compactMap { $0 },
                productName: target.product.name,
                product: product,
                productType: target.product.type
            )
            pbxProj.add(object: pbxTarget)
            pbxProject.targets.append(pbxTarget)
            pbxTargets[id] = pbxTarget

            if
                target.inputs.containsGeneratedFiles
                    || target.modulemaps.containsGeneratedFiles,
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
        xcodeprojBazelLabel: String
    ) throws -> PBXAggregateTarget? {
        guard files.containsGeneratedFiles else {
            return nil
        }

        guard
            let generatedFileList = files.first(
                where: { $0.key == .internal(generatedFileListPath) }
            )?.value.reference
        else {
            throw PreconditionError(message: "generatedFileList not in `files`")
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

        let shellScript = PBXShellScriptBuildPhase(
            outputFileListPaths: [
                generatedFileList.projectRelativePath(in: pbxProj).string,
            ],
            shellScript: #"""
PATH="${PATH//\/usr\/local\/bin//opt/homebrew/bin:/usr/local/bin}" \
  ${BAZEL_PATH} \
  build \
  --output_groups=generated_inputs \
  \#(xcodeprojBazelLabel)

"""#,
            showEnvVarsInLog: false,
            alwaysOutOfDate: true
        )
        pbxProj.add(object: shellScript)

        let pbxTarget = PBXAggregateTarget(
            name: "Bazel Generated Files",
            buildConfigurationList: configurationList,
            buildPhases: [shellScript],
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
File "\(headerFile.filePath)" not found
""")
            }
            let pbxBuildFile = PBXBuildFile(
                file: file.reference,
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
        inputs: Inputs,
        files: [FilePath: File]
    ) throws -> PBXSourcesBuildPhase {
        func buildFile(sourceFile: SourceFile) throws -> PBXBuildFile {
            guard let file = files[sourceFile.filePath] else {
                throw PreconditionError(message: """
File "\(sourceFile.filePath)" not found
""")
            }
            let pbxBuildFile = PBXBuildFile(
                file: file.reference,
                settings: sourceFile.settings
            )
            pbxProj.add(object: pbxBuildFile)
            return pbxBuildFile
        }

        let sources = Set(
            inputs.srcs.map(SourceFile.init)
            + inputs.nonArcSrcs.map { filePath in
                return SourceFile(
                    filePath,
                    compilerFlags: ["-fno-objc-arc"]
                )
            }
        )

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

private extension Inputs {
    var containsGeneratedFiles: Bool {
        return srcs.containsGeneratedFiles
            || nonArcSrcs.containsGeneratedFiles
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
