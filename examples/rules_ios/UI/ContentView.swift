import Lib
import SwiftUI

public struct ContentView: View {
    public init() {}

    public var body: some View {
        VStack {
            Text("Hello world")
        }
            .padding(64)
            .multilineTextAlignment(.center)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
