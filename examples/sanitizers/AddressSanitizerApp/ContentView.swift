import SwiftUI

struct ContentView: View {
    init() {
        AddressSanitizerExamples().run()
    }

    var body: some View {
        Text("""
        Application to demonstrate Address Sanitizer reporting heap buffer overflows in BwB mode.
        """)
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
