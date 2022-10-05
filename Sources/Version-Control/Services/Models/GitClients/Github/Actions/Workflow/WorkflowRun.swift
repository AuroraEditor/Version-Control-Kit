//
//  WorkflowRun.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/09/13.
//  Copyright © 2022 Aurora Company. All rights reserved.
//

import Foundation

public struct WorkflowRun: Codable {
    public let id: Int
    public let name: String
    public let nodeId: String
    public let headBranch: String
    public let runNumber: Int
    public let status: String
    public let conclusion: String
    public let workflowId: Int
    public let url: String
    public let htmlURL: String
    public let createdAt: String
    public let updatedAt: String
    public let headCommit: WorkflowRunCommit

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case nodeId = "node_id"
        case headBranch = "head_branch"
        case runNumber = "run_number"
        case status
        case conclusion
        case workflowId = "workflow_id"
        case url
        case htmlURL = "html_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case headCommit = "head_commit"
    }
}

public struct WorkflowRunCommit: Codable {
    public let id: String
    public let treeId: String
    public let message: String
    public let timestamp: String
    public let author: CommitAuthor

    enum CodingKeys: String, CodingKey {
        case id
        case treeId = "tree_id"
        case message
        case timestamp
        case author
    }
}

public struct CommitAuthor: Codable {
    public let name: String
    public let email: String
}
