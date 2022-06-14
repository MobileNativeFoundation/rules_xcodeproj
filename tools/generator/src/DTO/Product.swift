import XcodeProj

struct Product: Equatable, Decodable {
    let type: PBXProductType
    let name: String
    let path: FilePath
}
