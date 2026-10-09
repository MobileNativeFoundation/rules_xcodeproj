import Darwin
import Foundation
import ToolCommon

extension Generator {
    typealias WriteBytes = (_ bytes: UnsafeRawBufferPointer) throws -> Void

    /// Calls `body` with a function that writes to the file at `url`.
    static func write(
        to url: URL,
        _ body: (_ write: WriteBytes) throws -> Void
    ) throws {
        guard let file = fopen(url.path, "w") else { throw writeError(url) }
        defer { fclose(file) }
        setvbuf(file, nil, _IOFBF, 1 << 20)

        try body { bytes in
            _ = fwrite(bytes.baseAddress, 1, bytes.count, file)
        }

        guard fflush(file) == 0, ferror(file) == 0 else {
            throw writeError(url)
        }
    }
}

private func writeError(_ url: URL) -> PreconditionError {
    return PreconditionError(message: """
Failed to write "\(url.path)": \(String(cString: strerror(errno)))
""")
}
