//
//  Remote.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/12.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

/// Retrieve a list of Git remotes associated with a local repository.
///
/// This function lists the Git remotes configured for a given local Git repository. It returns an array of `GitRemote` objects, each representing a remote repository with a name and URL.
///
/// - Parameters:
///   - directoryURL: The URL of the local Git repository for which to retrieve the remotes.
///
/// - Throws: An error if there is a problem accessing the Git repository or executing the Git command to retrieve remotes.
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
    let result = try ShellClient.live().run(
        "cd \(directoryURL.relativePath.escapedWhiteSpaces());git remote -v"
    )

    if result.contains(GitError.notAGitRepository.rawValue) {
        return []
    }

    let lines = result.split(separator: "\n")
    let remotes = lines.filter {
        $0.hasSuffix("(fetch)")
    }.map {
        $0.split(separator: "\t")
    }.map {
        GitRemote(name: $0[0].description, url: $0[1].description)
    }

    return remotes
}

/// Add a new Git remote repository with the specified name and URL.
///
/// Use this function to add a new Git remote repository to the local repository, providing a name for the remote and its URL. If the remote repository with the given name already exists, the function updates the URL of the existing remote to the new URL.
///
/// - Parameters:
///   - directoryURL: The URL of the local Git repository where the remote will be added.
///   - name: The name for the new remote repository.
///   - url: The URL of the remote Git repository.
///
/// - Throws: An error if there is a problem accessing the Git repository or executing the Git command to add the remote repository.
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
///   - The function executes the Git command `git remote add <remote-name> <remote-url>` to add or update a remote repository. If a remote with the specified name already exists, it updates the URL to the new URL.
///
/// - Warning: Be cautious when passing user-provided remote names and URLs to this function, as it may execute arbitrary Git commands. Ensure that input is properly validated and sanitized to prevent command injection vulnerabilities.
///
/// - Returns: A `GitRemote` object representing the added or updated remote repository with its name and URL.
public func addRemote(directoryURL: URL, name: String, url: String) throws -> GitRemote? {
    try ShellClient.live().run(
        "cd \(directoryURL.relativePath.escapedWhiteSpaces());git remote add \(name) \(url)"
    )

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
/// - Throws: An error if there is a problem accessing the Git repository or executing the Git command to remove the remote repository.
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
///   - The function executes the Git command `git remote remove <remote-name>` to remove the remote repository. If the remote with the specified name does not exist, it does not raise an error.
///
/// - Warning: Be cautious when passing user-provided remote names to this function, as it may execute arbitrary Git commands. Ensure that input is properly validated and sanitized to prevent command injection vulnerabilities.
public func removeRemote(directoryURL: URL, name: String) throws {
    try ShellClient().run(
        "cd \(directoryURL.relativePath.escapedWhiteSpaces());git remote remove \(name)"
    )
}

/// Change the URL of a Git remote repository by its name.
///
/// Use this function to update the URL of a Git remote repository specified by its remote name. The function executes a Git command to change the URL of the specified remote repository.
///
/// - Parameters:
///   - directoryURL: The URL of the local Git repository.
///   - name: The name of the remote repository for which to change the URL.
///   - url: The new URL to set for the remote Git repository.
///
/// - Throws: An error if there is a problem accessing the Git repository or executing the Git command to change the remote's URL.
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
///   - The function executes the Git command `git remote set-url <remote-name> <new-url>` to change the URL of the specified remote repository.
///   - It returns `true` if the URL was successfully updated, and `false` otherwise.
///
/// - Warning: Be cautious when passing user-provided remote names and URLs to this function, as it may execute arbitrary Git commands. Ensure that input is properly validated and sanitized to prevent command injection vulnerabilities.
public func setRemoteURL(directoryURL: URL, name: String, url: String) throws -> Bool {
    try ShellClient().run(
        "cd \(directoryURL.relativePath.escapedWhiteSpaces());git remote set-url \(name) \(url)"
    )

    return true
}

/// Get the URL associated with a Git remote repository by its name.
///
/// Use this function to retrieve the URL of a Git remote repository specified by its remote name. The function executes a Git command to obtain the URL of the specified remote repository.
///
/// - Parameters:
///   - directoryURL: The URL of the local Git repository.
///   - name: The name of the remote repository for which to fetch the URL.
///
/// - Throws: An error if there is a problem accessing the Git repository or executing the Git command to retrieve the remote's URL.
///
/// - Returns: A string representing the URL of the remote Git repository, or `nil` if the specified remote repository could not be found.
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
///   - The function executes the Git command `git remote get-url <remote-name>` to retrieve the URL of the specified remote repository.
///   - If the specified remote repository does not exist, the function returns `nil`.
///
/// - Warning: Be cautious when passing user-provided remote names to this function, as it may execute arbitrary Git commands. Ensure that input is properly validated and sanitized to prevent command injection vulnerabilities.
public func getRemoteURL(directoryURL: URL, name: String) throws -> String? {
    let result = try ShellClient.live().run(
        "cd \(directoryURL.relativePath.escapedWhiteSpaces());git remote get-url \(name)"
    )

    return result.trimmingCharacters(in: .whitespacesAndNewlines)
}

/// Update the HEAD reference for a remote Git repository.
///
/// Use this function to update the HEAD reference of a remote Git repository associated with a specific remote name. The function executes a Git command to set the HEAD reference of the remote repository to its default branch (usually the main branch).
///
/// - Parameters:
///   - directoryURL: The URL of the local Git repository.
///   - remote: An instance of `IRemote` representing the remote repository to update.
///
/// - Throws: An error if there is a problem accessing the Git repository or executing the Git command to update the remote's HEAD reference.
///
/// - Note:
///   - The function executes the Git command `git remote set-head -a <remote-name>` to update the remote's HEAD reference to its default branch. This operation is typically used to synchronize the remote's HEAD reference with its default branch.
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
    try ShellClient().run(
        "cd \(directoryURL.relativePath.escapedWhiteSpaces());git remote set-head -a \(remote.name)"
    )
}

