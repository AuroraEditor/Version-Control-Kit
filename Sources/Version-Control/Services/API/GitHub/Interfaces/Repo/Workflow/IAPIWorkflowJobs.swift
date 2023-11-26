//
//  IAPIWorkflowJobs.swift
//  
//
//  Created by Tihan-Nico Paxton on 2023/09/24.
//

import Foundation

struct IAPIWorkflowJobs: Codable {
    let total_count: Int
    let jobs: [IAPIWorkflowJob]
}
