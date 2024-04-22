enum PIF {
    struct Project: Decodable {
        let targets: [String]
    }

    struct Target: Decodable {
        struct BuildConfiguration: Decodable {
            let name: String
            let buildSettings: [String: String]
        }

        let guid: String
        let buildConfigurations: [BuildConfiguration]
    }
}

struct BuildRequest: Decodable {
    let command: String = "build" // TODO: support other commands (e.g. "buildFiles")
    let configurationName: String
    let configuredTargets: [String]
    let platform: String

    enum Root: CodingKey {
        case configuredTargets
        case parameters

        enum ConfiguredTargets: CodingKey {
            case guid
        }
        enum Parameters: CodingKey {
            case activeRunDestination
            case configurationName

            enum ActiveRunDestination: CodingKey {
                case platform
            }
        }
    }

    init(from decoder: Decoder) throws {
        let root = try decoder.container(keyedBy: Root.self)
        let parameters = try root.nestedContainer(keyedBy: Root.Parameters.self, forKey: .parameters)

        // configurationName
        self.configurationName = try parameters.decode(String.self, forKey: .configurationName)

        // configuredTargets
        var configuredTargets = try root.nestedUnkeyedContainer(forKey: .configuredTargets)
        var decodedTargets = [String]()
        while !configuredTargets.isAtEnd {
            let target = try configuredTargets.nestedContainer(keyedBy: Root.ConfiguredTargets.self)
            decodedTargets.append(try target.decode(String.self, forKey: .guid))
        }
        self.configuredTargets = decodedTargets

        // platform
        let activeRunDestination = try parameters.nestedContainer(keyedBy: Root.Parameters.ActiveRunDestination.self, forKey: .activeRunDestination)
        self.platform = try activeRunDestination.decode(String.self, forKey: .platform)
    }
}

enum Output {
    typealias Map = [String: Target]

    struct Target: Codable {
        struct Config: Codable {
            struct Settings: Codable {
                let base: [String]
                var platforms: [String: Optional<[String]>]
            }

            let build: Settings?
            let buildFiles: Settings?
        }

        let label: String
        let configs: [String: Config]
    }
}
