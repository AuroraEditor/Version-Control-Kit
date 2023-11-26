//
//  Reset.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/12.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

/// The reset modes which are supported.
public enum GitResetMode: Int {
    /// Resets the index and working tree. Any changes to tracked files in the
    /// working tree since <commit> are discarded.
    case hard = 0
    /// Does not touch the index file or the working tree at all (but resets the
    /// head to <commit>, just like all modes do). This leaves all your changed
    /// files "Changes to be committed", as git status would put it.
    case soft
    /// Resets the index but not the working tree (i.e., the changed files are
    /// preserved but not marked for commit) and reports what has not been updated.
    /// This is the default action for git reset.
    case mixed
}

public struct Reset {

    public init() {}

    /// Convert a Git reset mode and a reference to an array of Git command arguments.
    ///
    /// Use this function to convert a specified reset mode (e.g., hard, mixed, soft) 
    /// and a reference to an array of Git command arguments that can be used for performing a reset operation.
    ///
    /// - Parameters:
    ///   - mode: The reset mode, represented by the `GitResetMode` enum.
    ///   - ref: A string that resolves to a reference, such as 'HEAD' or a commit SHA, \
    ///          to which the reset operation should be applied.
    ///
    /// - Returns: An array of Git command arguments that correspond to the specified reset mode and reference.
    ///
    /// - Example:
    ///   ```swift
    ///   let resetMode = GitResetMode.hard
    ///   let reference = "HEAD~2"
    ///
    ///   let args = resetModeToArgs(mode: resetMode, ref: reference)
    ///   print("Git command arguments: git \(args.joined(separator: " "))")
    ///   ```
    ///
    /// - Note:
    ///   - This function is used to generate the Git command arguments for \
    ///     a reset operation based on the specified reset mode and reference.
    ///   - The resulting arguments can be passed to Git commands for resetting the repository's HEAD and index.
    public func resetModeToArgs(mode: GitResetMode, ref: String) -> [String] {
        switch mode {
        case .hard:
            return ["reset", "--hard", ref]
        case .mixed:
            return ["reset", ref]
        case .soft:
            return ["reset", "--soft", ref]
        }
    }

