import XcodeProj

// DEBUG BEGIN
import Darwin
// DEBUG END

extension Generator {
    /// Creates an array of `XCScheme` entries for the specified targets.
    static func createXCSchemes(
        disambiguatedTargets: [TargetID: DisambiguatedTarget]
    ) -> [XCScheme] {
        // DEBUG BEGIN
        fputs("*** CHUCK disambiguatedTargets:\n", stderr)
        for (idx, item) in disambiguatedTargets.enumerated() {
            let disambiguatedTarget = item.1
            let target = disambiguatedTarget.target
            // fputs("*** CHUCK   \(idx) : \(String(reflecting: item.1))\n", stderr)
            fputs("*** CHUCK   \(idx) : \(String(reflecting: item.0))\n", stderr)
            fputs("*** CHUCK      disambiguatedTarget.name: \(String(reflecting: disambiguatedTarget.name))\n", stderr)
            fputs("*** CHUCK      target.name: \(String(reflecting: target.name))\n", stderr)
            fputs("*** CHUCK      target.product.type: \(String(reflecting: target.product.type))\n", stderr)
            fputs("*** CHUCK      dependencies: \(String(reflecting: target.dependencies))\n", stderr)
        }
        // DEBUG END

        // Need to group unit test target with its associated library for combo scheme
        // The rest of the targets will get their own scheme

        // Scheme actions: Build, Test, Run, Profile
        for _, disambiguatedTarget in disambiguatedTargets {
            // If
        }

        // GH101: Implement logic to create schemes from targets.
        return []
    }
}
