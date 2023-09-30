//
//  LFS.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/13.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

public struct LFS {
    
    public init() {}
    
    /// Install Git LFS (Large File Storage) global filters.
    ///
    /// Git LFS is an extension for handling large files in a Git repository. This function installs Git LFS global filters, which apply to all Git repositories on the system and are configured globally.
    ///
    /// - Parameters:
    ///   - force: A flag indicating whether to force the installation of global filters if they already exist.
    ///
    /// - Throws: An error if there was an issue installing global LFS filters or if the installation is forced and fails.
    ///
    /// - Example:
    ///   ```swift
    ///   do {
    ///       try installGlobalLFSFilters(force: false)
    ///       print("Global Git LFS filters installed successfully.")
    ///   } catch {
    ///       print("Error: \(error)")
    ///   }
    ///   ```
    ///
    /// - Note: If `force` is set to `true`, the function will forcibly install global LFS filters even if they already exist.
    ///
    /// - Important: Installing global Git LFS filters is typically required to properly manage large files in all Git repositories on the system. Make sure to call this function if you want to apply Git LFS globally.
    public func installGlobalLFSFilters(force: Bool) throws {
        var args = ["lfs", "install", "--skip-repo"]

        if force {
            args.append("--force")
        }

        try ShellClient().run("git \(args)")
    }

    /// Install Git LFS (Large File Storage) hooks in a Git repository.
    ///
    /// Git LFS is an extension for handling large files in a Git repository. This function installs Git LFS hooks in the repository, which are scripts that run at various points in the Git workflow to manage large files.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the Git repository where LFS hooks should be installed.
    ///   - force: A flag indicating whether to force the installation of hooks if they already exist.
    ///
    /// - Throws: An error if there was an issue installing LFS hooks, if the provided repository URL is invalid, or if the hooks installation is forced and fails.
    ///
    /// - Example:
    ///   ```swift
    ///   let repositoryURL = URL(fileURLWithPath: "/path/to/git/repo")
    ///
    ///   do {
    ///       try installLFSHooks(directoryURL: repositoryURL, force: false)
    ///       print("Git LFS hooks installed successfully.")
    ///   } catch {
    ///       print("Error: \(error)")
    ///   }
    ///   ```
    ///
    /// - Note: If `force` is set to `true`, the function will forcibly install LFS hooks even if they already exist in the repository.
    ///
    /// - Important: Installing Git LFS hooks is typically required to properly manage large files in a Git repository. Make sure to call this function if your repository uses Git LFS for large file storage.
    public func installLFSHooks(directoryURL: URL, force: Bool) throws {
        var args = ["lfs", "install"]

        if force {
            args.append("--force")
        }

        try ShellClient().run(
            "cd \(directoryURL.relativePath.escapedWhiteSpaces());git \(args)"
        )
    }

    /// Check whether the Git repository is configured to track any paths with Git LFS (Large File Storage).
    ///
    /// Git LFS is an extension for handling large files in a Git repository, and this function helps you determine if the repository is configured to track any paths using Git LFS within its configuration.
    ///
    /// - Parameter directoryURL: The URL of the Git repository.
    ///
    /// - Returns: `true` if the repository is configured to track paths with Git LFS; otherwise, `false`.
    ///
    /// - Throws: An error if there was an issue querying the Git repository or if the provided repository URL is invalid.
    ///
    /// - Example:
    ///   ```swift
    ///   let repositoryURL = URL(fileURLWithPath: "/path/to/git/repo")
    ///
    ///   do {
    ///       let isUsingLFS = try isUsingLFS(directoryURL: repositoryURL)
    ///       if isUsingLFS {
    ///           print("The Git repository is configured to use Git LFS.")
    ///       } else {
    ///           print("The Git repository is not using Git LFS.")
    ///       }
    ///   } catch {
    ///       print("Error: \(error)")
    ///   }
    ///   ```
    ///
    /// - Important: This function checks whether the Git repository is configured to track any paths with Git LFS in its configuration. It does not specify which paths are tracked; use `isTrackedByLFS` to check if specific files are tracked.
    public func isUsingLFS(directoryURL: URL) throws -> Bool {
        let result = try ShellClient.live().run(
            "cd \(directoryURL.relativePath.escapedWhiteSpaces());git lfs track"
        )

        // The result from "git lfs track" contains information about tracked paths.
        // We check if the result is not empty, indicating that paths are being tracked with Git LFS.
        return !result.isEmpty
    }

