import Darwin
import Foundation
import ToolCommon

extension Generator {
    /// Reads the files at `urls`, returning their concatenated contents.
    static func readPartials(_ urls: [URL]) throws -> [UInt8] {
        let sizes = try urls.map { url in
            var info = stat()
            guard stat(url.path, &info) == 0 else {
                throw PreconditionError(message: """
Failed to read "\(url.path)": \(String(cString: strerror(errno)))
""")
            }
            return Int(info.st_size)
        }

        return try [UInt8](
            unsafeUninitializedCapacity: sizes.reduce(0, +)
        ) { buffer, count in
            for url in urls {
                let fd = open(url.path, O_RDONLY)
                guard fd >= 0 else {
                    throw PreconditionError(message: """
Failed to read "\(url.path)": \(String(cString: strerror(errno)))
""")
                }
                defer { close(fd) }

                while count < buffer.count {
                    let read = Darwin.read(
                        fd,
                        buffer.baseAddress! + count,
                        buffer.count - count
                    )
                    guard read >= 0 else {
                        throw PreconditionError(message: """
Failed to read "\(url.path)": \(String(cString: strerror(errno)))
""")
                    }
                    guard read > 0 else { break }
                    count += read
                }
            }
        }
    }
}
