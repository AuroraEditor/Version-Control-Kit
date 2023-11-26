//
//  IAPIWorkflowRuns.swift
//  
//
//  Created by Tihan-Nico Paxton on 2023/09/24.
//

import Foundation

struct IAPIWorkflowRuns: Codable {
    let total_count: Int
    let workflow_runs: [IAPIWorkflowRun]
}
