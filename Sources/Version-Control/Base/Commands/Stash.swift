//
//  Stash.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/12.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

enum StashedFileChanges {
    case notLoaded
    case loading
    case loaded(files: [GitFileItem])
}

public struct Stash {

    public init() {}

    private let editorStashEntryMarker = "!!AuroraEditor"

    private let editorStashEntryMessageRe = "/!!AuroraEditor<(.+)>$/"

    public class StashResult {
        /// The stash entries created by Desktop
        var aeEntries: [StashEntry]
        /// The total amount of stash entries,
        /// i.e. stash entries created both by AE and outside of AE
        var stashEntryCount: Int

        init(aeEntries: [StashEntry], stashEntryCount: Int) {
            self.aeEntries = aeEntries
            self.stashEntryCount = stashEntryCount
        }
    }

    /// Get the list of stash entries created by AE in the current repository
    /// using the default ordering of refs (which is LIFO ordering),
    /// as well as the total amount of stash entries.
    @discardableResult
    func getStashes(directoryURL: URL) throws -> StashResult {
        let fields = [
            "name": "%gd",
            "stashSha": "%H",
            "message": "%gs",
            "tree": "%T",
            "parents": "%P"
        ]

        let formatArgs = GitDelimiterParser().createLogParser(fields)

        let args = ["stash", "list", "--format=\(fields.values.joined(separator: "%x00"))"]
        let result = try GitShell().git(args: args, path: directoryURL, name: #function)

        if result.exitCode == 128 {
            // There's no refs/stashes reflog in the repository or it's not a repository. In either case we don't care.
            return StashResult(aeEntries: [], stashEntryCount: 0)
        }

        var stashEntries = [StashEntry]()

        let entries = formatArgs.parse(result.stdout)

        for entry in entries {
            let branchName = extractBranchFromMessage(entry["message"] ?? "")

            if let branchName = branchName {
                stashEntries.append(StashEntry(
                    name: entry["name"] ?? "",
                    branchName: branchName,
                    stashSha: entry["stashSha"] ?? "",
                    files: nil, // Assuming this needs to be populated somehow.
                    tree: entry["tree"] ?? "",
                    parents: entry["parents"]?.components(separatedBy: " ") ?? []
                ))
            }
        }

        return StashResult(aeEntries: stashEntries, stashEntryCount: entries.count)
    }

    func moveStashEntry(directoryURL: URL,
                        stash: StashEntry,
                        branchName: String) throws {
        let message = "On \(branchName): \(createAEStashMessage(branchName: branchName))"
        var parentArgs: [String] = []
        if let parents = stash.parents {
            parentArgs += parents.map { "-p \($0)" }
        }

        let commitId = try GitShell().git(args: ["commit-tree"] + parentArgs + ["-m", message, "--no-gpg-sign", stash.tree ?? ""],
                                          path: directoryURL,
                                          name: #function)

        try GitShell().git(args: ["stash", "store", "-m", message, commitId.stdout.trimmingCharacters(in: .whitespacesAndNewlines)],
                           path: directoryURL,
                           name: #function)

        try dropAEStashEntry(directoryURL: directoryURL,
                             stashSha: stash.stashSha ?? "")
    }

    func getLastAEStashEntryForBranch(directoryURL: URL,
                                      branch: Any) throws -> StashEntry? {
        let stash = try getStashes(directoryURL: directoryURL)
        let branchName: String

        if let branchString = branch as? String {
            branchName = branchString
        } else if let branchObj = branch as? GitBranch {
            branchName = branchObj.name
        } else {
            // Handle the case where branch is neither a String nor a Branch
            return nil
        }

        // Since stash objects are returned in a LIFO manner, the first
        // entry found is guaranteed to be the last entry created
        return stash.aeEntries.first { $0.branchName == branchName }
    }

    /// Returns the last AE created stash entry for the given branch
    public func getLastAEStashEntryForBranch(directoryURL: URL,
                                             branch: String) throws {
        let stash = try getStashes(directoryURL: directoryURL)
        let branchName = branch
    }

    /// Creates a stash entry message that indicates the entry was created by Aurora Editor
    public func createAEStashMessage(branchName: String) -> String {
        return "\(editorStashEntryMarker)\(branchName)"
    }

    /// Stash the working directory changes for the current branch
    func createAEStashEntry(directoryURL: URL,
                            branch: Any,
                            untrackedFilesToStage: [WorkingDirectoryFileChange]) throws -> Bool {
        let fullySelectedUntrackedFiles = untrackedFilesToStage.map { $0.withIncludeAll(include: true) }

        try UpdateIndex().stageFiles(directoryURL: directoryURL,
                       files: untrackedFilesToStage)

        let branchName: String
        if let branchString = branch as? String {
            branchName = branchString
        } else if let branchObj = branch as? GitBranch {
            branchName = branchObj.name
        } else {
            // Handle the case where branch is neither a String nor a Branch
            return false
        }

        let message = createAEStashMessage(branchName: branchName)
        let args = ["stash", "push", "-m", message]

        let result = try GitShell().git(args: args,
                                        path: directoryURL,
                                        name: #function,
                                        options: IGitExecutionOptions(successExitCodes: Set([0, 1])))

        // Check for specific git errors
        if result.exitCode == 1 {
            let errorPrefixRe = try! NSRegularExpression(pattern: "^error: ", options: .anchorsMatchLines)
            let nsRange = NSRange(result.stderr.startIndex..<result.stderr.endIndex, in: result.stderr)

            if errorPrefixRe.firstMatch(in: result.stderr, options: [], range: nsRange) != nil {
                // Rethrow the error as it should prevent the stash from being created
                print("Stash creation failed.")
                return false
            }

            // If no error messages, log and continue
            print("[createAEStashEntry] a stash was created successfully but exit code \(result.exitCode) reported. stderr: \(result.stderr)")
        }

        // Check if there were no local changes to save
        if result.stdout == "No local changes to save\n" {
            return false
        }

        return true
    }

    private func getStashEntryMatchingSha(directoryURL: URL, sha: String) throws -> StashEntry? {
        let stash = try getStashes(directoryURL: directoryURL)
        return stash.aeEntries.first { $0.stashSha == sha }
    }

    /// Removes the given stash entry if it exists
    ///
    /// @param stashSha the SHA that identifies the stash entry
    func dropAEStashEntry(directoryURL: URL, stashSha: String) throws {
        if let entryToDelete = try getStashEntryMatchingSha(directoryURL: directoryURL, sha: stashSha) {
            let args = ["stash", "drop", entryToDelete.name ?? ""]
            try GitShell().git(args: args, path: directoryURL, name: #function)
        }
    }

    /// Pops the stash entry identified by matching `stashSha` to its commit hash.
    ///
    /// To see the commit hash of stash entry, run
    /// `git log -g refs/stash --pretty="%nentry: %gd%nsubject: %gs%nhash: %H%n"`
    /// in a repo with some stash entries.
    func popStashEntry(directoryURL: URL, stashSha: String) throws {
        // Ignoring these git errors for now, this will change when we start
        // implementing the stash conflict flow
        let expectedErrors = Set<GitError>([.MergeConflicts])
        let successExitCodes = Set<Int>([0, 1])
        guard let stashToPop = try getStashEntryMatchingSha(directoryURL: directoryURL, sha: stashSha) else {
            return
        }

        let args = ["stash", "pop", "--quiet", stashToPop.name ?? ""]
        let result = try GitShell().git(args: args,
                                        path: directoryURL,
                                        name: #function,
                                        options: IGitExecutionOptions(successExitCodes: successExitCodes,
                                                                      expectedErrors: expectedErrors))

        // Popping stashes that create conflicts in the working directory
        // report an exit code of `1` and are not dropped after being applied.
        // So, we check for this case and drop them manually.
        if result.exitCode == 1 {
            if !result.stderr.isEmpty {
                // Rethrow, because anything in stderr should prevent the stash from being popped.
                throw GitErrorParser(result: result, args: args)
            }

            print("[popStashEntry] a stash was popped successfully but exit code \(result.exitCode) reported.")
            // Bye bye
            try dropAEStashEntry(directoryURL: directoryURL, stashSha: stashSha)
        }
    }

    func extractBranchFromMessage(_ message: String) -> String? {
        let AEStashEntryMessageRe = try! NSRegularExpression(pattern: "On (.+): ", options: [])
        let range = NSRange(message.startIndex..<message.endIndex, in: message)

        if let match = AEStashEntryMessageRe.firstMatch(in: message, options: [], range: range) {
            let branchRange = Range(match.range(at: 1), in: message)
            if let branchRange = branchRange {
                return String(message[branchRange])
            }
        }

        return nil
    }

    /// Get the files that were changed in the given stash commit
    func getStashedFiles(directoryURL: URL, stashSha: String) async throws -> [CommittedFileChange] {
        let args = [
            "stash",
            "show",
            stashSha,
            "--raw",
            "--numstat",
            "-z",
            "--format=format:",
            "--no-show-signature",
            "--"
        ]

        let result = try GitShell().git(args: args, path: directoryURL, name: #function)
        let files = try GitLog().parseRawLogWithNumstat(stdout: result.stdout, sha: stashSha, parentCommitish: "\(stashSha)^").files

        return files
    }
}
