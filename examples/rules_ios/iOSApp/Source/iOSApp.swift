import CoreUtils
import MixedAnswer
import SwiftUI
import UI
import FooPod

@main
struct iOSApp: App { // swiftlint:disable:this type_name
    var body: some Scene {
        WindowGroup {
            ContentView()
                .print(Answers().answer())
        }
    }
}

extension View {
    func print(_ value: Any) -> Self {
        Swift.print(value)
        Swift.print(MixedAnswerSwift.swiftMixedAnswer())
        return self
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Text("foo")
    }
}
