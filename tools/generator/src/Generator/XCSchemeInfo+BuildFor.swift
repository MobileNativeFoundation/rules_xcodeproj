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
