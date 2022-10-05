//
//  Jobs.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/09/13.
//  Copyright © 2022 Aurora Company. All rights reserved.
//

import Foundation

public struct Jobs: Codable {
    public let id: Int
    public let runId: Int
    public let runURL: String
    public let runAttempt: Int
    public let url: String
    public let htmlURL: String
    public let status: String
    public let conclusion: String
    public let startedAt: String
    public let completedAt: String
    public let name: String
    public let steps: [JobSteps]
    public let runnerName: String?
    public let runnerGroupName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case runId = "run_id"
        case runURL = "run_url"
        case runAttempt = "run_attempt"
        case url
        case htmlURL = "html_url"
        case status
        case conclusion
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case name
        case steps
        case runnerName = "runner_name"
        case runnerGroupName = "runner_group_name"
    }
}
