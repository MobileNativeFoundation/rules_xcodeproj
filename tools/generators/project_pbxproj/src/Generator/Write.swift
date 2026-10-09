import Darwin
import Foundation
import ToolCommon

extension Generator {
    /// Writes bytes to the output.
    typealias WriteBytes = (_ bytes: UnsafeRawBufferPointer) throws -> Void

    /// Opens the file at `url` and calls `body` with a function that writes
    /// to it through a 1 MB buffer.
    static func write(
        to url: URL,
        _ body: (_ write: WriteBytes) throws -> Void
    ) throws {
        func writeError() -> PreconditionError {
            return PreconditionError(message: """
Failed to write "\(url.path)": \(String(cString: strerror(errno)))
""")
        }

        guard let file = fopen(url.path, "w") else { throw writeError() }
        setvbuf(file, nil, _IOFBF, 1 << 20)

        do {
            try body { bytes in
                guard bytes.count > 0 else { return }
                guard fwrite(bytes.baseAddress, 1, bytes.count, file) ==
                    bytes.count
                else {
                    throw writeError()
                }
            }
        } catch {
            fclose(file)
            throw error
        }

        guard fclose(file) == 0 else { throw writeError() }
    }
}
