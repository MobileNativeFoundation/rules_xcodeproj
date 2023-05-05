/// Helps set identifiers for `PBXProj` elements.
///
/// Identifiers are unique 12 byte numbers encoded as 24 character hex strings.
/// Since the various `PBXProj` partial generators need to work independently
/// from each other, they need help to be able to generate unique identifiers.
/// `Identifiers` is used to generate these identifiers.
public enum Identifiers {
    public enum FilesAndGroups {
        public static let mainGroup = "000000000000000000000003"
        public static let productsGroup = "000000000000000000000004"
    }

    public enum Project {
        public static let id = "000000000000000000000001"
        public static let buildConfigurationList = "000000000000000000000002"
    }
}
