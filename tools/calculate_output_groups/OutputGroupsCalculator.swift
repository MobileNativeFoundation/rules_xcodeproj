import Foundation
import ToolCommon
import ZippyJSON

struct OutputGroupsCalculator {
    func calculateOutputGroups(arguments: Arguments) async throws {
        let pifCache = arguments.baseObjRoot.appendingPathComponent("XCBuildData/PIFCache")
        let projectCache = pifCache.appendingPathComponent("project")
        let targetCache = pifCache.appendingPathComponent("target")

        guard let markerDate = arguments.buildMarkerFile.modificationDate else {
            throw UsageError.buildMarker(arguments.buildMarkerFile.path)
        }

        let fileManager = FileManager.default
        guard
            fileManager.fileExists(atPath: projectCache.path),
            fileManager.fileExists(atPath: targetCache.path)
        else {
            throw UsageError.pifCache(pifCache.path)
        }

        async let buildRequest = loadBuildRequestFile(
            inPath: arguments.baseObjRoot.appendingPathComponent("XCBuildData"),
            since: markerDate
        )
        async let targetMap = loadTargetMap(
            fromBase: arguments.baseObjRoot,
            projectCache: projectCache,
            targetCache: targetCache
        )

        let output = try await outputGroups(
            buildRequest: buildRequest,
            targets: targetMap,
            prefixes: arguments.outputGroupPrefixes
        )
        print(output)
    }

    private func loadBuildRequestFile(inPath path: URL, since: Date) async throws -> BuildRequest {
        @Sendable func findBuildRequestURL() -> URL? {
            path.newestDescendent(recursive: true, matching: { url in
                guard 
                    url.path.hasSuffix(".xcbuilddata/build-request.json"),
                    let date = url.modificationDate
                else { return false }
                return date >= since
            })
        }

        if let url = findBuildRequestURL() {
            return try url.decode(BuildRequest.self)
        }

        // If the file was not immediately found, kick off a process to wait for the file to be created (or time out).
        let findTask = Task {
            while true {
                try Task.checkCancellation()
                try await Task.sleep(for: .seconds(1))
                if let buildRequestURL = findBuildRequestURL() {
                    return buildRequestURL
                }
            }
        }
        let timeoutTask = Task {
            try await Task.sleep(for: .seconds(10))
            findTask.cancel()
        }

        do {
            let result = try await findTask.value
            timeoutTask.cancel()
            return try result.decode(BuildRequest.self)
        } catch {
            throw UsageError.buildRequest(path.path)
        }
    }

    private func loadTargetMap(
        fromBase baseObjRoot: URL,
        projectCache: URL,
        targetCache: URL
    ) async throws -> Output.Map {
        let projectURL = try findProjectURL(in: projectCache)
        let guidPayloadDir = baseObjRoot.appendingPathComponent("guid_payload")
        try FileManager.default.createDirectory(at: guidPayloadDir, withIntermediateDirectories: true)
        let guidPayloadFile = guidPayloadDir.appendingPathComponent(projectURL.lastPathComponent+"_v3.json")
        let targets: Output.Map
        do {
            targets = try guidPayloadFile.decode(Output.Map.self)
        } catch {
            let project = try projectURL.decode(PIF.Project.self)
            targets = try await decodeTargets(project.targets, in: targetCache)
            let data = try JSONEncoder().encode(targets)
            try data.write(to: guidPayloadFile)
        }
        return targets
    }

    private func outputGroups(
        buildRequest: BuildRequest,
        targets: Output.Map,
        prefixes: [String]
    ) throws -> String {
        var lines: [String] = []

        for guid in buildRequest.configuredTargets {
            guard
                let target = targets[guid],
                let config = target.configs[buildRequest.configurationName]
            else { continue }

            var settings: Output.Target.Config.Settings?
            switch buildRequest.command {
            case "build":
                settings = config.build
            case "buildFiles":
                settings = config.buildFiles
            default:
                break
            }
            guard let settings else {
                throw PreconditionError(message: "Settings not found for target/command combination: \(guid) / \(buildRequest.command)")
            }

            for platform in allPlatformsToSearch(buildRequest.platform) {
                guard let platform = settings.platforms[platform] else { continue }
                for prefix in prefixes {
                    for id in platform ?? settings.base {
                        lines.append("\(target.label)\n\(prefix) \(id)")
                    }
                }
            }
        }

        return lines.joined(separator: "\n")
    }

