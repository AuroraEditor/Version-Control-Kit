//
//  Checkout.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/12.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

public struct GitCheckout {

    public init() {}

    public typealias ProgressCallback = (CheckoutProgress) -> Void

    public func getCheckoutArgs(progressCallback: ProgressCallback?) -> [String] {
        // var args = gitNetworkArguments
        var args: [String] = []

        if let callback = progressCallback {
            args += ["checkout", "--progress"]
        } else {
            args += ["checkout"]
        }

        return args
    }

    public func getBranchCheckoutArgs(
        branch: GitBranch,
        enableRecurseSubmodulesFlag: Bool = false
    ) -> [String] {
        var args = [branch.name]

        if branch.type == .remote {
            args.append(contentsOf: ["-b", branch.nameWithoutRemote])
        }

        if enableRecurseSubmodulesFlag {
            args.append("--recurse-submodules")
        }

        args.append("--")

        return args
    }

    public func getCheckoutOpts( // swiftlint:disable:this function_parameter_count
        directoryURL: URL,
        title: String,
        target: String,
        progressCallback: ProgressCallback?,
        initialDescription: String?
    ) throws -> IGitExecutionOptions {
        var options: IGitExecutionOptions = IGitExecutionOptions()

        guard let progressCallback = progressCallback else {
            return options
        }

        let kind = "checkout"

        progressCallback(CheckoutProgress(kind: kind,
                                          targetBranch: target,
                                          value: 0,
                                          title: title,
                                          description: initialDescription ?? title))

        return try FromProcess().executionOptionsWithProgress(options: options,
                                                              parser: GitProgressParser(steps: [
                                                                ProgressStep(title: "Checking out files", weight: 1)
                                                              ] )) { progress in
            if progress.kind == "progress" {
                var description: String = ""
                if let gitProgress = progress as? IGitProgress {
                    description = gitProgress.details.text
                }
                let value = progress.percent

                progressCallback(CheckoutProgress(kind: kind,
                                                  targetBranch: target,
                                                  value: value,
                                                  title: title,
                                                  description: description))
            }
        }
    }

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
    @discardableResult
    public func checkoutBranch(
        directoryURL: URL,
        account: IGitAccount?,
        branch: GitBranch,
        progressCallback: ProgressCallback?
    ) throws -> Bool {
        let opts = try getCheckoutOpts(
            directoryURL: directoryURL,
            title: "Checking out branch \(branch.name)",
            target: branch.name,
            progressCallback: progressCallback,
            initialDescription: "Switching to Branch"
        )

        let baseArgs = getCheckoutArgs(progressCallback: progressCallback)
        let branchArgs = getBranchCheckoutArgs(branch: branch)
        let args = baseArgs + branchArgs

        try GitShell().git(args: args,
                           path: directoryURL,
                           name: #function)
        return true
    }

    public func checkoutCommit(directoryURL: URL,
                               account: IGitAccount?,
                               commit: Commit,
                               progressCallback: ProgressCallback?) async throws -> Bool {
        let opts = try getCheckoutOpts(
            directoryURL: directoryURL,
            title: "Checking out Commit",
            target: shortenSHA(commit.sha),
            progressCallback: progressCallback,
            initialDescription: nil
        )

        let baseArgs = getCheckoutArgs(progressCallback: progressCallback)
        let args = baseArgs + [commit.sha]

        try GitShell().git(args: args,
                           path: directoryURL,
                           name: #function,
                           options: opts)

        return true
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
        let args = ["checkout", "HEAD", "--"] + paths

        try GitShell().git(args: args,
                           path: directoryURL,
                           name: #function)

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
    ///       try checkoutConflictedFile(
    ///           directoryURL: directoryURL,
    ///           file: conflictedFile,
    ///           resolution: resolutionStrategy
    ///       )
    ///       print("File '\(conflictedFile.url.relativePath)' checked out with \(resolutionStrategy) resolution.")
    ///   } catch {
    ///       print("Error checking out conflicted file: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Warning:
    ///   Ensure that the specified `directoryURL` exists and is a valid Git repository directory.
    public func checkoutConflictedFile(directoryURL: URL,
                                       file: WorkingDirectoryFileChange,
                                       resolution: ManualConflictResolution) throws {
        let args = [
            "checkout",
            "--\(resolution.rawValue)",
            "--",
            file.path
        ]

        try GitShell().git(args: args,
                           path: directoryURL,
                           name: #function)
    }
}
