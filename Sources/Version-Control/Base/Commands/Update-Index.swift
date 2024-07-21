//
//  Update-Index.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/15.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

protocol IUpdateIndexOptions {
    /// Whether or not to add a file when it exists in the working directory
    /// but not in the index. Defaults to true (note that this differs from the
    /// default behavior of Git which is to ignore new files).
    ///
    /// @default true
    var add: Bool { get set }

    /// Whether or not to remove a file when it exists in the index but not
    /// in the working directory. Defaults to true (note that this differs from
    /// the default behavior of Git which is to ignore removed files).
    ///
    /// @default true
    var remove: Bool { get set }

    /// Whether or not to forcefully remove a file from the index even though it
    /// exists in the working directory. This implies remove.
    ///
    /// @default false
    var forceRemove: Bool { get set }

    /// Whether or not to replace conflicting entries in the index with that of
    /// the working directory. Imagine the following scenario
    ///
    /// $ touch foo && git update-index --add foo && git commit -m 'foo'
    /// $ rm foo && mkdir foo && echo "bar" > foo/bar
    /// $ git update-index --add foo/bar
    /// error: 'foo/bar' appears as both a file and as a directory
    /// error: foo/bar: cannot add to the index - missing --add option?
    /// fatal: Unable to process path foo/bar
    ///
    /// Replace ignores this conflict and overwrites the index with the
    /// newly created directory, causing the original foo file to be deleted
    /// in the index. This behavior matches what `git add` would do in a similar
    /// scenario.
    ///
    /// @default true
    var replace: Bool { get set }
}

public class UpdateIndexOptions: IUpdateIndexOptions {
    var add: Bool
    var remove: Bool
    var forceRemove: Bool
    var replace: Bool

    init(add: Bool = true,
         remove: Bool = true,
         forceRemove: Bool = false,
         replace: Bool = true) {
        self.add = add
        self.remove = remove
        self.forceRemove = forceRemove
        self.replace = replace
    }
}

public struct UpdateIndex {

    public init() {}

    /// Update the Git index with changes to specified paths in a local Git repository.
    ///
    /// This function updates the Git index with changes to the specified file paths in the local Git repository.
    ///
    /// - Parameters:
    ///   - directoryURL: The local directory URL of the Git repository.
    ///   - paths: An array of file paths to update in the Git index.
    ///   - options: An optional `UpdateIndexOptions` object that allows you to specify additional options\
    ///     for the `update-index` Git command.
    ///
    /// - Throws: An error if there's an issue with executing the Git command or if the specified paths are invalid.
    ///
    /// - Example:
    ///   ```swift
    ///   do {
    ///       let directoryURL = URL(fileURLWithPath: "/path/to/local/repository")
    ///       let pathsToUpdate = ["file1.txt", "file2.txt"]
    ///       let updateOptions = UpdateIndexOptions(add: true, remove: false, forceRemove: false, replace: false)
    ///       try updateIndex(directoryURL: directoryURL, paths: pathsToUpdate, options: updateOptions)
    ///   } catch {
    ///       print("Error: Unable to update the Git index.")
    ///   }
    public func updateIndex(directoryURL: URL,
                            paths: [String],
                            options: UpdateIndexOptions? = nil) throws {
        guard !paths.isEmpty else {
            return
        }

        var args = ["update-index"]

        if options?.add ?? true {
            args.append("--add")
        }

        if options?.remove ?? true || options?.forceRemove ?? false {
            args.append("--remove")
        }

        if options?.forceRemove ?? false {
            args.append("--force-remove")
        }

        if options?.replace ?? true {
            args.append("--replace")
        }

        args.append(contentsOf: ["-z", "--stdin"])

        let joinedPaths = paths.joined(separator: "\0")

        try GitShell().git(args: args,
                           path: directoryURL,
                           name: #function,
                           options: IGitExecutionOptions(stdin: joinedPaths))
    }

    public func stageFiles(directoryURL: URL,
                           files: [WorkingDirectoryFileChange]) throws {
        var normal = [String]()
        var oldRenamed = [String]()
        var partial = [WorkingDirectoryFileChange]()
        var deletedFiles = [String]()

        for file in files {
            switch file.selection.getSelectionType() {
            case .all:
                normal.append(file.path)

                guard let fileStatus = file.status as? CopiedOrRenamedFileStatus else {
                    if file.status?.kind == .deleted {
                        deletedFiles.append(file.path)
                    }
                    continue
                }
                oldRenamed.append(fileStatus.oldPath)
            case .partial:
                partial.append(file)
            case .none:
                print("None to be added!")
            }
        }

        // Staging files happens in three steps.
        //
        // In the first step we run through all of the renamed files, or
        // more specifically the source files (old) that were renamed and
        // forcefully remove them from the index. We do this in order to handle
        // the scenario where a file has been renamed and a new file has been
        // created in its original position. Think of it like this
        //
        // $ touch foo && git add foo && git commit -m 'foo'
        // $ git mv foo bar
        // $ echo "I'm a new foo" > foo
        //
        // Now we have a file which is of type Renamed that has its path set
        // to 'bar' and its oldPath set to 'foo'. But there's a new file called
        // foo in the repository. So if the user selects the 'foo -> bar' change
        // but not the new 'foo' file for inclusion in this commit we don't
        // want to add the new 'foo', we just want to recreate the move in the
        // index. We do this by forcefully removing the old path from the index
        // and then later (in step 2) stage the new file.
        try updateIndex(directoryURL: directoryURL,
                        paths: oldRenamed,
                        options: UpdateIndexOptions(forceRemove: true))

        // In the second step we update the index to match
        // the working directory in the case of new, modified, deleted,
        // and copied files as well as the destination paths for renamed
        // paths.
        try updateIndex(directoryURL: directoryURL,
                        paths: normal,
                        options: nil)

        // This third step will only happen if we have files that have been marked
        // for deletion. This covers us for files that were blown away in the last
        // updateIndex call
        try updateIndex(directoryURL: directoryURL,
                        paths: deletedFiles,
                        options: UpdateIndexOptions(forceRemove: true))

        for file in files {
            try Apply().applyPatchToIndex(directoryURL: directoryURL, file: file)
        }
    }

}
