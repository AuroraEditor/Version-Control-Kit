//
//  Diff-Check.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/29.
//  Copyright © 2022 Aurora Company. All rights reserved.
//

import Foundation

public struct DiffCheck {

    public init(){}

    /// Matches a line reporting a leftover conflict marker
    /// and captures the name of the file
    let pattern = "^.+:(\\d+): leftover conflict marker$"

    /// Returns a list of files with conflict markers present
    public func getFilesWithConflictMarkers(directoryURL: URL) throws -> [String: Int] {
        let args = ["diff", "--check"]

        let output = try GitShell().git(args: args,
                                        path: directoryURL,
                                        name: #function,
                                        options: IGitExecutionOptions(successExitCodes: Set([0, 2])))
        

        let captures = Regex().getCaptures(text: output.stdout,
                                           expression: try NSRegularExpression(pattern: pattern,
                                                                               options: .caseInsensitive))

        if captures.isEmpty {
            return [:]
        }

        // Flatten the list (only does one level deep)
        let flatCaptures = captures.flatMap { $0 }

        var counted: [String: Int] = [:]
        for val in flatCaptures {
            counted[val, default: 0] += 1
        }

        return counted
    }
}
