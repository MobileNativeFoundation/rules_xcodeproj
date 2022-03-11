import PathKit
import XcodeProj

extension Generator {
    static func addTargets(
        in pbxProj: PBXProj,
        for disambiguatedTargets: [TargetID: DisambiguatedTarget],
        products: Products,
        files: [FilePath: File]
    ) throws -> [TargetID: PBXNativeTarget] {
        let pbxProject = pbxProj.rootObject!

        let sortedDisambiguatedTargets = disambiguatedTargets
            .sortedLocalizedStandard(\.value.name)
        var pbxTargets = Dictionary<TargetID, PBXNativeTarget>(
            minimumCapacity: disambiguatedTargets.count
        )
        for (id, disambiguatedTarget) in sortedDisambiguatedTargets {
            let target = disambiguatedTarget.target

            guard let product = products.byTarget[id] else {
                throw PreconditionError(message: """
Product for target "\(id)" not found
""")
            }

            // TODO: Headers build phase

            let sourcesBuildPhase = try createCompileSourcesPhase(
                in: pbxProj,
                sources: target.srcs,
                files: files
            )
            let frameworksBuildPhase = try createFrameworksPhase(
                in: pbxProj,
                links: target.links,
                products: products.byPath
            )

            // TODO: Framework embeds

            // TODO: Copy resources

            let pbxTarget = PBXNativeTarget(
                name: disambiguatedTarget.name,
                buildPhases: [
                    sourcesBuildPhase,
                    frameworksBuildPhase,
                ],
                productName: target.product.name,
                product: product,
                productType: target.product.type
            )
            pbxProj.add(object: pbxTarget)
            pbxProject.targets.append(pbxTarget)
            pbxTargets[id] = pbxTarget

        }

        return pbxTargets
    }

    private static func createCompileSourcesPhase(
        in pbxProj: PBXProj,
        sources: Set<FilePath>,
        files: [FilePath: File]
    ) throws -> PBXSourcesBuildPhase {
        func buildFile(filePath: FilePath) throws -> PBXBuildFile {
            guard let file = files[filePath] else {
                throw PreconditionError(message: """
File "\(filePath)" not found
""")
            }
            let pbxBuildFile = PBXBuildFile(file: file.reference)
            pbxProj.add(object: pbxBuildFile)
            return pbxBuildFile
        }

        let filePaths: Set<FilePath>
        if sources.isEmpty {
            filePaths = [.internal(compileStubPath)]
        } else {
            filePaths = sources
        }

        let buildPhase = PBXSourcesBuildPhase(
            files: try filePaths.map(buildFile).sortedLocalizedStandard()
        )
        pbxProj.add(object: buildPhase)

        return buildPhase
    }

    private static func createFrameworksPhase(
        in pbxProj: PBXProj,
        links: Set<Path>,
        products: [Path: PBXFileReference]
    ) throws -> PBXFrameworksBuildPhase {
        func buildFile(path: Path) throws -> PBXBuildFile {
            guard let product = products[path] else {
                throw PreconditionError(message: """
Product with path "\(path)" not found
""")
            }
            let pbxBuildFile = PBXBuildFile(file: product)
            pbxProj.add(object: pbxBuildFile)
            return pbxBuildFile
        }

        let buildPhase = PBXFrameworksBuildPhase(
            files: try links
                .map(buildFile)
                .sortedLocalizedStandard()
        )
        pbxProj.add(object: buildPhase)

        return buildPhase
    }
}
