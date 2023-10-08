//
//  GitLog.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/09/08.
//  Copyright © 2022 Aurora Company. All rights reserved.
//

import Foundation

public enum CommitDate: String {
    case lastDay = "Last 24 Hours"
    case lastSevenDays = "Last 7 Days"
    case lastThirtyDays = "Last 30 Days"
}

/// Retrieve a list of Git commits from the repository's history.
///
/// This function retrieves a list of Git commits from the repository's history based on 
/// the specified parameters. \
/// You can filter commits by revision range, limit the number of commits returned,
/// skip a certain number of commits, and include additional Git log arguments. \
/// You can also filter commits by date and exclude merge commits if needed.
///
/// - Parameters:
///   - directoryURL: The URL of the Git repository directory.
///   - revisionRange: A string specifying the revision range for filtering commits (optional).
///   - limit: The maximum number of commits to retrieve (optional).
///   - skip: The number of commits to skip (optional).
///   - additionalArgs: Additional Git log arguments (optional).
///   - commitsSince: Filter commits based on date (optional).
///   - getMerged: Specify whether to include merge commits (optional).
///
/// - Throws: An error if there was an issue executing the Git log command or parsing the commit history.
///
/// - Returns: An array of `CommitHistory` objects representing the Git commits.
///
/// - Example:
///   ```swift
///   do {
///       let commits = try getCommits(directoryURL: myProjectDirectoryURL, limit: 10)
///       for commit in commits {
///           print("Commit Hash: \(commit.hash)")
///           print("Author: \(commit.author)")
///           print("Message: \(commit.message)")
///           // ...
///       }
///   } catch {
///       print("Error: \(error)")
///   }
///   ```
///
/// - Note: The `CommitHistory` structure represents a Git commit and includes fields such as
///         the commit hash, author, commit message, date, and more.
///
/// - Important: Ensure that you have a valid Git repository in the specified directory before calling this function.
public func getCommits(directoryURL: URL,
                       revisionRange: String = "",
                       limit: Int,
                       skip: Int = 0,
                       additionalArgs: [String] = [],
                       commitsSince: CommitDate? = nil,
                       getMerged: Bool = true) throws -> [CommitHistory] {
    var args: [String] = ["log"]

    if !getMerged {
        args.append("--no-merges")
    }

    if !revisionRange.isEmpty {
        args.append(revisionRange)
    }

    // Testing not sure if it works yet
    if commitsSince != nil {
        switch commitsSince {
        case .lastDay:
            args.append("--since=\"24 hours ago\"")
        case .lastSevenDays:
            args.append("--since=\"7 days ago\"")
        case .lastThirtyDays:
            args.append("--since=\"30 days ago\"")
        case .none:
            return []
        }
    }

    if limit > 0 {
        args.append("--max-count=\(limit)")
    }

    if skip > 0 {
        args.append("--skip=\(skip)")
    }

    // %H = SHA
    // %h = short SHA
    // %s = summary
    // %b = body
    // %an = author name
    // %ae = author email
    // %ad = author date
    // %cn = commiter name
    // %ce = comitter email
    // %cd = comitter date
    args.append("--pretty=%H¦%h¦%s¦%an¦%ae¦%ad¦%cn¦%ce¦%cd¦%D")

    let result = try ShellClient().run(
        "cd \(directoryURL.relativePath.escapedWhiteSpaces());git \(args.joined(separator: " "))"
    )

    print("cd \(directoryURL.relativePath.escapedWhiteSpaces());git \(args.joined(separator: " "))")

    return try result.split(separator: "\n")
        .map { line -> CommitHistory in
            let parameters = line.components(separatedBy: "¦")
            return CommitHistory(
                hash: String(parameters[1]),
                commitHash: String(parameters[0]),
                message: String(parameters[2]),
                author: String(parameters[3]),
                authorEmail: String(parameters[4]),
                commiter: String(parameters[6]),
                commiterEmail: String(parameters[7]),
                remoteURL: URL(string: try getRemoteURL(directoryURL: directoryURL,
                                                        name: "origin")!),
                date: Date().gitDateFormat(commitDate: String(parameters[5])) ?? Date(),
                isMerge: parameters[2].contains("Merge pull request")
            )
        }
}
