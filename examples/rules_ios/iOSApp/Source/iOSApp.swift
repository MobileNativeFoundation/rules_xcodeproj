import CoreUtils
import MixedAnswer
import SwiftUI
import UI

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
        let _: Foo = Foo.one
        Swift.print(value)
        Swift.print(MixedAnswerSwift.swiftMixedAnswer())
        return self
    }
}
