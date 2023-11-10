import SwiftUI
import Lib

@main
struct macOSApp: App { // swiftlint:disable:this type_name
    var body: some Scene {
        WindowGroup {
            VStack {
                ContentView()
                Text(Lib.libResourcesString)
            }
        }
    }
}
