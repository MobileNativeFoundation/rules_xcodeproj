import SwiftUI

@main
struct AppClip: App {
    
    init() {
        ThreadSanitizer().test()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// TODO: Once the base approach is approved,
// create a different test suite for sanitizers that will
// host all the sanitizers related test-cases.
struct ThreadSanitizer {
    func test() {
        var name = ""
        DispatchQueue.global().async {
            name.append("Thread Sanitizer Test")
        }
        print(name)
    }
}

