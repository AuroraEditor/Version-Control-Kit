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
    public func getRecentBranches(
        directoryURL: URL,
        limit: Int
    ) async throws -> [String] {
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

        let result = try await GitShell().git(
            args: args,
            path: directoryURL,
            name: #function
        )

        if result.exitCode == 128 {
            // error code 128 is returned if the branch is unborn
            return []
        }

        let lines = result.stdout.components(
            separatedBy: "\n"
        )
        var names = Set<String>()
        var excludedNames = Set<String>()

        for line in lines {
            if let match = regex.firstMatch(
                in: line,
                options: [],
                range: NSRange(
                    location: 0,
                    length: line.utf16.count
                )
            ),
               match.numberOfRanges == 4 {
                let operationTypeRange = Range(
                    match.range(at: 1),
                    in: line
                )!
                let excludeBranchNameRange = Range(
                    match.range(at: 2),
                    in: line
                )!
                let branchNameRange = Range(
                    match.range(at: 3),
                    in: line
                )!

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
    func getBranchCheckouts(
        directoryURL: URL,
        afterDate: Date
    ) async throws -> [String: Date] {
        let regexPattern = #"^[a-z0-9]{40}\sHEAD@{(.*)}\scheckout: moving from\s.*\sto\s(.*)$"#
        let regex = try NSRegularExpression(
            pattern: regexPattern,
            options: []
        )

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
                range: NSRange(
                    location: 0,
                    length: line.utf16.count
                )
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
}
