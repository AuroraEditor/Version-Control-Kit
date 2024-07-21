//
//  IAPIRepositoryPermissions.swift
//
//
//  Created by Nanashi Li on 2023/09/24.
//

import Foundation

/*
 * Information about how the user is permitted to interact with a repository.
 */
struct IAPIRepositoryPermissions: Codable {
    let admin: Bool
    let push: Bool
    let pull: Bool
}
