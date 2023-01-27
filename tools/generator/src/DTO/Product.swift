import PathKit
import XcodeProj

struct Product: Equatable {
    let type: PBXProductType
    let isResourceBundle: Bool
    let name: String
    let path: FilePath?
    var additionalPaths: [FilePath]
    let executableName: String?

    /// Custom initializer for easier testing.
    init(
        type: PBXProductType,
        isResourceBundle: Bool = false,
        name: String,
        path: FilePath?,
        additionalPaths: [FilePath] = [],
        executableName: String? = nil
    ) {
        self.type = type
        self.isResourceBundle = isResourceBundle
        self.name = name
        self.path = path
        self.additionalPaths = additionalPaths
        self.executableName = executableName
    }
}

// MARK: - Decodable

extension Product: Decodable {
    enum CodingKeys: String, CodingKey {
        case type = "t"
        case isResourceBundle = "r"
        case name = "n"
        case path = "p"
        case additionalPaths = "a"
        case executableName = "e"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        type = try container.decode(PBXProductType.self, forKey: .type)
        isResourceBundle = try container
            .decodeIfPresent(Bool.self, forKey: .isResourceBundle) ?? false
        name = try container.decode(String.self, forKey: .name)
        path = try container.decodeIfPresent(FilePath.self, forKey: .path)
        additionalPaths = try container
            .decodeIfPresent([FilePath].self, forKey: .additionalPaths) ?? []
        executableName = try container
            .decodeIfPresent(String.self, forKey: .executableName)
    }
}
