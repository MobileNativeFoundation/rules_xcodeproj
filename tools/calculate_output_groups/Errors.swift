import ToolCommon

extension UsageError {
    static func buildMarker(_ path: String) -> Self {
        .init(message: """
error: Build marker (\(path)) doesn't exist. If you manually cleared Derived \
Data, you need to close and re-open the project for the file to be created \
again. Using the "Clean Build Folder" command instead (⇧ ⌘ K) won't trigger \
this error. If this error still happens after re-opening the project, please \
file a bug report here: \
https://github.com/MobileNativeFoundation/rules_xcodeproj/issues/new?template=bug.md
""")
    }

    static func pifCache(_ path: String) -> Self {
        .init(message: """
error: PIFCache (\(path)) doesn't exist. If you manually cleared Derived \
Data, you need to close and re-open the project for the PIFCache to be created \
again. Using the "Clean Build Folder" command instead (⇧ ⌘ K) won't trigger \
this error. If this error still happens after re-opening the project, please \
file a bug report here: \
https://github.com/MobileNativeFoundation/rules_xcodeproj/issues/new?template=bug.md
""")
    }

    static func buildRequest(_ path: String) -> Self {
        .init(message: """
error: Couldn't find a build-request.json file inside \(path)". Please file a bug \
report here: https://github.com/MobileNativeFoundation/rules_xcodeproj/issues/new?template=bug.md
""")
    }
}
