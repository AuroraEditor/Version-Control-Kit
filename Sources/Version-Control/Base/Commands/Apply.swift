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

    /// Applies changes to the index for a specified file in a git repository, with special handling for renamed files.
    ///
    /// If the file change represents a rename, the function reconstructs this rename in the index. This involves
    /// staging the old file path for update and determining the blob ID of the removed file to update the index.
    /// This process ensures that the rename is properly reflected in the index, preparing it for a commit.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the git repository.
    ///   - file: A `WorkingDirectoryFileChange` object representing the file \ 
    ///           whose changes are to be applied to the index.
    /// - Throws: An error if the git commands fail to execute.
    ///
    /// # Example:
    /// ```
    /// let directoryURL = URL(fileURLWithPath: "/path/to/repo")
    /// let fileChange = WorkingDirectoryFileChange(path: "newName.txt", status: .renamed(oldName: "oldName.txt"))
    /// try await applyPatchToIndex(directoryURL: directoryURL, file: fileChange)
    /// ```
    func applyPatchToIndex( // swiftlint:disable:this function_body_length
        directoryURL: URL,
        file: WorkingDirectoryFileChange
    ) throws {
        // If the file was a rename we have to recreate that rename since we've
        // just blown away the index.
        if file.status.kind == .renamed {
            if let renamedFile = file.status as? CopiedOrRenamedFileStatus {
                if renamedFile.kind == .renamed {
                    try GitShell().git(args: ["add", "--u", "--", renamedFile.oldPath],
                                       path: directoryURL,
                                       name: #function)

                    // Figure out the blob oid of the removed file
                    let oldFile = try GitShell().git(args: ["ls-tree", "HEAD", "--", renamedFile.oldPath],
                                                     path: directoryURL,
                                                     name: #function)

                    let info = oldFile.stdout.split(separator: "\t",
                                                    maxSplits: 1,
                                                    omittingEmptySubsequences: true)[0]
                    let components = info.split(separator: " ",
                                                maxSplits: 3,
                                                omittingEmptySubsequences: true)
                    let mode = components[0]
                    let oid = components[2]

                    try GitShell().git(args: ["update-index",
                                              "--add",
                                              "--cacheinfo",
                                              String(mode),
                                              String(oid),
                                              file.path],
                                       path: directoryURL,
                                       name: #function)
                }
            }
        }

        let applyArgs: [String] = [
            "apply",
            "--cached",
            "--unidiff-zero",
            "--whitespace=nowarn",
            "-"
        ]

        let diff = try GitDiff().getWorkingDirectoryDiff(directoryURL: directoryURL,
                                                         file: file)

        if let diff = diff as? TextDiff {
            switch diff.kind {
            case .image, .binary, .submodule:
                throw NSError(
                    domain: "com.auroraeditor.versioncontrolkit.patcherror",
                    code: 0,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Can't create partial commit in binary file: \(file.path)"
                    ]
                )
            case .unrenderable:
                throw NSError(
                    domain: "com.auroraeditor.versioncontrolkit.patcherror",
                    code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "File diff is too large to generate a partial commit: \(file.path)"
                    ]
                )
            default:
                fatalError("Unknown diff kind: \(diff.kind)")
            }
        }

        if let diff = diff as? TextDiff {
            let patch = try PatchFormatterParser().formatPatch(file: file,
                                                               diff: diff)

            try GitShell().git(args: applyArgs,
                               path: directoryURL,
                               name: #function,
                               options: IGitExecutionOptions(stdin: patch))
        }
    }

    /// Verifies if a patch can be applied cleanly to the current state of the repository.
    ///
    /// This function uses the `git apply --check` command to test if the provided patch can be applied.
    /// The `--check` flag ensures that no changes are actually made to the files. It simply checks
    /// for potential conflicts. If the patch cannot be applied due to conflicts, the function returns `false`.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the git repository.
    ///   - patch: A string containing the patch data.
    /// - Returns: `true` if the patch can be applied cleanly, or `false` if conflicts are detected.
    /// - Throws: An error if the git command fails for reasons other than the patch not applying.
    ///
    /// # Example:
    /// ```
    /// let directoryURL = URL(fileURLWithPath: "/path/to/repo")
    /// let patchString = "diff --git a/file.txt b/file.txt..."
    /// let canApplyPatch = try checkPatch(directoryURL: directoryURL, patch: patchString)
    /// ```
    func checkPatch(directoryURL: URL,
                    patch: String) throws -> Bool {
        let result = try GitShell().git(args: ["apply", "--check", "-"],
                                        path: directoryURL,
                                        name: #function,
                                        options: IGitExecutionOptions(
                                            expectedErrors: [GitError.PatchDoesNotApply]
                                        ))

        if result.gitError == GitError.PatchDoesNotApply {
            return false
        }

        // If `apply --check` succeeds, then the patch applies cleanly.
        return true
    }

    /// Discards selected changes from a file in the working directory of a git repository.
    ///
    /// This function generates a patch representing the inverse of the selected changes and applies it
    /// to the file to discard those changes. If the selection results in no changes, the function does
    /// nothing. The function uses the `git apply` command with flags designed to apply a patch with
    /// a zero context and to suppress warnings about whitespace.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the git repository.
    ///   - filePath: The path to the file within the repository from which changes will be discarded.
    ///   - diff: An object conforming to the `ITextDiff` protocol representing the diff of the file.
    ///   - selection: A `DiffSelection` object representing the selected changes to discard.
    /// - Throws: An error if the patch cannot be generated or applied.
    ///
    /// # Example:
    /// ```
    /// let directoryURL = URL(fileURLWithPath: "/path/to/repo")
    /// let filePath = "file.txt"
    /// let diff = TextDiff(...) // Diff object conforming to ITextDiff
    /// let selection = DiffSelection(...) // Selection object specifying which changes to discard
    /// try discardChangesFromSelection(directoryURL: directoryURL,
    ///                                 filePath: filePath,
    ///                                 diff: diff,
    ///                                 selection: selection)
    /// ```
    func discardChangesFromSelection(directoryURL: URL,
                                     filePath: String,
                                     diff: ITextDiff,
                                     selection: DiffSelection) throws {
        guard let patch = PatchFormatterParser().formatPatchToDiscardChanges(filePath: filePath,
                                                                             diff: diff,
                                                                             selection: selection) else {
            // When the patch is null we don't need to apply it since it will be a noop.
            return
        }

        let args = ["apply", "--unidiff-zero", "--whitespace=nowarn", "-"]

        try GitShell().git(args: args,
                           path: directoryURL,
                           name: #function,
                           options: IGitExecutionOptions(stdin: patch))
    }
}
