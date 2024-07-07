//
//  GitStatus.swift
//
//
//  Created by Nanashi Li on 2023/11/20.
//

import Foundation

public struct GitStatus {

    public init() {}

    let MaxStatusBufferSize = 20_000_000 // 20MB in decima
    let conflictStatusCodes = ["DD", "AU", "UD", "UA", "DU", "AA", "UU"]

    /// Parse the conflicted state of a file entry.
    ///
    /// This function determines the conflicted state of a file entry based on the provided details.
    ///
    /// - Parameters:
    ///   - entry: The unmerged entry representing the file conflict.
    ///   - path: The file path.
    ///   - conflictDetails: The details of the conflicts in the repository.
    ///
    /// - Returns: A `ConflictedFileStatus` object representing the conflicted state of the file.
    ///
    /// - Example:
    ///   ```swift
    ///   let conflictEntry = TextConflictEntry(details: .init(action: .BothModified))
    ///   let conflictDetails = ConflictFilesDetails(conflictCountsByPath: ["file.txt": 3], binaryFilePaths: [])
    ///   let status = parseConflictedState(entry: conflictEntry, path: "file.txt", conflictDetails: conflictDetails)
    ///   print("Conflict status: \(status)")
    ///   ```
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

    /// Convert a file entry to an application-specific status.
    ///
    /// This function converts a file entry from the Git status to an application-specific status.
    ///
    /// - Parameters:
    ///   - path: The file path.
    ///   - entry: The file entry from the Git status.
    ///   - conflictDetails: The details of the conflicts in the repository.
    ///   - oldPath: The old path of the file if it has been renamed or copied.
    ///
    /// - Returns: An `AppFileStatus` object representing the status of the file.
    ///
    /// - Example:
    ///   ```swift
    ///   let entry = OrdinaryEntry(type: .added, submoduleStatus: nil)
    ///   let status = convertToAppStatus(path: "file.txt", entry: entry, conflictDetails: ConflictFilesDetails(), oldPath: nil)
    ///   print("App status: \(status)")
    ///   ```
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

