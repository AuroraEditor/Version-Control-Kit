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

public struct GitLog {

    public init() {}

    // File mode 160000 is used by git specifically for submodules:
    // https://github.com/git/git/blob/v2.37.3/cache.h#L62-L69
    let subModuleFileMode = "160000"

    func mapSubmoduleStatusFileModes(status: String, srcMode: String, dstMode: String) -> SubmoduleStatus? {
        let subModuleFileMode = subModuleFileMode // Define subModuleFileMode here

        if srcMode == subModuleFileMode && dstMode == subModuleFileMode && status == "M" {
            return SubmoduleStatus(commitChanged: true, modifiedChanges: false, untrackedChanges: false)
        } else if (srcMode == subModuleFileMode && status == "D") || (dstMode == subModuleFileMode && status == "A") {
            return SubmoduleStatus(commitChanged: false, modifiedChanges: false, untrackedChanges: false)
        }

        return nil
    }

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

    func isCopyOrRename(status: AppFileStatus) -> Bool {
        return status.kind == .copied || status.kind == .renamed
    }

    public func getCommits( // swiftlint:disable:this function_body_length
        directoryURL: URL,
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
                trailers: InterpretTrailers().parseRawUnfoldedTrailers(trailers: commit["trailers"] ?? "", seperators: ":"),
                tags: tags
            )
        }
    }

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

     - Note: This function processes raw Git log output with numstat information and extracts details about file changes 
             and line modification statistics. It iterates through the lines in the output, identifying file changes and computing
             the total number of lines added and deleted. It returns the parsed information in a tuple.

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
