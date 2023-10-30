import PBXProj

@testable import xcschemes

extension Generator {
    enum Stubs {
        static let createAutomaticSchemeInfo =
            CreateAutomaticSchemeInfo.stub(schemeInfos: [])
    }
}
