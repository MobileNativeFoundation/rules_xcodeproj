import Darwin
import ToolCommon

extension Generator {
    /// Assembles the `project.pbxproj` file from the concatenated `partials`,
    /// in the layout that Xcode writes, and passes it to `write`.
    ///
    /// See the README for the format the partials need to have.
    static func assembleProjectPBXProj(
        _ partials: [UInt8],
        _ write: WriteBytes
    ) throws {
        precondition(partials.count < UInt32.max, "Partials are too large")

        try partials.withUnsafeBufferPointer { input in
            let parser = Parser(input: input)

            let objectsStart = try parser.objectsStart()
            var (objects, objectsEnd) = try parser.objects(from: objectsStart)

            // Sorted by `isa`, then identifier. Ties keep their input order.
            objects.sort { lhs, rhs in
                let isa = parser.compare(lhs.isa, rhs.isa)
                if isa != 0 { return isa < 0 }
                let id = parser.compare(lhs.id, rhs.id)
                if id != 0 { return id < 0 }
                return lhs.start < rhs.start
            }

            func emit(_ range: Range<Int>) throws {
                try write(UnsafeRawBufferPointer(
                    start: input.baseAddress! + range.lowerBound,
                    count: range.count
                ))
            }
            func emit(_ string: StaticString) throws {
                try write(UnsafeRawBufferPointer(
                    start: string.utf8Start,
                    count: string.utf8CodeUnitCount
                ))
            }

            try emit(0 ..< objectsStart)

            // Objects that are next to each other in `partials` are written
            // with a single call
            var pending = objectsStart ..< objectsStart
            var sectionISA: Range<Int>?
            for object in objects {
                if let isa = sectionISA, parser.compare(isa, object.isa) == 0 {
                    if pending.upperBound == object.range.lowerBound {
                        pending = pending.lowerBound ..< object.range.upperBound
                        continue
                    }
                    try emit(pending)
                } else {
                    try emit(pending)
                    if let isa = sectionISA {
                        try emit("/* End ")
                        try emit(isa)
                        try emit(" section */\n")
                    }
                    try emit("\n/* Begin ")
                    try emit(object.isa)
                    try emit(" section */\n")
                    sectionISA = object.isa
                }
                pending = object.range
            }
            try emit(pending)
            if let isa = sectionISA {
                try emit("/* End ")
                try emit(isa)
                try emit(" section */\n")
            }

            try emit(objectsEnd ..< input.count)
        }
    }
}

/// An object in the `objects` dictionary. Offsets are into the partials.
private struct Object {
    let start: UInt32
    let end: UInt32
    let idEnd: UInt32
    let isaStart: UInt32
    let isaEnd: UInt32

    var range: Range<Int> { Int(start) ..< Int(end) }
    var id: Range<Int> { Int(start) + 2 ..< Int(idEnd) }
    var isa: Range<Int> { Int(isaStart) ..< Int(isaEnd) }
}

private let tab = UInt8(ascii: "\t")

private struct Parser {
    let input: UnsafeBufferPointer<UInt8>

    /// Returns the offset just after the `\tobjects = {` line.
    func objectsStart() throws -> Int {
        var start = 0
        while start < input.count {
            let end = lineEnd(start)
            if matches("\tobjects = {", at: start, lineEnd: end) {
                return min(end + 1, input.count)
            }
            start = end + 1
        }
        throw PreconditionError(message: """
Malformed 'PBXProj' partials: missing the 'objects = {' line
""")
    }

