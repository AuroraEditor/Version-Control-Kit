//
//  Code.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/15.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

/// Return an array of command line arguments for network operation that override
/// the default git configuration values provided by local, global, or system
/// level git configs.
///
/// These arguments should be inserted before the subcommand, i.e in the case of
/// git pull` these arguments needs to go before the `pull` argument.
public var gitNetworkArguments: [String] {
    // Explicitly unset any defined credential helper, we rely on our
    // own askpass for authentication.
    ["-c", "credential.helper="]
}

/// Returns the arguments to use on any git operation that can end up
/// triggering a rebase.
public func gitRebaseArguments() -> [String] {
    // Explicitly set the rebase backend to merge.
    // We need to force this option to be sure that AE
    // uses the merge backend even if the user has the apply backend
    // configured, since this is the only one supported.
    // This can go away once git deprecates the apply backend.
    return ["-c", "rebase.backend=merge"]
}

/// Parse the commit SHA from a Git command result string.
///
/// This function extracts the commit SHA from a Git command result string. It assumes that the result string follows a specific format, typically used in Git commands that return commit information.
///
/// - Parameter result: The Git command result string containing commit information.
///
/// - Returns: The commit SHA extracted from the result string.
///
/// - Example:
///   ```swift
///   let gitResult = "[commit abcdef12345678901234567890] Some commit message"
///   let commitSHA = parseCommitSHA(result: gitResult)
///   print("Parsed Commit SHA: \(commitSHA)")
///   ```
///
/// - Note:
///   This function is designed to work with Git command result strings that have a specific format, where the commit SHA is enclosed in square brackets (e.g., "[commit abcdef12345678901234567890]").
///
/// - Warning:
///   Ensure that the provided result string conforms to the expected format; otherwise, this function may not extract the commit SHA correctly.

public func parseCommitSHA(result: String) -> String {
    return String(result.split(separator: "]")[0].split(separator: " ")[1])
}
