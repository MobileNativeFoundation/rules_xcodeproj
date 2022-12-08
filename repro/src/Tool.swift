import Darwin
import Foundation
import ZippyJSON
import PathKit

func decode(useZippy: Bool) async  {
    let logger = DefaultLogger()
    let projectSpecPath = Path(ProcessInfo.processInfo.arguments[1])
    let targetsSpecPaths = ProcessInfo.processInfo.arguments[2...].map { Path($0) }

    print("Project spec: \(projectSpecPath)")
    print("Targets specs: \(targetsSpecPaths)")

    do {
        let project = try await readProject(path: projectSpecPath, targetsSpecPaths: targetsSpecPaths)
        print("Successfully decoded \(project.name)")
    } catch {
        logger.logError(error.localizedDescription)
        exit(1)
    }
}

protocol SpecDecoder {
    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable

    func anotherOne() -> SpecDecoder
}

extension JSONDecoder: SpecDecoder {
    func anotherOne() -> SpecDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
extension ZippyJSONDecoder: SpecDecoder {
    func anotherOne() -> SpecDecoder {
        let decoder = ZippyJSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}



func decodeSpec<T: Decodable>(
    _ type: T.Type,
    from path: Path
) async throws -> T {
    return try await Task {
        let decoder = ZippyJSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(type, from: try path.read())
    }.value
}

func readProject(path: Path, targetsSpecPaths: [Path]) async throws -> Project {
    do {
        async let targets = withThrowingTaskGroup(of: [TargetID: Target].self) { group in
            var targets: [TargetID: Target] = [:]

            for path in targetsSpecPaths {
                group.addTask {
                    return try await decodeSpec(
                        [TargetID: Target].self,
                        from: path
                    )
                }
            }
            for try await targetsSlice in group {
                try targets.merge(targetsSlice) { _, new in
//                    throw PreconditionError(message: """
//Duplicate target (\(new.name)) in target specs
//""")
                    return new
                }
            }

            return targets
        }

        var project = try await decodeSpec(Project.self, from: path)
        project.targets = try await targets
        return project
    } catch let error as DecodingError {
        // Return a more detailed error message
        throw PreconditionError(message: error.message)
    }
}

private extension DecodingError {
    var message: String {
        guard let context = context else {
            return "An unknown decoding error occurred."
        }

        return """
At codingPath [\(context.codingPathString)]: \(context.debugDescription)
"""
    }

    private var context: Context? {
        switch self {
        case let .typeMismatch(_, context): return context
        case let .valueNotFound(_, context): return context
        case let .keyNotFound(_, context): return context
        case let .dataCorrupted(context): return context
        @unknown default: return nil
        }
    }
}

private extension DecodingError.Context {
    var codingPathString: String {
        return codingPath.map(\.stringValue).joined(separator: ", ")
    }
}

@main
struct Tool {
    static func main() async {
        // toggle `useZippy` to test `JSONDecoder` instead
        await decode(useZippy: false)
    }
}
