//
//  Diff-Index.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/29.
//  Copyright © 2022 Aurora Company. All rights reserved.
//

import Foundation

/// Possible statuses of an entry in Git
public enum IndexStatus: Int {
    case unknown = 0
    case added
    case copied
    case deleted
    case modified
    case renamed
    case typeChanged
    case unmerged
}

public enum NoRenameIndexStatus {
    case added
    case deleted
    case modified
    case typeChanged
    case unmerged
    case unknown
}

public struct DiffIndex {

    public init() {}

    public func getIndexStatus(status: String) throws -> IndexStatus {
        switch status.substring(0) {
        case "A":
            return IndexStatus.added
        case "C":
            return IndexStatus.copied
        case "D":
            return IndexStatus.deleted
        case "M":
            return IndexStatus.modified
        case "R":
            return IndexStatus.renamed
        case "T":
            return IndexStatus.typeChanged
        case "U":
            return IndexStatus.unmerged
        case "X":
            return IndexStatus.unknown
        default:
            throw IndexError.unknownIndex("Unknown index status: \(status)")
        }
    }

    public func getNoRenameIndexStatus(_ status: String) throws -> NoRenameIndexStatus {
        do {
            let parsed = try getIndexStatus(status: status)

            switch parsed {
            case .unknown:
                return .unknown
            case .added:
                return .added
            case .copied, .renamed:
                throw IndexError.invalidStatus("Invalid index status for no-rename index status: \(parsed.rawValue)")
            case .deleted:
                return .deleted
            case .modified:
                return .modified
            case .typeChanged:
                return .typeChanged
            case .unmerged:
                return .unmerged
            }
        } catch {
            throw IndexError.invalidStatus("Unknown status: \(status)")
        }
    }

    /// The SHA for the nil tree
    public let nilTreeSHA = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"

    /// Get the status of changes in the Git index (staging area).
    ///
    /// This function retrieves the status of changes in the Git index (staging area) for all tracked files.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the Git repository directory where the `git diff-index` command will be executed.
    ///
    /// - Returns: A dictionary where the keys are file paths and the values are `IndexStatus` \
    ///            representing the status of each file in the index.
    ///
    /// - Throws: An error if there is a problem executing the `git diff-index` command or \
    ///           if the Git repository is not in a valid state.
    ///
    /// - SeeAlso: `git diff-index` documentation for additional options and details.
    public func getIndexChanges(directoryURL: URL) throws -> [String: NoRenameIndexStatus] {
        let args = [
            "diff-index",
            "--cached",
            "name-status",
            "--no-renames",
            "-z"
        ]

        var result = try GitShell().git(args: args + ["HEAD", "--"],
                                        path: directoryURL,
                                        name: #function,
                                        options: IGitExecutionOptions(successExitCodes: Set([0, 128])))

        if result.exitCode == 128 {
            result = try GitShell().git(args: args + [nilTreeSHA],
                                        path: directoryURL,
                                        name: #function)
        }

        let pieces = result.stdout.split(separator: "\0")

        var map = [String: NoRenameIndexStatus]()

        for number in stride(from: 0, to: pieces.count - 1, by: 2) {
            let statusString = String(pieces[number])
            let path = String(pieces[number + 1])
            let status = try getIndexStatus(status: statusString)

            switch status {
            case .unknown:
                map[path] = .unknown
            case .added:
                map[path] = .added
            case .deleted:
                map[path] = .deleted
            case .modified:
                map[path] = .modified
            case .typeChanged:
                map[path] = .typeChanged
            case .unmerged:
                map[path] = .unmerged
            default:
                map[path] = .unknown
            }
        }

        return map
    }
}
