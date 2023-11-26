//
//  IAPIRefCheckRuns.swift
//  
//
//  Created by Tihan-Nico Paxton on 2023/09/24.
//

import Foundation

struct IAPIRefCheckRuns: Codable {
    let total_count: Int
    let check_runs: [IAPIRefCheckRun]
}
