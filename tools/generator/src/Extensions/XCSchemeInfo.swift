import XcodeProj

struct XCSchemeInfo {
    let name: String
    let buildActionInfo: XCSchemeInfo.BuildActionInfo?
    let testActionInfo: XCSchemeInfo.TestActionInfo?
    let launchActionInfo: XCSchemeInfo.LaunchActionInfo?
}

extension XCSchemeInfo {
    struct BuildActionInfo {
        let targetInfos: [XCSchemeInfo.TargetInfo]
    }
}

extension XCSchemeInfo {
    struct TestActionInfo {
        let buildConfigurationName: String
        let targetInfos: [XCSchemeInfo.TargetInfo]
    }

    // TODO: Add init that confirms that the targetInfos are all isTestable.
}

extension XCSchemeInfo {
    struct LaunchActionInfo {
        let buildConfigurationName: String
        let targetInfo: XCSchemeInfo.TargetInfo
        let args: [String]
        let env: [String: String]
        let workingDirectory: String?
    }

    // TODO: Add init that confirms that the targetInfo is isLaunchable.
}

extension XCSchemeInfo {
    var wasCreatedForAppExtension: Bool {
        // TODO(chuck): Implement by looking at all of producTypes in the scheme. If any are
        // isExtension, then true.
        // wasCreatedForAppExtension: productType.isExtension ? true : nil
        return false
    }
}

extension XCSchemeInfo.LaunchActionInfo {
    var runnable: XCScheme.Runnable {
        if targetInfo.isWidgetKitExtension {
            return XCScheme.RemoteRunnable(
                buildableReference: targetInfo.buildableReference,
                bundleIdentifier: "com.apple.springboard",
                runnableDebuggingMode: "2"
            )
        } else {
            // If targeting a device for a Watch App, Xcode modifies the scheme
            // to use a `RemoteRunnable`. It does this automatically though, so
            // we don't have to account for it
            return XCScheme.BuildableProductRunnable(
                buildableReference: targetInfo.buildableReference
            )
        }
    }

    var askForAppToLaunch: Bool {
        return targetInfo.isWidgetKitExtension
    }

    var macroExpansion: XCScheme.BuildableReference? {
        // TODO(chuck): Update the host selection code.
        if let hostBuildableReference = targetInfo.hostInfos.first?.buildableReference,
            targetInfo.productType.isWatchApplication
        {
            return hostBuildableReference
        } else if targetInfo.pbxTarget.isTestable {
            return targetInfo.buildableReference
        }
        return nil
    }

    var launcher: String {
        if targetInfo.productType.canUseDebugLauncher {
            return XCScheme.defaultLauncher
        }
        return "Xcode.IDEFoundation.Launcher.PosixSpawn"
    }

    var debugger: String {
        if targetInfo.productType.canUseDebugLauncher {
            return XCScheme.defaultDebugger
        }
        return ""
    }
}
