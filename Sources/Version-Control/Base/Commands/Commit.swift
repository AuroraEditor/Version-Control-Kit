//
//  Commit.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/12.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

public struct GitCommit {

    public init() {}

    /// Creates a Git commit in a specified Git repository directory.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///   - message: The commit message for the new commit.
    ///   - files: An array of `GitFileItem` representing the files to be included in the commit.
    ///   - amend: A Boolean flag indicating whether to amend the last commit (default is `false`).
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the commit creation process.
    ///
    /// - Returns:
    ///   The SHA-1 hash of the newly created commit.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repo")
    ///   let commitMessage = "Added feature X" // Replace with your commit message
    ///   let filesToCommit = [GitFileItem(url: URL(fileURLWithPath: "file1.txt"), status: .modified)]
    ///
    ///   do {
    ///       let commitSHA = try createCommit(directoryURL: directoryURL, message: commitMessage, files: filesToCommit)
    ///       print("Commit \(commitSHA) created successfully.")
    ///   } catch {
    ///       print("Error creating commit: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Warning:
    ///   Ensure that the specified `directoryURL` exists and is a valid Git repository directory.
    public func createCommit(directoryURL: URL,
                             message: String,
                             files: [WorkingDirectoryFileChange],
                             amend: Bool = false) throws -> String {
        try Reset().unstageAll(directoryURL: directoryURL)

        try UpdateIndex().stageFiles(directoryURL: directoryURL,
                                     files: files)

        var args = ["-F", "-"]

        if amend {
            args.append("--amend")
        }

        let result = try GitShell().git(args: ["commit"] + args,
                                        path: directoryURL,
                                        name: #function,
                                        options: IGitExecutionOptions(stdin: message))

        return parseCommitSHA(result: result)
    }

    /// Creates a commit to finish an in-progress merge
    /// assumes that all conflicts have already been resolved
    ///
    /// @param repository repository to execute merge in
    /// @param files files to commit
    func createMergeCommit(directoryURL: URL,
                           files: [WorkingDirectoryFileChange],
                           manualResolutions: [String: ManualConflictResolution] = [:]) throws -> String {
        // Apply manual conflict resolutions
        for (path, resolution) in manualResolutions {
            if let file = files.first(where: { $0.path == path }) {
                try GitStage().stageManualConflictResolution(directoryURL: directoryURL,
                                                             file: file,
                                                             manualResolution: resolution)
            } else {
                print("Couldn't find file \(path) even though there's a manual resolution for it")
            }
        }

        // Stage other files
        let otherFiles = files.filter { !manualResolutions.keys.contains($0.path) }
        // Assuming `stageFiles` is implemented
        try UpdateIndex().stageFiles(directoryURL: directoryURL, files: files)

        // Create merge commit

        let result = try GitShell().git(
            args: [
                "commit",
                // no-edit here ensures the app does not accidentally invoke the user's editor
                "--no-edit",
                // By default Git merge commits do not contain any commentary (which
                // are lines prefixed with `#`). This works because the Git CLI will
                // prompt the user to edit the file in `.git/COMMIT_MSG` before
                // committing, and then it will run `--cleanup=strip`.
                //
                // This clashes with our use of `--no-edit` above as Git will now change
                // it's behavior to invoke `--cleanup=whitespace` as it did not ask
                // the user to edit the COMMIT_MSG as part of creating a commit.
                //
                // From the docs on git-commit (https://git-scm.com/docs/git-commit) I'll
                // quote the relevant section:
                // --cleanup=<mode>
                //     strip
                //        Strip leading and trailing empty lines, trailing whitespace,
                //        commentary and collapse consecutive empty lines.
                //     whitespace
                //        Same as `strip` except #commentary is not removed.
                //     default
                //        Same as `strip` if the message is to be edited. Otherwise `whitespace`.
                //
                // We should emulate the behavior in this situation because we don't
                // let the user view or change the commit message before making the
                // commit.
                "--cleanup=strip"
            ],
            path: directoryURL,
            name: #function
        )

        // Parse the commit SHA from the result
        return parseCommitSHA(result: result)
    }
}
