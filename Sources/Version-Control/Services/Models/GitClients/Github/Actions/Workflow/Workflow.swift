//
//  Workflow.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/09/13.
//  Copyright © 2022 Aurora Company. All rights reserved.
//

import Foundation
import SwiftUI

public struct Workflow: Codable, Hashable, Identifiable, Comparable {
    public static func < (lhs: Workflow, rhs: Workflow) -> Bool {
        return lhs.name < rhs.name
    }

    public let id: Int
    let nodeId: String
    let name: String
    let path: String
    let state: String
    let createdAt: String
    let updatedAt: String
    let url: String
    let htmlURL: String

    enum CodingKeys: String, CodingKey {
        case id
        case nodeId = "node_id"
        case name
        case path
        case state
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case url
        case htmlURL = "html_url"
    }
}
