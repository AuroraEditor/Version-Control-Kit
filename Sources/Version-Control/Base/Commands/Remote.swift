//
//  Remote.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/12.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

public struct Remote {

    public init() {}

    /// Retrieve a list of Git remotes associated with a local repository.
    ///
    /// This function lists the Git remotes configured for a given local Git repository. \
    /// It returns an array of `GitRemote` objects, each representing a remote repository with a name and URL.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the local Git repository for which to retrieve the remotes.
    ///
    /// - Throws: An error if there is a problem accessing the Git repository or \
    ///           executing the Git command to retrieve remotes.
    ///
    /// - Returns: An array of `GitRemote` objects representing the Git remotes configured for the local repository.
    ///
    /// - Example:
    ///   ```swift
    ///   let localRepositoryURL = URL(fileURLWithPath: "/path/to/local/repository")
    ///
    ///   do {
    ///       let remotes = try getRemotes(directoryURL: localRepositoryURL)
    ///       print("Git Remotes:")
    ///       for remote in remotes {
    ///           print("Name: \(remote.name), URL: \(remote.url)")
    ///       }
    ///   } catch {
    ///       print("Error retrieving remotes: \(error)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   - The function executes the Git command `git remote -v`\
    ///     to retrieve the list of Git remotes configured for the local repository.
    ///
    /// - Warning: Ensure that the provided `directoryURL` points to a valid local Git repository directory.\
    ///   Failure to do so may result in errors or incorrect results.
    ///
    /// - Returns: An array of `GitRemote` objects representing the configured Git remotes for the local repository.
    public func getRemotes(directoryURL: URL) throws -> [GitRemote] {
        let result = try GitShell().git(args: ["remote", "-v"],
                                        path: directoryURL,
                                        name: #function)

        // Check for Git errors
        if let gitError = result.gitError, gitError == .NotAGitRepository {
            return []
        }

        // Process the output into an array of IRemote
        let output = result.stdout
        let lines = output.components(separatedBy: "\n")
        let remotes = lines
            .filter { $0.contains("(fetch)") }
            .map { $0.split(whereSeparator: { $0.isWhitespace }).map(String.init) }
            .compactMap { parts in
                // Ensure we have at least two parts: remote name and URL
                if parts.count >= 2 {
                    return GitRemote(name: parts[0], url: parts[1])
                }
                return nil
            }

        return remotes
    }

    /// Add a new Git remote repository with the specified name and URL.
    ///
    /// Use this function to add a new Git remote repository to the local repository,
    /// providing a name for the remote and its URL. \
    /// If the remote repository with the given name already exists,
    /// the function updates the URL of the existing remote to the new URL.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the local Git repository where the remote will be added.
    ///   - name: The name for the new remote repository.
    ///   - url: The URL of the remote Git repository.
    ///
    /// - Throws: An error if there is a problem accessing the Git repository or \
    ///           executing the Git command to add the remote repository.
    ///
    /// - Returns: A `GitRemote` object representing the added remote repository with its name and URL.
    ///
    /// - Example:
    ///   ```swift
    ///   let localRepositoryURL = URL(fileURLWithPath: "/path/to/local/repository")
    ///   let remoteName = "my-remote"
    ///   let remoteURL = "https://github.com/myusername/myrepo.git"
    ///
    ///   do {
    ///       let addedRemote = try addRemote(directoryURL: localRepositoryURL, name: remoteName, url: remoteURL)
    ///       print("Remote '\(addedRemote.name)' added with URL: \(addedRemote.url)")
    ///   } catch {
    ///       print("Error adding remote: \(error)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   - The function executes the Git command `git remote add <remote-name> <remote-url>` \
    ///     to add or update a remote repository. \
    ///     If a remote with the specified name already exists, it updates the URL to the new URL.
    ///
    /// - Warning: Be cautious when passing user-provided remote names and URLs to this function, \
    ///            as it may execute arbitrary Git commands. \
    ///            Ensure that input is properly validated and sanitized to prevent command injection vulnerabilities.
    ///
    /// - Returns: A `GitRemote` object representing the added or updated remote repository with its name and URL.
    public func addRemote(directoryURL: URL, name: String, url: String) throws -> GitRemote? {
        try GitShell().git(args: ["remote", "add", name, url],
                           path: directoryURL,
                           name: #function)

        return GitRemote(name: name, url: url)
    }

    /// Remove an existing Git remote repository by its name or silently ignore if it doesn't exist.
    ///
    /// Use this function to remove an existing Git remote repository specified by its remote name.\
    /// If the remote with the given name does not exist, the function silently ignores the operation.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the local Git repository.
    ///   - name: The name of the remote repository to remove.
    ///
    /// - Throws: An error if there is a problem accessing the Git repository or \
    ///           executing the Git command to remove the remote repository.
    ///
    /// - Example:
    ///   ```swift
    ///   let localRepositoryURL = URL(fileURLWithPath: "/path/to/local/repository")
    ///   let remoteName = "my-remote"
    ///
    ///   do {
    ///       try removeRemote(directoryURL: localRepositoryURL, name: remoteName)
    ///       print("Remote '\(remoteName)' successfully removed or does not exist.")
    ///   } catch {
    ///       print("Error removing remote: \(error)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   - The function executes the Git command `git remote remove <remote-name>` to \
    ///     remove the remote repository. \
    ///     If the remote with the specified name does not exist, it does not raise an error.
    ///
    /// - Warning: Be cautious when passing user-provided remote names to this function, \
    ///            as it may execute arbitrary Git commands. \
    ///            Ensure that input is properly validated and sanitized to prevent command injection vulnerabilities.
    public func removeRemote(directoryURL: URL, name: String) throws {
        try GitShell().git(args: ["remote", "remove", name],
                           path: directoryURL,
                           name: #function,
                           options: IGitExecutionOptions(successExitCodes: Set([0, 2, 128])))
    }

    /// Change the URL of a Git remote repository by its name.
    ///
    /// Use this function to update the URL of a Git remote repository specified by its remote name. \
    /// The function executes a Git command to change the URL of the specified remote repository.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the local Git repository.
    ///   - name: The name of the remote repository for which to change the URL.
    ///   - url: The new URL to set for the remote Git repository.
    ///
    /// - Throws: An error if there is a problem accessing the Git repository or \
    ///           executing the Git command to change the remote's URL.
    ///
    /// - Returns: `true` if the URL was successfully updated; otherwise, `false`.
    ///
    /// - Example:
    ///   ```swift
    ///   let localRepositoryURL = URL(fileURLWithPath: "/path/to/local/repository")
    ///   let remoteName = "origin"
    ///   let newRemoteURL = "https://new-remote-url.com/repository.git"
    ///
    ///   do {
    ///       if try setRemoteURL(directoryURL: localRepositoryURL, name: remoteName, url: newRemoteURL) {
    ///           print("URL for remote '\(remoteName)' successfully updated.")
    ///       } else {
    ///           print("Failed to update URL for remote '\(remoteName)'.")
    ///       }
    ///   } catch {
    ///       print("Error changing remote URL: \(error)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   - The function executes the Git command `git remote set-url <remote-name> <new-url>` to\
    ///     change the URL of the specified remote repository.
    ///   - It returns `true` if the URL was successfully updated, and `false` otherwise.
    ///
    /// - Warning: Be cautious when passing user-provided remote names and URLs to this function, \
    ///            as it may execute arbitrary Git commands. \
    ///            Ensure that input is properly validated and sanitized to prevent command injection vulnerabilities.
    public func setRemoteURL(directoryURL: URL, name: String, url: String) throws -> Bool {
        try GitShell().git(args: ["remote", "set-url", name, url],
                           path: directoryURL,
                           name: #function)

        return true
    }

    /// Get the URL associated with a Git remote repository by its name.
    ///
    /// Use this function to retrieve the URL of a Git remote repository specified by its remote name. \
    /// The function executes a Git command to obtain the URL of the specified remote repository.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the local Git repository.
    ///   - name: The name of the remote repository for which to fetch the URL.
    ///
    /// - Throws: An error if there is a problem accessing the Git repository or \
    ///           executing the Git command to retrieve the remote's URL.
    ///
    /// - Returns: A string representing the URL of the remote Git repository, \
    ///            or `nil` if the specified remote repository could not be found.
    ///
    /// - Example:
    ///   ```swift
    ///   let localRepositoryURL = URL(fileURLWithPath: "/path/to/local/repository")
    ///   let remoteName = "origin"
    ///
    ///   do {
    ///       if let remoteURL = try getRemoteURL(directoryURL: localRepositoryURL, name: remoteName) {
    ///           print("URL for remote '\(remoteName)': \(remoteURL)")
    ///       } else {
    ///           print("Remote '\(remoteName)' not found.")
    ///       }
    ///   } catch {
    ///       print("Error retrieving remote URL: \(error)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   - The function executes the Git command `git remote get-url <remote-name>` to \
    ///     retrieve the URL of the specified remote repository.
    ///   - If the specified remote repository does not exist, the function returns `nil`.
    ///
    /// - Warning: Be cautious when passing user-provided remote names to this function, \
    ///            as it may execute arbitrary Git commands. \
    ///            Ensure that input is properly validated and sanitized to prevent command injection vulnerabilities.
    public func getRemoteURL(directoryURL: URL, name: String) async throws -> String? {

        let result = try await GitShell().git(args: ["remote",
                                                     "get-url",
                                                     name],
                                              path: directoryURL,
                                              name: #function,
                                              options: IGitExecutionOptions(successExitCodes: Set([0, 2, 128])))

        if result.exitCode != 0 {
            return nil
        }

        return result.stdout
    }

    /// Update the HEAD reference for a remote Git repository.
    ///
    /// Use this function to update the HEAD reference of a remote Git repository associated
    /// with a specific remote name. \
    /// The function executes a Git command to set the HEAD reference of the remote repository
    /// to its default branch (usually the main branch).
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the local Git repository.
    ///   - remote: An instance of `IRemote` representing the remote repository to update.
    ///
    /// - Throws: An error if there is a problem accessing the Git repository or executing \
    ///           the Git command to update the remote's HEAD reference.
    ///
    /// - Note:
    ///   - The function executes the Git command `git remote set-head -a <remote-name>` \
    ///     to update the remote's HEAD reference to its default branch. \
    ///     This operation is typically used to synchronize the remote's HEAD reference with its default branch.
    ///
    /// - Example:
    ///   ```swift
    ///   let localRepositoryURL = URL(fileURLWithPath: "/path/to/local/repository")
    ///   let remote = GitRemote(name: "origin", url: "https://github.com/your/repo.git")
    ///
    ///   do {
    ///       try updateRemoteHEAD(directoryURL: localRepositoryURL, remote: remote)
    ///       print("Remote HEAD reference updated for remote '\(remote.name)'.")
    ///   } catch {
    ///       print("Error updating remote HEAD reference: \(error)")
    ///   }
    ///   ```
    public func updateRemoteHEAD(directoryURL: URL, remote: IRemote) throws {
        try GitShell().git(args: [gitNetworkArguments.joined(),
                                  "remote",
                                  "set-head",
                                  "-a",
                                  remote.name],
                           path: directoryURL,
                           name: #function,
                           options: IGitExecutionOptions(successExitCodes: Set([0, 1, 128])))
    }

    /// Get the name of the HEAD branch in a remote Git repository.
    ///
    /// Use this function to retrieve the name of the HEAD branch in a remote Git repository
    /// associated with a specific remote name. \
    /// The function constructs the reference path for the remote's HEAD and retrieves it using the `Refs` utility.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the local Git repository.
    ///   - remote: The name of the remote repository for which to fetch the HEAD branch.
    ///
    /// - Throws: An error if there is a problem accessing the Git repository or retrieving the remote's HEAD reference.
    ///
    /// - Returns: A string representing the name of the HEAD branch in the remote repository, or `nil` if not found.
    ///
    /// - Example:
    ///   ```swift
    ///   let localRepositoryURL = URL(fileURLWithPath: "/path/to/local/repository")
    ///   let remoteName = "origin"
    ///
    ///   do {
    ///       if let remoteHEAD = try getRemoteHEAD(directoryURL: localRepositoryURL, remote: remoteName) {
    ///           print("Remote HEAD: \(remoteHEAD)")
    ///       } else {
    ///           print("Remote HEAD not found for remote '\(remoteName)'.")
    ///       }
    ///   } catch {
    ///       print("Error fetching remote HEAD reference: \(error)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   - This function constructs the reference path for the remote's HEAD using the provided \
    ///     `remote` name and then fetches the reference using the `Refs` utility.
    ///   - The function returns `nil` if the remote's HEAD reference is not found or \
    ///     if there is an error in the process.
    public func getRemoteHEAD(directoryURL: URL, remote: String) throws -> String? {
        let remoteNamespace = "refs/remotes/\(remote)/"
        if let match = try Refs().getSymbolicRef(directoryURL: directoryURL, ref: "\(remoteNamespace)HEAD"),
           match.count > remoteNamespace.count,
           match.starts(with: remoteNamespace) {
            return match.substring(remoteNamespace.count)
        }

        return nil
    }

    /// Retrieve the latest commit hash and reference for a given remote Git repository and branch.
    ///
    /// This function executes the `git ls-remote` command to fetch the latest commit hash and reference
    /// for a specified remote Git repository and branch.
    ///
    /// - Parameters:
    ///   - repoURL: The URL of the remote Git repository.
    ///   - branch: The branch for which to fetch the latest commit hash and reference.
    ///
    /// - Throws: An error if there is a problem accessing the Git repository or executing the Git command.
    ///
    /// - Returns: A tuple containing the latest commit hash and reference for the specified branch.
    ///
    /// - Example:
    ///   ```swift
    ///   let repoURL = "https://github.com/AuroraEditor/AuroraEditor.git"
    ///   let branch = "development"
    ///
    ///   do {
    ///       let (commitHash, ref) = try getLatestCommitHashAndRef(repoURL: repoURL, branch: branch)
    ///       print("Latest Commit Hash: \(commitHash), Reference: \(ref)")
    ///   } catch {
    ///       print("Error retrieving latest commit hash and reference: \(error)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   - The function executes the `git ls-remote` command with the specified repository URL and branch
    ///     to fetch the latest commit hash and reference.
    ///   - Ensure that the provided `repoURL` and `branch` are valid and accessible.
    ///
    /// - Returns: A tuple containing the latest commit hash and reference for the specified branch.
    public func getLatestCommitHashAndRef(
        directoryURL: URL,
        repoURL: String,
        branch: String
    ) async throws -> (commitHash: String, ref: String) {
        let result = try await GitShell().git(
            args: [
                "ls-remote",
                repoURL,
                branch
            ],
            path: directoryURL,
            name: #function
        )

        guard result.exitCode == 0 else {
            throw NSError(
                domain: "Remote",
                code: Int(
                    result.exitCode
                ),
                userInfo: [NSLocalizedDescriptionKey: "Failed to execute git command"]
            )
        }

        guard let line = result.stdout.split(separator: "\n").first else {
            throw NSError(
                domain: "Remote",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No output from git command"]
            )
        }

        let parts = line.split(separator: "\t")
        guard parts.count == 2 else {
            throw NSError(
                domain: "Remote",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Unexpected output format"]
            )
        }

        let commitHash = String(parts[0])
        let ref = String(parts[1])

        return (commitHash, ref)
    }
}
