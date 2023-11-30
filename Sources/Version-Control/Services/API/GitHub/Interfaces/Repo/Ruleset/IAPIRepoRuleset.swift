//
//  IAPIRepoRuleset.swift
//
//
//  Created by Nanashi Li on 2023/09/24.
//

import Foundation

enum UserCanBypass: String, Codable {
    case always = "always"
    case pullRequestOnly = "pull_requests_only"
    case never = "never"
}

/**
 A ruleset returned from the GitHub API's "get a ruleset for a repo" endpoint.
 */
struct IAPIRepoRuleset: Codable {
    /// The ID of the ruleset.
    let id: Int

    /**
     Whether the user making the API request can bypass the ruleset.
     
     - Possible values:
       - `always`: The user can always bypass the ruleset.
       - `pull_requests_only`: The user can bypass the ruleset only for pull requests.
       - `never`: The user cannot bypass the ruleset.
     */
    let current_user_can_bypass: UserCanBypass
}
