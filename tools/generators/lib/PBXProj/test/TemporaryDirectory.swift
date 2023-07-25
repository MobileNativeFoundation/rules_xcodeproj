import Foundation

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
