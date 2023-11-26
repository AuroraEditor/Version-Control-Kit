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
    case creation = "creation"
    case update = "update"
    case required_deployments = "required_deployments"
    case required_signatures = "required_signatures"
    case required_status_checks = "required_status_checks"
    case pull_request = "pull_request"
    case commit_message_pattern = "commit_message_pattern"
    case commit_author_email_pattern = "commit_author_email_pattern"
    case committer_email_pattern = "committer_email_pattern"
    case branch_name_pattern = "branch_name_pattern"
}
