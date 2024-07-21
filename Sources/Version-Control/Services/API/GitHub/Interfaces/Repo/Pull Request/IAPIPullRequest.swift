//
//  IAPIPullRequest.swift
//
//
//  Created by Nanashi Li on 2023/09/24.
//

import Foundation

/**
 Represents information about a pull request from the GitHub API.
 */
public struct IAPIPullRequest: Codable {
    public let number: Int
    public let title: String
    public let created_at: String
    public let updated_at: String
    public let user: IAPIIdentity
    public let head: IAPIPullRequestRef
    public let base: IAPIPullRequestRef
    public let body: String
    public let state: String
    public let draft: Bool?
}
