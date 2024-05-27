import Foundation
import ToolCommon

struct AutogenerationConfigArguments {
    let schemeNameExcludePatterns: [String]

    static func parse(
        from url: URL
    ) async throws -> Self {
      var rawArgs = ArraySlice(try await url.allLines.collect())

      let schemeNameExcludePatterns = try rawArgs.consumeArgs(
          "scheme-name-exclude-patterns",
          in: url
      )

      return AutogenerationConfigArguments(
        schemeNameExcludePatterns: schemeNameExcludePatterns
      )
    }
}