    /// Finds the objects starting at `start`, returning them and the offset of
    /// the first line after them (normally `\t};`).
    func objects(from start: Int) throws -> (objects: [Object], end: Int) {
        var objects: [Object] = []
        var start = start
        while start < input.count {
            let end = lineEnd(start)
            guard end != start else {
                // Skip empty lines
                start = end + 1
                continue
            }
            // Objects start at exactly two tabs
            guard end - start > 2, input[start] == tab,
                  input[start + 1] == tab, input[start + 2] != tab
            else {
                break
            }

            var idEnd = start + 2
            while idEnd < end && input[idEnd] != UInt8(ascii: " ") {
                idEnd += 1
            }

            let isa: Range<Int>
            let objectEnd: Int
            if matches("};", at: end - 2, lineEnd: end) {
                // Single-line: `\t\t<id> /* <comment> */ = {isa = <isa>; ...};`
                guard let isaStart = firstIndex(
                        after: " = {isa = ",
                        in: idEnd ..< end
                      ),
                      let isaEnd = input[isaStart ..< end]
                        .firstIndex(of: UInt8(ascii: ";"))
                else {
                    throw malformed("object without an 'isa'", at: start)
                }
                isa = isaStart ..< isaEnd
                objectEnd = end + 1
            } else {
                // Multi-line: `isa` is the first attribute, and the object
                // ends at a line that is exactly `\t\t};`
                let isaLine = end + 1
                let isaLineEnd = lineEnd(isaLine)
                let prefix: StaticString = "\t\t\tisa = "
                guard isaLine < input.count,
                      matches(prefix, at: isaLine, lineEnd: isaLineEnd),
                      matches(";", at: isaLineEnd - 1, lineEnd: isaLineEnd)
                else {
                    throw malformed("object without an 'isa'", at: start)
                }
                isa = isaLine + prefix.utf8CodeUnitCount ..< isaLineEnd - 1

                var line = isaLineEnd + 1
                while true {
                    guard line < input.count else {
                        throw malformed("unterminated object", at: start)
                    }
                    let end = lineEnd(line)
                    if end - line == 4,
                       matches("\t\t};", at: line, lineEnd: end)
                    {
                        objectEnd = end + 1
                        break
                    }
                    guard matches("\t\t\t", at: line, lineEnd: end) else {
                        throw malformed("unterminated object", at: start)
                    }
                    line = end + 1
                }
            }

            let clampedEnd = min(objectEnd, input.count)
            objects.append(Object(
                start: UInt32(start),
                end: UInt32(clampedEnd),
                idEnd: UInt32(idEnd),
                isaStart: UInt32(isa.lowerBound),
                isaEnd: UInt32(isa.upperBound)
            ))
            start = clampedEnd
        }
        return (objects, min(start, input.count))
    }

    /// Compares the bytes in `lhs` and `rhs`, like `memcmp`.
    func compare(_ lhs: Range<Int>, _ rhs: Range<Int>) -> Int32 {
        let result = memcmp(
            input.baseAddress! + lhs.lowerBound,
            input.baseAddress! + rhs.lowerBound,
            min(lhs.count, rhs.count)
        )
        guard result == 0 else { return result }
        return lhs.count == rhs.count ? 0 : (lhs.count < rhs.count ? -1 : 1)
    }

    /// Returns the offset of the `\n` ending the line at `start`, or the end
    /// of the input.
    private func lineEnd(_ start: Int) -> Int {
        guard start < input.count,
              let newline = memchr(
                input.baseAddress! + start,
                Int32(UInt8(ascii: "\n")),
                input.count - start
              )
        else {
            return input.count
        }
        return input.baseAddress!.distance(
            to: newline.assumingMemoryBound(to: UInt8.self)
        )
    }

    /// Whether `string` is at `offset`, without going past `lineEnd`.
    private func matches(
        _ string: StaticString,
        at offset: Int,
        lineEnd: Int
    ) -> Bool {
        let count = string.utf8CodeUnitCount
        guard offset >= 0, offset + count <= lineEnd else { return false }
        return memcmp(input.baseAddress! + offset, string.utf8Start, count) == 0
    }

    /// Returns the offset just after the first `string` in `range`.
    private func firstIndex(
        after string: StaticString,
        in range: Range<Int>
    ) -> Int? {
        guard let found = memmem(
            input.baseAddress! + range.lowerBound,
            range.count,
            string.utf8Start,
            string.utf8CodeUnitCount
        ) else {
            return nil
        }
        return input.baseAddress!.distance(
            to: found.assumingMemoryBound(to: UInt8.self)
        ) + string.utf8CodeUnitCount
    }

    private func malformed(_ message: String, at offset: Int) -> Error {
        let line = 1 + input[..<offset].lazy
            .filter { $0 == UInt8(ascii: "\n") }.count
        return PreconditionError(message: """
Malformed 'PBXProj' partials (line \(line)): \(message)
""")
    }
}
