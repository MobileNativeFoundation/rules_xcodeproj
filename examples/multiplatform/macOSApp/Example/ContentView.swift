import ExampleFramework
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text(Bar().baz())
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
