//
//  AuthorizationResponse.swift
//
//
//  Created by Nanashi Li on 2023/09/24.
//

import Foundation

/// Struct representing an authorization response.
struct AuthorizationResponse {
    /// The kind of authorization response.
    let kind: AuthorizationResponseKind
    
    /// The token associated with successful authorization.
    let token: String?
    
    /// The HTTP response associated with failed authorization.
    let response: String?
    
    /// The type of authentication mode required for two-factor authentication.
    let type: AuthenticationMode?
}
