import Foundation
import ToolCommon

struct AutogenerationConfigArguments {
    let appLanguage: String?
    let appRegion: String?
    let schemeNameExcludePatterns: [String]

    static func parse(
        from url: URL
    ) async throws -> Self {
      var rawArgs = ArraySlice(try await url.allLines.collect())

      let appLanguage = try rawArgs.consumeArg(
          "app_language",
          in: url
      )
      let appRegion = try rawArgs.consumeArg(
          "app_region",
          in: url
      )
      let schemeNameExcludePatterns = try rawArgs.consumeArgs(
          "scheme-name-exclude-patterns",
          in: url
      )

      return AutogenerationConfigArguments(
        appLanguage: !appLanguage.isEmpty ? appLanguage : nil,
        appRegion: !appRegion.isEmpty ? appRegion : nil,
        schemeNameExcludePatterns: schemeNameExcludePatterns
      )
    }
}
