//
//  Checkout.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/12.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

public struct Checkout {
    
    /// Checks out a Git branch in a specified directory.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///   - branch: The name of the Git branch to be checked out.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the branch checkout process.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repo")
    ///   let branchName = "feature/new-feature" // Replace with the desired branch name
    ///
    ///   do {
    ///       try checkoutBranch(directoryURL: directoryURL, branch: branchName)
    ///       print("Switched to branch '\(branchName)' successfully.")
    ///   } catch {
    ///       print("Error checking out branch: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Warning:
    ///   Ensure that the specified `directoryURL` exists and is a valid Git repository directory.
    public func checkoutBranch(directoryURL: URL, branch: String) throws {
        // Prepare the Git command arguments to check out the specified branch.
        try ShellClient.live().run(
            "cd \(directoryURL.relativePath.escapedWhiteSpaces());git checkout \(branch)"
        )
    }

    /// Checks out specific Git paths in a specified directory to their state in the HEAD commit.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///   - paths: An array of relative paths to the Git files or directories to be checked out.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the checkout process.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repo")
    ///   let pathsToCheckout = ["file1.txt", "directory/subfile2.txt"] // Replace with the desired paths
    ///
    ///   do {
    ///       try checkoutPaths(directoryURL: directoryURL, paths: pathsToCheckout)
    ///       print("Paths checked out successfully.")
    ///   } catch {
    ///       print("Error checking out paths: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Warning:
    ///   Ensure that the specified `directoryURL` exists and is a valid Git repository directory.
    public func checkoutPaths(directoryURL: URL, paths: [String]) throws {
        // Prepare the Git command arguments to check out the specified paths from the HEAD commit.
        let escapedPaths = paths.map { $0.escapedWhiteSpaces() }.joined(separator: " ")
        try ShellClient.live().run(
            "cd \(directoryURL.relativePath.escapedWhiteSpaces());git checkout HEAD -- \(escapedPaths)"
        )
    }

    /// Checks out a conflicted Git file with a specified resolution strategy in a specified directory.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///   - file: The GitFileItem representing the conflicted file.
    ///   - resolution: The manual conflict resolution strategy to apply to the conflicted file.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the file checkout process.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repo")
    ///   let conflictedFile = GitFileItem(url: URL(fileURLWithPath: "path/to/conflicted/file"), status: .conflicted)
    ///   let resolutionStrategy = ManualConflictResolution.ours // Replace with the desired resolution strategy
    ///
    ///   do {
    ///       try checkoutConflictedFile(directoryURL: directoryURL, file: conflictedFile, resolution: resolutionStrategy)
    ///       print("File '\(conflictedFile.url.relativePath)' checked out with \(resolutionStrategy) resolution.")
    ///   } catch {
    ///       print("Error checking out conflicted file: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Warning:
    ///   Ensure that the specified `directoryURL` exists and is a valid Git repository directory.
    func checkoutConflictedFile(directoryURL: URL,
                                file: GitFileItem,
                                resolution: ManualConflictResolution) throws {
        let args = [
            "checkout",
            "--\(resolution.rawValue)",
            "--",
            file.url.relativePath
        ]
        
        try ShellClient().run("cd \(directoryURL.relativePath.escapedWhiteSpaces());git \(args)")
    }
}
