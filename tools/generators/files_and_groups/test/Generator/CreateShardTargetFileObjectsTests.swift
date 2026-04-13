import Foundation
import XCTest

@testable import files_and_groups
@testable import PBXProj

final class CreateShardTargetFileObjectsTests: XCTestCase {
    func test_compileStubUsesInternalCompileStubIdentifier() async throws {
        let subIdentifier = Identifiers.BuildFiles.SubIdentifier(
            shard: "02",
            type: .compileStub,
            path: "",
            hash: "E4227FB5"
        )
        let url = URL(fileURLWithPath: "/tmp/buildfile_subidentifiers")

        let objects = try await Generator.CreateShardTargetFileObjects
            .defaultCallable(
                buildFileSubIdentifierFile: url,
                fileIdentifiersTask: Task {
                    [BazelPath("some/file.swift"): "FILE_ID"]
                },
                createBuildFileObject: .init(),
                readBuildFileSubIdentifiersFile: .init(callable: { _ in
                    [subIdentifier]
                })
            )

        XCTAssertEqual(objects.count, 1)

        guard case let .buildFile(object) = objects[0] else {
            XCTFail("Expected a build file object")
            return
        }

        XCTAssertEqual(
            object.identifier,
            Identifiers.BuildFiles.id(subIdentifier: subIdentifier)
        )
        XCTAssertEqual(
            object.content,
            #"""
{isa = PBXBuildFile; fileRef = FF0000000000000000000009 /* _CompileStub_.m */; }
"""#
        )
    }
}
