import XcodeProj

struct Environment {
    let createProject: (_ project: Project) -> (PBXProj, PBXProject)
}
