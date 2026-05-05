import Foundation
import ToolCommon

struct AutogenerationConfig {
    struct Action: Equatable {
        let title: String
        let scriptText: String
        let order: Int?
    }

    let appLanguage: String?
    let appRegion: String?
    let buildPreActions: [Action]
    let buildPostActions: [Action]
    let buildRunPostActionsOnFailure: Bool
    let codeCoverage: Bool
    let profilePreActions: [Action]
    let profilePostActions: [Action]
    let runPreActions: [Action]
    let runPostActions: [Action]
    let testPreActions: [Action]
    let testPostActions: [Action]
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
      let buildPreActions = try rawArgs.consumeBuildActions(
          "build-pre-actions",
          in: url
      )
      let buildPostActions = try rawArgs.consumeBuildActions(
          "build-post-actions",
          in: url
      )
      let buildRunPostActionsOnFailure = try rawArgs.consumeArg(
          "build-run-post-actions-on-failure",
          as: Bool.self,
          in: url
      )
      let profilePreActions = try rawArgs.consumeBuildActions(
          "profile-pre-actions",
          in: url
      )
      let profilePostActions = try rawArgs.consumeBuildActions(
          "profile-post-actions",
          in: url
      )
      let runPreActions = try rawArgs.consumeBuildActions(
          "run-pre-actions",
          in: url
      )
      let runPostActions = try rawArgs.consumeBuildActions(
          "run-post-actions",
          in: url
      )
      let testPreActions = try rawArgs.consumeBuildActions(
          "test-pre-actions",
          in: url
      )
      let testPostActions = try rawArgs.consumeBuildActions(
          "test-post-actions",
          in: url
      )
      let schemeNameExcludePatterns = try rawArgs.consumeArgs(
          "scheme-name-exclude-patterns",
          in: url
      )

      return AutogenerationConfig(
        appLanguage: appLanguage,
        appRegion: appRegion,
        buildPreActions: buildPreActions,
        buildPostActions: buildPostActions,
        buildRunPostActionsOnFailure: buildRunPostActionsOnFailure,
        codeCoverage: codeCoverage,
        profilePreActions: profilePreActions,
        profilePostActions: profilePostActions,
        runPreActions: runPreActions,
        runPostActions: runPostActions,
        testPreActions: testPreActions,
        testPostActions: testPostActions,
        schemeNameExcludePatterns: schemeNameExcludePatterns
      )
    }
}

private extension ArraySlice where Element == String {
    mutating func consumeBuildActions(
        _ namePrefix: String,
        in url: URL,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> [AutogenerationConfig.Action] {
        let count = try consumeArg(
            "\(namePrefix)-count",
            as: Int.self,
            in: url,
            file: file,
            line: line
        )

        var buildActions: [AutogenerationConfig.Action] = []
        for _ in (0..<count) {
            let title = try consumeArg(
                "\(namePrefix)-title",
                in: url,
                file: file,
                line: line
            ).nullsToNewlines
            let scriptText = try consumeArg(
                "\(namePrefix)-script-text",
                in: url,
                file: file,
                line: line
            ).nullsToNewlines
            let order = try consumeArg(
                "\(namePrefix)-order",
                as: Int?.self,
                in: url,
                file: file,
                line: line
            )

            buildActions.append(
                .init(
                    title: title,
                    scriptText: scriptText,
                    order: order
                )
            )
        }

        return buildActions
    }
}
