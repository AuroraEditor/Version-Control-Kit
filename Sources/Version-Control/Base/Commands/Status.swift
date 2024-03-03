//
//  File.swift
//  
//
//  Created by Nanashi Li on 2023/11/20.
//

import Foundation

public struct GitStatus {

    public init() {}

    let MaxStatusBufferSize = 20_000_000 // 20MB in decima
    let conflictStatusCodes = ["DD", "AU", "UD", "UA", "DU", "AA", "UU"]

    func parseConflictedState(
        entry: UnmergedEntry,
        path: String,
        conflictDetails: ConflictFilesDetails
    ) -> ConflictedFileStatus {
        if let textConflictEntry = entry as? TextConflictEntry,
           [.BothAdded, .BothModified].contains(textConflictEntry.details.action) {
            let isBinary = conflictDetails.binaryFilePaths.contains(path)
            if !isBinary {
                return ConflictsWithMarkers(kind: .conflicted,
                                            entry: textConflictEntry,
                                            conflictMarkerCount: conflictDetails.conflictCountsByPath[path] ?? 0,
                                            submoduleStatus: nil)
            }
        }

        let manualConflictEntry = entry as? ManualConflictEntry
        return ManualConflict(kind: .conflicted,
                              entry: manualConflictEntry!,
                              submoduleStatus: nil)
    }

    func convertToAppStatus(
        path: String,
        entry: FileEntry,
        conflictDetails: ConflictFilesDetails,
        oldPath: String?
    ) -> AppFileStatus {
        if let entry = entry as? OrdinaryEntry {
            switch entry.type {
            case .added:
                return PlainFileStatus(kind: .new, submoduleStatus: entry.submoduleStatus)
            case .modified:
                return PlainFileStatus(kind: .modified, submoduleStatus: entry.submoduleStatus)
            case .deleted:
                return PlainFileStatus(kind: .deleted, submoduleStatus: entry.submoduleStatus)
            }
        } else if let entry = entry as? RenamedOrCopiedEntry, let oldPath = oldPath {
            let kind: AppFileStatusKind = entry.kind == "copied" ? .copied : .renamed
            return CopiedOrRenamedFileStatus(kind: kind, oldPath: oldPath, submoduleStatus: entry.submoduleStatus)
        } else if let entry = entry as? UntrackedEntry {
            return UntrackedFileStatus(kind: .untracked, submoduleStatus: entry.submoduleStatus)
        } else if let entry = entry as? UnmergedEntry {
            return parseConflictedState(entry: entry, path: path, conflictDetails: conflictDetails)
        } else {
            fatalError("Unknown file status \(type(of: entry))")
        }
    }

    func getStatus(directoryURL: URL) async throws -> StatusResult? { // swiftlint:disable:this function_body_length
        let args = [
            "--no-optional-locks",
            "status",
            "--untracked-files=all",
            "--branch",
            "--porcelain=2",
            "-z"
        ]

        let result = try GitShell().git(args: args,
                                        path: directoryURL,
                                        name: #function,
                                        options: IGitExecutionOptions(successExitCodes: [0, 128]))

        if result.exitCode == 128 {
            print("'\(directoryURL.absoluteString)' is not a git repository.")
            return nil
        }

        if result.stdout.count > MaxStatusBufferSize {
            print("Output exceeds maximum buffer size.")
            return nil
        }

        let parsed = GitStatusParser().parsePorcelainStatus(output: result.stdout)
        let headers = parsed.compactMap { $0 as? IStatusHeader }
        let entries = parsed.compactMap { $0 as? IStatusEntry }

        let mergeHeadFound = try Merge().isMergeHeadSet(directoryURL: directoryURL)
        let conflictedFilesInIndex = entries.contains { conflictStatusCodes.contains($0.statusCode) }
        let rebaseInternalState = try Rebase().getRebaseInternalState(directoryURL: directoryURL)

        let conflictDetails = try getConflictDetails(
            directoryURL: directoryURL,
            mergeHeadFound: mergeHeadFound,
            lookForStashConflicts: conflictedFilesInIndex,
            rebaseInternalState: rebaseInternalState
        )

        var files = [String: WorkingDirectoryFileChange]()
        for entry in entries {
            files = buildStatusMap(files: files, entry: entry, conflictDetails: conflictDetails)
        }

        let statusHeadersData = headers.reduce(into: StatusHeadersData()) { partialResult, header in
            partialResult = parseStatusHeader(results: partialResult, header: header)
        }

        let workingDirectory = WorkingDirectoryStatus(files: Array(files.values))

        let isCherryPickingHeadFound = CherryPick().isCherryPickHeadFound(directoryURL: directoryURL)
        let squashMsgFound = try Merge().isSquashMsgSet(directoryURL: directoryURL)

        return StatusResult(
            currentBranch: statusHeadersData.currentBranch,
            currentUpstreamBranch: statusHeadersData.currentUpstreamBranch,
            currentTip: statusHeadersData.currentTip,
            branchAheadBehind: statusHeadersData.branchAheadBehind,
            exists: true,
            mergeHeadFound: mergeHeadFound,
            squashMsgFound: squashMsgFound,
            rebaseInternalState: rebaseInternalState,
            isCherryPickingHeadFound: isCherryPickingHeadFound,
            workingDirectory: workingDirectory,
            doConflictedFilesExist: conflictedFilesInIndex
        )
    }

