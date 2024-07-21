//
//  IAPIWorkflowRuns.swift
//  
//
//  Created by Nanashi Li on 2023/09/24.
//

import Foundation

struct IAPIWorkflowRuns: Codable {
    let total_count: Int
    let workflow_runs: [IAPIWorkflowRun]
}
