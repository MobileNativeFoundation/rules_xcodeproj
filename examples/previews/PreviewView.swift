import Dependency
import SwiftUI

public struct PreviewView: View {
    public init() {}
    public var body: some View {
        Text("Native Preview: \(dependencyText())")
            .padding()
    }
}

#Preview {
    PreviewView()
}