    // MARK: Helpers

    private func allPlatformsToSearch(_ platform: String) -> [String] {
        if platform == "macosx" || platform.contains("simulator") {
            return ["iphonesimulator", "appletvsimulator", "watchsimulator", "macosx"]
        } else {
            return ["iphoneos", "appletvos", "watchos", "macosx"]
        }
    }

    private func findProjectURL(in projectCache: URL) throws -> URL {
        guard let projectPIF = projectCache.newestDescendent() else {
            throw UsageError.pifCache(projectCache.path)
        }
        return projectPIF
    }

    private func decodeTargets(
        _ targets: [String],
        in targetCache: URL
    ) async throws -> Output.Map {
        try await withThrowingTaskGroup(
            of: PIF.Target.self,
            returning: Output.Map.self
        ) { group in
            let decoder = ZippyJSONDecoder()
            for target in targets {
                group.addTask {
                    let url = targetCache.appendingPathComponent("\(target)-json")
                    return try decoder.decode(PIF.Target.self, from: Data(contentsOf: url))
                }
            }
            return try await group.reduce(into: Output.Map()) { map, target in
                map[target.guid] = target.output
            }
        }
    }
}

extension PIF.Target {
    var output: Output.Target? {
        guard let label = buildConfigurations.lazy.compactMap(\.label).first else { return nil }
        return .init(
            label: label,
            configs: Dictionary(uniqueKeysWithValues: zip(
                buildConfigurations.map(\.name),
                buildConfigurations.map(\.output)
            ))
        )
    }
}
extension PIF.Target.BuildConfiguration {
    var label: String? {
        buildSettings["BAZEL_LABEL"]
    }

    var output: Output.Target.Config {
        var build: Output.Target.Config.Settings?
        if let value = buildSettings["BAZEL_TARGET_ID"] {
            build = .init(base: [value], platforms: [:])
        }
        var buildFiles: Output.Target.Config.Settings?
        if let value = buildSettings["BAZEL_COMPILE_TARGET_IDS"] {
            buildFiles = .init(base: compileTargetIds(value), platforms: [:])
        }
        if build != nil || buildFiles != nil {
            for (key, value) in buildSettings {
                if build != nil, key.starts(with: "BAZEL_TARGET_ID[sdk=") {
                    let platform = String(key.dropFirst(20).dropLast(2))
                    if value == "$(BAZEL_TARGET_ID)" {
                        // This value indicates that the provided platform inherits from the base build setting. Store nil for later processing.
                        build?.platforms[platform] = nil
                    } else {
                        build?.platforms[platform] = [value]
                    }
                }
                if buildFiles != nil, key.starts(with: "BAZEL_COMPILE_TARGET_IDS[sdk=") {
                    let platform = String(key.dropFirst(29).dropLast(2))
                    if value == "$(BAZEL_COMPILE_TARGET_IDS)" {
                        // This value indicates that the provided platform inherits from the base build setting. Store nil for later processing.
                        buildFiles?.platforms[platform] = nil
                    } else {
                        buildFiles?.platforms[platform] = compileTargetIds(value)
                    }
                }
            }
        }

        return .init(build: build, buildFiles: buildFiles)
    }

    private func compileTargetIds(_ value: String) -> [String] {
        var seenSpace = false
        // value is a space-separated list of space-separated pairs. split into an array of pairs.
        return value.split(whereSeparator: {
            guard $0 == " " else { return false }
            if seenSpace {
                seenSpace = false
                return true
            } else {
                seenSpace = true
            }
            return false
        }).map(String.init)
    }
}
