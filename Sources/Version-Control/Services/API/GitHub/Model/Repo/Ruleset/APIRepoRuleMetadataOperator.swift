//
//  APIRepoRuleMetadataOperator.swift
//
//
//  Created by Nanashi Li on 2023/09/24.
//

import Foundation

/**
 Enum representing different operators for metadata rule matching.
 */
public enum APIRepoRuleMetadataOperator: String, Codable {
    case startsWith = "starts_with"
    case endsWith = "ends_with"
    case contains = "contains"
    case regex = "regex"
}
