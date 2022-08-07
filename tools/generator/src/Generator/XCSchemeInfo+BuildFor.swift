import XcodeProj

extension XCSchemeInfo {
    struct BuildFor: Equatable, Hashable {
        var running = Value.unspecified
        var testing = Value.unspecified
        var profiling = Value.unspecified
        var archiving = Value.unspecified
        var analyzing = Value.unspecified
    }
}

extension XCSchemeInfo.BuildFor {
    enum Value: Equatable {
        case unspecified
        case enabled
        case disabled
    }
}

extension XCSchemeInfo.BuildFor.Value {
    func xcSchemeValue(
        _ value: XCScheme.BuildAction.Entry.BuildFor
    ) -> XCScheme.BuildAction.Entry.BuildFor? {
        switch self {
        case .disabled:
            return nil
        default:
            return value
        }
    }
}

extension XCSchemeInfo.BuildFor.Value {
    enum ValueError: Error {
        case incompatibleMerge
    }

    func merged(with other: XCSchemeInfo.BuildFor.Value) throws -> XCSchemeInfo.BuildFor.Value {
        switch (self, other) {
        case (.enabled, .disabled), (.disabled, .enabled):
            throw ValueError.incompatibleMerge
        default:
            return other
        }
    }
}

extension XCSchemeInfo.BuildFor {
    var asXCSchemeBuildFor: [XCScheme.BuildAction.Entry.BuildFor] {
        return [
            running.xcSchemeValue(.running),
            testing.xcSchemeValue(.testing),
            profiling.xcSchemeValue(.profiling),
            archiving.xcSchemeValue(.archiving),
            analyzing.xcSchemeValue(.analyzing),
        ].compactMap { $0 }
    }
}

extension XCSchemeInfo.BuildFor {
    mutating func mergeValue(
        _ keyPath: WritableKeyPath<XCSchemeInfo.BuildFor, XCSchemeInfo.BuildFor.Value>,
        with other: XCSchemeInfo.BuildFor
    ) throws {
        let currentValue = self[keyPath: keyPath]
        let otherValue = other[keyPath: keyPath]
        do {
            self[keyPath: keyPath] = try currentValue.merged(with: otherValue)
        } catch Value.ValueError.incompatibleMerge {
            throw PreconditionError(message: """
Unable to merge `BuildFor` values for \(keyPath). current: \(currentValue), other: \(otherValue)
""")
        }
    }

    mutating func merge(with other: XCSchemeInfo.BuildFor) throws {
        try mergeValue(\.running, with: other)
        try mergeValue(\.testing, with: other)
        try mergeValue(\.profiling, with: other)
        try mergeValue(\.archiving, with: other)
        try mergeValue(\.analyzing, with: other)
        // try running.merge(other.running)
        // try testing.merge(other.testing)
        // try profiling.merge(other.profiling)
        // try archiving.merge(other.archiving)
        // try analyzing.merge(other.analyzing)
    }
}

extension Sequence where Element == XCSchemeInfo.BuildFor {
    func merged() throws -> XCSchemeInfo.BuildFor {
        var result = XCSchemeInfo.BuildFor()
        for buildFor in self {
            try result.merge(with: buildFor)
        }
        return result
    }
}
