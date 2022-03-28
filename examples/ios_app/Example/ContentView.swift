import ExampleFramework
import ExternalFramework
import SwiftUI
import Utils

struct ContentView: View {
    static let exampleResourcesBundle = Bundle(
        path: Bundle.main.path(
            forResource: "ExampleResources",
            ofType: "bundle"
        )!
    )!

    var body: some View {
        VStack {
            Text("\(Foo().greeting())\n\(Bar.baz)\n\(Baz.bar)")
                .padding()
            Image("rules_xcodeproj", bundle: Self.exampleResourcesBundle)
                .resizable()
                .frame(width: 100, height: 100)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
