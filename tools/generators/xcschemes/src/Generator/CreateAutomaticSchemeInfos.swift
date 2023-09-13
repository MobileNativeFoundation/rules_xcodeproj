import Foundation
import PBXProj
import XCScheme

extension Generator {
    struct CreateAutomaticSchemeInfos {
        private let createTargetAutomaticSchemeInfos:
            CreateTargetAutomaticSchemeInfos

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createTargetAutomaticSchemeInfos:
                CreateTargetAutomaticSchemeInfos,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.createTargetAutomaticSchemeInfos =
                createTargetAutomaticSchemeInfos

            self.callable = callable
        }

        /// Creates `SchemeInfo`s for automatically generated schemes.
        func callAsFunction(
            extensionHostIDs: [TargetID: [TargetID]],
            targets: [Target],
            targetsByID: [TargetID: Target],
            targetsByKey: [Target.Key: Target],
            transitivePreviewReferences: [TargetID: [BuildableReference]]
        ) throws -> [SchemeInfo] {
            return try callable(
                /*extensionHostIDs:*/ extensionHostIDs,
                /*targets:*/ targets,
                /*targetsByID:*/ targetsByID,
                /*targetsByKey:*/ targetsByKey,
                /*transitivePreviewReferences:*/ transitivePreviewReferences,
                /*createTargetAutomaticSchemeInfos:*/
                    createTargetAutomaticSchemeInfos
            )
        }
    }
}

// MARK: - CreateAutomaticSchemeInfos.Callable

extension Generator.CreateAutomaticSchemeInfos {
    typealias Callable = (
        _ extensionHostIDs: [TargetID: [TargetID]],
        _ targets: [Target],
        _ targetsByID: [TargetID: Target],
        _ targetsByKey: [Target.Key: Target],
        _ transitivePreviewReferences: [TargetID: [BuildableReference]],
        _ createTargetAutomaticSchemeInfos:
            Generator.CreateTargetAutomaticSchemeInfos
    ) throws -> [SchemeInfo]

    static func defaultCallable(
        extensionHostIDs: [TargetID: [TargetID]],
        targets: [Target],
        targetsByID: [TargetID: Target],
        targetsByKey: [Target.Key: Target],
        transitivePreviewReferences: [TargetID: [BuildableReference]],
        createTargetAutomaticSchemeInfos:
            Generator.CreateTargetAutomaticSchemeInfos
    ) throws -> [SchemeInfo] {
        return try targets.flatMap { target -> [SchemeInfo] in
            guard target.productType.shouldCreateScheme else {
                return []
            }

            return try createTargetAutomaticSchemeInfos(
                extensionHostIDs: extensionHostIDs,
                target: target,
                targetsByID: targetsByID,
                targetsByKey: targetsByKey,
                transitivePreviewReferences:
                    transitivePreviewReferences
            )
        }
    }
}

private extension PBXProductType {
    var shouldCreateScheme: Bool {
        switch self {
        case .messagesApplication, .watch2AppContainer, .watch2Extension:
            return false
        default:
            return true
        }
    }
}
