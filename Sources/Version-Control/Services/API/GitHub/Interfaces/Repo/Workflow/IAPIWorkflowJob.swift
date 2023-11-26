//
//  IAPIWorkflowJob.swift
//  
//
//  Created by Tihan-Nico Paxton on 2023/09/24.
//

import Foundation

struct IAPIWorkflowJob: Codable {
    let id: Int
    let name: String
    let status: APICheckStatus
    let conclusion: APICheckConclusion?
    let completed_at: String
    let started_at: String
    let steps: [IAPIWorkflowJobStep]
    let html_url: String
}
