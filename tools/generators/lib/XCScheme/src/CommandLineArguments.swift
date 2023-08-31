extension Array where Element == String {
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

private func createCommandLineArgument(_ arg: String) -> String {
    return #"""
         <CommandLineArgument
            argument = "\#(arg.schemeXmlEscaped)"
            isEnabled = "YES">
         </CommandLineArgument>
"""#
}
