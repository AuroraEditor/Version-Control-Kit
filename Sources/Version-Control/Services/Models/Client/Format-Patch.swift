//
//  Format-Patch.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/13.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

/// Generate a patch representing the changes associated with a range of commits.
///
/// This function generates a patch representing the changes introduced by \
/// a range of commits between the `base` and `head` references.
///
/// - Parameters:
///   - directoryURL: The URL of the Git repository directory where the `git format-patch` command will be executed.
///   - base: The reference (commit, branch, etc.) representing the starting point of the commit range.
///   - head: The reference (commit, branch, etc.) representing the ending point of the commit range.
///
/// - Returns: A string containing the generated patch.
///
/// - Throws: An error if there is a problem executing the `git format-patch` command or \
///           if the Git repository is not in a valid state.
///
/// - Example:
///   ```swift
///   let directoryURL = URL(fileURLWithPath: "/path/to/git/repository")
///   let baseReference = "main"
///   let headReference = "feature/branch"
///
///   do {
///       let patch = try formatPatch(directoryURL: directoryURL, base: baseReference, head: headReference)
///       print("Generated Patch:")
///       print(patch)
///   } catch {
///       print("Error generating patch: \(error.localizedDescription)")
///   }
///   ```
///
/// - Note: Ensure that you have the necessary permissions to execute Git commands in the specified directory, \
/// and that the Git repository is in a valid state.
public func formatPatch(directoryURL: URL, base: String, head: String) throws -> String {
    let result = try ShellClient.live().run(
        "cd \(directoryURL.relativePath.escapedWhiteSpaces());" +
        "git format-patch --unified=1 --minimal --stdout \(base)..<\(head)"
    )

    return result
}