    /// Check whether the Git repository is configured to track a specific file with Git LFS (Large File Storage).
    ///
    /// Git LFS is an extension for handling large files in a Git repository, and this function helps you determine if a particular file is tracked by Git LFS within the repository's configuration.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the Git repository.
    ///   - path: The relative path of the file to check for Git LFS tracking.
    ///
    /// - Returns: `true` if the file is tracked by Git LFS in the repository's configuration; otherwise, `false`.
    ///
    /// - Throws: An error if there was an issue querying the Git repository or if the provided paths are invalid.
    ///
    /// - Example:
    ///   ```swift
    ///   let repositoryURL = URL(fileURLWithPath: "/path/to/git/repo")
    ///   let filePath = "data/bigfile.dat"
    ///
    ///   do {
    ///       let isTracked = try isTrackedByLFS(directoryURL: repositoryURL, path: filePath)
    ///       if isTracked {
    ///           print("The file '\(filePath)' is tracked by Git LFS.")
    ///       } else {
    ///           print("The file '\(filePath)' is not tracked by Git LFS.")
    ///       }
    ///   } catch {
    ///       print("Error: \(error)")
    ///   }
    ///   ```
    ///
    /// - Important: This function checks whether a specific file within the Git repository is tracked by Git LFS in the repository's configuration. Ensure that the provided path is valid and that the repository is configured to use Git LFS.
    public func isTrackedByLFS(directoryURL: URL,
                               path: String) throws -> Bool {
        let result = try ShellClient.live().run(
            "cd \(directoryURL.relativePath.escapedWhiteSpaces());git check-attr filter \(path)")

        // "git check-attr -a" will output every filter it can find in .gitattributes
        // and it looks like this:
        //
        // README.md: diff: lfs
        // README.md: merge: lfs
        // README.md: text: unset
        // README.md: filter: lfs
        //
        // To verify git-lfs this test will just focus on that last row, "filter",
        // and the value associated with it. If nothing is found in .gitattributes
        // the output will look like this
        //
        // README.md: filter: unspecified
        let lfsFilterRegex = "/: filter: lfs/"

        let match = result.contains(lfsFilterRegex)

        return match
    }

    /// Query a Git repository to filter a set of provided relative paths and identify which files are not covered by the current Git LFS (Large File Storage) configuration.
    ///
    /// Git LFS is an extension for handling large files in a Git repository, and this function helps you determine which files are not tracked by Git LFS within the specified relative paths.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the Git repository.
    ///   - filePaths: A list of relative paths within the repository to check for Git LFS tracking.
    ///
    /// - Returns: An array of relative file paths that are not tracked by Git LFS in the repository.
    ///
    /// - Throws: An error if there was an issue querying the Git repository or if the provided paths are invalid.
    ///
    /// - Example:
    ///   ```swift
    ///   let repositoryURL = URL(fileURLWithPath: "/path/to/git/repo")
    ///   let pathsToCheck = ["file1.txt", "file2.jpg", "data/bigfile.dat"]
    ///
    ///   do {
    ///       let untrackedFiles = try filesNotTrackedByLFS(directoryURL: repositoryURL, filePaths: pathsToCheck)
    ///       if !untrackedFiles.isEmpty {
    ///           print("The following files are not tracked by Git LFS:")
    ///           for file in untrackedFiles {
    ///               print(file)
    ///           }
    ///       } else {
    ///           print("All files are tracked by Git LFS.")
    ///       }
    ///   } catch {
    ///       print("Error: \(error)")
    ///   }
    ///   ```
    ///
    /// - Important: This function checks which files within the specified relative paths are not tracked by Git LFS in the Git repository. Ensure that the provided paths are valid and that the repository is configured to use Git LFS.
    public func filesNotTrackedByLFS(directoryURL: URL,
                                     filePaths: [String]) throws -> [String] {
        var filesNotTrackedByGitLFS: [String] = []

        // Iterate through the provided relative file paths.
        for filePath in filePaths {
            // Check if the file is tracked by Git LFS.
            let isTracked = try isTrackedByLFS(directoryURL: directoryURL, path: filePath)

            // If not tracked by Git LFS, add it to the list.
            if !isTracked {
                filesNotTrackedByGitLFS.append(filePath)
            }
        }

        return filesNotTrackedByGitLFS
    }
}
