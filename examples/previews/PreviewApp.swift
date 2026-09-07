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
            }
        }
    }
}
