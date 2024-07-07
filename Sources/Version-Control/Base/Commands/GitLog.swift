//
//  GitLog.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/09/08.
//  Copyright © 2022 Aurora Company. All rights reserved.
//

import Foundation

public enum CommitDate: String {
    case none
    case lastDay = "Last 24 Hours"
    case lastSevenDays = "Last 7 Days"
    case lastThirtyDays = "Last 30 Days"

    public var gitArgs: [String] {
        switch self {
        case .lastDay:
            return ["--since=\"24 hours ago\""]
        case .lastSevenDays:
            return ["--since=\"7 days ago\""]
        case .lastThirtyDays:
            return ["--since=\"30 days ago\""]
        case .none:
            return []
        }
    }
}

public struct GitLog {

    public init() {}

    // File mode 160000 is used by git specifically for submodules:
    // https://github.com/git/git/blob/v2.37.3/cache.h#L62-L69
    let subModuleFileMode = "160000"

    /// Map the submodule status based on file modes and the raw Git status.
    ///
    /// This function determines the submodule status based on the source and destination file modes
    /// and the raw Git status string. It returns a `SubmoduleStatus` object indicating whether the
    /// submodule commit has changed, has modified changes, or has untracked changes.
    ///
    /// - Parameters:
    ///   - status: The raw Git status string.
    ///   - srcMode: The source file mode.
    ///   - dstMode: The destination file mode.
    ///
    /// - Returns: A `SubmoduleStatus` object if the conditions for a submodule status are met, otherwise `nil`.
    ///
    /// - Example:
    ///   ```swift
    ///   let status = "M"
    ///   let srcMode = "160000" // submodule file mode
    ///   let dstMode = "160000" // submodule file mode
    ///   let submoduleStatus = mapSubmoduleStatusFileModes(status: status, srcMode: srcMode, dstMode: dstMode)
    ///   if let submoduleStatus = submoduleStatus {
    ///       print("Submodule commit changed: \(submoduleStatus.commitChanged)")
    ///       print("Submodule has modified changes: \(submoduleStatus.modifiedChanges)")
    ///       print("Submodule has untracked changes: \(submoduleStatus.untrackedChanges)")
    ///   } else {
    ///       print("No submodule status changes.")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   This function checks if the file modes indicate a submodule and then determines the submodule status \
    ///   based on the provided raw Git status string.
    func mapSubmoduleStatusFileModes(status: String, srcMode: String, dstMode: String) -> SubmoduleStatus? {
        let subModuleFileMode = subModuleFileMode

        if srcMode == subModuleFileMode && dstMode == subModuleFileMode && status == "M" {
            return SubmoduleStatus(commitChanged: true, modifiedChanges: false, untrackedChanges: false)
        } else if (srcMode == subModuleFileMode && status == "D") || (dstMode == subModuleFileMode && status == "A") {
            return SubmoduleStatus(commitChanged: false, modifiedChanges: false, untrackedChanges: false)
        }

        return nil
    }

