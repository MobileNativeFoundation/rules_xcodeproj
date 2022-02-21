import CustomDump

@testable import XcodeProj

extension PBXObjects: CustomDumpReflectable {
    private static let ignoredProperties: Set<String> = [
        // Ignore lock property which is always different
        "lock",
    ]

    public var customDumpMirror: Mirror {
        let mirror = Mirror(reflecting: self)

        return Mirror(
            self,
            children: mirror.children
                .filter { !Self.ignoredProperties.contains($0.label!) },
            displayStyle: mirror.displayStyle
        )
    }
}

extension PBXObjectReference: CustomDumpReflectable {
    private static let ignoredProperties: Set<String> = [
        // Don't show all objects, as that makes the diffs super noisy
        "objects",
    ]

    public var customDumpMirror: Mirror {
        let mirror = Mirror(reflecting: self)

        return Mirror(
            self,
            children: mirror.children
                .filter { !Self.ignoredProperties.contains($0.label!) },
            displayStyle: mirror.displayStyle
        )
    }
}

extension PBXObject: CustomDumpReflectable {
    public var customDumpMirror: Mirror {
        return Mirror(
            self,
            // `PBXObject` has subclasses, and CustomDump will only look at the
            // direct children of a mirror. Here we show them all.
            children: Self.collectChildren(mirror: Mirror(reflecting: self))
                .sorted { lhs, rhs in
                    guard lhs.label == rhs.label else {
                        return lhs.label.localizedStandardCompare(rhs.label)
                            == .orderedAscending
                    }
                    return lhs.depth > rhs.depth
                }
                .map { (label: $0.label, value: $0.value) },
            displayStyle: .class
        )
    }

    static func collectChildren(
        mirror: Mirror,
        depth: Int = 0
    ) -> [(label: String, value: Any, depth: Int)] {
        var children: [(label: String, value: Any, depth: Int)]
        if let superclassMirror = mirror.superclassMirror {
            children = collectChildren(
                mirror: superclassMirror,
                depth: depth + 1
            )
        } else {
            children = []
        }

        children.append(
            contentsOf: processChildren(mirror, depth: depth)
        )

        return children
    }

    static func typeName(_ type: Any.Type) -> String {
        return String(reflecting: type)
    }

    static let valueSubstitutions: [String: [String: AnyKeyPath]] = [
        typeName(PBXBuildFile.self): ["buildPhase": \PBXObject.uuid],
        typeName(PBXContainerItemProxy.self): [
            "containerPortalReference": \PBXObjectReference.value,
            "remoteGlobalIDReference":
                \PBXContainerItemProxy.RemoteGlobalIDReference.uuid,
        ],
        typeName(PBXFileElement.self): ["parent": \PBXObject.uuid],
        typeName(PBXTargetDependency.self): [
            "targetReference": \PBXObjectReference.value,
        ],
    ]

    static func processChildren(
        _ mirror: Mirror,
        depth: Int
    ) -> [(label: String, value: Any, depth: Int)] {
        let substitutions = valueSubstitutions[
            typeName(mirror.subjectType),
            default: [:]
        ]

        return mirror.children.map { label, value in
            let label = label!
            let keyPath = substitutions[label, default: \Any.self]
            let effectiveValue = value[keyPath: keyPath] as Any

            return (label, effectiveValue, depth)
        }
    }
}
