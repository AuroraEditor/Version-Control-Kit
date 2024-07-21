//
//  IAPIRepository.swift
//  
//
//  Created by Nanashi Li on 2023/09/24.
//

import Foundation

/**
 * Information about a repository as returned by the GitHub API.
 */
public struct IAPIRepository: Codable {
    let cloneUrl: String
    let sshUrl: String
    let htmlUrl: String
    let name: String
    let owner: IAPIIdentity
    let isPrivate: Bool
    let isFork: Bool
    let defaultBranch: String
    let pushedAt: String
    let hasIssues: Bool
    let isArchived: Bool
}
