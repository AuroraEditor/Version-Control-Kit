//
//  Rev-Parse.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/16.
//  Copyright © 2022 Aurora Company. All rights reserved.
//

import Foundation

public enum RepositoryType {
    case bare
    case regular
    case missing
    case unsafe
}

/// Determine the type of a Git repository at the specified `path`.
///
/// This function attempts to identify the type of a Git repository located at the specified `path`. It can determine whether the repository is a bare repository, a regular repository, or if it couldn't be found.
///
/// - Parameters:
///   - path: The path to the directory where the Git repository is located.
///
/// - Returns:
///   - A `RepositoryType` enumeration value indicating the type of the Git repository:
///     - `.bare`: If the repository is a bare repository.
///     - `.regular`: If the repository is a regular (non-bare) repository.
///     - `.missing`: If the repository couldn't be found or an error occurred during the determination.
///
/// - Throws:
///   - An error of type `Error` if any issues occur during the type determination process.
///
/// - Example:
///   ```swift
///   let repositoryPath = "/path/to/repo" // Replace with the path to the Git repository
///
///   do {
///       let repositoryType = try getRepositoryType(path: repositoryPath)
///       print("Repository at \(repositoryPath) is of type: \(repositoryType)")
///   } catch {
///       print("Error determining the repository type: \(error.localizedDescription)")
///   }
///   ```
///
/// - Note:
///   This function uses the `git rev-parse --is-bare-repository` command to determine if the repository is bare or regular. It also checks for certain error messages to identify unsafe or missing repositories.
///
/// - Warning:
///   This function assumes that the Git executable is available and accessible in the system's PATH.
public func getRepositoryType(path: String) throws -> RepositoryType {
    if FileManager().directoryExistsAtPath(path) {
        return .missing
    }

    do {
        let result = try ShellClient.live().run(
            "cd \(path);git rev-parse --is-bare-repository -show-cdup"
        )

        if !result.contains(GitError.notAGitRepository.rawValue) {
            let isBare = result.split(separator: "\n", maxSplits: 2)

            return isBare.description == "true" ? .bare : .regular
        }

        if result.contains("fatal: detected dubious ownership in repository at") {
            return .unsafe
        }

        return .missing
    } catch {
        // This could theoretically mean that the Git executable didn't exist but
        // in reality, it's almost always going to be that the process couldn't be
        // launched inside of `path` meaning it didn't exist. This would constitute
        // a race condition given that we stat the path before executing Git.
        print("Git doesn't exist, returning as missing")
        return .missing
    }
}
