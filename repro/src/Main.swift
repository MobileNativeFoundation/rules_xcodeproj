import Darwin
import Foundation
import ZippyJSON
import PathKit

func decode(useZippy: Bool) {
    let logger = DefaultLogger()
    let path = Path(ProcessInfo.processInfo.arguments[1])

    do {
        if useZippy {
            let project = try zippyReadProject(path: path)
            print("Successfully decoded \(project.name) with ZippyJSONDecoder")
        } else {
            let project = try defaultReadProject(path: path)
            print("Successfully decoded \(project.name) with JSONDecoder")
        }
    } catch {
        logger.logError(error.localizedDescription)
        exit(1)
    }
}

func defaultReadProject(path: Path) throws -> Project {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    do {
        return try decoder.decode(Project.self, from: try path.read())
    } catch let error as DecodingError {
        // Return a more detailed error message
        throw PreconditionError(message: error.message)
    }
}

func zippyReadProject(path: Path) throws -> Project {
    let decoder = ZippyJSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    do {
        return try decoder.decode(Project.self, from: try path.read())
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

// toggle `useZippy` to test `JSONDecoder` instead
decode(useZippy: true)
