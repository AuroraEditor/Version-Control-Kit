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
    
    /// Create a Git tag in a repository.
    ///
    /// This function creates a Git tag with the specified `name` in a Git repository located at the specified `directoryURL`. The tag is associated with a target commit identified by its SHA (`targetCommitSha`).
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
    ///   This function uses the `git tag -a` command to create an annotated Git tag with the specified `name` and associates it with the target commit identified by `targetCommitSha`. The tag message is intentionally left empty.
    ///
    /// - Warning:
    ///   Be cautious when creating tags, especially annotated tags, as they can affect the history and versioning of a Git repository.
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
        
        try ShellClient().run(
            "cd \(directoryURL.relativePath.escapedWhiteSpaces());git \(args.joined(separator: " "))"
        )
    }


    /// Delete a Git tag from a repository.
    ///
    /// This function deletes a Git tag with the specified `name` from a Git repository located at the specified `directoryURL`.
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
        try ShellClient().run(
            "cd \(directoryURL.relativePath.escapedWhiteSpaces());git tag -d \(name)"
        )
    }

    /// Retrieve a dictionary of all Git tags in a repository.
    ///
    /// This asynchronous function retrieves a dictionary containing all Git tags in a Git repository located at the specified `directoryURL`. The dictionary maps tag names (strings) to their corresponding commit SHAs (strings).
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
    ///   This function uses the `git show-ref` command to retrieve a list of all Git tags and their associated commit SHAs. It normalizes tag names by removing the leading "refs/tags/" and trailing "^{}" from annotated tags.
    ///
    /// - Important:
    ///   This function is asynchronous and must be called from within an asynchronous context (e.g., an `async` function).
    func getAllTags(directoryURL: URL) async throws -> [String: String]? {
        var tags = [String: String]()
        
        let result = try ShellClient.live().run(
            "cd \(directoryURL.relativePath.escapedWhiteSpaces());git show-ref --tags -d"
        )

        let tagsArray = try result.stdout().split(separator: "\n").map { line in
            let components = line.split(separator: " ")

            let commitSha = String(components[0])
            var tagName = String(components[1])

            // Normalize tag names by removing the leading ref/tags/ and the trailing ^{}.
            //
            // git show-ref returns two entries for annotated tags:
            // deadbeef refs/tags/annotated-tag
            // de510b99 refs/tags/annotated-tag^{}
            //
            // The first entry sha correspond to the blob object of the annotation, while the second
            // entry corresponds to the actual commit where the tag was created.
            // By normalizing the tag name we can make sure that the commit sha gets stored in the returned
            // Map of commits (since git will always print the entry with the commit sha at the end).
            tagName = tagName
                .replacingOccurrences(of: "refs/tags/", with: "")
                .replacingOccurrences(of: "^{}", with: "")

            return (tagName, commitSha)
        }

        for (tagName, commitSha) in tagsArray where tagName != nil {
            tags[tagName] = commitSha
        }

        return tags
    }

    /// Fetch tags to be pushed to a remote Git repository.
    ///
    /// This function fetches the tags that are pending to be pushed to a remote Git repository specified by `remote`. It performs a dry run of the push operation to identify unpushed tags. The tags are then extracted from the Git command result.
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
    ///   let remote = GitRemote(name: "origin", url: "https://github.com/user/repo.git") // Replace with your Git remote details
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
    ///   This function performs a dry run of the push operation and parses the Git command result to identify unpushed tags. It removes the "refs/tags/" prefix from the tag names.
    public func fetchTagsToPush(directoryURL: URL,
                                remote: GitRemote,
                                branchName: String) throws -> [String] {
        let args: [Any] = [
            gitNetworkArguments,
            "push",
            remote.name,
            branchName,
            "--follow-tags",
            "--dry-run",
            "--no-verify",
            "--porcelain"
        ]

        let result = try ShellClient.live().run(
            "cd \(directoryURL.relativePath.escapedWhiteSpaces());git \(args)"
        )

        let lines = result.split(separator: "\n").map { String($0) }
        var currentLine = 1
        var unpushedTags: [String] = []

        while currentLine < lines.count && lines[currentLine] != "Done" {
            let line = lines[currentLine]
            let parts = line

            if parts.substring(0) == "*" && parts.substring(2) == "[new tag]" {
                let tagName = parts.substring(1).split(separator: ":").map {
                    String($0)
                }

                if !tagName.description.isEmpty {
                    unpushedTags.append(tagName.description.replacingOccurrences(of: "/^refs\\/tags\\//", with: ""))
                }
            }
            currentLine += 1
        }

        return unpushedTags
    }
}
