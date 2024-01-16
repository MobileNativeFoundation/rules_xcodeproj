enum RuleKind: String {
    case appleIntentLibrary = "apple_intent_library"
    case iOSApplication = "ios_application"
    case iOSExtension = "ios_extension"
    case iOSFramework = "ios_framework"
    case iOSUITest = "ios_ui_test"
    case iOSUnitTest = "ios_unit_test"
    case swiftLibrary = "swift_library"
    case xcodeproj = "xcodeproj"
    case xcodeprojTopLevelTarget = "top_level_target"
}

extension RuleKind: CustomStringConvertible {
    var description: String {
        return rawValue
    }
}

private let iosBzl = "@build_bazel_rules_apple//apple:ios.bzl"
private let resourcesBzl = "@build_bazel_rules_apple//apple:resources.bzl"
private let swiftBzl = "@build_bazel_rules_swift//swift:swift.bzl"
private let xcodeProjBzl = "@rules_xcodeproj//xcodeproj:defs.bzl"

extension RuleKind {
    var bazelDep: BazelDep {
        switch self {
        case .appleIntentLibrary: return .rulesApple
        case .iOSApplication: return .rulesApple
        case .iOSExtension: return .rulesApple
        case .iOSFramework: return .rulesApple
        case .iOSUITest: return .rulesApple
        case .iOSUnitTest: return .rulesApple
        case .swiftLibrary: return .rulesSwift
        case .xcodeproj: return .rulesXcodeproj
        case .xcodeprojTopLevelTarget: return .rulesXcodeproj
        }
    }

    private var bzlPath: String {
        switch self {
        case .appleIntentLibrary: return resourcesBzl
        case .iOSApplication: return iosBzl
        case .iOSExtension: return iosBzl
        case .iOSFramework: return iosBzl
        case .iOSUITest: return iosBzl
        case .iOSUnitTest: return iosBzl
        case .swiftLibrary: return swiftBzl
        case .xcodeproj: return xcodeProjBzl
        case .xcodeprojTopLevelTarget: return xcodeProjBzl
        }
    }

    var loadableSymbol: LoadableSymbol {
        return LoadableSymbol(bzlPath: bzlPath, symbol: rawValue)
    }
}
