//
//  Branch.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/12.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

public struct Branch {

    public init() {}

    /// Retrieves the name of the current Git branch in a specified directory.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the branch retrieval process.
    ///
    /// - Returns:
    ///   The name of the current branch as a string.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repo")
    ///
    ///   do {
    ///       let currentBranch = try getCurrentBranch(directoryURL: directoryURL)
    ///       print("Current Branch: \(currentBranch)")
    ///   } catch {
    ///       print("Error retrieving current branch: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Warning:
    ///   Ensure that the specified `directoryURL` exists and is a valid Git repository directory.
    public func getCurrentBranch(directoryURL: URL) throws -> String {
        return try ShellClient.live().run(
            "cd \(directoryURL.relativePath.escapedWhiteSpaces());git rev-parse --abbrev-ref HEAD"
        ).removingNewLines()
    }

    /// Retrieves a list of Git branches in a specified directory.
    ///
    /// - Parameters:
    ///   - allBranches: A Boolean flag indicating whether to list all branches, \
    ///                  including remote branches (default is `false`).
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the branch retrieval process.
    ///
    /// - Returns:
    ///   An array of branch names.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repo")
    ///
    ///   // List all branches (local and remote)
    ///   do {
    ///       let branches = try getBranches(true, directoryURL: directoryURL)
    ///       if branches.isEmpty {
    ///           print("No branches found.")
    ///       } else {
    ///           print("Branches:")
    ///           for branch in branches {
    ///               print(branch)
    ///           }
    ///       }
    ///   } catch {
    ///       print("Error retrieving branches: \(error.localizedDescription)")
    ///   }
    ///
    ///   // List only local branches (default behavior)
    ///   do {
    ///       let localBranches = try getBranches(directoryURL: directoryURL)
    ///       if localBranches.isEmpty {
    ///           print("No local branches found.")
    ///       } else {
    ///           print("Local Branches:")
    ///           for branch in localBranches {
    ///               print(branch)
    ///           }
    ///       }
    ///   } catch {
    ///       print("Error retrieving local branches: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Warning:
    ///   Ensure that the specified `directoryURL` exists and is a valid Git repository directory.
    public func getBranches(_ allBranches: Bool = false, directoryURL: URL) throws -> [String] {
        if allBranches == true {
            return try ShellClient.live().run(
                "cd \(directoryURL.relativePath.escapedWhiteSpaces());git branch -a --format \"%(refname:short)\""
            )
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
        }
        return try ShellClient.live().run(
            "cd \(directoryURL.relativePath.escapedWhiteSpaces());git branch --format \"%(refname:short)\""
        )
        .components(separatedBy: "\n")
        .filter { !$0.isEmpty }
    }

    /// Creates a new Git branch in a specified directory.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory where the branch will be created.
    ///   - name: The name of the new branch.
    ///   - startPoint: An optional starting point for the new branch (e.g., commit hash or existing branch name).
    ///   - noTrack: A Boolean flag indicating whether the new branch should not track a remote branch.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during branch creation.
    ///
    /// - Note:
    ///   If `startPoint` is not provided, a new branch will be created without a starting point.
    ///
    /// - Note:
    ///   If `noTrack` is `true`, the `--no-track` flag will be included when creating the branch.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repo")
    ///   let branchName = "feature/new-feature"
    ///
    ///   do {
    ///       try createBranch(directoryURL: directoryURL, name: branchName, startPoint: "main", noTrack: false)
    ///       print("Branch '\(branchName)' created successfully.")
    ///   } catch {
    ///       print("Error creating branch: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Warning:
    ///   Ensure that the specified `directoryURL` exists and is a valid Git repository directory.
    ///
    /// - SeeAlso:
    ///   [Git Branch Documentation](https://git-scm.com/docs/git-branch)
    public func createBranch(directoryURL: URL,
                             name: String,
                             startPoint: String?,
                             noTrack: Bool?) throws {
        var args: [String] = startPoint != nil ? ["branch", name, startPoint!] : ["branch", name]

        if noTrack != nil {
            args.append("--no-track")
        }

        try ShellClient().run(
            "cd \(directoryURL.relativePath.escapedWhiteSpaces());git \(args.joined(separator: " "))")
    }