    /// Reset the Git repository's HEAD and index to a specified reference with the given mode.
    ///
    /// Use this function to reset the repository's HEAD and index to match a specific reference
    /// (e.g., commit or branch) using the specified reset mode.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory where the Git repository is located.
    ///   - mode: The mode to use when resetting the repository. See the `GitResetMode` enum for more information.
    ///   - ref: A string that resolves to a reference, such as 'HEAD' or a commit SHA, \
    ///          to which the repository's HEAD and index should be reset.
    ///
    /// - Throws: An error if the operation fails. \
    ///           Possible errors include Git-related errors or issues with the provided repository path.
    ///
    /// - Returns: `true` if the reset operation was successful; otherwise, `false`.
    ///
    /// - Example:
    ///   ```swift
    ///   // Replace with the repository's directory URL
    ///   let repositoryURL = URL(fileURLWithPath: "/path/to/your/repository")
    ///
    ///   do {
    ///       let success = try reset(directoryURL: repositoryURL, mode: .mixed, ref: "HEAD~2")
    ///       if success {
    ///           print("Repository has been reset to the specified reference.")
    ///       } else {
    ///           print("Repository reset failed.")
    ///       }
    ///   } catch {
    ///       print("Failed to reset the repository: \(error)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   - The `mode` parameter determines how the reset operation will behave (e.g., soft, mixed, hard). \
    ///     Refer to the `GitResetMode` enum for more details.
    ///   - This function alters the state of the Git repository, so use it with caution.
    ///
    /// - Warning:
    ///   Ensure that the provided `directoryURL` points to a valid Git repository directory. \
    ///   If the operation fails, check for potential issues with the repository or file permissions.
    public func reset(directoryURL: URL,
                      mode: GitResetMode,
                      ref: String) throws -> Bool {
        let args = resetModeToArgs(mode: mode, ref: ref)
        try GitShell().git(args: args,
                           path: directoryURL,
                           name: #function)
        return true
    }

    /// Updates the index with information from a particular tree for a given set of paths.
    ///
    /// Use this function to reset the index (staging area) to match a specific tree or commit 
    /// for a set of specified paths in the Git repository.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory where the Git repository is located.
    ///   - mode: The mode to use when resetting the index. See the `GitResetMode` enum for more information.
    ///   - ref: A string that resolves to a tree, such as 'HEAD' or a commit SHA, from which to update the index.
    ///   - paths: An array of strings representing the paths that should be updated in the index \
    ///            with information from the specified tree or commit.
    ///
    /// - Throws: An error if the operation fails. 
    ///           Possible errors include Git-related errors or issues with the provided repository path.
    ///
    /// - Example:
    ///   ```swift
    ///   // Replace with the repository's directory URL
    ///   let repositoryURL = URL(fileURLWithPath: "/path/to/your/repository")
    ///   // Replace with the paths you want to update
    ///   let pathsToUpdate = ["file1.txt", "folder/file2.txt"]
    ///
    ///   do {
    ///       try resetPaths(directoryURL: repositoryURL, mode: .soft, ref: "HEAD", paths: pathsToUpdate)
    ///       print("Index has been reset for the specified paths.")
    ///   } catch {
    ///       print("Failed to reset the index: \(error)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   - The `mode` parameter determines how the index will be reset (e.g., soft, mixed, hard).\
    ///     Refer to the `GitResetMode` enum for more details.
    ///   - This function updates the index to match the specified tree or commit, \
    ///     effectively altering the staging area's content.
    ///
    /// - Warning:
    ///   Ensure that the provided `directoryURL` points to a valid Git repository directory. \
    ///   If the operation fails, check for potential issues with the repository or file permissions.
    ///
    /// - SeeAlso: `GitResetMode`, `reset`, `resetPaths(directoryURL:mode:ref:)`
    public func resetPaths(directoryURL: URL,
                           mode: GitResetMode,
                           ref: String,
                           paths: [String]) throws {
        if paths.isEmpty {
            return
        }

        let baseArgs = resetModeToArgs(mode: mode,
                                       ref: ref)

        let args = baseArgs + ["--"] + paths

        try GitShell().git(args: args,
                           path: directoryURL,
                           name: #function)
    }

    /// Unstages all changes in the Git repository.
    ///
    /// This function removes all changes from the staging area (index) of the Git repository,
    /// effectively "unstaging" them. Any changes that were previously staged but not committed will be reset.
    ///
    /// - Parameter directoryURL: The URL of the directory where the Git repository is located.
    ///
    /// - Returns: `true` if the operation was successful, `false` otherwise.
    ///
    /// - Example:
    ///   ```swift
    ///   let repositoryURL = URL(
    ///       fileURLWithPath: "/path/to/your/repository"
    ///   ) // Replace with the repository's directory URL
    ///   let success = try? unstageAll(directoryURL: repositoryURL)
    ///   if success == true {
    ///       print("All changes have been unstaged.")
    ///   } else {
    ///       print("Failed to unstage changes.")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   This function is useful for undoing the staging of changes that were previously marked for commit
    ///   but not yet committed. \
    ///   After calling this function, 
    ///   the changes will remain in the working directory but will no longer be part of the next commit.
    ///
    /// - Warning:
    ///   Ensure that the provided `directoryURL` points to a valid Git repository directory. \
    ///   If the operation fails, check for potential issues with the repository or file permissions.
    ///
    /// - Returns: `true` if all changes were successfully unstaged, `false` if there was an error during the operation.
    @discardableResult
    public func unstageAll(directoryURL: URL) throws -> Bool {
        try GitShell().git(args: ["reset", "--", "."],
                           path: directoryURL,
                           name: #function)
        return true
    }
}
