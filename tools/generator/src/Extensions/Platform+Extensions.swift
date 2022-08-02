// MARK: `Platform.compatibility`

extension Platform {
    enum Compatibility: Equatable {
        case compatible
        case osNotEqual
        case variantNotEqual
        case archNotEqual
        case noMinimumOsSemanticVersionForSelf
        case noMinimumOsSemanticVersionForOther
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
        guard let minOsVersion = minimumOsVersion.semanticVersion else {
            return .noMinimumOsSemanticVersionForSelf
        }
        guard let otherMinOsVersion = other.minimumOsVersion.semanticVersion else {
            return .noMinimumOsSemanticVersionForOther
        }
        guard minOsVersion <= otherMinOsVersion else {
            return .minimumOsVersionGreaterThanOther
        }
        return .compatible
    }
}

// MARK: `Platform.compatibleWith`

extension Platform {
    func compatibleWith<Platforms: Sequence>(
        anyOf platforms: Platforms
    ) -> Bool where Platforms.Element == Platform {
        return platforms.contains { self.compatibility(with: $0).isCompatible }
    }
}
