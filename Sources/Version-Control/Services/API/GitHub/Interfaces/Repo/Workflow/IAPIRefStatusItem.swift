//
//  IAPIRefStatusItem.swift
//
//
//  Created by Nanashi Li on 2023/09/24.
//

import Foundation

struct IAPIRefStatusItem: Codable {
    let state: APIRefState
    let target_url: String?
    let description: String
    let context: String
    let id: Int
}
