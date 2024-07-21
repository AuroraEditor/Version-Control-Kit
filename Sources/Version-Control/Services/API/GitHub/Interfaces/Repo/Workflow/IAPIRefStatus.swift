//
//  IAPIRefStatus.swift
//  
//
//  Created by Nanashi Li on 2023/09/24.
//

import Foundation

struct IAPIRefStatus: Codable {
    let state: APIRefState
    let total_count: Int
    let statuses: [IAPIRefStatusItem]
}
