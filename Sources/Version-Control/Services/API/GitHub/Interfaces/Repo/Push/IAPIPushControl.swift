//
//  IAPIPushControl.swift
//
//
//  Created by Tihan-Nico Paxton on 2023/09/24.
//

/**
 A structure representing information about push control settings for a protected branch.
 */
struct IAPIPushControl: Codable {
    /**
     * What status checks are required before merging?
     *
     * Empty array if user is admin and branch is not admin-enforced
     */
    let required_status_checks: [String]
    
    /**
     * How many reviews are required before merging?
     *
     * 0 if user is admin and branch is not admin-enforced
     */
    let required_approving_review_count: Int
    
    /**
     * Is user permitted?
     *
     * Always `true` for admins.
     * `true` if `Restrict who can push` is not enabled.
     * `true` if `Restrict who can push` is enabled and user is in list.
     * `false` if `Restrict who can push` is enabled and user is not in list.
     */
    let allow_actor: Bool
    
    /**
     * Currently unused properties
     */
    let pattern: String?
    let required_signatures: Bool
    let required_linear_history: Bool
    let allow_deletions: Bool
    let allow_force_pushes: Bool
}

