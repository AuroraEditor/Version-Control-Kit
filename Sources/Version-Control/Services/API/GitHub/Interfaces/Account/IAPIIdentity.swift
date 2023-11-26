//
//  IAPIIdentity.swift
//  
//
//  Created by Tihan-Nico Paxton on 2023/09/24.
//

import Foundation

/**
 Minimum subset of an identity returned by the GitHub API.
 */
public struct IAPIIdentity: Codable {
    public let id: Int
    public let login: String
    public let avatar_url: String
    public let html_url: String
    public let type: GitHubAccountType
}

/**
 Enumeration to represent the type of GitHub account.
 */
public enum GitHubAccountType: String, Codable {
    case user = "User"
    case organization = "Organization"
}
