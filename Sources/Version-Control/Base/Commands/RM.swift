//
//  RM.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/13.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

public struct RM { // swiftlint:disable:this type_name

    public init() {}

    /// Remove all files from the Git index.
    ///
    /// This function removes all files from the Git index (staging area) in a Git repository \
    /// located at the specified `directoryURL`. \
    /// The files are removed from the staging area while keeping them in the working directory.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the file removal from the index.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repo") // Replace with the path to the Git repository
    ///
    ///   do {
    ///       try unstageAllFiles(directoryURL: directoryURL)
    ///       print("All files have been removed from the Git index.")
    ///   } catch {
    ///       print("Error removing files from the Git index: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   This function uses the `git rm --cached -r -f .` command to remove all files from the Git \
    ///   index while preserving them in the working directory.
    ///
    /// - Warning:
    ///   Exercise caution when using this function, \
    ///   as it can lead to the removal of all staged changes without committing them. \
    ///   Make sure you understand the implications of unstaging files from the index.
    public func unstageAllFiles(directoryURL: URL) throws {

        // these flags are important:
        // --cached - to only remove files from the index
        // -r - to recursively remove files, in case files are in folders
        // -f - to ignore differences between working directory and index
        //          which will block this
        try GitShell().git(args: ["rm",
                                  "--chached",
                                  "-r",
                                  "-f",
                                  "."],
                           path: directoryURL,
                           name: #function)
    }

    /// Remove a conflicted file from both the working tree and the Git index (staging area).
    ///
    /// This function removes a conflicted file specified by `file` from both the working tree and the \
    /// Git index (staging area) in a Git repository located at the specified `directoryURL`. \
    /// The file will be deleted from the working directory, and the removal will be staged for the next commit.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///   - file: The `GitFileItem` representing the conflicted file to be removed.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the removal process.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repo") // Replace with the path to the Git repository
    ///   let conflictedFile = GitFileItem(url: URL(fileURLWithPath: "path/to/conflicted/file"), gitStatus: .conflicted)
    ///
    ///   do {
    ///       try removeConflictedFile(directoryURL: directoryURL, file: conflictedFile)
    ///       print("Conflicted file \(conflictedFile.url.path) has been removed.")
    ///   } catch {
    ///       print("Error removing conflicted file: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   This function uses the `git rm` command with the `--` flag to remove the specified conflicted file \
    ///        from both the working directory and the Git index.
    ///
    /// - Warning:
    ///   Be cautious when using this function, as it permanently deletes the conflicted file \
    ///   from both the working directory and the Git index.
    public func removeConflictedFile(directoryURL: URL,
                                     file: WorkingDirectoryFileChange) throws {
        try GitShell().git(args: ["rm",
                                  "--",
                                  file.path],
                           path: directoryURL,
                           name: #function)
    }
}
