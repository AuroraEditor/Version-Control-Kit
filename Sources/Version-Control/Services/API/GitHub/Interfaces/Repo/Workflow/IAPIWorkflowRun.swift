//
//  IAPIWorkflowRun.swift
//  
//
//  Created by Nanashi Li on 2023/09/24.
//

import Foundation

struct IAPIWorkflowRun: Codable {
    let id: Int
    let workflow_id: Int
    let cancel_url: String
    let created_at: String
    let logs_url: String
    let name: String
    let rerun_url: String
    let check_suite_id: Int
    let event: String
}
