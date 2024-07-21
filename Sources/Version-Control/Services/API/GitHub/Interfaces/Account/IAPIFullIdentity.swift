//
//  IAPIFullIdentity.swift
//  
//
//  Created by Nanashi Li on 2023/09/24.
//

import Foundation

/**
 * Complete identity details returned in some situations by the GitHub API.
 *
 * If you are not sure what is returned as part of an API response, you should
 * use `IAPIIdentity` as that contains the known subset of an identity and does
 * not cover scenarios where privacy settings of a user control what information
 * is returned.
 */
struct IAPIFullIdentity: Codable {
    let id: Int
    let htmlUrl: String
    let login: String
    let avatarUrl: String

    /**
     * The user's real name or null if the user hasn't provided
     * a real name for their public profile.
     */
    let name: String?

    /**
     * The email address for this user or null if the user has not
     * specified a public email address in their profile.
     */
    let email: String?
    let type: GitHubAccountType
    let plan: Plan?

    struct Plan: Codable {
        let name: String
    }
}
