//
//  AuthorizationResponseKind.swift
//
//
//  Created by Nanashi Li on 2023/09/24.
//

/// Enum representing different kinds of authorization responses.
enum AuthorizationResponseKind {
    /// The authorization was successful.
    case authorized
    
    /// The authorization failed.
    case failed
    
    /// Two-factor authentication is required.
    case twoFactorAuthenticationRequired
    
    /// User verification is required.
    case userRequiresVerification
    
    /// Personal access token is blocked.
    case personalAccessTokenBlocked
    
    /// An error occurred during authorization.
    case error
    
    /// The enterprise is too old for the authorization.
    case enterpriseTooOld
    
    /// Web authentication flow is required.
    ///
    /// The API has indicated that the user is required to go through
    /// the web authentication flow.
    case webFlowRequired
}
