//
//  APIRepoRuleType.swift
//  
//
//  Created by Nanashi Li on 2023/09/24.
//

import Foundation

/**
 Enum representing different types of repository rules that can be configured.
 */
public enum APIRepoRuleType: String, Codable {
    case creation
    case deletion
    case update
    case required_deployments
    case required_signatures
    case required_status_checks
    case required_linear_history
    case pull_request
    case commit_message_pattern
    case commit_author_email_pattern
    case committer_email_pattern
    case branch_name_pattern
    case non_fast_forward
}
