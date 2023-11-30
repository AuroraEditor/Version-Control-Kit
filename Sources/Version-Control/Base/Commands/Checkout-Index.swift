//
//  File.swift
//  
//
//  Created by Nanashi Li on 2023/10/29.
//

import Foundation

public struct CheckoutIndex {

    public init() {}

    public func checkoutIndex(directoryURL: URL,
                              paths: [String]) async throws {

        if paths.isEmpty {
            return
        }

        let options: IGitExecutionOptions = IGitExecutionOptions(
            stdin: paths.joined(separator: "\0"),
            successExitCodes: Set([0, 1])
        )

        try GitShell().git(args: ["checkout-index", "-f", "-u", "-q", "--stdin", "-z"],
                           path: directoryURL,
                           name: #function,
        options: options)
    }
}
