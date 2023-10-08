//
//  Reflog.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/13.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

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
public func getRecentBranches(directoryURL: URL, limit: Int) throws -> [String] {
    // Regular expression to match branch checkout and rename events in Git log.
    let regexPattern = ".*? (renamed|checkout)(?:: moving from|\\s*) (?:refs/heads/|\\s*)(.*?) to (?:refs/heads/|\\s*)(.*?)$"

    let regex = try NSRegularExpression(pattern: regexPattern, options: [])

    // Create a process to execute the Git log command.
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["git", "log", "-g", "--no-abbrev-commit", "--pretty=oneline", "HEAD", "-n", "\(limit)", "--"]
    process.currentDirectoryURL = URL(fileURLWithPath: directoryURL.relativePath.escapedWhiteSpaces())

    // Create a pipe for capturing the stdout of the Git log command.
    let stdoutPipe = Pipe()
    process.standardOutput = stdoutPipe

    // Execute the Git log command and wait for it to complete.
    try process.run()
    process.waitUntilExit()

    // Read the stdout data and convert it to a string.
    let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
    if let stdoutString = String(data: stdoutData, encoding: .utf8) {
        var branchNames = [String]()
        var excludedNames = Set<String>()

        // Split the stdout string into lines.
        let lines = stdoutString.components(separatedBy: .newlines)

        for line in lines {
            // Try to match the line with the regular expression.
            if let result = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
               result.numberOfRanges == 4 {
                let operationType = (line as NSString).substring(with: result.range(at: 1))
                let excludeBranchName = (line as NSString).substring(with: result.range(at: 2))
                let branchName = (line as NSString).substring(with: result.range(at: 3))

                // Exclude the original branch name if it was renamed.
                if operationType == "renamed" {
                    excludedNames.insert(excludeBranchName)
                }

                // Add the branch name to the result if it's not excluded.
                if !excludedNames.contains(branchName) {
                    branchNames.append(branchName)
                }
            }

            // Exit the loop if the desired limit is reached.
            if branchNames.count == limit {
                break
            }
        }

        return branchNames
    } else {
        // Throw an error if stdout data couldn't be converted to a string.
        throw NSError(domain: "Error converting stdout data to string", code: 0, userInfo: nil)
    }
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
public func getBranchCheckouts(directoryURL: URL, afterDate: Date) throws -> [String: Date] {
    // Regular expression to match branch checkout events in Git reflog.
    let regexPattern = #"^[a-z0-9]{40}\sHEAD@{(.*)}\scheckout: moving from\s.*\sto\s(.*)$"#
    let regex = try NSRegularExpression(pattern: regexPattern, options: [])

    // Create a process to execute the Git reflog command.
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [
        "git",
        "reflog",
        "--date=iso",
        "--after=\(afterDate.ISO8601Format())",
        "--pretty=%H %gd %gs",
        "--grep-reflog=checkout: moving from .* to .*$",
        "--"
    ]
    process.currentDirectoryURL = URL(fileURLWithPath: directoryURL.relativePath.escapedWhiteSpaces())

    // Create pipes for capturing the stdout and stderr of the Git reflog command.
    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    // Execute the Git reflog command and wait for it to complete.
    try process.run()
    process.waitUntilExit()

    // Read the stdout data and convert it to a string.
    let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
    if let stdoutString = String(data: stdoutData, encoding: .utf8) {
        var checkouts = [String: Date]()

        // Split the stdout string into lines.
        let lines = stdoutString.components(separatedBy: .newlines)

        for line in lines {
            // Try to match the line with the regular expression.
            if let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
               match.numberOfRanges == 3 {
                let timestamp = (line as NSString).substring(with: match.range(at: 1))
                let branchName = (line as NSString).substring(with: match.range(at: 2))

                // Convert the timestamp to a Date object.
                if let date = ISO8601DateFormatter().date(from: timestamp) {
                    checkouts[branchName] = date
                }
            }
        }

        return checkouts
    } else {
        // Throw an error if stdout data couldn't be converted to a string.
        throw NSError(domain: "Error converting stdout data to string", code: 0, userInfo: nil)
    }
}
