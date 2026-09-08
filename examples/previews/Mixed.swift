import SwiftUI

public struct MixedPreviewView: View {
    public init() {}
    public var body: some View {
        Text("Mixed total: \(previewC() + previewCpp() + previewObjC() + previewObjCpp())")
            .padding()
    }
}

#Preview {
    MixedPreviewView()
}
