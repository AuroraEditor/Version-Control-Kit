//
//  Branch.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/12.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

public struct Branch { // swiftlint:disable:this type_body_length

    public init() {}

    /// Retrieves the current branch name in the given directory.
    ///
    /// - Parameter directoryURL: The URL of the directory where the Git repository is located.
    /// - Returns: A string representing the name of the current branch.
    /// - Throws: An error if the shell command fails.
    public func getCurrentBranch(directoryURL: URL) throws -> String {
        return try ShellClient.live().run(
            "cd \(directoryURL.relativePath.escapedWhiteSpaces());git branch --show-current"
        ).removingNewLines()
    }

    /// Fetches all branches in the given directory, optionally filtering by prefixes.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory where the Git repository is located.
    ///   - prefixes: An array of strings representing branch name prefixes to filter by. Defaults to an empty array.
    /// - Returns: An array of `GitBranch` instances representing the fetched branches.
    /// - Throws: An error if the shell command fails.
    public func getBranches(directoryURL: URL, prefixes: [String] = []) throws -> [GitBranch] {
        let fields = ["fullName": "%(refname)",
                      "shortName": "%(refname:short)",
                      "upstreamShortName": "%(upstream:short)",
                      "sha": "%(objectname)",
                      "author": "%(author)",
                      "symRef": "%(symref)"]

        let (args, parser) = GitDelimiterParser().createForEachRefParser(fields)

        // Set the prefix arguments for the git command
        var prefixArgs = prefixes
        if prefixes.isEmpty {
            prefixArgs = ["refs/heads", "refs/remotes"]
        }

        // Combine the git command with the necessary arguments
        let gitCommand = ["for-each-ref"] + args + prefixArgs

        // Execute the git command using the GitShell utility
        let result = try GitShell().git(
            args: gitCommand,
            path: directoryURL,
            name: #function,
            options: IGitExecutionOptions(expectedErrors: Set([GitError.NotAGitRepository]))
        )

        // Check for a specific git error
        if result.gitError == GitError.NotAGitRepository {
            return []
        }

        // Initialize an array to hold the GitBranch objects
        var branches = [GitBranch]()

        // Parse the output of the git command
        let parsedOutput = parser(result.stdout)

        // Iterate through each parsed ref
        for ref in parsedOutput {
            // Exclude symbolic refs from the branch list
            if !(ref["symRef"]?.isEmpty ?? true) {
                continue
            }

            // Parse the commit author identity
            let author = try CommitIdentity.parseIdentity(identity: ref["author"] ?? "")
            let tip = IBranchTip(sha: ref["sha"] ?? "", author: author)

            // Determine the branch type
            let type: BranchType = ref["fullName"]?.hasPrefix("refs/heads") ?? false ? .local : .remote

            // Get the upstream branch name, if any
            let upstream = ref["upstreamShortName"]?.isEmpty ?? true ? nil : ref["upstreamShortName"]

            // Create a new GitBranch object with the parsed data
            if let shortName = ref["shortName"], let fullName = ref["fullName"] {
                let branch = GitBranch(
                    name: shortName,
                    upstream: upstream,
                    tip: tip,
                    type: type,
                    ref: fullName
                )
                branches.append(branch)
            }
        }

        return branches
    }

