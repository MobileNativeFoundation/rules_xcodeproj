import Mixed
import SwiftUI
import Views

@main
struct PreviewApp: App {
    var body: some Scene {
        WindowGroup {
            VStack {
                PreviewView()
                MixedPreviewView()
                Text(previewResourceMessage)
            }
        }
    }
}

#Preview {
    VStack {
        PreviewView()
        MixedPreviewView()
        Text(previewResourceMessage)
    }
}

private var previewResourceMessage: String {
    guard let bundleURL = Bundle.main.url(forResource: "SharedResources", withExtension: "bundle"),
          let bundle = Bundle(url: bundleURL),
          let messageURL = bundle.url(forResource: "message", withExtension: "txt"),
          let message = try? String(contentsOf: messageURL, encoding: .utf8)
    else { return "Preview resource missing" }
    return message.trimmingCharacters(in: .whitespacesAndNewlines)
}
