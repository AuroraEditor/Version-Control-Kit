//
//  Rev-Parse.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/16.
//  Copyright © 2022 Aurora Company. All rights reserved.
//

import Foundation

public enum RepositoryType {
    case missing
    case bare
    case regular(topLevelWorkingDirectory: String)
    case unsafe(path: String)
}

public struct RevParse {

    public init() {}

    /// Determine the type of a Git repository at the specified `path`.
    ///
    /// This function attempts to identify the type of a Git repository located at the specified `path`. \
    /// It can determine whether the repository is a bare repository, a regular repository, or if it couldn't be found.
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
    ///   This function uses the `git rev-parse --is-bare-repository` command to determine \
    ///   if the repository is bare or regular. \
    ///   It also checks for certain error messages to identify unsafe or missing repositories.
    ///
    /// - Warning:
    ///   This function assumes that the Git executable is available and accessible in the system's PATH.
    func getRepositoryType(directoryURL: URL) throws -> RepositoryType {
        if FileManager().directoryExistsAtPath(directoryURL.relativePath) {
            return .missing
        }

        do {
            let result = try GitShell().git(args: ["rev-parse", "--is-bare-repository", "--show-cdup"],
                                            path: directoryURL,
                                            name: #function,
                                            options: IGitExecutionOptions(
                                                successExitCodes: Set([0, 128])
                                            ))

            if result.exitCode == 0 {
                let lines = result.stdout.components(separatedBy: "\n")
                if let isBare = lines.first, let cdup = lines.dropFirst().first {
                    return isBare == "true" ? .bare : .regular(
                        topLevelWorkingDirectory: resolve(
                            basePath: directoryURL.relativePath,
                            relativePath: cdup
                        )
                    )
                }
            }

            if let unsafeMatch = result.stderr.range(
                of: "fatal: detected dubious ownership in repository at '(.+)'", 
                options: .regularExpression
            ) {
                let unsafePath = String(result.stderr[unsafeMatch])
                return .unsafe(path: unsafePath)
            }

            return .missing
        } catch {
            if (error as NSError).code == NSFileNoSuchFileError {
                return .missing
            }
            throw error
        }
    }

    internal func resolve(basePath: String, relativePath: String) -> String {
        // Check if the relativePath is already an absolute path
        if relativePath.hasPrefix("/") {
            return relativePath
        }

        // Construct the absolute path by expanding tilde and appending relativePath
        let expandedPath = NSString(string: relativePath).expandingTildeInPath
        return NSString(string: basePath).appendingPathComponent(expandedPath)
    }

}
