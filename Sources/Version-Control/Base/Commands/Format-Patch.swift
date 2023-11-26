//
//  Format-Patch.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/13.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

public struct FormatPatch {

    public init() {}

    /// Creates a patch string representation of changes between two commits.
    ///
    /// This asynchronous function leverages the `GitShell` utility to run the `git format-patch` 
    /// command, which generates a patch string for the changes between two specified revisions in a Git repository.
    ///
    /// - Parameters:
    ///   - directoryURL: A `URL` pointing to the Git repository's directory.
    ///   - base: A `String` representing the base commit or reference.
    ///   - head: A `String` representing the head commit or reference.
    ///
    /// - Returns: A `String` containing the patch data.
    ///
    /// - Throws: An error if the `git` command fails or if there are issues accessing the repository.
    ///
    /// The function constructs a revision range from the base to the head parameters, then passes this along with 
    /// other arguments to the `git` command via `GitShell`. The command specifies a unified diff with minimal
    /// context and directs the output to standard output instead of creating files. The function awaits the result and
    /// returns the standard output, which contains the patch data.
    ///
    /// This is an asynchronous function, and it must be called with `await` in an asynchronous context. 
    /// The use of `try` indicates that the function can throw an error which must be handled by the caller.
    func formatPatch(directoryURL: URL,
                     base: String,
                     head: String) async throws -> String {
        let range = RevList().revRange(from: base, to: head)
        let output = try GitShell().git(args: ["format-patch", "--unified=1", "--minimal", "--stdout", range],
                                        path: directoryURL,
                                        name: #function)
        return output.stdout
    }
}