    func buildStatusMap(
        files: [String: WorkingDirectoryFileChange],
        entry: IStatusEntry,
        conflictDetails: ConflictFilesDetails
    ) -> [String: WorkingDirectoryFileChange] {
        var files = files
        let status = GitStatusParser().mapStatus(
            statusCode: entry.statusCode,
            submoduleStatusCode: entry.submoduleStatusCode
        )

        if let status = status as? OrdinaryEntry {
            if status.index == .added && status.workingTree == .deleted {
                return files
            }
        } else if let status = status as? UntrackedEntry {
            files.removeValue(forKey: entry.path)
        }

        let appStatus = convertToAppStatus(
            path: entry.path,
            entry: status,
            conflictDetails: conflictDetails,
            oldPath: entry.oldPath
        )

        let initialSelectionType: DiffSelectionType =
        appStatus.kind == .modified && appStatus.submoduleStatus != nil && !appStatus.submoduleStatus!.commitChanged
        ? .none
        : .all

        let selection = DiffSelection(defaultSelectionType: initialSelectionType)

        files[entry.path] = WorkingDirectoryFileChange(path: entry.path, status: appStatus, selection: selection)
        return files
    }

    func parseStatusHeader(results: StatusHeadersData,
                           header: IStatusHeader) -> StatusHeadersData {
        var currentBranch = results.currentBranch
        var currentUpstreamBranch = results.currentUpstreamBranch
        var currentTip = results.currentTip
        var branchAheadBehind = results.branchAheadBehind

        let value = header.value

        // Regex patterns
        let branchOidPattern = #"^branch\.oid ([a-f0-9]+)$"#
        let branchHeadPattern = #"^branch.head (.*)$"#
        let branchUpstreamPattern = #"^branch.upstream (.*)$"#
        let branchAbPattern = #"^branch.ab \+(\d+) -(\d+)$"#

        // Branch OID
        if let match = value.matchingStrings(regex: branchOidPattern).first {
            currentTip = match[1]
        }
        // Branch Head
        else if let match = value.matchingStrings(regex: branchHeadPattern).first, match[1] != "(detached)" {
            currentBranch = match[1]
        }
        // Branch Upstream
        else if let match = value.matchingStrings(regex: branchUpstreamPattern).first {
            currentUpstreamBranch = match[1]
        }
        // Branch Ahead-Behind
        else if let match = value.matchingStrings(regex: branchAbPattern).first {
            let ahead = Int(match[1])
            let behind = Int(match[2])
            if let ahead = ahead, let behind = behind {
                branchAheadBehind = IAheadBehind(ahead: ahead, behind: behind)
            }
        }

        return StatusHeadersData(
            currentBranch: currentBranch,
            currentUpstreamBranch: currentUpstreamBranch,
            currentTip: currentTip,
            branchAheadBehind: branchAheadBehind,
            match: nil
        )
    }

    func getMergeConflictDetails(directoryURL: URL) throws -> ConflictFilesDetails {
        let conflictCountsByPath = try DiffCheck().getFilesWithConflictMarkers(directoryURL: directoryURL)
        let binaryFilePaths = try GitDiff().getBinaryPaths(directoryURL: directoryURL, ref: "MERGE_HEAD")
        return ConflictFilesDetails(conflictCountsByPath: conflictCountsByPath, binaryFilePaths: binaryFilePaths)
    }

    func getRebaseConflictDetails(directoryURL: URL) throws -> ConflictFilesDetails {
        let conflictCountsByPath = try DiffCheck().getFilesWithConflictMarkers(directoryURL: directoryURL)
        let binaryFilePaths = try GitDiff().getBinaryPaths(directoryURL: directoryURL, ref: "REBASE_HEAD")
        return ConflictFilesDetails(conflictCountsByPath: conflictCountsByPath, binaryFilePaths: binaryFilePaths)
    }

    func getWorkingDirectoryConflictDetails(directoryURL: URL) throws -> ConflictFilesDetails {
        let conflictCountsByPath = try DiffCheck().getFilesWithConflictMarkers(directoryURL: directoryURL)
        var binaryFilePaths: [String] = []

        do {
            // It's totally fine if HEAD doesn't exist, which throws an error.
            binaryFilePaths = try GitDiff().getBinaryPaths(directoryURL: directoryURL, ref: "HEAD")
        } catch {
            print("Error getting binary paths: \(error)")
        }

        return ConflictFilesDetails(conflictCountsByPath: conflictCountsByPath, binaryFilePaths: binaryFilePaths)
    }

    func getConflictDetails(directoryURL: URL,
                            mergeHeadFound: Bool,
                            lookForStashConflicts: Bool,
                            rebaseInternalState: RebaseInternalState?
    ) throws -> ConflictFilesDetails {
        do {
            if mergeHeadFound {
                return try getMergeConflictDetails(directoryURL: directoryURL)
            }

            if let rebaseState = rebaseInternalState {
                return try getRebaseConflictDetails(directoryURL: directoryURL)
            }

            if lookForStashConflicts {
                return try getWorkingDirectoryConflictDetails(directoryURL: directoryURL)
            }
        } catch {
            print("Unexpected error from git operations in getConflictDetails: \(error)")
        }
        return ConflictFilesDetails(conflictCountsByPath: [:], binaryFilePaths: [])
    }
}