    /// Map the raw Git status to an `AppFileStatus` object.
    ///
    /// This function converts a raw Git status string to an `AppFileStatus` object, \
    /// which includes information about the type of change (e.g., modified, new, deleted, etc.) and \
    /// submodule status. It also handles renames and copies with the appropriate old path if provided.
    ///
    /// - Parameters:
    ///   - rawStatus: The raw Git status string.
    ///   - oldPath: The optional old path of the file if it has been renamed or copied.
    ///   - srcMode: The source mode (file mode) of the file.
    ///   - dstMode: The destination mode (file mode) of the file.
    ///
    /// - Returns: An `AppFileStatus` object representing the file's status.
    ///
    /// - Example:
    ///   ```swift
    ///   let rawStatus = "R100"
    ///   let oldPath = "old/path/to/file.txt"
    ///   let srcMode = "100644"
    ///   let dstMode = "100644"
    ///   let status = mapStatus(rawStatus: rawStatus, oldPath: oldPath, srcMode: srcMode, dstMode: dstMode)
    ///   print("File Status: \(status.kind), Old Path: \(status.oldPath ?? "N/A")")
    ///   ```
    ///
    /// - Note:
    ///   This function uses regular expressions to detect rename and copy status codes \
    ///   and handles submodule statuses appropriately.
    func mapStatus(rawStatus: String,
                   oldPath: String?,
                   srcMode: String,
                   dstMode: String) -> AppFileStatus {
        let status = rawStatus.trimmingCharacters(in: .whitespaces)
        let submoduleStatus = mapSubmoduleStatusFileModes(status: status, srcMode: srcMode, dstMode: dstMode)

        switch status {
        case "M":
            return PlainFileStatus(kind: .modified,
                                   submoduleStatus: submoduleStatus)
        case "A":
            return PlainFileStatus(kind: .new,
                                   submoduleStatus: submoduleStatus)
        case "?":
            return PlainFileStatus(kind: .untracked,
                                   submoduleStatus: submoduleStatus)
        case "D":
            return PlainFileStatus(kind: .deleted,
                                   submoduleStatus: submoduleStatus)
        case "R" where oldPath != nil:
            return CopiedOrRenamedFileStatus(kind: .renamed,
                                             oldPath: oldPath ?? "",
                                             submoduleStatus: submoduleStatus)
        case "C" where oldPath != nil:
            return CopiedOrRenamedFileStatus(kind: .renamed,
                                             oldPath: oldPath ?? "",
                                             submoduleStatus: submoduleStatus)
        default:
            if status.range(of: #"R[0-9]+"#, options: .regularExpression) != nil,
                let oldPath = oldPath {
                return CopiedOrRenamedFileStatus(kind: .renamed,
                                                 oldPath: oldPath,
                                                 submoduleStatus: submoduleStatus)
            } else if status.range(of: #"C[0-9]+"#, options: .regularExpression) != nil,
                        let oldPath = oldPath {
                return CopiedOrRenamedFileStatus(kind: .copied,
                                                 oldPath: oldPath,
                                                 submoduleStatus: submoduleStatus)
            } else {
                return PlainFileStatus(kind: .modified, submoduleStatus: submoduleStatus)
            }
        }
    }

    /// Determine if the given status indicates a copy or rename operation.
    ///
    /// - Parameter status: The `AppFileStatus` object to check.
    ///
    /// - Returns: `true` if the status indicates a copy or rename operation; otherwise, `false`.
    func isCopyOrRename(status: AppFileStatus) -> Bool {
        return status.kind == .copied || status.kind == .renamed
    }

    /// Retrieve a list of commits from a Git repository.
    ///
    /// This function retrieves a list of commits from a specified Git repository directory.
    /// It can optionally filter commits by a file path within the repository,
    /// a revision range, and can limit or skip a specified number of commits.
    /// The retrieved commits are parsed and returned as an array of `Commit` objects.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///   - fileURL: An optional string representing the file path within the repository to filter commits by.
    ///   - revisionRange: An optional string specifying a revision range (e.g., "HEAD~5..HEAD").
    ///   - limit: An optional integer specifying the maximum number of commits to retrieve.
    ///   - skip: An optional integer specifying the number of commits to skip.
    ///   - additionalArgs: An optional array of additional arguments to pass to the Git command.
    ///
    /// - Throws: An error of type `GitError` if the Git command fails.
    ///
    /// - Returns: An array of `Commit` objects representing the retrieved commits.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repository")
    ///   let fileURL = "path/to/file.txt"
    ///
    ///   do {
    ///       let commits = try getCommits(directoryURL: directoryURL, 
    ///                                    fileURL: fileURL,
    ///                                    revisionRange: "HEAD~5..HEAD",
    ///                                    limit: 10,
    ///                                    skip: 0)
    ///       for commit in commits {
    ///           print("Commit SHA: \(commit.sha)")
    ///           print("Commit Summary: \(commit.summary)")
    ///       }
    ///   } catch {
    ///       print("Failed to retrieve commits: \(error)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   This function uses the `git log` command to retrieve commit information. \
    ///   The `fileURL` parameter can be used to filter commits that affect a specific file. \
    ///   If no `fileURL` is provided, the function retrieves commits for the entire repository.
    public func getCommits( // swiftlint:disable:this function_body_length
        directoryURL: URL,
        fileURL: String = "",
        revisionRange: String?,
        limit: Int?,
        skip: Int?,
        additionalArgs: [String] = []
    ) throws -> [Commit] {

        let fields = [
            "sha": "%H",
            "shortSha": "%h",
            "summary": "%s",
            "body": "%b",
            "author": "%an <%ae> %ad",
            "comitter": "%cn <%ce> %cd",
            "parents": "%P",
            "trailers": "%(trailers:unfold,only)",
            "refs": "%D"
        ]

        let formatArgs = GitDelimiterParser().createLogParser(fields)

        var args = ["log"]

        if let revisionRange = revisionRange {
            args.append(revisionRange)
        }

        args.append(contentsOf: ["--date=raw"])

        if let limit = limit {
            args.append("--max-count=\(limit)")
        }

        if let skip = skip {
            args.append("--skip=\(skip)")
        }

        args += formatArgs.formatArgs
        args += ["--no-show-signature", "--no-color"]
        args += additionalArgs
        args.append("--")

        if !fileURL.isEmpty {
            args.append(fileURL)
        }

        let result = try GitShell().git(args: args,
                                        path: directoryURL,
                                        name: #function)

        if result.exitCode == 128 {
            return []
        }

        let parsedCommits = formatArgs.parse(result.stdout)

        return try parsedCommits.map { commit in
            let tags = commit["refs"]?
                .split(separator: ",")
                .compactMap { ref -> String? in
                    if ref.starts(with: "tag: ") {
                        return String(ref.dropFirst("tag: ".count))
                    }
                    return nil
                } ?? []

            return Commit(
                sha: commit["sha"] ?? "",
                shortSha: commit["shortSha"] ?? "",
                summary: commit["summary"] ?? "",
                body: commit["body"] ?? "",
                author: try CommitIdentity.parseIdentity(identity: commit["author"] ?? ""),
                commiter: try CommitIdentity.parseIdentity(identity: commit["comitter"] ?? ""),
                parentShas: commit["parents"]?.split(separator: " ").map(String.init) ?? [],
                trailers: InterpretTrailers().parseRawUnfoldedTrailers(
                    trailers: commit["trailers"] ?? "", seperators: ":"
                ),
                tags: tags
            )
        }
    }

    /// Retrieve the list of changed files for a specific commit in a Git repository.
    ///
    /// This function retrieves the list of changed files for a specific commit SHA in a given Git repository directory.
    /// It uses Git's log command with options to detect renames and copies, and returns the changeset data.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///   - sha: The commit SHA for which to retrieve the list of changed files.
    ///
    /// - Throws: An error of type `GitError` if the Git command fails.
    ///
    /// - Returns: An `IChangesetData` object containing the list of changed files, lines added, and lines deleted.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repository")
    ///   let commitSHA = "abcdef1234567890abcdef1234567890abcdef12"
    ///
    ///   Task {
    ///       do {
    ///           let changesetData = try await getChangedFiles(directoryURL: directoryURL,
    ///                                                         sha: commitSHA)
    ///           print("Files changed: \(changesetData.files)")
    ///           print("Lines added: \(changesetData.linesAdded)")
    ///           print("Lines deleted: \(changesetData.linesDeleted)")
    ///       } catch {
    ///           print("Failed to retrieve changed files: \(error)")
    ///       }
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   This function uses asynchronous processing to run the Git command and parse the results.
    ///   It detects renames and copies by using the `-M` and `-C` options in the Git log command.
    func getChangedFiles(directoryURL: URL,
                         sha: String) async throws -> IChangesetData {
        // Opt-in for rename detection (-M) and copies detection (-C)
        // This is equivalent to the user configuring 'diff.renames' to 'copies'
        // NOTE: order here matters - doing -M before -C means copies aren't detected
        let args = [
            "log",
            sha,
            "-C",
            "-M",
            "-m",
            "-1",
            "--no-show-signature",
            "--first-parent",
            "--raw",
            "--format=format:",
            "--numstat",
            "-z",
            "--"
        ]

        let result = try GitShell().git(args: args,
                                    path: directoryURL,
                                    name: #function)
        let changedData =  try parseRawLogWithNumstat(stdout: result.stdout, sha: sha, parentCommitish: "\(sha)^")

        // Create an instance of IChangesetData from ChangesetData
        let changesetData: IChangesetData = IChangesetData(
            files: changedData.files,
            linesAdded: changedData.linesAdded,
            linesDeleted: changedData.linesDeleted
        )

        return changesetData
    }

    /**
     Parses the raw Git log output with numstat and extracts file changes and line modification statistics.

     - Parameters:
     - stdout: The raw Git log output containing numstat information.
     - sha: The commit SHA associated with the log output.
     - parentCommitish: The parent commitish associated with the log output.

     - Returns: A tuple containing an array of `CommittedFileChange` objects representing file changes, the total 
                number of lines added, and the total number of lines deleted.

     - Throws: An error if the log output or numstat information is invalid.

     - Note: This function processes raw Git log output with numstat information and extracts details about \
             file changes and line modification statistics. It iterates through the lines in the output, \
             identifying file changes and computing the total number of lines added and deleted. \
             It returns the parsed information in a tuple.

     */
    func parseRawLogWithNumstat(stdout: String,
                                sha: String,
                                parentCommitish: String) throws -> IChangesetData {
        var files = [CommittedFileChange]()
        var linesAdded = 0
        var linesDeleted = 0
        var numStatCount = 0

        let lines = stdout.split(separator: "\0")

        var number = 0
        while number < lines.count - 1 {
            let line = lines[number]
            if line.hasPrefix(":") {
                let lineComponents = line.split(separator: " ")
                guard lineComponents.count >= 3 else {
                    fatalError("Invalid log output (srcMode, dstMode, status)")
                }

                let srcMode = String(lineComponents[0].dropFirst())
                let dstMode = String(lineComponents[1])
                let status = String(lineComponents.last!)
                let oldPath: String? = status.hasPrefix("R") || status.hasPrefix("C") ? String(lines[number + 1]) : nil
                let path = String(lines[number + 2])

                files.append(CommittedFileChange(path: path,
                                                 status: mapStatus(rawStatus: status,
                                                                   oldPath: oldPath,
                                                                   srcMode: srcMode,
                                                                   dstMode: dstMode),
                                                 commitish: sha,
                                                 parentCommitish: parentCommitish))
                number += oldPath != nil ? 3 : 2
            } else {
                guard let match = line.range(of: "^(\\d+|-)\\t(\\d+|-)", options: .regularExpression) else {
                    fatalError("Invalid numstat line")
                }

                let added = line[match].split(separator: "\t")[0]
                let deleted = line[match].split(separator: "\t")[1]

                linesAdded += added == "-" ? 0 : Int(added)!
                linesDeleted += deleted == "-" ? 0 : Int(deleted)!

                if isCopyOrRename(status: files[numStatCount].status) {
                    number += 2
                }
                numStatCount += 1
            }
        }

        return IChangesetData(files: files,
                              linesAdded: linesAdded,
                              linesDeleted: linesDeleted)
    }

    /// Retrieve a specific commit from a Git repository by its reference.
    ///
    /// This function retrieves a specific commit from a Git repository directory using the provided commit reference. \
    /// It fetches the commit details and returns a `Commit` object if found.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///   - ref: The commit reference (e.g., commit SHA, branch name, tag) to retrieve.
    ///
    /// - Throws: An error of type `GitError` if the Git command fails.
    ///
    /// - Returns: A `Commit` object representing the specified commit if found, otherwise `nil`.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repository")
    ///   let commitRef = "abcdef1234567890abcdef1234567890abcdef12"
    ///
    ///   do {
    ///       if let commit = try getCommit(directoryURL: directoryURL, ref: commitRef) {
    ///           print("Commit SHA: \(commit.sha)")
    ///           print("Commit Summary: \(commit.summary)")
    ///       } else {
    ///           print("Commit not found.")
    ///       }
    ///   } catch {
    ///       print("Failed to retrieve commit: \(error)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   This function uses the `getCommits` function to fetch the commit details and returns the first commit found.
    func getCommit(directoryURL: URL,
                   ref: String) throws -> Commit? {
        let commits = try getCommits(directoryURL: directoryURL,
                                     revisionRange: ref,
                                     limit: 1,
                                     skip: nil)
        if commits.count < 1 {
            return nil
        }

        return commits[0]
    }

    /// Check if merge commits exist after a specified commit reference in a Git repository.
    ///
    /// This function checks if there are any merge commits after a specified commit reference in the given Git repository directory. \
    /// If a commit reference is provided, it checks for merge commits in the revision range from that commit to `HEAD`. \
    /// If no commit reference is provided, it checks for merge commits in the entire repository history.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///   - commitRef: An optional string representing the commit reference to start checking from.
    ///
    /// - Throws: An error of type `GitError` if the Git command fails.
    ///
    /// - Returns: `true` if there are merge commits after the specified commit reference, otherwise `false`.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repository")
    ///   let commitRef = "abcdef1234567890abcdef1234567890abcdef12"
    ///
    ///   do {
    ///       let hasMergeCommits = try doMergeCommitsExistAfterCommit(directoryURL: directoryURL, commitRef: commitRef)
    ///       if hasMergeCommits {
    ///           print("There are merge commits after the specified commit.")
    ///       } else {
    ///           print("There are no merge commits after the specified commit.")
    ///       }
    ///   } catch {
    ///       print("Failed to check for merge commits: \(error)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   This function uses the `git log` command with the `--merges` option to filter for merge commits.
    func doMergeCommitsExistAfterCommit(directoryURL: URL,
                                        commitRef: String?) throws -> Bool {
        let commitRevRange: String?
        if let commitRef = commitRef {
            commitRevRange = RevList().revRange(from: commitRef, to: "HEAD")
        } else {
            commitRevRange = nil
        }

        let mergeCommits = try getCommits(directoryURL: directoryURL,
                                          revisionRange: commitRevRange,
                                          limit: nil,
                                          skip: nil,
                                          additionalArgs: ["--merges"])

        return !mergeCommits.isEmpty
    }
}
