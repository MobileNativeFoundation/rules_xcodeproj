import XcodeProj

extension XcodeScheme {
    struct BuildFor: Equatable, Hashable, Decodable {
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
    enum Value: String, Equatable, Hashable, Decodable {
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
        case .enabled:
            return value
        default:
            return nil
        }
    }
}

extension XcodeScheme.BuildFor.Value {
    var isEnabled: Bool {
        guard self == .enabled else {
            return false
        }
        return true
    }

    var isDisabled: Bool {
        guard self == .disabled else {
            return false
        }
        return true
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

    mutating func merge(with other: XcodeScheme.BuildFor.Value) throws {
        self = try merged(with: other)
    }
}

extension XcodeScheme.BuildFor.Value {
    mutating func enableIfNotDisabled() {
        guard self != .disabled else {
            return
        }
        self = .enabled
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

extension PartialKeyPath where Root == XcodeScheme.BuildFor {
    var stringValue: String {
        switch self {
        case \XcodeScheme.BuildFor.running: return "running"
        case \XcodeScheme.BuildFor.testing: return "testing"
        case \XcodeScheme.BuildFor.profiling: return "profiling"
        case \XcodeScheme.BuildFor.archiving: return "archiving"
        case \XcodeScheme.BuildFor.analyzing: return "analyzing"
        default: return "<unknown>"
        }
    }
}

extension PartialKeyPath where Root == XcodeScheme.BuildFor {
    var actionType: String {
        switch self {
        case \XcodeScheme.BuildFor.running: return "launch"
        case \XcodeScheme.BuildFor.testing: return "test"
        case \XcodeScheme.BuildFor.profiling: return "profile"
        case \XcodeScheme.BuildFor.archiving: return "archive"
        case \XcodeScheme.BuildFor.analyzing: return "analyze"
        default: return "<unknown>"
        }
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

extension XcodeScheme.BuildFor {
    static let allEnabled = XcodeScheme.BuildFor(
        running: .enabled,
        testing: .enabled,
        profiling: .enabled,
        archiving: .enabled,
        analyzing: .enabled
    )
}
