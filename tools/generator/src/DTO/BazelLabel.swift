struct BazelLabel: Equatable, Hashable, Decodable {
    let repository: String
    let package: String
    let name: String
}

// extension BazelLabel {
//     static func parse(_: String) -> BazelLabel? {
//         // TODO: IMPLEMENT ME!
//         return BazelLabel(
//             repository: "",
//             package: "",
//             name: ""
//         )
//     }
// }

extension BazelLabel {
    init?(_: String) {
        // TODO: IMPLEMENT ME!
        self.init(
            repository: "",
            package: "",
            name: ""
        )
    }
}

extension BazelLabel: CustomStringConvertible {
    var description: String {
        return "\(repository)//\(package):\(name)"
    }
}

extension BazelLabel: RawRepresentable {
    init?(rawValue: String) {
        self.init(rawValue)
    }

    var rawValue: String { "\(self)" }
}

extension BazelLabel: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self.init(value)!
        // guard let label = self.init(value) else {
        //     fatalError("Invalid Bazel label: \(value)")
        // }
        // self = label
    }
}

// struct BazelLabel: Equatble, Hashable, Decodable {
//     let rawValue: String

//     init(_ labelStr: String) {
//         self.rawValue = labelStr
//     }
// }

// extension BazelLabel: RawRepresentable {
//     init?
// }
