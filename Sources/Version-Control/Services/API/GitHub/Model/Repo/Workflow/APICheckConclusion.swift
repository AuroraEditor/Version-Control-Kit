//
//  APICheckConclusion.swift
//  
//
//  Created by Tihan-Nico Paxton on 2023/09/24.
//

import Foundation

// The conclusion of a completed check run
enum APICheckConclusion: String, Codable {
    case actionRequired = "action_required"
    case canceled
    case timedOut = "timed_out"
    case failure
    case neutral
    case success
    case skipped
    case stale
}
