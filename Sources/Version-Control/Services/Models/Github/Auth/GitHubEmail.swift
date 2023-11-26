//
//  GitHubEmail.swift
//
//
//  Created by Tihan-Nico Paxton on 2023/09/25.
//

import Foundation

public struct GitHubEmail {
    
    public init(){}
    
    /// Look up the preferred email address for a GitHub account.
    ///
    /// This function determines the preferred email address associated with a GitHub account. It follows a set of prioritized conditions to select the preferred email address.
    ///
    /// - Parameters:
    ///   - account: The GitHub account for which to look up the preferred email.
    ///
    /// - Returns: The preferred email address for the GitHub account.
    ///
    /// - Example:
    ///   ```swift
    ///   let githubAccount = Account(id: 12345, login: "octocat", endpoint: "users.noreply.github.com", emails: ["octocat@example.com"])
    ///   let preferredEmail = lookupPreferredEmail(account: githubAccount)
    ///   // preferredEmail is "octocat@example.com" as it's the primary and public email address.
    ///   ```
    ///
    /// - SeeAlso: `isEmailPublic(email:)`
    /// - SeeAlso: `getStealthEmailForUser(id:login:endpoint:)`
    public func lookupPreferredEmail(account: Account) -> String {
        let emails = account.emails

        if emails.isEmpty {
            return getStealthEmailForUser(id: account.id, login: account.login)
        }

        if let primary = emails.first(where: { $0.primary && isEmailPublic(email: $0) }) {
            return primary.email
        }

        let stealthSuffix = "@" + getStealthEmailHostForEndpoint()
        if let noReply = emails.first(where: { $0.email.lowercased().hasSuffix(stealthSuffix) }) {
            return noReply.email
        }

        return emails[0].email
    }

    /// Checks if the visibility of an email address is public or null.
    ///
    /// - Parameter email: An `IAPIEmail` object representing an email address.
    ///
    /// - Returns: `true` if the email address visibility is public or null, `false` otherwise.
    ///
    /// - Example:
    ///   ```swift
    ///   let email = IAPIEmail(visibility: .public, email: "example@example.com")
    ///   let isPublic = isEmailPublic(email)
    ///   // isPublic is true
    ///   ```
    public func isEmailPublic(email: IAPIEmail) -> Bool {
        return email.visibility == .public || email.visibility == .null
    }

    /// Get the email host for "noreply" GitHub user email addresses.
    ///
    /// - Returns: The email host used for "noreply" GitHub user email addresses, typically "users.noreply.github.com."
    ///
    /// - Example:
    ///   ```swift
    ///   let emailHost = getStealthEmailHostForEndpoint()
    ///   // emailHost is "users.noreply.github.com"
    ///   ```
    public func getStealthEmailHostForEndpoint() -> String {
        return "users.noreply.github.com"
    }

    /// Generate a legacy "noreply" email address for a GitHub user.
    ///
    /// This function constructs a legacy "noreply" email address for a GitHub user based on their login and the provided endpoint.
    ///
    /// - Parameters:
    ///   - login: The login or username of the GitHub user.
    ///   - endpoint: The endpoint associated with the GitHub user.
    ///
    /// - Returns: A legacy "noreply" email address in the format "<login>@<endpoint>," typically used for GitHub users.
    ///
    /// - Example:
    ///   ```swift
    ///   let login = "octocat"
    ///   let legacyEmail = getLegacyStealthEmailForUser(login: login)
    ///   // legacyEmail is "octocat@users.noreply.github.com"
    ///   ```
    ///
    /// - SeeAlso: `getStealthEmailHostForEndpoint()`
    public func getLegacyStealthEmailForUser(login: String) -> String {
        let stealthEmailHost = getStealthEmailHostForEndpoint()
        return "\(login)@\(stealthEmailHost)"
    }

    /// Generate a "noreply" email address for a GitHub user with additional information.
    ///
    /// This function constructs a "noreply" email address for a GitHub user based on their ID, login, and the provided endpoint.
    ///
    /// - Parameters:
    ///   - id: The ID of the GitHub user.
    ///   - login: The login or username of the GitHub user.
    ///   - endpoint: The endpoint associated with the GitHub user.
    ///
    /// - Returns: A "noreply" email address in the format "<id>+<login>@<endpoint>," which includes additional information and is typically used for GitHub notifications.
    ///
    /// - Example:
    ///   ```swift
    ///   let userId = 12345
    ///   let login = "octocat"
    ///   let stealthEmail = getStealthEmailForUser(id: userId, login: login)
    ///   // stealthEmail is "12345+octocat@users.noreply.github.com"
    ///   ```
    ///
    /// - SeeAlso: `getStealthEmailHostForEndpoint()`
    public func getStealthEmailForUser(id: Int, login: String) -> String {
        let stealthEmailHost = getStealthEmailHostForEndpoint()
        return "\(id)+\(login)@\(stealthEmailHost)"
    }

    /// Check if an email address is attributable to a GitHub account.
    ///
    /// This function checks whether a given email address can be attributed to a specific GitHub account. It does so by comparing the email address with the following:
    ///
    /// 1. Email addresses associated with the GitHub account (`account.emails`).
    /// 2. The "noreply" email address generated for the GitHub account.
    /// 3. The legacy "noreply" email address generated for the GitHub account.
    ///
    /// - Parameters:
    ///   - account: The GitHub account for which attribution is checked.
    ///   - email: The email address to check for attribution.
    ///
    /// - Returns: `true` if the email address is attributable to the GitHub account; otherwise, `false`.
    ///
    /// - Example:
    ///   ```swift
    ///   let githubAccount = Account(id: 12345, login: "octocat", endpoint: "users.noreply.github.com", emails: ["octocat@example.com"])
    ///   let emailToCheck = "12345+octocat@users.noreply.github.com"
    ///   let isAttributable = isAttributableEmailFor(account: githubAccount, email: emailToCheck)
    ///   // isAttributable is true since the email matches the GitHub account's generated "noreply" email.
    ///   ```
    ///
    /// - SeeAlso: `getStealthEmailForUser(id:login:endpoint:)`
    /// - SeeAlso: `getLegacyStealthEmailForUser(login:endpoint:)`
    public func isAttributableEmailFor(account: Account, email: String) -> Bool {
        let needle = email.lowercased()
        return account.emails.contains { $0.email.lowercased() == needle } ||
            getStealthEmailForUser(id: account.id, login: account.login).lowercased() == needle ||
            getLegacyStealthEmailForUser(login: account.login).lowercased() == needle
    }
}
