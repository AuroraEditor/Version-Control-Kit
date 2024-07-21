//
//  IAPIEmail.swift
//
//
//  Created by Nanashi Li on 2023/09/24.
//

import Foundation

/// `null` can be returned by the API for legacy reasons. A non-null value is
/// set for the primary email address currently, but in the future visibility
/// may be defined for each email address.
public enum EmailVisibility: String, Codable {
    case `public` = "public"
    case `private` = "private"
    case `null` = ""
}

/// Information about a user's email as returned by the GitHub API.
public struct IAPIEmail: Codable {
    let email: String
    let verified: Bool
    let primary: Bool
    let visibility: EmailVisibility

    public init(
        email: String,
        verified: Bool,
        primary: Bool,
        visibility: EmailVisibility
    ) {
        self.email = email
        self.verified = verified
        self.primary = primary
        self.visibility = visibility
    }
}
