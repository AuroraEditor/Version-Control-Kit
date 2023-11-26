//
//  IAPIOrganization.swift
//
//
//  Created by Tihan-Nico Paxton on 2023/09/24.
//

import Foundation

/**
 * Entity returned by the `/user/orgs` endpoint.
 *
 * Because this is specific to one endpoint it omits the `type` member from
 * `IAPIIdentity` that callers might expect.
 */
struct IAPIOrganization: Codable {
    let id: Int
    let url: String
    let login: String
    let avatarUrl: String
}
