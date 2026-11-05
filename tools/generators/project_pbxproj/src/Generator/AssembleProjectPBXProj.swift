import Darwin
import ToolCommon

extension Generator {
    /// Assembles the `project.pbxproj` file from the concatenated `partials`,
    /// in the layout that Xcode writes, and passes it to `write`.
    static func assembleProjectPBXProj(
        _ partials: [UInt8],
        _ write: WriteBytes
    ) throws {
        try partials.withUnsafeBufferPointer { input in
            var lines = Lines(input: input)

            // Everything up to and including the `objects = {` line
            while true {
                guard let line = lines.next() else {
                    throw PreconditionError(message: """
Malformed 'PBXProj' partials: missing the 'objects = {' line
""")
                }
                if lines.hasPrefix("\tobjects = {", line) { break }
            }
            let objectsStart = lines.offset

            var objects: [Object] = []
            var objectsEnd = lines.offset
            while let line = lines.next() {
                if line.isEmpty {
                    objectsEnd = lines.offset
                    continue
                }
                // Objects start at exactly two tabs
                guard line.count > 2, lines.hasPrefix("\t\t", line),
                      !lines.hasPrefix("\t\t\t", line)
                else {
                    break
                }
                let start = line.lowerBound

                let idEnd = input[line].firstIndex(of: UInt8(ascii: " ")) ??
                    line.upperBound

                let isa: Range<Int>
                if lines.hasSuffix("};", line) {
                    // `\t\t<id> /* <comment> */ = {isa = <isa>; ...};`
                    guard let isaStart = lines.firstIndex(
                            after: " = {isa = ",
                            in: idEnd ..< line.upperBound
                          ),
                          let isaEnd = input[isaStart ..< line.upperBound]
                            .firstIndex(of: UInt8(ascii: ";"))
                    else {
                        throw lines.malformed("object without an 'isa'", start)
                    }
                    isa = isaStart ..< isaEnd
                } else {
                    // `isa` is the first attribute, and the object ends at a
                    // line that is exactly `\t\t};`
                    let prefix: StaticString = "\t\t\tisa = "
                    guard let isaLine = lines.next(),
                          lines.hasPrefix(prefix, isaLine),
                          lines.hasSuffix(";", isaLine)
                    else {
                        throw lines.malformed("object without an 'isa'", start)
                    }
                    isa = isaLine.lowerBound + prefix.utf8CodeUnitCount ..<
                        isaLine.upperBound - 1

                    while true {
                        guard let line = lines.next() else {
                            throw lines.malformed("unterminated object", start)
                        }
                        if line.count == 4, lines.hasPrefix("\t\t};", line) {
                            break
                        }
                        guard lines.hasPrefix("\t\t\t", line) else {
                            throw lines.malformed("unterminated object", start)
                        }
                    }
                }

                objects.append(Object(
                    range: start ..< lines.offset,
                    idEnd: idEnd,
                    isa: isa
                ))
                objectsEnd = lines.offset
            }

            // Sorted by `isa`, then identifier. Ties keep their input order.
            objects.sort { lhs, rhs in
                let isa = input.compare(lhs.isa, rhs.isa)
                if isa != 0 { return isa < 0 }
                let id = input.compare(lhs.id, rhs.id)
                if id != 0 { return id < 0 }
                return lhs.range.lowerBound < rhs.range.lowerBound
            }

            // Ranges of `input` that are next to each other are written with
            // a single call
            var pending = 0 ..< 0
            func flush() throws {
                try write(.init(UnsafeBufferPointer(rebasing: input[pending])))
                pending = 0 ..< 0
            }
            func emit(_ range: Range<Int>) throws {
                if pending.upperBound == range.lowerBound {
                    pending = pending.lowerBound ..< range.upperBound
                } else {
                    try flush()
                    pending = range
                }
            }
            func emit(_ string: StaticString) throws {
                try flush()
                try write(UnsafeRawBufferPointer(
                    start: string.utf8Start,
                    count: string.utf8CodeUnitCount
                ))
            }
            func endSection(_ isa: Range<Int>) throws {
                try emit("/* End ")
                try emit(isa)
                try emit(" section */\n")
            }

            try emit(0 ..< objectsStart)
            var sectionISA: Range<Int>?
            for object in objects {
                let isNewSection = sectionISA
                    .map { input.compare($0, object.isa) != 0 } ?? true
                if isNewSection {
                    if let isa = sectionISA { try endSection(isa) }
                    try emit("\n/* Begin ")
                    try emit(object.isa)
                    try emit(" section */\n")
                    sectionISA = object.isa
                }
                try emit(object.range)
            }
            if let isa = sectionISA { try endSection(isa) }
            try emit(objectsEnd ..< input.count)
            try flush()
        }
    }
}

