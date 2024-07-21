//
//  APICheckStatus.swift
//
//
//  Created by Nanashi Li on 2023/09/24.
//

import Foundation

// The overall status of a check run
enum APICheckStatus: String, Codable {
    case queued
    case inProgress = "in_progress"
    case completed
}
