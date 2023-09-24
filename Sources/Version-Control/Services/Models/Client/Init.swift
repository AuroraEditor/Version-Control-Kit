//
//  Init.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/13.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

/// Initialize a new Git repository in the specified directory.
///
/// This function creates a new Git repository in the provided directory and configures the default branch name based on system settings. If a Git repository already exists in the specified directory, this function has no effect.
///
/// - Parameters:
///   - directoryURL: The URL of the directory where the Git repository should be initialized.
///
/// - Throws: An error if there was an issue initializing the Git repository.
///
/// - Example:
///   ```swift
///   do {
///       try initGitRepository(directoryURL: myProjectDirectoryURL)
///       print("Git repository initialized successfully.")
///   } catch {
///       print("Error: \(error)")
///   }
///   ```
///
/// - Note: If a Git repository already exists in the specified directory, this function will not reinitialize it and will have no effect.
///
/// - Important: Make sure to call this function to initialize a new Git repository in a directory before performing Git operations on that directory.
public func initGitRepository(directoryURL: URL) throws {
    try ShellClient().run(
        // swiftlint:disable:next line_length
        "cd \(directoryURL.relativePath.escapedWhiteSpaces());git -c init.defaultBranch=\(DefaultBranch().getDefaultBranch()) init"
    )
}
