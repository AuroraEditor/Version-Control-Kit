//
//  Apply.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/15.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

public struct Apply {

    /// Applies a Git patch to the Git index for a specified file in a specified directory.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///   - file: The GitFileItem representing the file to which the patch should be applied.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the patch application process.
    ///
    /// - Note:
    ///   If the file was renamed (`file.gitStatus == .renamed`), \
    ///   this function recreates the rename operation by staging the removal of the old file \
    ///   and adding the old file's blob to the index under the new name.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repo")
    ///   let fileToPatch = GitFileItem(url: URL(fileURLWithPath: "path/to/file"), status: .modified)
    ///
    ///   do {
    ///       try applyPatchToIndex(directoryURL: directoryURL, file: fileToPatch)
    ///       print("Patch applied to the index for '\(fileToPatch.url.relativePath)'.")
    ///   } catch {
    ///       print("Error applying patch to the index: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Warning:
    ///   Ensure that the specified `directoryURL` exists and is a valid Git repository directory.
    public func applyPatchToIndex(directoryURL: URL,
                                  file: GitFileItem) throws {
        // If the file was a rename we have to recreate that rename since we've
        // just blown away the index. Think of this block of weird looking commands
        // as running `git mv`.
        if file.gitStatus == .renamed {
            // Make sure the index knows of the removed file. We could use
            // update-index --force-remove here but we're not since it's
            // possible that someone staged a rename and then recreated the
            // original file and we don't have any guarantees for in which order
            // partial stages vs full-file stages happen. By using git add the
            // worst that could happen is that we re-stage a file already staged
            // by updateIndex.
            try ShellClient().run(
                "cd \(directoryURL.relativePath.escapedWhiteSpaces());git add --u \(file.url)")

            // Figure out the blob oid of the removed file
            // <mode> SP <type> SP <object> TAB <file>
            let oldFile = try ShellClient.live().run(
                "cd \(directoryURL.relativePath.escapedWhiteSpaces());git ls-tree HEAD --\(file.url)")

            let info = oldFile.split(separator: "\t", maxSplits: 1)
            let mode = info.split(separator: " ", maxSplits: 3)
            let oid = mode

            // Add the old file blob to the index under the new name
            try ShellClient().run(
                // swiftlint:disable:next line_length
                "cd \(directoryURL.relativePath.escapedWhiteSpaces());git update-index --add --cacheinfo \(mode) \(oid) \(file.url)")
        }

        let applyArgs: [String] = [
            "apply",
            "--cached",
            "--undiff-zero",
            "--whitespace=nowarn",
            "-"
        ]

        try ShellClient().run(
            "cd \(directoryURL.relativePath.escapedWhiteSpaces());git \(applyArgs)")

    }
}
