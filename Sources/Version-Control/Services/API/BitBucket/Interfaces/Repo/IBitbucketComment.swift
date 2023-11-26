//
//  IBitbucketComment.swift
//
//
//  Created by Nanashi Li on 2023/10/31.
//

import Foundation

/**
 Represents both issue comments and PR review comments.
 */
public struct IBitbucketComment: Codable {
    public let id: Int
    public let body: String
    public let html_url: String
    public let user: IAPIIdentity
    public let created_at: String
}
