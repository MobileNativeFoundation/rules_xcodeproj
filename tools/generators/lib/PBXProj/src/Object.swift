/// A `PBXProject.objects` element.
public struct Object: Equatable {
    public let identifier: String
    public let content: String

    public init(identifier: String, content: String) {
        self.identifier = identifier
        self.content = content
    }
}
