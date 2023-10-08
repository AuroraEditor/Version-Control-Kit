//
//  Check.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/09/08.
//  Copyright © 2022 Aurora Company. All rights reserved.
//

import Foundation

public struct Check {

    public init() {}

    /// Checks if a given workspace directory is a Git repository or a Git worktree.
    ///
    /// - Parameter workspaceURL: The URL of the workspace directory to be checked.
    ///
    /// - Returns: `true` if the workspace is a Git repository or worktree, `false` otherwise.
    ///
    /// - Note: This function checks the type of the workspace using `getRepositoryType`, \
    ///   and if it's marked as unsafe by Git, \
    ///   it falls back to a naive approximation by looking for the `.git` directory.
    ///
    /// - Example:
    ///   ```swift
    ///   let workspaceURL = URL(fileURLWithPath: "/path/to/workspace")
    ///
    ///   if checkIfProjectIsRepo(workspaceURL: workspaceURL) {
    ///       print("The workspace is a Git repository or worktree.")
    ///   } else {
    ///       print("The workspace is not a Git repository or worktree.")
    ///   }
    ///   ```
    ///
    /// - Warning:
    ///   Ensure that the specified `workspaceURL` exists and is a valid directory.
    public func checkIfProjectIsRepo(workspaceURL: URL) -> Bool {
        do {
            let type = try getRepositoryType(path: workspaceURL.path)

            if type == .unsafe {
                // If the path is considered unsafe by Git, we won't be able to
                // verify that it's a repository (or worktree). So we'll fall back to this
                // naive approximation.
                return FileManager().directoryExistsAtPath("\(workspaceURL)/.git")
            }

            return type != .missing
        } catch {
            print("We couldn't verify if the current project is a Git repo!")
            return false
        }
    }
}
