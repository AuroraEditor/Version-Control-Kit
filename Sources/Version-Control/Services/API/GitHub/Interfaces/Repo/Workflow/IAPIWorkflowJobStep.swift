//
//  IAPIWorkflowJobStep.swift
//
//
//  Created by Nanashi Li on 2023/09/24.
//

import Foundation

struct IAPIWorkflowJobStep: Codable {
    let name: String
    let number: Int
    let status: APICheckStatus
    let conclusion: APICheckConclusion?
    let completed_at: String
    let started_at: String
    let log: String
}
