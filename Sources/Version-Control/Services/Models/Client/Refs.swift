//
//  Refs.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/08/12.
//  Copyright © 2022 Aurora Company. All rights reserved.
//  This source code is restricted for Aurora Editor usage only.
//

import Foundation

public struct Refs {
    
    public init() {}

    /// Format a local branch name as a Git ref syntax.
    ///
    /// In Git, branch names are often represented as refs, and this function converts a local branch name into the corresponding ref syntax. It ensures that situations where the branch name is ambiguous are handled correctly.
    ///
    /// - Parameter name: The local branch name to format.
    ///
    /// - Returns: The branch name in Git ref syntax, such as `refs/heads/main`.
    ///
    /// - Example:
    ///   ```swift
    ///   let localBranchName = "main"
    ///   let formattedRef = formatAsLocalRef(name: localBranchName)
    ///   print("Local Branch: \(localBranchName), Formatted Ref: \(formattedRef)")
    ///   ```
    ///
    /// - Note:
    ///   - If the `name` already starts with `refs/heads/`, it is considered fully qualified and is returned as-is.
    ///   - If the `name` starts with `heads/`, it is formatted as `refs/heads/<name>`.
    ///   - In all other cases, `refs/heads/` is added to the beginning of the branch name.
    ///
    /// - Returns: The branch name in Git ref syntax, such as `refs/heads/main`.
    public func formatAsLocalRef(name: String) -> String {
        if name.starts(with: "heads/") {
            // In some cases, Git may report the name explicitly to distinguish it from a remote ref with the same name.
            // This ensures we format it correctly.
            return "refs/\(name)"
        } else if !name.starts(with: "refs/heads/") {
            // By default, Git drops the `heads` prefix unless necessary. Include it to ensure the ref is fully qualified.
            return "refs/heads/\(name)"
        } else {
            return name
        }
    }

    /// Read the canonical ref pointed to by a symbolic ref in the Git repository.
    ///
    /// Symbolic refs in Git are references that point to other references, similar to symbolic links in a filesystem. They provide an additional layer of indirection. This function allows you to resolve a symbolic ref to its canonical ref, providing you with the actual reference it points to.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of the Git repository where the symbolic ref should be resolved.
    ///   - ref: The symbolic ref to resolve.
    ///
    /// - Throws: An error if there is a problem accessing the Git repository or executing the Git command to read the symbolic ref.
    ///
    /// - Returns: The canonical ref pointed to by the symbolic ref, or `nil` if the symbolic ref cannot be found or is not a symbolic ref.
    ///
    /// - Example:
    ///   ```swift
    ///   let localRepositoryURL = URL(fileURLWithPath: "/path/to/local/repository")
    ///   let symbolicRefName = "HEAD" // Example symbolic ref name
    ///
    ///   do {
    ///       if let canonicalRef = try getSymbolicRef(directoryURL: localRepositoryURL, ref: symbolicRefName) {
    ///           print("Symbolic Ref: \(symbolicRefName), Canonical Ref: \(canonicalRef)")
    ///       } else {
    ///           print("Symbolic Ref \(symbolicRefName) not found or is not a symbolic ref.")
    ///       }
    ///   } catch {
    ///       print("Error reading symbolic ref: \(error)")
    ///   }
    ///   ```
    ///
    /// - Note:
    ///   - The function executes the Git command `git symbolic-ref -q <ref>` to read the canonical ref pointed to by the symbolic ref.
    ///
    /// - Warning: Ensure that the provided `directoryURL` points to a valid Git repository directory. Failure to do so may result in errors or incorrect results.
    ///
    /// - Returns: The canonical ref pointed to by the symbolic ref, or `nil` if the symbolic ref cannot be found or is not a symbolic ref.
    public func getSymbolicRef(directoryURL: URL, ref: String) throws -> String? {
        let result = try ShellClient.live().run(
            "cd \(directoryURL.relativePath.escapedWhiteSpaces());git symbolic-ref -q \(ref)"
        )

        return result.trimmingCharacters(in: .whitespaces)
    }
}
