import Foundation
import ToolCommon

struct AutogenerationConfigArguments {
    let appLanguage: String?
    let appRegion: String?
    let codeCoverage: Bool
    let schemeNameExcludePatterns: [String]

    static func parse(
        from url: URL
    ) async throws -> Self {
      var rawArgs = ArraySlice(try await url.allLines.collect())

      let appLanguage = try rawArgs.consumeArg(
          "app-language",
           as: String?.self,
          in: url
      )
      let appRegion = try rawArgs.consumeArg(
          "app-region",
           as: String?.self,
          in: url
      )
      let codeCoverage = try rawArgs.consumeArg(
          "code-coverage",
           as: Bool.self,
          in: url
      )
      let schemeNameExcludePatterns = try rawArgs.consumeArgs(
          "scheme-name-exclude-patterns",
          in: url
      )

      return AutogenerationConfigArguments(
        appLanguage: appLanguage,
        appRegion: appRegion,
        codeCoverage: codeCoverage,
        schemeNameExcludePatterns: schemeNameExcludePatterns
      )
    }
}
