import Foundation

class TemporaryFile {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
    }

    deinit {
        _ = try? FileManager.default.removeItem(at: url)
    }
}
