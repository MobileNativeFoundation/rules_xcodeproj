import CoreUtils
import UI
import SwiftUI

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
        return self
    }
}
