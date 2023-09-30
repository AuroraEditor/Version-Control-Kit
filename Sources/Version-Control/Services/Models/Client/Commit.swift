//
//  Commit.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/12.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

public struct Commit {
    
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
                             files: [GitFileItem],
                             amend: Bool = false) throws -> String {
        try Reset().unstageAll(directoryURL: directoryURL)

        var args = ["-F", "-"]

        if amend {
            args.append("--amend")
        }

        let result = try ShellClient.live().run(
            "cd \(directoryURL.relativePath.escapedWhiteSpaces());git commit \(args)"
        )

        return parseCommitSHA(result: result)
    }

    /// Creates a commit to finish an in-progress merge
    /// assumes that all conflicts have already been resolved
    ///
    /// @param repository repository to execute merge in
    /// @param files files to commit
    public func createMergeCommit() {}
}