    /// Renames an existing Git branch in a specified directory.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///   - branch: The name of the branch to be renamed.
    ///   - newName: The new name for the branch.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the branch renaming process.
    ///
    /// - Note:
    ///   If the branch renaming is successful, the old branch name will no longer exist, \
    ///   and a new branch with the specified `newName` will be created.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repo")
    ///   let oldBranchName = "feature/old-feature"
    ///   let newBranchName = "feature/new-feature"
    ///
    ///   do {
    ///       try renameBranch(directoryURL: directoryURL, branch: oldBranchName, newName: newBranchName)
    ///   } catch {
    ///       print("Error renaming branch: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Warning:
    ///   Ensure that the specified `directoryURL` exists and is a valid Git repository directory.
    public func renameBranch(directoryURL: URL,
                             branch: String,
                             newName: String) throws {
        /// Prepare and execute the Git command to rename the branch using a ShellClient.
        try ShellClient().run(
            "cd \(directoryURL.relativePath.escapedWhiteSpaces());git branch -m \(branch) \(newName)")
    }

    /// Deletes a local Git branch in a specified directory.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///   - branchName: The name of the local branch to be deleted.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the branch deletion process.
    ///
    /// - Returns:
    ///   A `Bool` value indicating whether the branch was successfully deleted. \
    ///   Returns `true` if the branch was deleted successfully; otherwise, returns `false`.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repo")
    ///   let branchToDelete = "feature/old-feature"
    ///
    ///   do {
    ///       let isDeleted = try deleteLocalBranch(directoryURL: directoryURL, branchName: branchToDelete)
    ///       if isDeleted {
    ///           print("Branch '\(branchToDelete)' was successfully deleted.")
    ///       } else {
    ///           print("Branch '\(branchToDelete)' could not be deleted.")
    ///       }
    ///   } catch {
    ///       print("Error deleting branch: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Warning:
    ///   Ensure that the specified `directoryURL` exists and is a valid Git repository directory.
    public func deleteLocalBranch(directoryURL: URL,
                                  branchName: String) throws -> Bool {
        /// Prepare and execute the Git command to delete the local branch using a ShellClient.
        try ShellClient().run(
            "cd \(directoryURL.relativePath.escapedWhiteSpaces());git branch -D \(branchName)")

        // Return true to indicate that the branch deletion was attempted.
        return true
    }

    /// Deletes a remote Git branch in a specified directory.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///   - remoteName: The name of the remote repository (e.g., "origin").
    ///   - remoteBranchName: The name of the remote branch to be deleted.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the remote branch deletion process.
    ///
    /// - Note:
    ///   This function attempts to delete the remote branch on the specified remote repository. \
    ///   If the deletion fails due to the remote branch already being deleted or for any other reason, \
    ///   it may try to remove the corresponding local reference.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repo")
    ///   let remoteName = "origin"
    ///   let remoteBranchName = "feature/old-feature"
    ///
    ///   do {
    ///       try deleteRemoteBranch(
    ///           directoryURL: directoryURL,
    ///           remoteName: remoteName,
    ///           remoteBranchName: remoteBranchName
    ///       )
    ///       print("Remote branch '\(remoteBranchName)' was successfully deleted on '\(remoteName)'.")
    ///   } catch {
    ///       print("Error deleting remote branch: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Warning:
    ///   Ensure that the specified `directoryURL` exists and is a valid Git repository directory.
    public func deleteRemoteBranch(directoryURL: URL,
                                   remoteName: String,
                                   remoteBranchName: String) throws {
        let args: [Any] = [
            "push",
            remoteName,
            ":\(remoteBranchName)"
        ]

        let result = try ShellClient.live().run(
            "cd \(directoryURL.relativePath.escapedWhiteSpaces());git \(args)")

        // It's possible that the delete failed because the ref has already
        // been deleted on the remote. If we identify that specific
        // error we can safely remove our remote ref which is what would
        // happen if the push didn't fail.
        if result == GitError.branchDeletionFailed.rawValue {
            let ref = "refs/remotes/\(remoteName)/\(remoteBranchName)"
            try UpdateRef().deleteRef(directoryURL: directoryURL, ref: ref, reason: nil)
        }
    }

