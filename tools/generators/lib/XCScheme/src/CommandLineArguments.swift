public struct CommandLineArgument: Equatable {
    let value: String
    let isEnabled: Bool
    let isLiteralString: Bool

    public init(
        value: String,
        isEnabled: Bool = true,
        isLiteralString: Bool = true
    ) {
        self.value = value
        self.isEnabled = isEnabled
        self.isLiteralString = isLiteralString
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
    let argument: String
    if !arg.isLiteralString {
        argument = arg.value.schemeXmlEscaped
    } else if arg.value.isEmpty {
        argument = "''"
    } else {
        argument = arg.value
            .replacingOccurrences(of: " ", with: #"\ "#)
            .replacingOccurrences(of: "\n", with: "\\\n")
            .replacingOccurrences(of: "'", with: #"\'"#)
            .replacingOccurrences(of: #"""#, with: #"\""#)
            .schemeXmlEscaped
    }

    return #"""
         <CommandLineArgument
            argument = "\#(argument)"
            isEnabled = "\#(arg.isEnabled.xmlString)">
         </CommandLineArgument>
"""#
}
