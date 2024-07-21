//
//  IAPIPullRequestRef.swift
//
//
//  Created by Nanashi Li on 2023/09/24.
//

import Foundation

/**
 Represents a pull request reference from the GitHub API.
 */
public struct IAPIPullRequestRef: Codable {
    public let ref: String
    public let sha: String
    public let repo: IAPIRepository?
}