    /// Retrieve the status of the working directory in a Git repository.
    ///
    /// This function retrieves the status of the working directory in the given Git repository directory.
    ///
    /// - Parameter directoryURL: The URL of the directory containing the Git repository.
    ///
    /// - Throws: An error of type `GitError` if the Git command fails.
    ///
    /// - Returns: A `StatusResult` object representing the status of the working directory.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repository")
    ///
    ///   Task {
    ///       do {
    ///           if let statusResult = try await getStatus(directoryURL: directoryURL) {
    ///               print("Current branch: \(statusResult.currentBranch)")
    ///               print("Merge head found: \(statusResult.mergeHeadFound)")
    ///           } else {
    ///               print("Not a Git repository.")
    ///           }
    ///       } catch {
    ///           print("Failed to get status: \(error)")
    ///       }
    ///   }
    ///   ```
    public func getStatus(directoryURL: URL) async throws -> StatusResult? { // swiftlint:disable:this function_body_length
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

    /// Build the status map of working directory changes.
    ///
    /// This function builds the status map of working directory changes based on the provided entries.
    ///
    /// - Parameters:
    ///   - files: The existing map of working directory changes.
    ///   - entry: The status entry from the Git status.
    ///   - conflictDetails: The details of the conflicts in the repository.
    ///
    /// - Returns: An updated map of working directory changes.
    ///
    /// - Example:
    ///   ```swift
    ///   let entries = [/* array of IStatusEntry */]
    ///   let files = [String: WorkingDirectoryFileChange]()
    ///   let conflictDetails = ConflictFilesDetails()
    ///   for entry in entries {
    ///       files = buildStatusMap(files: files, entry: entry, conflictDetails: conflictDetails)
    ///   }
    ///   print("Status map: \(files)")
    ///   ```
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

    /// Parse the status headers from the Git status output.
    ///
    /// This function parses the status headers from the Git status output and updates the status header data.
    ///
    /// - Parameters:
    ///   - results: The existing status header data.
    ///   - header: The status header entry from the Git status output.
    ///
    /// - Returns: An updated `StatusHeadersData` object.
    ///
    /// - Example:
    ///   ```swift
    ///   let headers = [/* array of IStatusHeader */]
    ///   var statusHeadersData = StatusHeadersData()
    ///   for header in headers {
    ///       statusHeadersData = parseStatusHeader(results: statusHeadersData, header: header)
    ///   }
    ///   print("Status headers data: \(statusHeadersData)")
    ///   ```
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

    /// Get the details of merge conflicts in the repository.
    ///
    /// This function retrieves the details of merge conflicts in the given Git repository directory.
    ///
    /// - Parameter directoryURL: The URL of the directory containing the Git repository.
    ///
    /// - Throws: An error of type `GitError` if the Git command fails.
    ///
    /// - Returns: A `ConflictFilesDetails` object containing the details of the merge conflicts.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repository")
    ///   let conflictDetails = try getMergeConflictDetails(directoryURL: directoryURL)
    ///   print("Merge conflict details: \(conflictDetails)")
    ///   ```
    func getMergeConflictDetails(directoryURL: URL) throws -> ConflictFilesDetails {
        let conflictCountsByPath = try DiffCheck().getFilesWithConflictMarkers(directoryURL: directoryURL)
        let binaryFilePaths = try GitDiff().getBinaryPaths(directoryURL: directoryURL, ref: "MERGE_HEAD")
        return ConflictFilesDetails(conflictCountsByPath: conflictCountsByPath, binaryFilePaths: binaryFilePaths)
    }

    /// Get the details of rebase conflicts in the repository.
    ///
    /// This function retrieves the details of rebase conflicts in the given Git repository directory.
    ///
    /// - Parameter directoryURL: The URL of the directory containing the Git repository.
    ///
    /// - Throws: An error of type `GitError` if the Git command fails.
    ///
    /// - Returns: A `ConflictFilesDetails` object containing the details of the rebase conflicts.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repository")
    ///   let conflictDetails = try getRebaseConflictDetails(directoryURL: directoryURL)
    ///   print("Rebase conflict details: \(conflictDetails)")
    ///   ```
    func getRebaseConflictDetails(directoryURL: URL) throws -> ConflictFilesDetails {
        let conflictCountsByPath = try DiffCheck().getFilesWithConflictMarkers(directoryURL: directoryURL)
        let binaryFilePaths = try GitDiff().getBinaryPaths(directoryURL: directoryURL, ref: "REBASE_HEAD")
        return ConflictFilesDetails(conflictCountsByPath: conflictCountsByPath, binaryFilePaths: binaryFilePaths)
    }

    /// Get the details of working directory conflicts in the repository.
    ///
    /// This function retrieves the details of working directory conflicts in the given Git repository directory.
    ///
    /// - Parameter directoryURL: The URL of the directory containing the Git repository.
    ///
    /// - Throws: An error of type `GitError` if the Git command fails.
    ///
    /// - Returns: A `ConflictFilesDetails` object containing the details of the working directory conflicts.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repository")
    ///   let conflictDetails = try getWorkingDirectoryConflictDetails(directoryURL: directoryURL)
    ///   print("Working directory conflict details: \(conflictDetails)")
    ///   ```
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

    /// Get the details of conflicts in the repository.
    ///
    /// This function retrieves the details of conflicts in the given Git repository directory based on the current state.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///   - mergeHeadFound: A boolean indicating if a merge head is found.
    ///   - lookForStashConflicts: A boolean indicating if stash conflicts should be looked for.
    ///   - rebaseInternalState: The internal state of a rebase operation.
    ///
    /// - Throws: An error of type `GitError` if the Git command fails.
    ///
    /// - Returns: A `ConflictFilesDetails` object containing the details of the conflicts.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repository")
    ///   let mergeHeadFound = true
    ///   let rebaseState: RebaseInternalState? = nil
    ///   let conflictDetails = try getConflictDetails(directoryURL: directoryURL,
    ///                                                mergeHeadFound: mergeHeadFound,
    ///                                                lookForStashConflicts: false,
    ///                                                rebaseInternalState: rebaseState)
    ///   print("Conflict details: \(conflictDetails)")
    ///   ```
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