    /// Retrieves a list of local Git branches that point to a specified commit.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///   - commitsh: The commit SHA or reference to which branches should be checked.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the branch retrieval process.
    ///
    /// - Returns:
    ///   An optional array of branch names that point to the specified commit. Returns `nil` if no branches are found.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repo")
    ///   let commitSHA = "abc123" // Replace with the actual commit SHA
    ///
    ///   do {
    ///       if let branches = try getBranchesPointedAt(directoryURL: directoryURL, commitsh: commitSHA) {
    ///           if branches.isEmpty {
    ///               print("No branches point to commit \(commitSHA).")
    ///           } else {
    ///               print("Branches pointing to commit \(commitSHA):")
    ///               for branch in branches {
    ///                   print(branch)
    ///               }
    ///           }
    ///       } else {
    ///           print("No branches found.")
    ///       }
    ///   } catch {
    ///       print("Error retrieving branches: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Warning:
    ///   Ensure that the specified `directoryURL` exists and is a valid Git repository directory.
    public func getBranchesPointedAt(directoryURL: URL,
                                     commitsh: String) throws -> [String]? {
        let args = [
            "branch",
            "--points-at=\(commitsh)",
            "--format=%(refname:short)"
        ]

        let result = try ShellClient.live().run(
            "cd \(directoryURL.relativePath.escapedWhiteSpaces());git \(args)")

        let resultSplit = result.split(separator: "\n").map { String($0) }
        let resultRange = Array(resultSplit.reversed())
        return resultRange.isEmpty ? nil : resultRange
    }

    /// Retrieves a dictionary of branch names and their corresponding commit SHAs \
    /// that are merged into the specified branch.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///   - branchName: The name of the branch against which you want to compare for merged branches.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the branch retrieval process.
    ///
    /// - Returns:
    ///   A dictionary containing branch names as keys and their corresponding commit SHAs as values, \
    ///   representing branches that are merged into the specified branch.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repo")
    ///   let targetBranchName = "main" // Replace with the branch you want to check
    ///
    ///   do {
    ///       let mergedBranches = try getMergedBranches(directoryURL: directoryURL, branchName: targetBranchName)
    ///       if mergedBranches.isEmpty {
    ///           print("No branches merged into \(targetBranchName).")
    ///       } else {
    ///           print("Branches merged into \(targetBranchName):")
    ///           for (branch, sha) in mergedBranches {
    ///               print("\(branch) - \(sha)")
    ///           }
    ///       }
    ///   } catch {
    ///       print("Error retrieving merged branches: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Warning:
    ///   Ensure that the specified `directoryURL` exists and is a valid Git repository directory.
    func getMergedBranches(directoryURL: URL,
                           branchName: String) throws -> [String: String] {
        let canonicalBranchRef = Refs().formatAsLocalRef(name: branchName)

        let args = ["branch", "--format=%(refname):%(objectname)", "--merged", branchName]

        do {
            let result = try ShellClient().run("cd \(directoryURL.relativePath.escapedWhiteSpaces());git \(args)")

            var mergedBranches = [String: String]()
            for line in result.split(separator: "\n") {
                let components = line.split(separator: ":", maxSplits: 1)
                if components.count == 2 {
                    let ref = String(components[0])
                    let sha = String(components[1])

                    // Don't include the branch we're using to compare against
                    // in the list of branches merged into that branch.
                    if ref != canonicalBranchRef {
                        mergedBranches[ref] = sha
                    }
                }
            }
            return mergedBranches
        } catch {
            throw error
        }
    }
} // swiftlint:disable:this file_length
