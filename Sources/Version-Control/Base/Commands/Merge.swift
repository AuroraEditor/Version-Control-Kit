//
//  Merge.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/13.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

public enum MergeResult {
    /// The merge completed successfully
    case success
    /// The merge was a noop since the current branch
    /// was already up to date with the target branch.
    case alreadyUpToDate
    /// The merge failed, likely due to conflicts.
    case failed
}

public struct Merge {

    public init() {}

    /// Merge the named branch into the current branch in the Git repository.
    ///
    /// This function performs a merge operation,
    /// incorporating changes from a named branch into the current branch of the Git repository. \
    /// You can specify whether to perform a regular merge or a squash merge.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the Git repository.
    ///   - branch: The name of the branch to merge into the current branch.
    ///   - isSquash: A flag indicating whether to perform a squash merge. Default is `false`.
    ///
    /// - Returns: A `MergeResult` indicating the result of the merge operation.
    ///
    /// - Throws: An error if there was an issue with the merge operation or if the provided branch name is invalid.
    ///
    /// - Example:
    ///   ```swift
    ///   let repositoryURL = URL(fileURLWithPath: "/path/to/git/repo")
    ///   let branchToMerge = "feature/branch-to-merge"
    ///
    ///   do {
    ///       let mergeResult = try merge(directoryURL: repositoryURL, branch: branchToMerge, isSquash: false)
    ///       switch mergeResult {
    ///           case .success:
    ///               print("Merge successful.")
    ///           case .alreadyUpToDate:
    ///               print("Branch is already up to date.")
    ///       }
    ///   } catch {
    ///       print("Error: \(error)")
    ///   }
    ///   ```
    ///
    /// - Important: This function performs a merge operation in the Git repository. \
    ///              Ensure that the provided branch name is valid and that the repository is in a \
    ///              clean state before calling this function.
    public func merge(directoryURL: URL,
                      branch: String,
                      isSquash: Bool = false) throws -> MergeResult {
        var args = ["merge"]

        if isSquash {
            args.append("--squash")
        }

        args.append(branch)

        // Execute the Git merge command.
        let result = try GitShell().git(args: args,
                                        path: directoryURL,
                                        name: #function,
                                        options: IGitExecutionOptions(expectedErrors: Set([GitError.MergeConflicts])))

        if result.exitCode != 0 {
            return MergeResult.failed
        }

        // If squash merge was requested, commit the changes without editing.
        if isSquash {
            let exitCode = try GitShell().git(args: ["commit", "--no-edit"],
                                              path: directoryURL,
                                              name: #function)
            if exitCode.exitCode != 0 {
                return MergeResult.failed
            }
        }

        return result.stdout == noopMergeMessage ? MergeResult.alreadyUpToDate : MergeResult.success
    }

    private let noopMergeMessage = "Already up to date.\n"

    /// Find the base commit between two commit-ish identifiers in the Git repository.
    ///
    /// This function calculates the merge base commit between two commit-ish identifiers
    /// (e.g., branch names, commit hashes) in the Git repository.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the Git repository.
    ///   - firstCommitish: The first commit-ish identifier.
    ///   - secondCommitish: The second commit-ish identifier.
    ///
    /// - Returns: The commit hash of the merge base if found, or `nil` if there is no common base commit.
    ///
    /// - Throws: An error if there was an issue calculating the merge base or if the commit-sh \
    ///           identifiers are invalid.
    ///
    /// - Example:
    ///   ```swift
    ///   let repositoryURL = URL(fileURLWithPath: "/path/to/git/repo")
    ///   let firstBranch = "feature/branch-a"
    ///   let secondBranch = "feature/branch-b"
    ///   if let mergeBase = try getMergeBase(
    ///       directoryURL: repositoryURL,
    ///       firstCommitish: firstBranch,
    ///       secondCommitish: secondBranch
    ///   ) {
    ///       print("Merge base commit: \(mergeBase)")
    ///   } else {
    ///       print("No common merge base found.")
    ///   }
    ///   ```
    ///
    /// - Important: This function requires valid commit-ish identifiers as input, \
    ///              and it may return `nil` if there is no common merge base between the provided commit-ish identifiers.
    public func getMergeBase(directoryURL: URL,
                             firstCommitish: String,
                             secondCommitish: String) throws -> String? {

        let process = try GitShell().git(args: ["merge-base",
                                                firstCommitish,
                                                secondCommitish],
                                         path: directoryURL,
                                         name: #function,
                                         options: IGitExecutionOptions(successExitCodes: Set([0, 1, 128])))

        // - 1 is returned if a common ancestor cannot be resolved
        // - 128 is returned if a ref cannot be found
        //   "warning: ignoring broken ref refs/remotes/origin/main."
        if process.exitCode == 1 || process.exitCode == 128 {
            return nil
        }

        return process.stdout.trimmingCharacters(in: .whitespaces)
    }

    /// Abort a conflicted merge in the Git repository.
    ///
    /// This function aborts a mid-flight merge operation that is in a conflicted state. \
    /// It is equivalent to running the `git merge --abort` command in the repository.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the Git repository.
    ///
    /// - Throws: An error if there was an issue aborting the merge operation or \
    ///           if the repository is not in a merge-conflicted state.
    ///
    /// - Example:
    ///   ```swift
    ///   let repositoryURL = URL(fileURLWithPath: "/path/to/git/repo")
    ///   try abortMerge(directoryURL: repositoryURL)
    ///   print("Merge aborted successfully.")
    ///   ```
    ///
    /// - Important: This function should only be called when the repository is in a conflicted state \
    ///              due to a mid-flight merge operation.
    public func abortMerge(directoryURL: URL) throws {
        // Execute the `git merge --abort` command to abort the conflicted merge.
        try GitShell().git(args: ["merge", "--abort"],
                           path: directoryURL,
                           name: #function)
    }

    /// Check if the `.git/MERGE_HEAD` file exists in the Git repository.
    ///
    /// This function checks for the presence of the `.git/MERGE_HEAD` file in the repository's Git directory. \
    /// The existence of this file typically indicates that the repository is in a conflicted state due to
    /// an ongoing merge operation.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the Git repository.
    ///
    /// - Returns: `true` if the `.git/MERGE_HEAD` file exists, indicating a conflicted state; otherwise, `false`.
    ///
    /// - Throws: An error if there was an issue accessing or reading the repository's Git directory.
    ///
    /// - Example:
    ///   ```swift
    ///   let repositoryURL = URL(fileURLWithPath: "/path/to/git/repo")
    ///   let isMergeHead = try isMergeHeadSet(directoryURL: repositoryURL)
    ///   if isMergeHead {
    ///       print("The repository is in a conflicted state due to an ongoing merge operation.")
    ///   } else {
    ///       print("The repository is not in a conflicted state.")
    ///   }
    ///   ```
    ///
    /// - Returns: `true` if the `.git/MERGE_HEAD` file exists; otherwise, `false`.
    public func isMergeHeadSet(directoryURL: URL) throws -> Bool {
        let path = try String(contentsOf: directoryURL) + ".git/MERGE_HEAD"
        return FileManager.default.fileExists(atPath: path)
    }

    /// Check if the `.git/SQUASH_MSG` file exists in the Git repository.
    ///
    /// This function checks for the presence of the `.git/SQUASH_MSG` file in the repository's Git directory. \
    /// The existence of this file typically indicates that a merge with the `--squash` option has been initiated,
    /// and the merge has not yet been committed. It can be an indicator of a detected conflict.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the Git repository.
    ///
    /// - Returns: `true` if the `.git/SQUASH_MSG` file exists, \
    ///            indicating a potential merge --squash scenario; otherwise, `false`.
    ///
    /// - Throws: An error if there was an issue accessing or reading the repository's Git directory.
    ///
    /// - Note: If a merge --squash is aborted, the `.git/SQUASH_MSG` file may not be cleared automatically, \
    ///         leading to its presence in non-merge --squashing scenarios.
    ///
    /// - Example:
    ///   ```swift
    ///   let repositoryURL = URL(fileURLWithPath: "/path/to/git/repo")
    ///   let isSquashMsg = try isSquashMsgSet(directoryURL: repositoryURL)
    ///   if isSquashMsg {
    ///       print("Potential merge --squash scenario detected.")
    ///   } else {
    ///       print("No merge --squash scenario detected.")
    ///   }
    ///   ```
    ///
    /// - Returns: `true` if the `.git/SQUASH_MSG` file exists; otherwise, `false`.
    public func isSquashMsgSet(directoryURL: URL) throws -> Bool {
        let path = try String(contentsOf: directoryURL) + ".git/SQUASH_MSG"
        return FileManager.default.fileExists(atPath: path)
    }
}
