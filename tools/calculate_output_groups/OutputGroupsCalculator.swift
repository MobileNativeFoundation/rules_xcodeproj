import Foundation
import ToolCommon
import ZippyJSON

struct OutputGroupsCalculator {
    func calculateOutputGroups(arguments: Arguments) async throws {
        let pifCache = arguments.baseObjRoot
            .appendingPathComponent("XCBuildData/PIFCache")
        let projectCache = pifCache.appendingPathComponent("project")
        let targetCache = pifCache.appendingPathComponent("target")

        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: projectCache.path) &&
                fileManager.fileExists(atPath: targetCache.path)
        else {
            throw UsageError(message: """
error: PIFCache (\(pifCache)) doesn't exist. If you manually cleared Derived \
Data, you need to close and re-open the project for the PIFCache to be created \
again. Using the "Clean Build Folder" command instead (⇧ ⌘ K) won't trigger \
this error. If this error still happens after re-opening the project, please \
file a bug report here: \
https://github.com/MobileNativeFoundation/rules_xcodeproj/issues/new?template=bug.md
""")
        }

        let projectURL = try Self.findProjectURL(in: projectCache)
        let project = try Self.decodeProject(at: projectURL)
        let targets =
            try await Self.decodeTargets(project.targets, in: targetCache)

        dump(targets)
    }

    static func findProjectURL(in projectCache: URL) throws -> URL {
        let projectPIFsEnumerator = FileManager.default.enumerator(
            at: projectCache,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [
                .skipsHiddenFiles,
                .skipsPackageDescendants,
                .skipsSubdirectoryDescendants,
            ]
        )!

        var newestProjectPIF: URL?
        var newestProjectPIFDate = Date.distantPast
        for case let projectPIF as URL in projectPIFsEnumerator {
            guard let resourceValues = try? projectPIF.resourceValues(
                forKeys: [.contentModificationDateKey]
            ), let modificationDate = resourceValues.contentModificationDate
            else {
                continue
            }

            // TODO: The modification date is in the filename, should we use
            // that instead?
            if modificationDate > newestProjectPIFDate {
                newestProjectPIF = projectPIF
                newestProjectPIFDate = modificationDate
            }
        }

        guard let projectPIF = newestProjectPIF else {
            throw UsageError(message: """
error: Couldn't find a Project PIF at "\(projectCache)". Please file a bug \
report here: https://github.com/MobileNativeFoundation/rules_xcodeproj/issues/new?template=bug.md
""")
        }

        return projectPIF
    }

    static func decodeProject(at url: URL) throws -> ProjectPIF {
        let decoder = ZippyJSONDecoder()
        return try decoder.decode(ProjectPIF.self, from: Data(contentsOf: url))
    }

    static func decodeTargets(
        _ targets: [String],
        in targetCache: URL
    ) async throws -> [TargetPIF] {
        return try await withThrowingTaskGroup(
            of: TargetPIF.self,
            returning: [TargetPIF].self
        ) { group in
            for target in targets {
                group.addTask {
                    let url =
                        targetCache.appendingPathComponent("\(target)-json")
                    let decoder = ZippyJSONDecoder()
                    return try decoder
                        .decode(TargetPIF.self, from: Data(contentsOf: url))
                }
            }

            var targetPIFs: [TargetPIF] = []
            for try await target in group {
                targetPIFs.append(target)
            }

            return targetPIFs
        }
    }
}

struct ProjectPIF: Decodable {
    let targets: [String]
}

struct TargetPIF: Decodable {
    struct BuildConfiguration: Decodable {
        let name: String
        let buildSettings: [String: String]
    }

    let guid: String
    let buildConfigurations: [BuildConfiguration]
}

struct Target {
    let label: String

    // Maps Platform Name -> [Target ID]
    let targetIds: [String: [String]]
}
