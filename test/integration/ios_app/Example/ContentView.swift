import SwiftUI
import Utils

struct ContentView: View {
    var body: some View {
        Text(Utils.Foo().greeting())
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
