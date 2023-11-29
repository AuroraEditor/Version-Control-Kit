//
//  IGitAccount.swift
//
//
//  Created by Nanashi Li on 2023/10/31.
//

import Foundation

/**
 * An account which can be used to potentially authenticate with a git server.
 */
public struct IGitAccount {

    /** The login/username to authenticate with. */
    let login: String

    /** The endpoint with which the user is authenticating. */
    let endpoint: String
}
