//
//  Add.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/12.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

public struct Add {
    /// Stages a file that has conflicts after a Git operation such as a merge or cherry-pick.
    ///
    /// This function is typically used to mark a file with conflicts as resolved by adding it to the staging area.
    /// After resolving the conflicts manually in the file, you would call this function to stage the file.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory where the Git repository is located.
    ///   - file: A `WorkingDirectoryFileChange` object representing the file with conflicts to be staged.
    /// - Throws: An error if the `git add` command fails.
    func addConflictedFile(directoryURL: URL,
                           file: WorkingDirectoryFileChange) throws {

        try GitShell().git(args: ["add", "--", file.path],
                           path: directoryURL,
                           name: #function)
    }
}
