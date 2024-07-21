//
//  IAPIWorkflowJobs.swift
//  
//
//  Created by Nanashi Li on 2023/09/24.
//

import Foundation

struct IAPIWorkflowJobs: Codable {
    let total_count: Int
    let jobs: [IAPIWorkflowJob]
}
