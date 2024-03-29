public struct EnvironmentVariable: Equatable {
    let key: String
    let value: String
    let isEnabled: Bool

    public init(key: String, value: String, isEnabled: Bool = true) {
        self.key = key
        self.value = value
        self.isEnabled = isEnabled
    }
}

extension Array where Element == EnvironmentVariable {
    // This isn't a full `callAsFunction()` type because we don't test it
    // directly, but we reuse the logic in 3 elements.
    var environmentVariablesString: String {
        guard !isEmpty else {
            return ""
        }

        return #"""
      <EnvironmentVariables>
\#(map(createEnvironmentVariableElement).joined(separator: "\n"))
      </EnvironmentVariables>

"""#
    }
}

private func createEnvironmentVariableElement(
    _ variable: EnvironmentVariable
) -> String {
    return #"""
         <EnvironmentVariable
            key = "\#(variable.key.schemeXmlEscaped)"
            value = "\#(variable.value.schemeXmlEscaped)"
            isEnabled = "\#(variable.isEnabled.xmlString)">
         </EnvironmentVariable>
"""#
}
