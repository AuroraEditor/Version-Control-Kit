//
//  IBitBucketAPIPullRequest.swift
//
//
//  Created by Nanashi Li on 2023/10/30.
//

import Foundation

struct IBitBucketAPIPullRequest: Codable {
    public let id: Int
    public let title: String
    public let created_on: String
    public let updated_on: String
    public let author: IAPIIdentity
    public let summary: IBitbucketRenderedBody
    public let state: String
}
