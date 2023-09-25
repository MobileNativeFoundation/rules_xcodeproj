public struct CommandLineArgument: Equatable {
    let value: String
    let enabled: Bool

    public init(value: String, enabled: Bool = true) {
        self.value = value
        self.enabled = enabled
    }
}

extension Array where Element == CommandLineArgument {
    // This isn't a full `callAsFunction()` type because we don't test it
    // directly, but we reuse the logic in 3 elements.
    var commandLineArgumentsString: String {
        guard !isEmpty else {
            return ""
        }

        return #"""
      <CommandLineArguments>
\#(map(createCommandLineArgument).joined(separator: "\n"))
      </CommandLineArguments>

"""#
    }
}

private func createCommandLineArgument(_ arg: CommandLineArgument) -> String {
    return #"""
         <CommandLineArgument
            argument = "\#(arg.value.schemeXmlEscaped)"
            isEnabled = "\#(arg.enabled.xmlString)">
         </CommandLineArgument>
"""#
}
