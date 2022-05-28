struct BuildSettingConditional: Equatable, Hashable {
    static let any: Self = .init(platform: nil)

    private let platform: Platform?
}

extension BuildSettingConditional {
    init(platform: Platform) {
        self.platform = platform
    }

    func conditionalize(_ key: String) -> String {
        guard let platform = platform else {
            return key
        }

        // The order here is the order that Xcode likes them (sdk before arch)
        var components = [key]
        if sdkConditionalAllowed(on: key) {
            components.append("[sdk=\(platform.name)*]")
        }
        if archConditionalAllowed(on: key) {
            components.append("[arch=\(platform.arch)]")
        }
        return components.joined()
    }

    private func archConditionalAllowed(on key: String) -> Bool {
        // TODO: If we ever add support for Universal targets we minimally need
        //   to exclude "ARCHS" here
        return false
    }

    private func sdkConditionalAllowed(on key: String) -> Bool {
        return key != "SDKROOT"
    }
}

extension BuildSettingConditional: Comparable {
    static func < (
        lhs: BuildSettingConditional,
        rhs: BuildSettingConditional
    ) -> Bool {
        guard
            let lhsPlatform = lhs.platform, let rhsPlatform = rhs.platform
        else {
            // Sort `.any` first
            return lhs.platform == nil && rhs.platform != nil
        }

        guard lhsPlatform.environment == rhsPlatform.environment else {
            // Sort simulator first
            switch (lhsPlatform.environment, rhsPlatform.environment) {
            case ("Simulator", _): return true
            case (_, "Simulator"): return false
            case (nil, _): return true
            case (_, nil): return false
            case ("Device", _): return true
            case (_, "Device"): return false
            default: return false
            }
        }

        // Sort Apple Silicon first
        return lhsPlatform.arch == "arm64" && rhsPlatform.arch != "arm64"
    }
}

extension Target {
    var buildSettingConditional: BuildSettingConditional {
        return BuildSettingConditional(platform: platform)
    }
}
