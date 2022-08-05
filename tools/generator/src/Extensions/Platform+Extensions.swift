// MARK: `Platform.compatibility`

extension Platform {
    enum Compatibility: Equatable {
        case compatible
        case osNotEqual
        case variantNotEqual
        case archNotEqual
        case minimumOsVersionGreaterThanOther

        var isCompatible: Bool {
            switch self {
            case .compatible:
                return true
            default:
                return false
            }
        }
    }

    func compatibility(with other: Platform) -> Compatibility {
        guard os == other.os else {
            return .osNotEqual
        }
        guard variant == other.variant else {
            return .variantNotEqual
        }
        guard arch == other.arch else {
            return .archNotEqual
        }
        guard minimumOsVersion <= other.minimumOsVersion else {
            return .minimumOsVersionGreaterThanOther
        }
        return .compatible
    }
}

// MARK: `Platform.compatibleWith`

extension Platform {
    /// Determines whether the `Platform` is compatible with any of the specified `Platform` values.
    func compatibleWith<Platforms: Sequence>(
        anyOf platforms: Platforms
    ) -> Bool where Platforms.Element == Platform {
        return platforms.contains { self.compatibility(with: $0).isCompatible }
    }
}

extension Sequence where Element == Platform {
    /// Determines whether any of the `Platform` values are compatible with the specified `Platform`
    /// value.
    func compatibleWith(_ platform: Platform) -> Bool {
        return contains { $0.compatibility(with: platform).isCompatible }
    }
}
