//
//  APIRepoRuleType.swift
//  
//
//  Created by Tihan-Nico Paxton on 2023/09/24.
//

import Foundation

/**
 Enum representing different types of repository rules that can be configured.
 */
enum APIRepoRuleType: String, Codable {
    case creation
    case update
    case required_deployments
    case required_signatures
    case required_status_checks
    case pull_request
    case commit_message_pattern
    case commit_author_email_pattern
    case committer_email_pattern
    case branch_name_pattern
}
