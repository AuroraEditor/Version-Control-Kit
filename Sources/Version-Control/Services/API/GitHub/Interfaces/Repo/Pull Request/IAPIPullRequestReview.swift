//
//  File.swift
//  
//
//  Created by Tihan-Nico Paxton on 2023/09/24.
//

import Foundation

/**
 Represents a pull request review from the GitHub API.
 */
public struct IAPIPullRequestReview: Codable {
    public let id: Int
    public let node_id: String
    public let user: IAPIIdentity
    public let body: String?
    public let commit_id: String
    public let submitted_at: String?
    public let state: APIPullRequestReviewState
    public let html_url: String
}
