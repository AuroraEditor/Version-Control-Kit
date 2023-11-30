//
//  Reflog.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/13.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

public struct Reflog {

    public init() {}

    /// Get a list of the `limit` most recently checked out branches in the Git repository.
    ///
    /// This function retrieves information from the Git logs to identify branches
    /// that were recently checked out. \
    /// It is useful for tracking branch history and provides the names of branches
    /// that were either checked out or renamed.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the Git repository.
    ///   - limit: The maximum number of recently checked out branches to retrieve.
    ///
    /// - Returns: An array of branch names that were recently checked out or renamed, with a maximum count of `limit`.
    ///
    /// - Throws: An error if there was an issue executing the Git log command or if the output couldn't be parsed.
    ///
    /// - Note:
    ///   - This function uses regular expressions to parse the Git log output, \
    ///     looking for branch checkout and rename events.
    ///   - Renamed branches are considered as part of the history, \
    ///     and their original names are excluded from the result to avoid duplicates.
    ///
    /// - Example:
    ///   ```swift
    ///   let repositoryURL = URL(fileURLWithPath: "/path/to/git/repo")
    ///   let recentBranches = try getRecentBranches(directoryURL: repositoryURL, limit: 5)
    ///   print("Recent Branches: \(recentBranches)")
    ///   ```
    ///
    /// - Returns: An array of branch names that were recently checked out or renamed, with a maximum count of `limit`.
    func getRecentBranches(directoryURL: URL,
                           limit: Int) throws -> [String] {
        // Define a regular expression to match branch names in git log entries
        let regexPattern = #"^\w+ \w+(?:: moving from|\s*) (?:refs/heads/|\s*)(.*?) to (?:refs/heads/|\s*)(.*?)$"#

        // Create a regular expression
        guard let regex = try? NSRegularExpression(pattern: regexPattern, options: []) else {
            throw fatalError("Invalid regex")
        }

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
                                        name: #function,
                                        options: IGitExecutionOptions(successExitCodes: Set([0, 128])))

        // Check if the git log returned an error code 128 (branch is unborn)
        if result.exitCode == 128 {
            return []
        }

        // Split the stdout of git log into lines
        let lines = result.stdout.split(separator: "\n")

        // Create sets to store branch names and excluded names
        var branchNames = Set<String>()
        var excludedNames = Set<String>()

        for line in lines {
            // Try to match the line with the regular expression
            if let match = regex.firstMatch(in: String(line), options: [], range: NSRange(line.startIndex..., in: line)) {
                let excludeBranchNameRange = Range(match.range(at: 1), in: line)!
                let branchNameRange = Range(match.range(at: 2), in: line)!

                let excludeBranchName = String(line[excludeBranchNameRange])
                let branchName = String(line[branchNameRange])

                if !excludedNames.contains(excludeBranchName) {
                    branchNames.insert(branchName)
                }

                if branchNames.count == limit {
                    break
                }
            }
        }

        return Array(branchNames)
    }

    private let noCommitsOnBranchRe = "fatal: your current branch '.*' does not have any commits yet"

    /// Get a distinct list of branches that have been checked out after a specific date in the Git repository.
    ///
    /// This function retrieves information from the Git reflog to identify branches
    /// that were checked out after a given date. \
    /// It returns a dictionary where the keys are branch names,
    /// and the values are the timestamps when the branches were checked out.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the Git repository.
    ///   - afterDate: The date after which to search for branch checkouts.
    ///
    /// - Returns: A dictionary where keys are branch names, and values are the timestamps of their checkouts.
    ///
    /// - Throws: An error if there was an issue executing the Git reflog command or if the output couldn't be parsed.
    ///
    /// - Note:
    ///   - This function uses regular expressions to parse the Git reflog output, looking for checkout events.
    ///   - The reflog records information about various operations, \
    ///     and this function specifically filters for "checkout" events after the specified date.
    ///
    /// - Example:
    ///   ```swift
    ///   let repositoryURL = URL(fileURLWithPath: "/path/to/git/repo")
    ///   let afterDate = Date(timeIntervalSinceReferenceDate: 0) // A reference date, e.g., January 1, 2001
    ///   let branchCheckouts = try getBranchCheckouts(directoryURL: repositoryURL, afterDate: afterDate)
    ///   print("Branch Checkouts: \(branchCheckouts)")
    ///   ```
    ///
    /// - Returns: A dictionary where keys are branch names, and values are the timestamps of their checkouts.
    func getBranchCheckouts(directoryURL: URL,
                            afterDate: Date) throws -> [String: Date] {
        // Regular expression to match reflog entries
        let regex = try NSRegularExpression(pattern: #"^[a-z0-9]{40}\sHEAD@{(.*)}\scheckout: moving from\s.*\sto\s(.*)$"#)

        // Format the afterDate as ISO string
        let dateFormatter = ISO8601DateFormatter()
        let afterDateString = dateFormatter.string(from: afterDate)

        // Run the Git reflog command
        let args = [
            "reflog",
            "--date=iso",
            "--after=\(afterDateString)",
            "--pretty=%H %gd %gs",
            "--grep-reflog=checkout: moving from .* to .*$",
            "--"
        ]

        let result = try GitShell().git(args: args,
                                        path: directoryURL,
                                        name: #function)

        var checkouts = [String: Date]()

        // Check for the edge case
        if result.exitCode == 128 {
            return checkouts
        }

        // Split the result stdout into lines
        let lines = result.stdout.split(separator: "\n")

        for line in lines {
            // Attempt to match the line with the regex
            if let match = regex.firstMatch(in: String(line), options: [], range: NSRange(line.startIndex..., in: line)) {
                let timestampRange = Range(match.range(at: 1), in: line)!
                let branchNameRange = Range(match.range(at: 2), in: line)!

                // Extract timestamp and branch name from the matched groups
                let timestampString = String(line[timestampRange])
                let branchName = String(line[branchNameRange])

                // Convert the timestamp string to a Date
                if let timestamp = dateFormatter.date(from: timestampString) {
                    checkouts[branchName] = timestamp
                }
            }
        }

        return checkouts
    }

}
