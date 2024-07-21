//
//  IAPICheckSuite.swift
//  
//
//  Created by Nanashi Li on 2023/09/24.
//

import Foundation

struct IAPICheckSuite: Codable {
    let id: Int
    let rerequestable: Bool
    let runs_rerequestable: Bool
    let status: APICheckStatus
    let created_at: String
}
