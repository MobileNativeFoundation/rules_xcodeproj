import Foundation
import SwiftProtobuf

import tools_bep_parser_bep_build_event_stream_proto

@main
struct MainApp {
    static let importantMnemonics: Set<String> = [
        "CppCompile",
//        "CppLink",
//        "ObjcLink",
//        "ObjcCompile",
//        "SwiftArchive",
//        "SwiftCompile",
    ]

    static func main() async throws {
        let bepPath = "/Users/brentley/Developer/rules_xcodeproj/bep"

        guard let fileHandle = FileHandle(forReadingAtPath: bepPath) else {
            fatalError(#"Failed to open file for BEP stream at "\#(bepPath)""#)
        }

        for try await event in BuildEventSequence(fileHandle: fileHandle) {
            guard let payload = event.payload else {
                continue
            }

            switch payload {
            case let .action(action):
                guard importantMnemonics.contains(action.type) else {
                    break
                }
                print("Action completed: \(action.label): \(action.type): \(action.commandLine)")

            case let .namedSetOfFiles(fileSet):
                print("Files: \(processFileSet(fileSet, id: event.id.namedSet))")

            case .completed(_):
                print("Target completed: \(event.id.targetCompleted)")

            default:
                break
            }
        }
    }

    static var fileSets: [BuildEventStream_BuildEventId.NamedSetOfFilesId: BuildEventStream_NamedSetOfFiles] = [:]

    static func processFileSet(_ fileSet: BuildEventStream_NamedSetOfFiles, id: BuildEventStream_BuildEventId.NamedSetOfFilesId) -> [String] {
        fileSets[id] = fileSet
        let paths = fileSet.files.map { file in
            return (file.pathPrefix + [file.name]).joined(separator: "/")
        }
        let additionalPaths = fileSet.fileSets
            .map { fileSets[$0]! }
            .flatMap { processFileSet($0, id: id) }
        return paths + additionalPaths
    }
}