/// An object in the `objects` dictionary, as offsets into the partials.
/// They are stored as `UInt32`s because sorting smaller values is faster.
private struct Object {
    private let start, end, idEnd, isaStart, isaEnd: UInt32

    init(range: Range<Int>, idEnd: Int, isa: Range<Int>) {
        start = UInt32(range.lowerBound)
        end = UInt32(range.upperBound)
        self.idEnd = UInt32(idEnd)
        isaStart = UInt32(isa.lowerBound)
        isaEnd = UInt32(isa.upperBound)
    }

    var range: Range<Int> { Int(start) ..< Int(end) }
    var id: Range<Int> { Int(start) + 2 ..< Int(idEnd) }
    var isa: Range<Int> { Int(isaStart) ..< Int(isaEnd) }
}

/// Iterates over the lines of `input`.
private struct Lines {
    let input: UnsafeBufferPointer<UInt8>

    /// The offset of the next line.
    private(set) var offset = 0

    /// Returns the next line, without its `\n`.
    mutating func next() -> Range<Int>? {
        guard offset < input.count else { return nil }
        let start = offset
        let end = memchr(
            input.baseAddress! + start,
            Int32(UInt8(ascii: "\n")),
            input.count - start
        ).map {
            input.baseAddress!.distance(
                to: $0.assumingMemoryBound(to: UInt8.self)
            )
        } ?? input.count
        offset = min(end + 1, input.count)
        return start ..< end
    }

    func hasPrefix(_ string: StaticString, _ line: Range<Int>) -> Bool {
        return line.count >= string.utf8CodeUnitCount &&
            matches(string, at: line.lowerBound)
    }

    func hasSuffix(_ string: StaticString, _ line: Range<Int>) -> Bool {
        return line.count >= string.utf8CodeUnitCount &&
            matches(string, at: line.upperBound - string.utf8CodeUnitCount)
    }

    private func matches(_ string: StaticString, at offset: Int) -> Bool {
        return memcmp(
            input.baseAddress! + offset,
            string.utf8Start,
            string.utf8CodeUnitCount
        ) == 0
    }

    /// Returns the offset just after the first `string` in `range`.
    func firstIndex(after string: StaticString, in range: Range<Int>) -> Int? {
        let count = string.utf8CodeUnitCount
        return memmem(
            input.baseAddress! + range.lowerBound,
            range.count,
            string.utf8Start,
            count
        ).map {
            input.baseAddress!.distance(
                to: $0.assumingMemoryBound(to: UInt8.self)
            ) + count
        }
    }

    func malformed(_ message: String, _ offset: Int) -> Error {
        let line = 1 + input[..<offset].lazy
            .filter { $0 == UInt8(ascii: "\n") }.count
        return PreconditionError(message: """
Malformed 'PBXProj' partials (line \(line)): \(message)
""")
    }
}

private extension UnsafeBufferPointer<UInt8> {
    /// Compares the bytes in `lhs` and `rhs`, like `memcmp`.
    func compare(_ lhs: Range<Int>, _ rhs: Range<Int>) -> Int32 {
        let result = memcmp(
            baseAddress! + lhs.lowerBound,
            baseAddress! + rhs.lowerBound,
            Swift.min(lhs.count, rhs.count)
        )
        guard result == 0 else { return result }
        return lhs.count == rhs.count ? 0 : (lhs.count < rhs.count ? -1 : 1)
    }
}
