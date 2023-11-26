//
//  Tag.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/12.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

public struct Tag {

    public init() {}

    /// Create a Git tag in a repository.
    ///
    /// This function creates a Git tag with the specified `name` in a Git repository located \
    /// at the specified `directoryURL`. \
    /// The tag is associated with a target commit identified by its SHA (`targetCommitSha`).
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///   - name: The name of the Git tag to be created.
    ///   - targetCommitSha: The SHA of the target commit to which the tag will be associated.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the tag creation process.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repo") // Replace with the path to the Git repository
    ///   let tagName = "v1.0" // Replace with the desired tag name
    ///   let targetCommitSHA = "c3e9a7f" // Replace with the SHA of the target commit
    ///
    ///   do {
    ///       try createTag(directoryURL: directoryURL, name: tagName, targetCommitSha: targetCommitSHA)
    ///       print("Tag \(tagName) has been created.")
    ///   } catch {
    ///       print("Error creating tag \(tagName): \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   This function uses the `git tag -a` command to create an annotated Git tag with \
    ///   the specified `name` and associates it with the target commit identified by \
    ///   `targetCommitSha`. The tag message is intentionally left empty.
    ///
    /// - Warning:
    ///   Be cautious when creating tags, especially annotated tags, \
    ///   as they can affect the history and versioning of a Git repository.
    public func createTag(directoryURL: URL,
                          name: String,
                          targetCommitSha: String) throws {
        let args = [
            "tag",
             "-a",
             "-m",
             "",
             name,
             targetCommitSha
        ]

        try GitShell().git(args: args,
                           path: directoryURL,
                           name: #function)
    }

    /// Delete a Git tag from a repository.
    ///
    /// This function deletes a Git tag with the specified `name` from a Git repository located at \
    /// the specified `directoryURL`.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///   - name: The name of the Git tag to be deleted.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the tag deletion process.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repo") // Replace with the path to the Git repository
    ///   let tagName = "v1.0" // Replace with the name of the tag to be deleted
    ///
    ///   do {
    ///       try deleteTag(directoryURL: directoryURL, name: tagName)
    ///       print("Tag \(tagName) has been deleted.")
    ///   } catch {
    ///       print("Error deleting tag \(tagName): \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   This function uses the `git tag -d` command to delete the specified tag from the Git repository.
    public func deleteTag(directoryURL: URL, name: String) throws {

        let args = [
            "tag",
            "-d",
            name
        ]

        try GitShell().git(args: args,
                           path: directoryURL,
                           name: #function)
    }

    /// Retrieve a dictionary of all Git tags in a repository.
    ///
    /// This asynchronous function retrieves a dictionary containing all Git tags in a Git repository \
    /// located at the specified `directoryURL`. \
    /// The dictionary maps tag names (strings) to their corresponding commit SHAs (strings).
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///
    /// - Returns:
    ///   A dictionary where the keys are tag names and the values are commit SHAs.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the tag retrieval process.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repo") // Replace with the path to the Git repository
    ///
    ///   do {
    ///       let tags = try await getAllTags(directoryURL: directoryURL)
    ///       if let tags = tags, !tags.isEmpty {
    ///           print("Tags:")
    ///           for (tagName, commitSHA) in tags {
    ///               print("\(tagName): \(commitSHA)")
    ///           }
    ///       } else {
    ///           print("No Git tags found in the repository.")
    ///       }
    ///   } catch {
    ///       print("Error retrieving Git tags: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   This function uses the `git show-ref` command to retrieve a list of all Git tags and \
    ///   their associated commit SHAs. \
    ///   It normalizes tag names by removing the leading "refs/tags/" and trailing "^{}" from annotated tags.
    ///
    /// - Important:
    ///   This function is asynchronous and must be called from within an asynchronous context \
    ///   (e.g., an `async` function).
    func getAllTags(directoryURL: URL) throws -> [String: String] {
        let args = ["show-ref", "--tags", "-d"]

        let tags = try GitShell().git(args: args,
                                      path: directoryURL,
                                      name: #function,
                                      options: IGitExecutionOptions(
                                        successExitCodes: Set([0, 1])
                                      ))

        let tagsArray = tags.stdout.split(separator: "\n")
            .compactMap { line -> (String, String)? in
                let components = line.split(separator: " ", maxSplits: 1)
                guard components.count == 2,
                      let firstColonIndex = line.firstIndex(of: ":") else {
                    return nil
                }

                let commitSha = String(components[0])
                let tagName = line[line.index(after: firstColonIndex)...]
                    .replacingOccurrences(of: "refs/tags/", with: "")
                    .replacingOccurrences(of: "^{}", with: "")

                return (tagName, commitSha)
            }

        return Dictionary(uniqueKeysWithValues: tagsArray)
    }

    /// Fetch tags to be pushed to a remote Git repository.
    ///
    /// This function fetches the tags that are pending to be pushed to a remote Git repository specified by `remote`. \
    /// It performs a dry run of the push operation to identify unpushed tags. \
    /// The tags are then extracted from the Git command result.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the directory containing the Git repository.
    ///   - remote: The Git remote to which the tags will be pushed.
    ///   - branchName: The name of the branch associated with the push operation.
    ///
    /// - Throws:
    ///   - An error of type `Error` if any issues occur during the tag fetching process.
    ///
    /// - Returns:
    ///   An array of tag names (strings) that are pending to be pushed to the remote repository.
    ///
    /// - Example:
    ///   ```swift
    ///   let directoryURL = URL(fileURLWithPath: "/path/to/repo") // Replace with the path to the Git repository
    ///   let remote = GitRemote(
    ///       name: "origin",
    ///       url: "https://github.com/user/repo.git"
    ///   ) // Replace with your Git remote details
    ///   let branchName = "main" // Replace with the name of the branch associated with the push operation
    ///
    ///   do {
    ///       let unpushedTags = try fetchTagsToPush(directoryURL: directoryURL, remote: remote, branchName: branchName)
    ///       if !unpushedTags.isEmpty {
    ///           print("Unpushed Tags: \(unpushedTags)")
    ///       } else {
    ///           print("No unpushed tags found.")
    ///       }
    ///   } catch {
    ///       print("Error fetching unpushed tags: \(error.localizedDescription)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   This function performs a dry run of the push operation and parses the Git command \
    ///   result to identify unpushed tags. It removes the "refs/tags/" prefix from the tag names.
    func fetchTagsToPush(directoryURL: URL,
                         account: IGitAccount?,
                         remote: IRemote,
                         branchName: String) throws -> [String] {
        let args: [String] = [
            gitNetworkArguments.joined(),
            "push",
            remote.name,
            branchName,
            "--follow-tags",
            "--dry-run",
            "--no-verify",
            "--porcelain"
        ]

        let result = try GitShell().git(args: args,
                                        path: directoryURL,
                                        name: #function,
                                        options: IGitExecutionOptions(
                                            env: [
                                                "login": account?.login ?? "",
                                                "endpoint": account?.endpoint ?? ""
                                            ],
                                            successExitCodes: Set([0, 1, 128])
                                        ))

        guard result.exitCode == 0 || result.exitCode == 1 else {
            return []
        }

        let lines = result.stdout.split(separator: "\n")
        var unpushedTags = [String]()

        for (index, line) in lines.dropFirst().enumerated() {
            if let firstColonIndex = line.firstIndex(of: ":"),
               line.hasPrefix("*") {
                let tagName = String(line[..<firstColonIndex])
                unpushedTags.append(tagName.replacingOccurrences(of: "refs/tags/", with: ""))
            }

            if index == lines.count - 2 {
                break // 'Done' line reached
            }
        }

        return unpushedTags
    }
}
