import ExampleFramework
import ExternalFramework
import SwiftUI
import Utils

struct ContentView: View {
    var body: some View {
        Text("\(Foo().greeting())\n\(Bar.baz)\n\(Baz.bar)")
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
