import SwiftUI
import UI

@main
struct watchOSApp: App { // swiftlint:disable:this type_name
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