/// Get the name of the HEAD branch in a remote Git repository.
///
/// Use this function to retrieve the name of the HEAD branch in a remote Git repository associated with a specific remote name. The function constructs the reference path for the remote's HEAD and retrieves it using the `Refs` utility.
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
///   - This function constructs the reference path for the remote's HEAD using the provided `remote` name and then fetches the reference using the `Refs` utility.
///   - The function returns `nil` if the remote's HEAD reference is not found or if there is an error in the process.
public func getRemoteHEAD(directoryURL: URL, remote: String) throws -> String? {
    let remoteNamespace = "refs/remotes/\(remote)/"
    let match = try Refs().getSymbolicRef(directoryURL: directoryURL, ref: "\(remoteNamespace)HEAD")

    if match != nil && match!.count > remoteNamespace.count
        && match!.starts(with: remoteNamespace) {
        return match!.substring(remoteNamespace.count)
    }

    return nil
}

/// Get the HEAD branch reference from a remote Git repository hosted at the specified URL.
///
/// Use this function to retrieve the reference of the HEAD branch from a remote Git repository hosted at the given URL. The function runs a Git command to fetch the HEAD reference information and processes the output to extract the branch name.
///
/// - Parameters:
///   - url: The URL of the remote Git repository from which to fetch the HEAD reference.
///
/// - Throws: An error if there is a problem running the Git command or processing its output.
///
/// - Returns: A string representing the name of the HEAD branch in the remote repository.
///
/// - Example:
///   ```swift
///   let repositoryURL = "https://github.com/example/repo.git"
///
///   do {
///       let remoteHEAD = try getRemoteHEAD(url: repositoryURL)
///       print("Remote HEAD: \(remoteHEAD)")
///   } catch {
///       print("Error fetching remote HEAD reference: \(error)")
///   }
///   ```
///
/// - Note:
///   - This function fetches the HEAD reference information from a remote Git repository at the specified URL.
///   - It extracts the name of the HEAD branch from the Git command output, removing any empty or unnecessary characters.
public func getRemoteHEAD(url: String) throws -> String {
    return try ShellClient.live().run(
        "git ls-remote -q --symref \(url) | head -1 | cut -f1 | sed 's!^ref: refs/heads/!!'"
    ).components(separatedBy: "\n").filter { !$0.isEmpty }.first ?? ""
}

/// Get a list of remote branches from a Git repository hosted at the specified URL.
///
/// Use this function to retrieve a list of remote branch names from a Git repository hosted at the given URL. The function runs a Git command to fetch remote branch information and processes the output to extract branch names.
///
/// - Parameters:
///   - url: The URL of the remote Git repository from which to fetch branch information.
///
/// - Throws: An error if there is a problem running the Git command or processing its output.
///
/// - Returns: An array of strings representing the names of remote branches in the repository.
///
/// - Example:
///   ```swift
///   let repositoryURL = "https://github.com/example/repo.git"
///
///   do {
///       let remoteBranches = try getRemoteBranch(url: repositoryURL)
///       print("Remote branches: \(remoteBranches)")
///   } catch {
///       print("Error fetching remote branches: \(error)")
///   }
///   ```
///
/// - Note:
///   - This function fetches remote branch information from a Git repository at the specified URL.
///   - It extracts the names of remote branches from the Git command output, removing any empty or non-branch entries.
public func getRemoteBranch(url: String) throws -> [String] {
    return try ShellClient.live().run(
        "git ls-remote \(url) --h --sort origin \"refs/heads/*\" | cut -f2 | sed 's!^refs/heads/!!'"
    ).components(separatedBy: "\n").filter { !$0.isEmpty }
}
