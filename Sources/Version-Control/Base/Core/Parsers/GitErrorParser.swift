//
//  GitErrorParser.swift
//
//
//  Created by Nanashi Li on 2023/10/31.
//

import Foundation

class GitErrorParser: Error {
    /// The result from the failed command.
    let result: IGitResult

    /// The args for the failed command.
    let args: [String]

    /// Whether or not the error message is just the raw output of the git command.
    let isRawMessage: Bool

    init(result: IGitResult, args: [String]) {
        var rawMessage = true
        var message = ""

        if let gitErrorDescription = result.gitErrorDescription {
            message = gitErrorDescription
            rawMessage = false
        } else if !result.combinedOutput.isEmpty {
            message = result.combinedOutput
        } else if !result.stderr.isEmpty {
            message = result.stderr
        } else if !result.stdout.isEmpty {
            message = result.stdout
        } else {
            message = "Unknown error"
            rawMessage = false
        }

        self.result = result
        self.args = args
        self.isRawMessage = rawMessage
    }
}

