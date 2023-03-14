import SwiftUI

struct ContentView: View {
    init() {
        ThreadSanitizerExamples().run()
    }

    var body: some View {
        Text("""
        Application to demonstrate Thread Sanitizer reporting data races in BwB mode.
        """)
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
