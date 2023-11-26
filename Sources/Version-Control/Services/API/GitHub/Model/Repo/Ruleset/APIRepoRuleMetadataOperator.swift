//
//  APIRepoRuleMetadataOperator.swift
//
//
//  Created by Tihan-Nico Paxton on 2023/09/24.
//

import Foundation

/**
 Enum representing different operators for metadata rule matching.
 */
enum APIRepoRuleMetadataOperator: String, Codable {
    case startsWith = "starts_with"
    case endsWith = "ends_with"
    case contains = "contains"
    case regex = "regex"
}
