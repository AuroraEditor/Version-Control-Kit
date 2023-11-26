//
//  Cherry-Pick.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/12.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

public struct CherryPickSnapshot {
    let remainingCommits: [Commit]
    let commits: [Commit]
    let progress: MultiCommitOperationProgress
    let targetBranchUndoSha: String
    let cherryPickedCount: Int
}

public struct CherryPick {

    public init() {}

    /// The app-specific results from attempting to cherry pick commits
    enum CherryPickResult: String {
        /// Git completed the cherry pick without reporting any errors, and the caller can
        /// signal success to the user.
        case completedWithoutError = "CompletedWithoutError"
        /// The cherry pick encountered conflicts while attempting to cherry pick and
        /// need to be resolved before the user can continue.
        case conflictsEncountered = "ConflictsEncountered"
        /// The cherry pick was not able to continue as tracked files were not staged in
        /// the index.
        case outstandingFilesNotStaged = "OutstandingFilesNotStaged"
        /// The cherry pick was not attempted:
        /// - it could not check the status of the repository.
        /// - there was an invalid revision range provided.
        /// - there were uncommitted changes present.
        /// - there were errors in checkout the target branch
        case unableToStart = "UnableToStart"
        /// An unexpected error as part of the cherry pick flow was caught and handled.
        /// Check the logs to find the relevant Git details.
        case error = "Error"
    }

    /// Configures Git execution options with a callback to monitor the progress of cherry-picking operations.
    ///
    /// - Parameters:
    ///   - baseOptions: The base options for Git execution.
    ///   - commits: An array of `CommitOneLine` representing the commits to be cherry-picked.
    ///   - progressCallback: An escaping closure that is called with the progress of the operation.
    ///   - cherryPickedCount: An optional integer representing the number of commits already cherry-picked. Defaults to 0.
    /// - Returns: An `IGitExecutionOptions` instance with the process callback configured.
    internal func configureOptionsWithCallBack(baseOptions: IGitExecutionOptions,
                                               commits: [Commit],
                                               progressCallback: @escaping (IMultiCommitOperationProgress) -> Void,
                                               cherryPickedCount: Int = 0) -> IGitExecutionOptions {
        var options = baseOptions
        let parser = GitCherryPickParser(commits: commits,
                                         count: cherryPickedCount)

        options.processCallback = { stdoutContent in
            var stdout: String = ""

            let stdoutPipe = Pipe()
            stdoutContent.standardOutput = stdoutPipe

            let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: stdoutData, encoding: .utf8) {
                stdout = output
            }

            let lines = stdout.components(separatedBy: .newlines)
            for line in lines {
                if let progress = parser.parse(line: line) {
                    progressCallback(progress)
                }
            }
        }