    /// Identifies branches that have diverged from their upstream counterparts.
    ///
    /// - Parameter directoryURL: The URL of the directory where the Git repository is located.
    /// - Returns: An array of `ITrackingBranch` instances representing the branches that have diverged.
    /// - Throws: An error if the shell command fails.
    public func getBranchesDifferingFromUpstream(directoryURL: URL) throws -> [ITrackingBranch] {
        let fields = ["fullName": "%(refname)",
                      "sha": "%(objectname)",
                      "upstream": "%(upstream)",
                      "symRef": "%(symref)",
                      "head": "%(HEAD)"]

        // Create the parser using the fields defined above
        let (args, parse) = GitDelimiterParser().createForEachRefParser(fields)

        // Define the prefixes for the git command
        let prefixes = ["refs/heads", "refs/remotes"]

        // Execute the git command using the GitShell utility
        let result = try GitShell().git(args: ["for-each-ref"] + args + prefixes,
                                        path: directoryURL,
                                        name: #function,
                                        options: IGitExecutionOptions(
                                            expectedErrors: Set([GitError.NotAGitRepository])
                                        ))

        // Check for a specific git error
        if result.gitError == GitError.NotAGitRepository {
            return []
        }

        var localBranches = [ILocalBranch]()
        var remoteBranchShas = [String: String]()

        // Parse the output of the git command
        let parsedOutput = parse(result.stdout)

        // Iterate through each parsed ref
        for ref in parsedOutput {
            if !(ref["symref"]?.isEmpty ?? true) || ref["head"] == "*" {
                // Exclude symbolic refs and the current branch
                continue
            }

            if ref["fullName"]?.hasPrefix("refs/heads") ?? false {
                if ref["upstream"]?.isEmpty ?? true {
                    // Exclude local branches without upstream
                    continue
                }

                if let fullName = ref["fullName"], let sha = ref["sha"], let upstream = ref["upstream"] {
                    let trackingBranch = ILocalBranch(ref: fullName, sha: sha, upstream: upstream)
                    localBranches.append(trackingBranch)
                }
            } else if let fullName = ref["fullName"], let sha = ref["sha"] {
                remoteBranchShas[fullName] = sha
            }
        }

        var eligibleBranches = [ITrackingBranch]()

        // Compare the SHA of every local branch with the SHA of its upstream
        for branch in localBranches {
            if let remoteSha = remoteBranchShas[branch.upstream], remoteSha != branch.sha {
                let trackingBranch = ITrackingBranch(ref: branch.ref,
                                                     sha: branch.sha,
                                                     upstreamRef: branch.upstream,
                                                     upstreamSha: remoteSha)
                eligibleBranches.append(trackingBranch)
            }
        }

        return eligibleBranches
    }

