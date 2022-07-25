import Foundation
import SwiftProtobuf

import tools_bep_parser_bep_build_event_stream_proto

struct BuildEventSequence<Base>: AsyncSequence
where Base: AsyncSequence, Base.Element == UInt8 {
    var base: Base
    typealias Element = BuildEventStream_BuildEvent

    struct AsyncIterator: AsyncIteratorProtocol {
        var base: Base.AsyncIterator

        mutating func next() async throws -> BuildEventStream_BuildEvent? {
            var length: UInt64?
            var value: UInt64 = 0
            var shift: UInt64 = 0
            while let byte = try await base.next() {
                value |= UInt64(byte & 0x7f) << shift
                if byte & 0x80 == 0 {
                    length = value
                    break
                }
                shift += 7
                if shift > 63 {
                    throw BinaryDecodingError.malformedProtobuf
                }
            }

            guard let length = length else {
                // End of File
                return nil
            }

            guard length != 0 else {
                // The message was all defaults, nothing to actually read
                return BuildEventStream_BuildEvent()
            }

            // TODO: Use something like
            // https://github.com/apple/swift-async-algorithms/blob/main/Guides/BufferedBytes.md
            // and https://developer.apple.com/documentation/system/filedescriptor/read(into:retryoninterrupt:)
            // to buffer bytes directly from a file handle, instead of appending
            // byte by byte
            var data = Data()
            while let byte = try await base.next() {
                data.append(byte)
                if data.count == length {
                    return try BuildEventStream_BuildEvent(serializedData: data)
                }
            }

            guard data.isEmpty else {
                throw BinaryDelimited.Error.truncated
            }

            return nil
        }
    }

    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(base: base.makeAsyncIterator())
    }
}

extension BuildEventSequence where Base == FileHandle.AsyncBytes {
    init(fileHandle: FileHandle) {
        self.init(base: fileHandle.bytes)
    }
}
