//
//  Rebase.swift
//
//
//  Created by Nanashi Li on 2023/11/01.
//

import Foundation

public struct Rebase {

    public init() {}

    func getRebaseInternalState(directoryURL: URL) throws -> RebaseInternalState? {
        let rebaseMergePath = directoryURL.appendingPathComponent(".git/rebase-merge")

        let isRebase = isRebaseHeadSet(directoryURL: directoryURL)

        if !isRebase {
            return nil
        }

        let originalBranchTip = try String(
            contentsOf: rebaseMergePath.appendingPathComponent("orig-head")
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        var targetBranch = try String(
            contentsOf: rebaseMergePath.appendingPathComponent("head-name")
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        if targetBranch.hasPrefix("refs/heads/") {
            targetBranch.removeFirst("refs/heads/".count)
        }

        let baseBranchTip = try String(
            contentsOf: rebaseMergePath.appendingPathComponent("onto")
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        return RebaseInternalState(targetBranch: originalBranchTip,
                                   baseBranchTip: targetBranch,
                                   originalBranchTip: baseBranchTip)
    }

    func getRebaseSnapshot(directoryURL: URL) -> (progress: MultiCommitOperationProgress,
                                                  commits: [Commit])? {
        let rebaseMergePath = directoryURL.appendingPathComponent(".git/rebase-merge")

        guard let next = try? Int(String(contentsOf: rebaseMergePath.appendingPathComponent("msgnum"))),
              let last = try? Int(String(contentsOf: rebaseMergePath.appendingPathComponent("end"))),
              let originalBranchTip = try? String(
                contentsOf: rebaseMergePath.appendingPathComponent("orig-head")
              ).trimmingCharacters(in: .whitespacesAndNewlines),
              let baseBranchTip = try? String(
                contentsOf: rebaseMergePath.appendingPathComponent("onto")
              ).trimmingCharacters(in: .whitespacesAndNewlines),
              next > 0,
              last > 0 else {
            return nil
        }

        let percentage = Double(next) / Double(last)
        let value = formatRebaseValue(value: percentage)

        guard let commits = try? RevList().getCommitsBetweenCommits(directoryURL: directoryURL,
                                                                    baseBranchSha: baseBranchTip,
                                                                    targetBranchSha: originalBranchTip),
              !commits.isEmpty else {
            return nil
        }

        let nextCommitIndex = next - 1
        let hasValidCommit = nextCommitIndex >= 0 && nextCommitIndex < commits.count
        let currentCommitSummary = hasValidCommit ? commits[nextCommitIndex].summary : ""

        let progress = MultiCommitOperationProgress(
            kind: "multiCommitOperation",
            currentCommitSummary: currentCommitSummary,
            position: next,
            totalCommitCount: last,
            value: Int(value)
        )

        return (progress: progress, commits: commits)
    }

    func rebase(directoryURL: URL,
                baseBranch: GitBranch,
                targetBranch: GitBranch,
                progressCallback: ((MultiCommitOperationProgress) -> Void)? = nil) throws -> RebaseResult? {
        let baseOptions: IGitExecutionOptions = IGitExecutionOptions(expectedErrors: [GitError.RebaseConflicts])
        var options = baseOptions

        if let progressCallback = progressCallback {
            if let commits = try RevList().getCommitsBetweenCommits(directoryURL: directoryURL,
                                                                    baseBranchSha: baseBranch.tip!.sha,
                                                                    targetBranchSha: targetBranch.tip!.sha) {
                options = configureOptionsForRebase(options: baseOptions,
                                                    progress: RebaseProgressOptions(commits: commits,
                                                                                    progressCallback: progressCallback))
            } else {
                print("Unable to rebase these branches because one or both of the refs do not exist in the repository")
                return nil
            }
        }

        let result = try GitShell().git(args: gitRebaseArguments + ["rebsse", baseBranch.name, targetBranch.name],
                                        path: directoryURL,
                                        name: #function,
                                        options: options)

        return parseRebaseResult(result: result)
    }

    /// Check the `.git/REBASE_HEAD` file exists in a repository to confirm
    /// a rebase operation is underway.
    func isRebaseHeadSet(directoryURL: URL) -> Bool {
        let gitDirectoryURL = directoryURL.appendingPathComponent(".git")
        let rebaseHeadURL = gitDirectoryURL.appendingPathComponent("REBASE_HEAD")
        let fileManager = FileManager.default

        return fileManager.fileExists(atPath: rebaseHeadURL.path)
    }

    /// Attempt to read the `.git/REBASE_HEAD` file inside a repository to confirm
    /// the rebase is still active.
    func readRebaseHead(directoryURL: URL) -> String? {
        let gitDirectoryURL = directoryURL.appendingPathComponent(".git")
        let rebaseHeadURL = gitDirectoryURL.appendingPathComponent("REBASE_HEAD")

        do {
            let rebaseHeadContents = try String(contentsOf: rebaseHeadURL, encoding: .utf8)
            return rebaseHeadContents.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            print("[rebase] a problem was encountered reading .git/REBASE_HEAD, so it is unsafe to continue rebasing")
            return nil
        }
    }

    let rebasingRegexPattern = #"^Rebasing \((\d+)\/(\d+)\)$"#

    public func abortRebase(directoryURL: URL) throws {
        try GitShell().git(args: ["rebase", "--abort"],
                           path: directoryURL,
                           name: #function)
    }

    func parseRebaseResult(result: IGitResult) -> RebaseResult {
        if result.exitCode == 0 {
            if result.stdout.trimmingCharacters(in: .whitespacesAndNewlines).range(
                of: #"^Current branch [^ ]+ is up to date.$"#,
                options: .regularExpression) != nil {
                return .alreadyUpToDate
            }
            return .completedWithoutError
        }

        if result.gitError == GitError.RebaseConflicts {
            return .conflictsEncountered
        }

        if result.gitError == GitError.UnresolvedConflicts {
            return .outstandingFilesNotStaged
        }

        return .error
    }

    func configureOptionsForRebase(options: IGitExecutionOptions,
                                   progress: RebaseProgressOptions?) -> IGitExecutionOptions {
        guard let progress = progress else {
            return options
        }

        var newOptions = options
        let parser = GitRebaseParser(commits: progress.commits)

        newOptions.processCallback = { output in
            // Assuming output is a string containing the content of stderr
            var stdout = ""

            let stdoutPipe = Pipe()
            output.standardOutput = stdoutPipe

            let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: stdoutData, encoding: .utf8) {
                stdout = output
            }

            let lines = stdout.components(separatedBy: "\n")
            for line in lines {
                if let progressInfo = parser.parse(line: line) {
                    progress.progressCallback(progressInfo)
                }
            }
        }

        return newOptions
    }

    func continueRebase(directoryURL: URL,
                        files: [WorkingDirectoryFileChange],
                        manualResolutions: [String: ManualConflictResolution] = [:],
                        progressCallback: ((MultiCommitOperationProgress) -> Void)?,
                        gitEditor: String = ":") async throws -> RebaseResult {

        let trackedFiles = files.filter { $0.status?.kind != .untracked }

        // Apply conflict resolutions
        for (path, resolution) in manualResolutions {
            if let file = files.first(where: { $0.path == path }) {
                try GitStage().stageManualConflictResolution(directoryURL: directoryURL,
                                                             file: file,
                                                             manualResolution: resolution)
            } else {
                print("[continueRebase] couldn't find file \(path) even though there's a manual resolution for it")
            }
        }

        let otherFiles = trackedFiles.filter { !manualResolutions.keys.contains($0.path) }
        try UpdateIndex().stageFiles(directoryURL: directoryURL, files: otherFiles)

        guard let status = try await GitStatus().getStatus(directoryURL: directoryURL) else {
            print("[continueRebase] unable to get status after staging changes, skipping any other steps")
            return .aborted
        }

        guard let rebaseCurrentCommit = readRebaseHead(directoryURL: directoryURL) else {
            return .aborted
        }

        let trackedFilesAfter = status.workingDirectory.files.filter { $0.status?.kind != .untracked }

        var options = IGitExecutionOptions(env: ["GIT_EDITOR": gitEditor],
                                           expectedErrors: [.RebaseConflicts, .UnresolvedConflicts])

        if let progressCallback = progressCallback {
            guard let snapshot = getRebaseSnapshot(directoryURL: directoryURL) else {
                print("[continueRebase] unable to get rebase status, skipping any other steps")
                return .aborted
            }

            options = configureOptionsForRebase(options: options,
                                                progress: RebaseProgressOptions(commits: snapshot.commits,
                                                                                progressCallback: progressCallback))
        }

        if trackedFilesAfter.isEmpty {
            print([
                "[rebase] no tracked changes to commit for \(rebaseCurrentCommit),",
                " continuing rebase but skipping this commit"
            ].joined())

            let result = try GitShell().git(args: ["rebase", "--skip"],
                                            path: directoryURL,
                                            name: #function,
                                            options: options)
            return parseRebaseResult(result: result)
        }

        let result = try GitShell().git(args: ["rebase", "--continue"],
                                        path: directoryURL,
                                        name: #function,
                                        options: options)
        return parseRebaseResult(result: result)
    }

    func rebaseInteractive(directoryURL: URL,
                           pathOfGeneratedTodo: String,
                           lastRetainedCommitRef: String?,
                           action: String = "Interactive rebase",
                           gitEditor: String = ":",
                           progressCallback: ((MultiCommitOperationProgress) -> Void)? = nil,
                           commits: [Commit]? = nil
    ) throws -> RebaseResult {
        var baseOptions = IGitExecutionOptions(env: ["GIT_EDITOR": gitEditor],
                                               expectedErrors: [.RebaseConflicts])

        if let progressCallback = progressCallback, let commits = commits {
            let context = RebaseProgressOptions(commits: commits,
                                                progressCallback: progressCallback)
            baseOptions = configureOptionsForRebase(options: baseOptions, progress: context)
        } else {
            // Log warning if commits are not provided
            return .error
        }

        let ref = lastRetainedCommitRef ?? "--root"
        let sequenceEditorCommand = "cat \"\(pathOfGeneratedTodo)\" >"

        let result = try GitShell().git(args: ["-c",
                                               "sequence.editor=\(sequenceEditorCommand)",
                                               "rebase",
                                               "-i",
                                               ref],
                                        path: directoryURL,
                                        name: #function,
                                        options: baseOptions)

        return parseRebaseResult(result: result)
    }
}
