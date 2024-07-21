//
//  IAPISlimRepoRuleset.swift
//
//
//  Created by Nanashi Li on 2023/09/24.
//

import Foundation

/**
 A ruleset returned from the GitHub API's "get all rulesets for a repo" endpoint.
 This endpoint returns a slimmed-down version of the full ruleset object, though
 only the ID is used.
 */
struct IAPISlimRepoRuleset: Codable {
    /// The ID of the ruleset.
    let id: Int
}
