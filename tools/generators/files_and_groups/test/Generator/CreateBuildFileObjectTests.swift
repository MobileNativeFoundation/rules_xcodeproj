import CustomDump
import XCTest

@testable import files_and_groups
@testable import PBXProj

class CreateBuildFileObjectTests: XCTestCase {
    func test_appClip() {
        // Arrange

        let subIdentifier = Identifiers.BuildFiles.SubIdentifier(
            shard: "SHARDA",
            type: .appClip,
            path: "an/app_clip.app",
            hash: "HASHA"
        )
        let fileIdentifier = "FILE_ID"

        let expectedElement = Object(
            identifier: "SHARDAFFHASHA /* app_clip.app in Embed App Clips */",
            content: #"""
{isa = PBXBuildFile; fileRef = FILE_ID; settings = {ATTRIBUTES = (RemoveHeadersOnCopy, ); }; }
"""#
        )

        // Act

        let element = Generator.CreateBuildFileObject.defaultCallable(
            subIdentifier: subIdentifier,
            fileIdentifier: fileIdentifier
        )

        // Assert

        XCTAssertNoDifference(element, expectedElement)
    }

    func test_appExtension() {
        // Arrange

        let subIdentifier = Identifiers.BuildFiles.SubIdentifier(
            shard: "SHARDA",
            type: .appExtension,
            path: "an/app_extension.appex",
            hash: "HASHA"
        )
        let fileIdentifier = "FILE_ID"

        let expectedElement = Object(
            identifier: #"""
SHARDAFFHASHA /* app_extension.appex in Embed App Extensions */
"""#,
            content: #"""
{isa = PBXBuildFile; fileRef = FILE_ID; settings = {ATTRIBUTES = (RemoveHeadersOnCopy, ); }; }
"""#
        )

        // Act

        let element = Generator.CreateBuildFileObject.defaultCallable(
            subIdentifier: subIdentifier,
            fileIdentifier: fileIdentifier
        )

        // Assert

        XCTAssertNoDifference(element, expectedElement)
    }

    func test_compileStub() {
        // Arrange

        let subIdentifier = Identifiers.BuildFiles.SubIdentifier(
            shard: "SHARDA",
            type: .compileStub,
            path: "",
            hash: "HASHA"
        )
        let fileIdentifier = "FILE_ID"

        let expectedElement = Object(
            identifier: #"""
SHARDA00HASHA0000000000FE /* _CompileStub_.m in Sources */
"""#,
            content: #"""
{isa = PBXBuildFile; fileRef = FILE_ID; }
"""#
        )

        // Act

        let element = Generator.CreateBuildFileObject.defaultCallable(
            subIdentifier: subIdentifier,
            fileIdentifier: fileIdentifier
        )

        // Assert

        XCTAssertNoDifference(element, expectedElement)
    }

    func test_header() {
        // Arrange

        let subIdentifier = Identifiers.BuildFiles.SubIdentifier(
            shard: "SHARDA",
            type: .header,
            path: "a/header/file.h",
            hash: "HASHA"
        )
        let fileIdentifier = "FILE_ID"

        let expectedElement = Object(
            identifier: "SHARDAFFHASHA /* file.h in Headers */",
            content: #"""
{isa = PBXBuildFile; fileRef = FILE_ID; settings = {ATTRIBUTES = (Public, ); }; }
"""#
        )

        // Act

        let element = Generator.CreateBuildFileObject.defaultCallable(
            subIdentifier: subIdentifier,
            fileIdentifier: fileIdentifier
        )

        // Assert

        XCTAssertNoDifference(element, expectedElement)
    }

    func test_nonArcSource() {
        // Arrange

        let subIdentifier = Identifiers.BuildFiles.SubIdentifier(
            shard: "SHARDA",
            type: .nonArcSource,
            path: "a/non_arc_source/file.c",
            hash: "HASHA"
        )
        let fileIdentifier = "FILE_ID"

        let expectedElement = Object(
            identifier: "SHARDAFFHASHA /* file.c in Sources */",
            content: #"""
{isa = PBXBuildFile; fileRef = FILE_ID; settings = {COMPILER_FLAGS = "-fno-objc-arc"; }; }
"""#
        )

        // Act

        let element = Generator.CreateBuildFileObject.defaultCallable(
            subIdentifier: subIdentifier,
            fileIdentifier: fileIdentifier
        )

        // Assert

        XCTAssertNoDifference(element, expectedElement)
    }

    func test_source() {
        // Arrange

        let subIdentifier = Identifiers.BuildFiles.SubIdentifier(
            shard: "SHARDA",
            type: .source,
            path: "a/source/file.swift",
            hash: "HASHA"
        )
        let fileIdentifier = "FILE_ID"

        let expectedElement = Object(
            identifier: "SHARDAFFHASHA /* file.swift in Sources */",
            content: #"""
{isa = PBXBuildFile; fileRef = FILE_ID; }
"""#
        )

        // Act

        let element = Generator.CreateBuildFileObject.defaultCallable(
            subIdentifier: subIdentifier,
            fileIdentifier: fileIdentifier
        )

        // Assert

        XCTAssertNoDifference(element, expectedElement)
    }

    func test_awatchContent() {
        // Arrange

        let subIdentifier = Identifiers.BuildFiles.SubIdentifier(
            shard: "SHARDA",
            type: .watchContent,
            path: "some/watch_content.appex",
            hash: "HASHA"
        )
        let fileIdentifier = "FILE_ID"

        let expectedElement = Object(
            identifier: #"""
SHARDAFFHASHA /* watch_content.appex in Embed Watch Content */
"""#,
            content: #"""
{isa = PBXBuildFile; fileRef = FILE_ID; settings = {ATTRIBUTES = (RemoveHeadersOnCopy, ); }; }
"""#
        )

        // Act

        let element = Generator.CreateBuildFileObject.defaultCallable(
            subIdentifier: subIdentifier,
            fileIdentifier: fileIdentifier
        )

        // Assert

        XCTAssertNoDifference(element, expectedElement)
    }
}
