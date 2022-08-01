// MARK: `Platform.OSVersion.semanticVersion`

extension Platform.OSVersion {
    var semanticVersion: SemanticVersion? {
        return .init(version: fullVersion)
    }
}

// MARK: `Platform.compatibility`

extension Platform {
    enum Compatibility: Equatable {
        case compatible
        case osNotEqual
        case variantNotEqual
        case archNotEqual
        case noMinimumOsSemanticVersionForSelf
        case noMinimumOsSemanticVersionForOther
        case minimumOsVersionGreaterThan

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
            return .minimumOsVersionGreaterThan
        }
        return .compatible
    }
}
