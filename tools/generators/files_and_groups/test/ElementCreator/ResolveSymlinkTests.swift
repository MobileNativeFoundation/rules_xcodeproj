import XCTest

@testable import files_and_groups

final class ResolveSymlinkTests: XCTestCase {
    var fixtureDirectory: TemporaryDirectory!

    override func setUpWithError() throws {
        // Create fixtures:
        //
        //  files/
        //      file
        //  symlinks/
        //      absolute1 -> /tmp
        //      absolute2 -> /private/tmp
        //      relative1 -> relative2
        //      relative2 -> ../files/file

        guard fixtureDirectory == nil else {
            return
        }

        fixtureDirectory = try TemporaryDirectory()

        let fileManager = FileManager.default

        let filesDir = fixtureDirectory.url.appendingPathComponent(
            "files",
            isDirectory: true
        )
        try fileManager
            .createDirectory(at: filesDir, withIntermediateDirectories: false)

        let file = filesDir.appendingPathComponent("file", isDirectory: false)
        try "".write(to: file, atomically: false, encoding: .utf8)

        let symlinksDir = fixtureDirectory.url.appendingPathComponent(
            "symlinks",
            isDirectory: true
        )
        try fileManager.createDirectory(
            at: symlinksDir,
            withIntermediateDirectories: false
        )

        let absoluteSymlink1 = symlinksDir
            .appendingPathComponent("absolute1", isDirectory: false)
        try fileManager.createSymbolicLink(
            at: absoluteSymlink1,
            withDestinationURL: URL(fileURLWithPath: "/tmp", isDirectory: true)
        )

        let absoluteSymlink2 = symlinksDir
            .appendingPathComponent("absolute2", isDirectory: false)
        try fileManager.createSymbolicLink(
            at: absoluteSymlink2,
            withDestinationURL: URL(
                fileURLWithPath: "/private/tmp",
                isDirectory: true
            )
        )

        let relativeSymlink2 = symlinksDir
            .appendingPathComponent("relative2", isDirectory: false)
        try fileManager.createSymbolicLink(
            atPath: relativeSymlink2.path,
            withDestinationPath: "../files/file"
        )

        let relativeSymlink1 = symlinksDir
            .appendingPathComponent("relative1", isDirectory: false)
        try fileManager.createSymbolicLink(
            atPath: relativeSymlink1.path,
            withDestinationPath: "relative2"
        )
    }

    func test_nonSymlink() {
        // Arrange

        let path = "\(fixtureDirectory.url.path)/files/file"

        // Act

        let symlinkDest =
            ElementCreator.ResolveSymlink.defaultCallable(path: path)

        // Assert

        XCTAssertNil(symlinkDest)
    }

    func test_absoluteSymlink_tmp() {
        // Arrange

        let path = "\(fixtureDirectory.url.path)/symlinks/absolute1"

        let expectedSymlinkDest = "/tmp"

        // Act

        let symlinkDest =
            ElementCreator.ResolveSymlink.defaultCallable(path: path)

        // Assert

        XCTAssertEqual(symlinkDest, expectedSymlinkDest)
    }

    func test_absoluteSymlink_privateTmp() {
        // Arrange

        let path = "\(fixtureDirectory.url.path)/symlinks/absolute2"

        let expectedSymlinkDest = "/private/tmp"

        // Act

        let symlinkDest =
            ElementCreator.ResolveSymlink.defaultCallable(path: path)

        // Assert

        XCTAssertEqual(symlinkDest, expectedSymlinkDest)
    }

    func test_relativeSymlink() {
        // Arrange

        let path = "\(fixtureDirectory.url.path)/symlinks/relative2"

        let expectedSymlinkDest = "\(fixtureDirectory.url.path)/files/file"

        // Act

        let symlinkDest =
            ElementCreator.ResolveSymlink.defaultCallable(path: path)

        // Assert

        XCTAssertEqual(symlinkDest, expectedSymlinkDest)
    }

    func test_deepRelativeSymlink() {
        // Arrange

        let path = "\(fixtureDirectory.url.path)/symlinks/relative1"

        let expectedSymlinkDest = "\(fixtureDirectory.url.path)/files/file"

        // Act

        let symlinkDest =
            ElementCreator.ResolveSymlink.defaultCallable(path: path)

        // Assert

        XCTAssertEqual(symlinkDest, expectedSymlinkDest)
    }
}

class TemporaryDirectory {
    let url: URL

    /// Creates a new temporary directory.
    ///
    /// The directory is recursively deleted when this object deallocates.
    init() throws {
        url = try FileManager.default.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: FileManager.default.temporaryDirectory,
            create: true
        )
    }

    deinit {
        _ = try? FileManager.default.removeItem(at: url)
    }
}
