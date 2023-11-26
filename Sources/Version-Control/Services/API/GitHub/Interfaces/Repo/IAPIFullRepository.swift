//
//  IAPIFullRepository.swift
//
//
//  Created by Tihan-Nico Paxton on 2023/09/24.
//

import Foundation

struct IAPIFullRepository: Codable {
    
    /**
     * The parent repository of a fork.
     *
     * HACK: BEWARE: This is defined as `parent: IAPIRepository | undefined`
     * rather than `parent?: ...` even though the parent property is actually
     * optional in the API response. So we're lying a bit to the type system
     * here saying that this will be present but the only time the difference
     * between omission and explicit undefined matters is when using constructs
     * like `x in y` or `y.hasOwnProperty('x')` which we do very rarely.
     *
     * Without at least one non-optional type in this interface TypeScript will
     * happily let us pass an IAPIRepository in place of an IAPIFullRepository.
     */
    let parent: IAPIRepository?
    let cloneUrl: String
    let sshUrl: String
    let htmlUrl: String
    let name: String
    let owner: IAPIIdentity
    let isPrivate: Bool
    let isFork: Bool
    let defaultBranch: String
    let pushedAt: String
    let hasIssues: Bool
    let isArchived: Bool
    
    /**
     * The high-level permissions that the currently authenticated
     * user enjoys for the repository. Undefined if the API call
     * was made without an authenticated user or if the repository
     * isn't the primarily requested one (i.e. if this is the parent
     * repository of the requested repository)
     *
     * The permissions hash will also be omitted when the repository
     * information is embedded within another object such as a pull
     * request (base.repo or head.repo).
     *
     * In other words, the only time when the permissions property
     * will be present is when explicitly fetching the repository
     * through the `/repos/user/name` endpoint or similar.
     */
    let permissions: IAPIRepositoryPermissions?
}
