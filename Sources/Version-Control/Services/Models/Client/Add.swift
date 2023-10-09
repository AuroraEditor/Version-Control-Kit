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
    /**
     Adds a conflicted file to the index.

     Typically done after having resolved conflicts either manually
     or through checkout --theirs/--ours.
     */
    func addConflictedFile(directoryURL: URL,
                           file: GitFileItem) async throws {

        try ShellClient().run("cd \(directoryURL.relativePath.escapedWhiteSpaces()); git add -- \(file.url)")
    }
}