    /// Retrieves a list of the most recently modified branches, up to a specified limit.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory where the Git repository is located.
    ///   - limit: An integer specifying the maximum number of branches to retrieve.
    /// - Returns: An array of strings representing the names of the recent branches.
    /// - Throws: An error if the shell command fails.
    public func getRecentBranches(directoryURL: URL, limit: Int) throws -> [String] {
        let regex = try NSRegularExpression(
            // swiftlint:disable:next line_length
            pattern: #"^.*? (renamed|checkout)(?:: moving from|\s*) (?:refs/heads/|\s*)(.*?) to (?:refs/heads/|\s*)(.*?)$"#,
            options: []
        )

        let args = [
            "log",
            "-g",
            "--no-abbrev-commit",
            "--pretty=oneline",
            "HEAD",
            "-n",
            "2500",
            "--"
        ]

        let result = try GitShell().git(args: args,
                                        path: directoryURL,
                                        name: #function)

        if result.exitCode == 128 {
            // error code 128 is returned if the branch is unborn
            return []
        }

        let lines = result.stdout.components(separatedBy: "\n")
        var names = Set<String>()
        var excludedNames = Set<String>()

        for line in lines {
            if let match = regex.firstMatch(
                in: line,
                options: [],
                range: NSRange(location: 0, length: line.utf16.count)
               ),
               match.numberOfRanges == 4 {
                let operationTypeRange = Range(match.range(at: 1), in: line)!
                let excludeBranchNameRange = Range(match.range(at: 2), in: line)!
                let branchNameRange = Range(match.range(at: 3), in: line)!

                let operationType = String(line[operationTypeRange])
                let excludeBranchName = String(line[excludeBranchNameRange])
                let branchName = String(line[branchNameRange])

                if operationType == "renamed" {
                    // exclude intermediate-state renaming branch from recent branches
                    excludedNames.insert(excludeBranchName)
                }

                if !excludedNames.contains(branchName) {
                    names.insert(branchName)
                }
            }

            if names.count >= limit {
                break
            }
        }

        return Array(names)
    }

    func getCommitsOnBranch() {
        guard let noCommitsOnBranchRe = try? NSRegularExpression(
            pattern: "fatal: your current branch '.*' does not have any commits yet"
        ) else {
            print("Failed to create regular expression")
            return
        }
    }

    /// Asynchronously fetches the names and dates of branches checked out after a specified date.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory where the Git repository is located.
    ///   - afterDate: A `Date` object representing the starting point for the search.
    /// - Returns: A dictionary mapping branch names to the dates they were checked out.
    /// - Throws: An error if the shell command fails.
    func getBranchCheckouts(directoryURL: URL, afterDate: Date) async throws -> [String: Date] {
        let regexPattern = #"^[a-z0-9]{40}\sHEAD@{(.*)}\scheckout: moving from\s.*\sto\s(.*)$"# // regexr.com/46n1v
        let regex = try NSRegularExpression(pattern: regexPattern, options: [])

        let args = [
            "reflog",
            "--date=iso",
            "--after=\(afterDate.timeIntervalSince1970)",
            "--pretty=%H %gd %gs",
            "--grep-reflog=checkout: moving from .* to .*$",
            "--"
        ]

        let result = try GitShell().git(args: args,
                                        path: directoryURL,
                                        name: #function)

        var checkouts = [String: Date]()

        if result.exitCode == 128 {
            return checkouts
        }

        let lines = result.stdout.components(separatedBy: "\n")
        for line in lines {
            if let match = regex.firstMatch(
                in: line,
                options: [],
                range: NSRange(location: 0, length: line.utf16.count)
            ),
            match.numberOfRanges == 3 {
                let timestampRange = Range(match.range(at: 1), in: line)!
                let branchNameRange = Range(match.range(at: 2), in: line)!

                let timestampString = String(line[timestampRange])
                let branchName = String(line[branchNameRange])

                if let timestamp = ISO8601DateFormatter().date(from: timestampString) {
                    checkouts[branchName] = timestamp
                }
            }
        }

        return checkouts
    }

    /// Creates a new branch in the specified directory.
    ///
    /// This function creates a new branch in the specified Git repository directory. It allows
    /// for an optional starting point for the new branch and an option to prevent tracking the
    /// new branch.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory where the Git repository is located.
    ///   - name: A string representing the name of the new branch.
    ///   - startPoint: An optional string representing the starting point for the new branch.
    ///   - noTrack: A boolean indicating whether to track the branch. Defaults to false.
    /// - Throws: An error if the shell command fails.
    ///
    /// - Example:
    ///   ```swift
    ///   do {
    ///       let directoryURL = URL(fileURLWithPath: "/path/to/repository")
    ///       let branchName = "new-feature-branch"
    ///       let startPoint = "main"
    ///       let noTrack = true
    ///       try createBranch(directoryURL: directoryURL, name: branchName, startPoint: startPoint, noTrack: noTrack)
    ///       print("Branch created successfully.")
    ///   } catch {
    ///       print("Failed to create branch: \(error)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   If `noTrack` is set to `true`, the new branch will not track the remote branch from
    ///   which it was created. This can be useful when branching directly from a remote branch
    ///   to avoid automatically pushing to the remote branch's upstream.
    public func createBranch(directoryURL: URL,
                             name: String,
                             startPoint: String?,
                             noTrack: Bool = false) throws {
        var args: [String]

        if let startPoint = startPoint {
            args = ["branch", name, startPoint]
        } else {
            args = ["branch", name]
        }

        // If we're branching directly from a remote branch, we don't want to track it
        // Tracking it will make the rest of the desktop think we want to push to that
        // remote branch's upstream (which would likely be the upstream of the fork)
        if noTrack {
            args.append("--no-track")
        }

        try GitShell().git(args: args,
                           path: directoryURL,
                           name: "createBranch")
    }

    /// Renames a branch in the specified directory.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory where the Git repository is located.
    ///   - branch: A `GitBranch` object representing the branch to rename.
    ///   - newName: A string representing the new name of the branch.
    /// - Throws: An error if the shell command fails.
    public func renameBranch(directoryURL: URL,
                             branch: GitBranch,
                             newName: String) throws {
        let args = [
            "branch",
            "-m",
            branch.nameWithoutRemote,
            newName
        ]

        /// Prepare and execute the Git command to rename the branch using a ShellClient.
        try GitShell().git(args: args,
                           path: directoryURL,
                           name: "renameBranch")
    }

    /// Deletes a local branch in the specified directory.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory where the Git repository is located.
    ///   - branchName: A string representing the name of the branch to delete.
    /// - Returns: A boolean indicating whether the branch was deleted.
    /// - Throws: An error if the shell command fails.
    public func deleteLocalBranch(directoryURL: URL,
                                  branchName: String) throws -> Bool {
        let args = [
            "branch",
            "-D",
            branchName]

        /// Prepare and execute the Git command to delete the local branch using a ShellClient.
        try GitShell().git(args: args,
                           path: directoryURL,
                           name: #function)

        // Return true to indicate that the branch deletion was attempted.
        return true
    }

    /// Deletes a remote branch in the specified directory.
    ///
    /// This function deletes a remote branch in the specified Git repository directory. It uses the `git push`
    /// command with a colon (`:`) in front of the branch name to delete the branch on the remote repository.
    ///
    /// If the deletion fails due to an authentication error or if the branch has already been deleted on the
    /// remote, the function attempts to delete the local reference to the remote branch.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory where the Git repository is located.
    ///   - remoteName: A string representing the name of the remote repository.
    ///   - remoteBranchName: A string representing the name of the branch to delete.
    /// - Throws: An error if the shell command fails.
    ///
    /// - Example:
    ///   ```swift
    ///   do {
    ///       let directoryURL = URL(fileURLWithPath: "/path/to/repository")
    ///       let remoteName = "origin"
    ///       let remoteBranchName = "feature-branch"
    ///       try deleteRemoteBranch(directoryURL: directoryURL, remoteName: remoteName, remoteBranchName: remoteBranchName)
    ///       print("Remote branch deleted successfully.")
    ///   } catch {
    ///       print("Failed to delete remote branch: \(error)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   Ensure that you have the necessary permissions to delete branches on the remote repository. If the
    ///   user is not authenticated or lacks the required permissions, the push operation will fail, and the
    ///   caller must handle this error appropriately.
    public func deleteRemoteBranch(directoryURL: URL,
                                   remoteName: String,
                                   remoteBranchName: String) throws -> Bool {
        let args = [
            gitNetworkArguments.joined(),
            "push",
            remoteName,
            ":\(remoteBranchName)"
        ]

        // If the user is not authenticated, the push is expected to fail
        // Let this propagate and leave it to the caller to handle
        let result = try GitShell().git(args: args,
                                        path: directoryURL,
                                        name: #function,
                                        options: IGitExecutionOptions(
                                            expectedErrors: Set([GitError.BranchDeletionFailed])
                                        ))

        // It's possible that the delete failed because the ref has already
        // been deleted on the remote. If we identify that specific
        // error we can safely remove our remote ref which is what would
        // happen if the push didn't fail.
        if result.gitError == GitError.BranchDeletionFailed {
            let ref = "refs/remotes/\(remoteName)/\(remoteBranchName)"
            try UpdateRef().deleteRef(directoryURL: directoryURL, ref: ref, reason: nil)
        }

        return true
    }

    /// Finds all branches that point at a specific commitish in the given directory.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory where the Git repository is located.
    ///   - commitish: A string representing the commit-ish to which the branches should point.
    /// - Returns: An optional array of strings representing the branch names.
    /// - Throws: An error if the shell command fails.
    func getBranchesPointedAt(directoryURL: URL,
                              commitish: String) throws -> [String]? {
        let args = [
            "branch",
            "--points-at=\(commitish)",
            "--format=%(refname:short)"
        ]

        let result = try GitShell().git(args: args,
                                        path: directoryURL,
                                        name: "branchPointedAt",
                                        options: IGitExecutionOptions(successExitCodes: Set([0, 1, 129])))

        if result.exitCode == 1 || result.exitCode == 129 {
            return nil
        }

        // Split the output and remove the trailing empty string
        let branches = result.stdout.components(separatedBy: "\n").dropLast()
        return Array(branches)
    }

    /// Retrieves a dictionary of branches that have been merged into a specified branch.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory where the Git repository is located.
    ///   - branchName: A string representing the name of the branch to compare.
    /// - Returns: A dictionary mapping branch names to their respective commit SHAs.
    /// - Throws: An error if the shell command fails.
    func getMergedBranches(directoryURL: URL,
                           branchName: String) throws -> [String: String] {
        let canonicalBranchRef = Refs().formatAsLocalRef(name: branchName)
        let formatArgs = ["--format=%(objectname) %(refname:short)"]

        let args = ["branch"] + formatArgs + ["--merged", branchName]

        var mergedBranches = [String: String]()

        let result = try GitShell().git(args: args,
                                        path: directoryURL,
                                        name: "mergedBranches")

        for line in result.stdout.components(separatedBy: "\n") {
            let components = line.components(separatedBy: " ")
            if components.count == 2 {
                let sha = components[0]
                let ref = components[1]
                // Don't include the branch we're using to compare against
                // in the list of branches merged into that branch.
                if ref != canonicalBranchRef {
                    mergedBranches[ref] = sha
                }
            }
        }

        return mergedBranches
    }
}
// swiftlint:disable:this file_length
