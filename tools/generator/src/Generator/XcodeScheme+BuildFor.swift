import XcodeProj

extension XcodeScheme {
    struct BuildFor: Equatable, Hashable {
        var running: Value
        var testing: Value
        var profiling: Value
        var archiving: Value
        var analyzing: Value

        init(
            running: Value = .unspecified,
            testing: Value = .unspecified,
            profiling: Value = .unspecified,
            archiving: Value = .unspecified,
            analyzing: Value = .unspecified
        ) {
            self.running = running
            self.testing = testing
            self.profiling = profiling
            self.archiving = archiving
            self.analyzing = analyzing
        }
    }
}

extension XcodeScheme.BuildFor {
    enum Value: Equatable, Hashable, Decodable {
        case unspecified
        case enabled
        case disabled
    }
}

extension XcodeScheme.BuildFor.Value {
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

extension XcodeScheme.BuildFor.Value {
    enum ValueError: Error, Equatable {
        case incompatibleMerge
    }

    func merged(with other: XcodeScheme.BuildFor.Value) throws -> XcodeScheme.BuildFor.Value {
        switch (self, other) {
        case (.enabled, .disabled), (.disabled, .enabled):
            throw ValueError.incompatibleMerge
        case (.enabled, .unspecified), (.unspecified, .enabled), (.enabled, .enabled):
            return .enabled
        case (.disabled, .unspecified), (.unspecified, .disabled), (.disabled, .disabled):
            return .disabled
        case (.unspecified, .unspecified):
            return .unspecified
        }
    }

    mutating func merge(with other: XCSchemeInfo.BuildFor.Value) throws {
        self = try merged(with: other)
    }
}

extension XcodeScheme.BuildFor {
    var xcSchemeValue: [XCScheme.BuildAction.Entry.BuildFor] {
        return [
            running.xcSchemeValue(.running),
            testing.xcSchemeValue(.testing),
            profiling.xcSchemeValue(.profiling),
            archiving.xcSchemeValue(.archiving),
            analyzing.xcSchemeValue(.analyzing),
        ].compactMap { $0 }
    }
}

extension XcodeScheme.BuildFor {
    private mutating func mergeValue(
        _ keyPath: WritableKeyPath<XcodeScheme.BuildFor, XcodeScheme.BuildFor.Value>,
        with other: XcodeScheme.BuildFor
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

    mutating func merge(with other: XcodeScheme.BuildFor) throws {
        try mergeValue(\.running, with: other)
        try mergeValue(\.testing, with: other)
        try mergeValue(\.profiling, with: other)
        try mergeValue(\.archiving, with: other)
        try mergeValue(\.analyzing, with: other)
    }
}

extension Sequence where Element == XcodeScheme.BuildFor {
    func merged() throws -> XcodeScheme.BuildFor {
        var result = XcodeScheme.BuildFor()
        for buildFor in self {
            try result.merge(with: buildFor)
        }
        return result
    }
}
