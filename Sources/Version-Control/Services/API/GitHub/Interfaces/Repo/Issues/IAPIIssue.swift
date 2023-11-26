//
//  IAPIIssue.swift
//
//
//  Created by Tihan-Nico Paxton on 2023/09/24.
//

import Foundation

/** Information about an issue as returned by the GitHub API. */
struct IAPIIssue: Codable {
    let number: Int
    let title: String
    let state: APIIssueState
    let updatedAt: String
}
