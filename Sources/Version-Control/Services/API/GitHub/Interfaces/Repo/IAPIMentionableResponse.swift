//
//  IAPIMentionableResponse.swift
//  
//
//  Created by Nanashi Li on 2024/07/15.
//

public struct IAPIMentionableResponse: Codable {
    public let etag: String?
    public let users: [IAPIMentionableUser]
}

public struct IAPIMentionableUser: Codable {
    /**
     * The username or "handle" of the user
     */
    public let login: String
    /**
     * The user's real name (or at least the name that the user
     * has configured to be shown) or null if the user hasn't provided
     * a real name for their public profile.
     */

    public let name: String?
    /**
     * The user's attributable email address or null if the
     * user doesn't have an email address that they can be
     * attributed by
     */
    public let email: String
    /**
     * A url to an avatar image chosen by the user
     */
    public let avatar_url: String
}
