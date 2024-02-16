import Lib
import SwiftUI

public struct ContentView: View {
    let text: String

    public init(text: String = "Hello world") {
        self.text = text
    }

    public var body: some View {
        VStack {
            Text(text)
        }
            .padding(64)
            .multilineTextAlignment(.center)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(text: "Hello world from the previews!")
    }
}
