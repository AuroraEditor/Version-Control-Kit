//
//  Gravatar.swift
//
//
//  Created by Tihan-Nico Paxton on 2023/09/25.
//

import Foundation

struct Gravatar {

    /// Generates a Gravatar URL based on the provided email address and size.
    ///
    /// - Parameters:
    ///   - email: The email address associated with the Gravatar.
    ///   - size: An optional size parameter for the Gravatar image (default is 60).
    ///
    /// - Returns: A URL string representing the Gravatar image.
    ///
    /// - Example:
    ///   ```swift
    ///   let email = "example@example.com"
    ///   let gravatarUrl = generateGravatarUrl(email: email, size: 80)
    ///   ```
    ///
    /// - Note: Gravatar is a service that provides globally recognized avatars associated with email addresses.
    func generateGravatarUrl(email: String, size: Int = 60) -> String {
        let hash = email.md5(trim: true, caseSensitive: false)
        return "https://www.gravatar.com/avatar/\(hash)?s=\(size)"
    }
}