        return options
    }

    /// Initiates a cherry-pick operation in a given directory with progress monitoring.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory where the cherry-pick operation is to be performed.
    ///   - commits: An array of `CommitOneLine` instances representing the commits to be cherry-picked.
    ///   - progressCallback: An optional closure called with progress information during the operation.
    /// - Throws: An error if the operation cannot start or if a problem occurs during execution.
    /// - Returns: A `CherryPickResult` indicating the outcome of the cherry-pick operation.
    func cherryPick(directoryURL: URL,
                    commits: [Commit],
                    progressCallback: ((IMultiCommitOperationProgress) -> Void)?) throws -> CherryPickResult {
        guard !commits.isEmpty else {
            return .unableToStart
        }

        var baseOptions: IGitExecutionOptions = IGitExecutionOptions(expectedErrors: [
            GitError.MergeConflicts,
            GitError.ConflictModifyDeletedInBranch
        ])

        if let progressCallback = progressCallback {
            baseOptions = configureOptionsWithCallBack(baseOptions: baseOptions,
                                                       commits: commits,
                                                       progressCallback: progressCallback)
        }

        let commitSHAs = commits.map { $0.sha }
        let args = ["cherry-pick"] + commitSHAs + ["--keep-redundant-commits", "-m", "1"]

        let result = try GitShell().git(args: args,
                                        path: directoryURL,
                                        name: #function,
                                        options: baseOptions)

        return try parseCherryPickResult(result: result)
    }

    /// Parses the result of a Git cherry-pick command and translates it into a `CherryPickResult`.
    ///
    /// - Parameter result: The `IGitResult` obtained from the Git operation.
    /// - Throws: An error if the result is unhandled or if an unrecognized Git error occurs.
    /// - Returns: A `CherryPickResult` that represents the outcome of the cherry-pick operation.
    internal func parseCherryPickResult(result: IGitResult) throws -> CherryPickResult {
        if result.exitCode == 0 {
            return .completedWithoutError
        }

        guard let gitError = result.gitError else {
            throw NSError(domain: "com.auroraeditor.editor",
                          code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Unhandled result found: \(result)"])
        }

        switch gitError {
        case .ConflictModifyDeletedInBranch, .MergeConflicts:
            return .conflictsEncountered
        case .UnresolvedConflicts:
            return .outstandingFilesNotStaged
        default:
            throw NSError(domain: "com.auroraeditor.editor",
                          code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Unhandled Git error: \(gitError)"])
        }
    }

    /// Retrieves the current snapshot of the cherry-pick operation status in a given directory.
    ///
    /// - Parameter directoryURL: The URL of the directory to check for cherry-pick progress.
    /// - Throws: An error if necessary information cannot be read from the repository.
    /// - Returns: A `CherryPickSnapshot` if cherry-pick is in progress, or nil if not.
    func getCherryPickSnapshot(directoryURL: URL) throws -> CherryPickSnapshot? {
        guard isCherryPickHeadFound(directoryURL: directoryURL) else {
            return nil
        }

        // Read the necessary files (.git/sequencer/*)
        let abortSafetyPath = directoryURL.appendingPathComponent(".git/sequencer/abort-safety").path
        let headPath = directoryURL.appendingPathComponent(".git/sequencer/head").path
        let todoPath = directoryURL.appendingPathComponent(".git/sequencer/todo").path

        guard let abortSafetySha = try? String(contentsOfFile: abortSafetyPath, 
                                               encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
              let headSha = try? String(contentsOfFile: headPath, 
                                        encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
              let remainingPicks = try? String(contentsOfFile: todoPath, 
                                               encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines) else {
            print("Could not read file")
            return nil
        }

        // Parse the commits from the todo file
        let remainingCommits = remainingPicks.split(separator: "\n").compactMap { line -> Commit? in
            let parts = line.split(separator: " ", maxSplits: 2)
            guard parts.count >= 3, parts[0] == "pick" else { return nil }
            return Commit(sha: String(parts[1]), summary: String(parts[2]))
        }

        // Get the commits that have already been cherry-picked
        let commitsCherryPicked = try RevList().getCommitsInRange(directoryURL: directoryURL,
                                                                  range: "\(headSha)...\(abortSafetySha)")

        let commits = commitsCherryPicked! + remainingCommits
        let position = commitsCherryPicked!.count + 1

        // Calculate the progress
        let progress = MultiCommitOperationProgress(
            kind: "multiCommitOperation",
            currentCommitSummary: remainingCommits.first?.summary ?? "",
            position: position,
            totalCommitCount: commits.count,
            value: Int(Double(position) / Double(commits.count))
        )

        return CherryPickSnapshot(
            remainingCommits: remainingCommits,
            commits: commits,
            progress: progress,
            targetBranchUndoSha: headSha,
            cherryPickedCount: commitsCherryPicked!.count
        )
    }

    /// Continues a paused cherry-pick operation after resolving conflicts or making manual changes.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory where the cherry-pick operation is to be continued.
    ///   - files: An array of `WorkingDirectoryFileChange` representing the changes to be staged.
    ///   - manualResolutions: A dictionary mapping file paths to `ManualConflictResolution` objects. Defaults to an empty dictionary.
    ///   - progressCallback: An optional closure called with progress information during the operation.
    /// - Throws: An error if the operation cannot start or if a problem occurs during execution.
    /// - Returns: A `CherryPickResult` indicating the outcome of the continued operation.
    func continueCherryPick(
        directoryURL: URL,
        files: [WorkingDirectoryFileChange],
        manualResolutions: [String: ManualConflictResolution] = [:],
        progressCallback: ((MultiCommitOperationProgress) -> Void)? = nil
    ) throws -> CherryPickResult {
        // Only stage files related to cherry-pick
        let trackedFiles = files.filter { $0.status.kind != .untracked }

        // Apply conflict resolutions
        for (path, resolution) in manualResolutions {
            guard let file = files.first(where: { $0.path == path }) else {
                continue
            }
            try GitStage().stageManualConflictResolution(directoryURL: directoryURL,
                                                         file: file,
                                                         manualResolution: resolution)
        }

        // Stage other files
        let otherFiles = trackedFiles.filter { !manualResolutions.keys.contains($0.path) }
        try UpdateIndex().stageFiles(directoryURL: directoryURL, files: otherFiles)

        // Verify cherry-pick is still in progress
        guard isCherryPickHeadFound(directoryURL: directoryURL) else {
            return .unableToStart
        }

        // Configure git execution options
        var options = IGitExecutionOptions(env: ["GIT_EDITOR": ":"],
                                           expectedErrors: [.MergeConflicts,
                                            .ConflictModifyDeletedInBranch,
                                            .UnresolvedConflicts])

        // Continue cherry-pick
        let result = try GitShell().git(args: ["cherry-pick", "--continue", "--keep-redundant-commits"],
                                        path: directoryURL,
                                        name: #function,
                                        options: options)
        return try parseCherryPickResult(result: result)
    }

    /// Aborts the current cherry-pick operation.
    ///
    /// - Parameter directoryURL: The URL of the directory where the cherry-pick operation is to be aborted.
    /// - Throws: An error if the abort command fails.
    public func abortCherryPick(directoryURL: URL) throws {
        try ShellClient().run(
            "cd \(directoryURL.relativePath.escapedWhiteSpaces());git cherry-pick --abort"
        )
    }

    /// Checks if a cherry-pick operation is in progress in a given directory.
    ///
    /// - Parameter directoryURL: The URL of the directory to check for cherry-pick operation.
    /// - Returns: A Boolean value indicating whether a cherry-pick operation is in progress.
    public func isCherryPickHeadFound(directoryURL: URL) -> Bool {
        do {
            let cherryPickHeadPath = try String(contentsOf: directoryURL) + ".git/CHERRY_PICK_HEAD"

            return FileManager.default.fileExists(atPath: cherryPickHeadPath)
        } catch {
            print(
                "[cherryPick] A problem was encountered reading .git/CHERRY_PICK_HEAD," +
                " so it is unsafe to continue cherry-picking."
            )
            return false
        }
    }
}
